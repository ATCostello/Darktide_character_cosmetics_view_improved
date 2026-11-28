local mod = get_mod("character_cosmetics_view_improved")
local MasterItems = require("scripts/backend/master_items")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UISettings = require("scripts/settings/ui/ui_settings")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local InventoryCosmeticsView = require("scripts/ui/views/inventory_cosmetics_view/inventory_cosmetics_view")
local StoreView = require("scripts/ui/views/store_view/store_view")

local previewed_items = {}
Selected_purchase_offer = {}
current_commodores_offers = {}

local function clear_commodores_offers()
	table.clear(current_commodores_offers)
end

-- 1 = Penance, 2 = Commisary, 3 = Commodore's Vestures, 4 = Hestia's Blessings

mod.on_all_mods_loaded = function()
	mod.get_wishlist()
end

mod:hook_safe(CLASS.InventoryCosmeticsView, "_start_show_layout", function(self, element)
	mod.get_wishlist()

	mod.list_premium_cosmetics(self)
	mod.focus_on_item(self, previewed_items)
	self._commodores_toggle = mod:get("show_commodores") or "loc_VPCC_show_all_commodores"
end)

mod:hook_safe(CLASS.InventoryCosmeticsView, "on_exit", function(self, element)
	mod.set_wishlist()
end)

mod:hook_safe(CLASS.InventoryView, "on_exit", function(self, element)
	previewed_items = {}
	Selected_purchase_offer = {}
	clear_commodores_offers()
end)

mod:hook_safe(CLASS.ViewElementGrid, "_on_present_grid_layout_changed", function(self, layout, content_blueprints, ...)
	if content_blueprints and content_blueprints.gear_item then
		content_blueprints.gear_item.unload_icon = function() end
	end
end)

mod.is_unobtainable = function(item)
	if not item then
		return false
	end

	if item.source == nil or (item.source == "none" and item.always_owned == false) then
		return true
	end

	return false
end

mod.get_wishlist = function()
	wishlisted_items = mod:get("wishlisted_items")

	if wishlisted_items == nil then
		wishlisted_items = {}
	end
end

mod.set_wishlist = function()
	mod:set("wishlisted_items", wishlisted_items)
end

local function is_on_wishlist(dev_name)
	if not dev_name or not wishlisted_items then
		return false
	end

	for i = 1, #wishlisted_items do
		local item = wishlisted_items[i]

		if item and item.dev_name == dev_name then
			return true
		end
	end

	return false
end

mod.focus_on_item = function(self, items)
	if not items or not self or not self._item_grid then
		return
	end

	local item_grid = self._item_grid
	local widgets = item_grid:widgets() or {}

	for slot, item in pairs(items) do
		if item and item.__master_item then
			local item_name = item.__master_item.name

			for i = 1, #widgets do
				local widget = widgets[i]
				local content = widget and widget.content
				local element_item = content and content.item
				local element_master_item = element_item and element_item.__master_item

				if element_master_item and item_name and element_master_item.name == item_name then
					local widget_index = item_grid:widget_index(widget)

					if widget_index then
						local scrollbar_animation_progress = item_grid:get_scrollbar_percentage_by_index(widget_index)
							or 0
						local instant_scroll = true
						local ui_manager = Managers.ui

						item_grid:focus_grid_index(
							widget_index,
							math.min(scrollbar_animation_progress + 0.05, 1),
							instant_scroll
						)

						if ui_manager and not ui_manager:using_cursor_navigation() then
							item_grid:select_grid_index(widget_index)
						end

						break
					end
				end
			end
		end
	end
end

InventoryCosmeticsView.cb_on_preview_pressed = function(self)
	local previewed_item = self._previewed_item
	local presentation_profile = self._presentation_profile
	local presentation_loadout = presentation_profile and presentation_profile.loadout
	local preview_profile_equipped = self._preview_profile_equipped_items
	local slots = previewed_item and previewed_item.slots
	local slot = slots and slots[1]

	if previewed_item and presentation_loadout and preview_profile_equipped and slot then
		local item_type = previewed_item.item_type
		local ITEM_TYPES = UISettings.ITEM_TYPES

		if item_type == ITEM_TYPES.GEAR_LOWERBODY or item_type == ITEM_TYPES.GEAR_UPPERBODY then
			self:_play_sound(UISoundEvents.apparel_equip)
		elseif
			item_type == ITEM_TYPES.GEAR_HEAD
			or item_type == ITEM_TYPES.EMOTE
			or item_type == ITEM_TYPES.END_OF_ROUND
			or item_type == ITEM_TYPES.GEAR_EXTRA_COSMETIC
		then
			self:_play_sound(UISoundEvents.apparel_equip_small)
		elseif item_type == ITEM_TYPES.PORTRAIT_FRAME or item_type == ITEM_TYPES.CHARACTER_INSIGNIA then
			self:_play_sound(UISoundEvents.apparel_equip_frame)
		elseif item_type == ITEM_TYPES.CHARACTER_TITLE then
			self:_play_sound(UISoundEvents.title_equip)
		else
			self:_play_sound(UISoundEvents.apparel_equip)
		end

		presentation_loadout[slot] = previewed_item
		preview_profile_equipped[slot] = previewed_item
		previewed_items[slot] = previewed_item
		local preview_button = self._widgets_by_name and self._widgets_by_name.preview_button

		if preview_button and preview_button.content and preview_button.content.hotspot then
			preview_button.content.hotspot.disabled = true
		end
	end
end

InventoryCosmeticsView.cb_on_wishlist_pressed = function(self)
	if self._previewed_item and self._previewed_item.__master_item then
		local previewed_item = self._previewed_item
		local previewed_item_name = previewed_item.__master_item.name
		local previewed_item_dev_name = previewed_item.__master_item.dev_name
		local previewed_item_display_name = previewed_item.__master_item.display_name
		local previewed_item_gearid = previewed_item.__gear_id
		local widgets_by_name = self._widgets_by_name
		local wishlist_button = widgets_by_name and widgets_by_name.wishlist_button

		local already_on_wishlist = false

		if wishlisted_items ~= nil and not table.is_empty(wishlisted_items) then
			for i = #wishlisted_items, 1, -1 do
				local item = wishlisted_items[i]

				if item and item.dev_name == previewed_item_dev_name then
					already_on_wishlist = true
					table.remove(wishlisted_items, i)
					self:_play_sound(UISoundEvents.notification_default_exit)

					if wishlist_button and wishlist_button.style then
						wishlist_button.style.background_gradient.default_color =
							Color.terminal_background_gradient(nil, true)
					end
					local text = Localize(item.display_name or "") .. Localize("loc_VPCC_wishlist_removed")
					local event_manager = Managers.event

					if event_manager then
						event_manager:trigger("event_add_notification_message", "default", text)
					end

					break
				end
			end
		end

		if not already_on_wishlist then
			local temp = {
				name = previewed_item_name,
				dev_name = previewed_item_dev_name,
				gearid = previewed_item_gearid,
				display_name = previewed_item_display_name,
			}

			wishlisted_items = wishlisted_items or {}
			wishlisted_items[#wishlisted_items + 1] = temp

			self:_play_sound(UISoundEvents.notification_default_enter)

			if wishlist_button and wishlist_button.style then
				wishlist_button.style.background_gradient.default_color = Color.terminal_text_warning_light(nil, true)
			end

			local text = Localize(previewed_item_display_name or "") .. Localize("loc_VPCC_wishlist_added")
			local event_manager = Managers.event

			if event_manager then
				event_manager:trigger("event_add_notification_message", "default", text)
			end
		end

		mod.set_wishlist()
		mod.update_wishlist_icons(self)
	end
end

mod:hook_safe(CLASS.InventoryCosmeticsView, "_update_equip_button_status", function(self)
	-- If the equip button is enabled, do not show the preview button.
	if self._equip_button_status == "disabled" then
		self._preview_button_disabled = false
	else
		self._preview_button_disabled = true
	end

	local preview_button = self._widgets_by_name and self._widgets_by_name.preview_button

	if preview_button and preview_button.content then
		preview_button.content.visible = not self._preview_button_disabled
	end
end)

mod:hook_safe(CLASS.InventoryCosmeticsView, "_register_button_callbacks", function(self)
	local widgets_by_name = self._widgets_by_name

	if not widgets_by_name then
		return
	end

	local preview_button = widgets_by_name.preview_button
	local store_button = widgets_by_name.store_button
	local wishlist_button = widgets_by_name.wishlist_button

	if preview_button and preview_button.content and preview_button.content.hotspot then
		preview_button.content.hotspot.pressed_callback = callback(self, "cb_on_preview_pressed")
	end

	if store_button and store_button.content and store_button.content.hotspot then
		store_button.content.hotspot.pressed_callback = callback(self, "cb_on_store_pressed")
	end

	if wishlist_button and wishlist_button.content and wishlist_button.content.hotspot then
		wishlist_button.content.hotspot.pressed_callback = callback(self, "cb_on_wishlist_pressed")
	end
end)

mod:hook_safe(
	CLASS.InventoryCosmeticsView,
	"_set_preview_widgets_visibility",
	function(self, visible, allow_equip_button)
		local widgets_by_name = self._widgets_by_name

		if not widgets_by_name then
			return
		end

		local previewed_item = self._previewed_item
		local master_item = previewed_item and previewed_item.__master_item
		local wishlist_button = widgets_by_name.wishlist_button
		local preview_button = widgets_by_name.preview_button

		if wishlist_button and wishlist_button.content then
			wishlist_button.content.visible = master_item
					and previewed_item.__locked == true
					and master_item.source == "premium_store"
				or false
		end

		if preview_button and preview_button.content then
			local selected_slot = self._selected_slot
			local slot_name = selected_slot and selected_slot.name

			if
				slot_name == "slot_gear_head"
				or slot_name == "slot_gear_upperbody"
				or slot_name == "slot_gear_lowerbody"
				or slot_name == "slot_gear_extra_cosmetic"
			then
				preview_button.content.visible = allow_equip_button and false or not visible
			else
				preview_button.content.visible = false
			end
		end
	end
)

mod.update_wishlist_icons = function(self)
	local item_grid = self and self._item_grid

	if not item_grid then
		return
	end

	local widgets = item_grid:widgets() or {}

	for i = 1, #widgets do
		local widget = widgets[i]
		local content = widget and widget.content
		local entry = content and content.entry

		if entry then
			local entry_item = entry.item
			local master_item = entry_item and entry_item.__master_item
			local dev_name = master_item and master_item.dev_name

			entry.item_on_wishlist = is_on_wishlist(dev_name)
		end
	end
end

mod.wishlist_store_check = function(self, archetype)
	if wishlisted_items ~= nil and not table.is_empty(wishlisted_items) then
		local _store_promise = mod.grab_current_commodores_items(self, archetype)
		return _store_promise
	end
end

local NOTIFICATION_STOREFRONTS = {
	"ogryn",
	"zealot",
	"veteran",
	"psyker",
	false,
}

local function chain_store_checks(self, index, on_complete)
	if index > #NOTIFICATION_STOREFRONTS or not wishlisted_items or table.is_empty(wishlisted_items) then
		on_complete()

		return
	end

	local promise = mod.wishlist_store_check(self, NOTIFICATION_STOREFRONTS[index] or nil)

	if not promise then
		chain_store_checks(self, index + 1, on_complete)

		return
	end

	promise:next(function()
		chain_store_checks(self, index + 1, on_complete)
	end)
end

local function show_wishlist_notification(self, character_notifications_enabled, weapon_notifications_enabled)
	if not wishlisted_items or table.is_empty(wishlisted_items) then
		return
	end

	local available_items = {}

	for i = 1, #wishlisted_items do
		local item = wishlisted_items[i]
		local item_name = item and item.name
		local gearid = item and item.gearid

		if item_name or gearid then
			if item.parent_item then
				if not weapon_notifications_enabled then
					goto continue
				end
			elseif not character_notifications_enabled then
				goto continue
			end

			if mod.get_item_in_current_commodores(self, gearid, item_name) then
				local item_text = Localize(item.display_name or "")

				if item.parent_item then
					item_text = item_text .. " (" .. item.parent_item .. ")"
				end

				available_items[#available_items + 1] = item_text
			end
		end

		::continue::
	end

	if #available_items > 0 then
		local text_parts = {
			"{#color(255, 170, 30)}" .. Localize("loc_VPCC_wishlist_notification") .. "\n",
		}

		for i = 1, #available_items do
			text_parts[#text_parts + 1] = "{#color(125, 108, 56)} {#color(169, 191, 153)}"
				.. available_items[i]
				.. "\n"
		end

		local event_manager = Managers.event

		if event_manager then
			event_manager:trigger("event_add_notification_message", "default", table.concat(text_parts))
		end
	end
end

mod.display_wishlist_notification = function(self)
	local character_notifications_enabled = mod:get("toggle_wishlist_notifications") ~= false
	local WCVI = get_mod("weapon_cosmetics_view_improved")
	local weapon_notifications_enabled = not WCVI or WCVI:get("toggle_wishlist_notifications") ~= false

	if not character_notifications_enabled and not weapon_notifications_enabled then
		return
	end

	clear_commodores_offers()
	chain_store_checks(self, 1, function()
		show_wishlist_notification(self, character_notifications_enabled, weapon_notifications_enabled)
	end)
end

mod:hook_safe(CLASS.StateMainMenu, "event_main_menu_entered", function(self, profile)
	mod.display_wishlist_notification(self)
end)

mod.remove_item_from_wishlist = function(item)
	local item_name = item and item.name

	if not item_name or not wishlisted_items or table.is_empty(wishlisted_items) then
		return
	end

	for i = #wishlisted_items, 1, -1 do
		local wishlisted_item = wishlisted_items[i]

		if wishlisted_item and wishlisted_item.name == item_name then
			table.remove(wishlisted_items, i)
		end
	end
end

local function string_starts(text, prefix)
	return string.sub(text, 1, string.len(prefix)) == prefix
end

mod:hook_safe(CLASS.InventoryCosmeticsView, "_preview_element", function(self, element)
	if not element then
		return
	end

	local is_locked = element.locked
	local item_name_widget = self._item_name_widget

	if is_locked and item_name_widget and item_name_widget.offset then
		item_name_widget.offset[2] = item_name_widget.offset[2] - 80
	end

	local widgets_by_name = self._widgets_by_name

	if not widgets_by_name then
		return
	end

	local wishlist_button = widgets_by_name.wishlist_button
	local previewed_item = self._previewed_item
	local previewed_master_item = previewed_item and previewed_item.__master_item
	local item_on_wishlist = is_on_wishlist(previewed_master_item and previewed_master_item.dev_name)

	if wishlist_button and wishlist_button.style then
		wishlist_button.style.background_gradient.default_color = item_on_wishlist
				and Color.terminal_text_warning_light(nil, true)
			or Color.terminal_background_gradient(nil, true)
	end

	mod.update_wishlist_icons(self)

	local is_item_previewed = false
	local previewed_item_name = previewed_master_item and previewed_master_item.name

	if previewed_item_name then
		for slot, previous_item in pairs(previewed_items) do
			local previous_master_item = previous_item and previous_item.__master_item

			if previous_master_item and previous_master_item.name == previewed_item_name then
				is_item_previewed = true

				break
			end
		end
	end

	local store_button = widgets_by_name.store_button

	if store_button and store_button.content then
		store_button.content.visible = element.purchase_offer ~= nil
	end

	Selected_purchase_offer = element.purchase_offer

	local preview_button = widgets_by_name.preview_button

	if preview_button and preview_button.content and preview_button.content.hotspot then
		preview_button.content.hotspot.disabled = is_item_previewed
	end
end)

local add_definitions = function(definitions)
	if not definitions then
		return
	end

	definitions.scenegraph_definition = definitions.scenegraph_definition or {}
	definitions.widget_definitions = definitions.widget_definitions or {}
	local preview_button_size = {
		374,
		76,
	}
	local store_button_size = {
		374,
		76,
	}

	definitions.scenegraph_definition.preview_button = {
		horizontal_alignment = "right",
		parent = "info_box",
		vertical_alignment = "bottom",
		size = preview_button_size,
		position = {
			0,
			-8,
			1,
		},
	}

	definitions.widget_definitions.preview_button =
		UIWidget.create_definition(ButtonPassTemplates.default_button, "preview_button", {
			gamepad_action = "confirm_pressed",
			visible = false,
			original_text = Utf8.upper(Localize("loc_VPCC_preview")),
			hotspot = {},
		})
	local wishlist_button_size = {
		48,
		48,
	}

	definitions.scenegraph_definition.wishlist_button = {
		horizontal_alignment = "right",
		parent = "info_box",
		vertical_alignment = "bottom",
		size = wishlist_button_size,
		position = {
			50,
			-20,
			2,
		},
	}

	definitions.widget_definitions.wishlist_button =
		UIWidget.create_definition(ButtonPassTemplates.terminal_button, "wishlist_button", {
			gamepad_action = "confirm_pressed",
			visible = false,
			original_text = Utf8.upper(Localize("loc_VPCC_wishlist")),
			hotspot = {},
		})

	definitions.scenegraph_definition.store_button = {
		horizontal_alignment = "right",
		parent = "info_box",
		vertical_alignment = "bottom",
		size = store_button_size,
		position = {
			0,
			65,
			1,
		},
	}

	definitions.widget_definitions.store_button =
		UIWidget.create_definition(ButtonPassTemplates.default_button, "store_button", {
			gamepad_action = "confirm_pressed",
			visible = false,
			original_text = Utf8.upper(Localize("loc_VPCC_store")),
			hotspot = {},
		})
end

mod:hook_require("scripts/ui/views/inventory_cosmetics_view/inventory_cosmetics_view_definitions", function(definitions)
	add_definitions(definitions)
end)

local function _item_plus_overrides(item, gear, gear_id, is_preview_item)
	if not item then
		return nil
	end

	local gearid = (math.uuid and math.uuid()) or gear_id or item.name
	local gear_id_for_log = (gear and gear.masterDataInstance and gear.masterDataInstance.id) or item.name or "unknown"

	local masterDataInstance = {
		id = gear_id_for_log,
	}

	local slots = {
		item.slots,
	}

	local __gear = {
		uuid = gearid,
		masterDataInstance = masterDataInstance,
		slots = slots,
	}

	local item_instance = {
		__master_item = item,
		__gear = __gear,
		__gear_id = gearid,
		__original_gear_id = is_preview_item and gear_id,
		__is_preview_item = is_preview_item and true or false,
		__locked = true,
	}

	setmetatable(item_instance, {
		__index = function(t, field_name)
			local master_ver = rawget(item_instance, "__master_ver")

			if master_ver ~= MasterItems.get_cached_version() then
				if MasterItems and MasterItems.update_master_data then
					local success = MasterItems.update_master_data(item_instance)

					if not success then
						Log.error(
							"MasterItems",
							"[_item_plus_overrides][1] could not update master data with %s",
							gear_id_for_log
						)

						return nil
					end
				else
					return nil
				end
			end

			if field_name == "gear_id" then
				return rawget(item_instance, "__gear_id")
			end

			if field_name == "gear" then
				return rawget(item_instance, "__gear")
			end

			local master_item = rawget(item_instance, "__master_item")

			if not master_item then
				Log.warning("MasterItemCache", string.format("No master data for item with id %s", gear_id_for_log))

				return nil
			end

			local field_value = master_item[field_name]

			if field_name == "rarity" and field_value == -1 then
				return nil
			end

			return field_value
		end,
		__newindex = function(t, field_name, value)
			rawset(t, field_name, value)
		end,
		__tostring = function(t)
			local master_item = rawget(item_instance, "__master_item")

			return string.format(
				"master_item: [%s] gear_id: [%s]",
				tostring(master_item and master_item.name),
				tostring(rawget(item_instance, "__gear_id"))
			)
		end,
	})

	if not MasterItems or not MasterItems.update_master_data then
		return nil
	end

	local success = MasterItems.update_master_data(item_instance)

	if not success then
		Log.error("MasterItems", "[_item_plus_overrides][2] could not update master data with %s", gear_id_for_log)

		return nil
	end

	return item_instance
end

local ColorUtilities = require("scripts/utilities/ui/colors")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local function _symbol_text_change_function(content, style)
	local hotspot = content and content.hotspot

	if not hotspot or not style or not style.text_color then
		return
	end

	local color

	if hotspot.is_selected or hotspot.is_focused then
		color = style.selected_color
	elseif hotspot.is_hover then
		color = style.hover_color
	else
		color = style.default_color
	end

	if not color then
		return
	end

	local progress = math.max(
		math.max(hotspot.anim_hover_progress or 0, hotspot.anim_select_progress or 0),
		hotspot.anim_focus_progress or 0
	)

	ColorUtilities.color_lerp(style.text_color, color, progress, style.text_color)
end

local add_wishlist_icon = function(ItemPassTemplates)
	if not ItemPassTemplates then
		return
	end

	ItemPassTemplates.gear_item = ItemPassTemplates.gear_item or {}

	local wishlist_icon_text_style = table.clone(UIFontSettings.header_3)

	wishlist_icon_text_style.text_color = Color.terminal_corner_selected(255, true)
	wishlist_icon_text_style.default_color = Color.terminal_corner_selected(255, true)
	wishlist_icon_text_style.hover_color = Color.terminal_corner_selected(255, true)
	wishlist_icon_text_style.selected_color = Color.terminal_corner_selected(255, true)
	wishlist_icon_text_style.font_size = 18
	wishlist_icon_text_style.drop_shadow = false
	wishlist_icon_text_style.text_horizontal_alignment = "right"
	wishlist_icon_text_style.text_vertical_alignment = "top"
	wishlist_icon_text_style.offset = {
		-10,
		5,
		7,
	}

	ItemPassTemplates.gear_item[#ItemPassTemplates.gear_item + 1] = {
		pass_type = "text",
		value = Utf8.upper(Localize("loc_VPCC_wishlist")),
		style = wishlist_icon_text_style,
		visibility_function = function(content, style)
			return content and content.entry and content.entry.item_on_wishlist or false
		end,
		change_function = _symbol_text_change_function,
	}
end

local add_store_item_icon = function(ItemPassTemplates)
	if not ItemPassTemplates then
		return
	end

	ItemPassTemplates.gear_item = ItemPassTemplates.gear_item or {}

	local item_store_icon_text_style = table.clone(UIFontSettings.header_3)

	item_store_icon_text_style.text_color = Color.terminal_corner_selected(255, true)
	item_store_icon_text_style.default_color = Color.terminal_corner_selected(255, true)
	item_store_icon_text_style.hover_color = Color.terminal_corner_selected(255, true)
	item_store_icon_text_style.selected_color = Color.terminal_corner_selected(255, true)
	item_store_icon_text_style.font_size = 24
	item_store_icon_text_style.drop_shadow = false
	item_store_icon_text_style.text_horizontal_alignment = "left"
	item_store_icon_text_style.text_vertical_alignment = "bottom"
	item_store_icon_text_style.offset = {
		10,
		-5,
		7,
	}

	ItemPassTemplates.gear_item[#ItemPassTemplates.gear_item + 1] = {
		pass_type = "text",
		value = Utf8.upper(Localize("loc_VPCC_in_store")),
		style = item_store_icon_text_style,
		visibility_function = function(content, style)
			return content
					and content.entry
					and content.entry.purchase_offer
					and mod:get("display_commodores_price_in_inventory") == false
				or false
		end,
		change_function = _symbol_text_change_function,
	}
end

local adjust_display_store_price = function(ItemPassTemplates)
	if not ItemPassTemplates then
		return
	end

	if ItemPassTemplates.gear_item then
		local item_price_style = table.clone(UIFontSettings.body)

		item_price_style.text_horizontal_alignment = "left"
		item_price_style.text_vertical_alignment = "bottom"
		item_price_style.horizontal_alignment = "left"
		item_price_style.vertical_alignment = "center"
		item_price_style.offset = {
			35,
			-8,
			12,
		}
		item_price_style.font_size = 20
		item_price_style.text_color = Color.white(255, true)
		item_price_style.default_color = Color.white(255, true)
		item_price_style.hover_color = Color.white(255, true)
		local gear_item_price_style = table.clone(item_price_style)

		gear_item_price_style.offset = {
			35,
			-3,
			12,
		}

		local price_text = {
			pass_type = "text",
			style_id = "price_text",
			value = "n/a",
			value_id = "price_text",
			style = gear_item_price_style,
			visibility_function = function(content, style)
				return content
						and content.has_price_tag
						and not content.sold
						and mod:get("display_commodores_price_in_inventory") == true
					or false
			end,
		}

		local wallet_icon = {
			pass_type = "texture",
			style_id = "wallet_icon",
			value = "content/ui/materials/base/ui_default_base",
			value_id = "wallet_icon",
			style = {
				horizontal_alignment = "left",
				vertical_alignment = "bottom",
				size = {
					28,
					20,
				},
				offset = {
					5,
					-5,
					12,
				},
				color = {
					255,
					255,
					255,
					255,
				},
			},
			visibility_function = function(content, style)
				return content
						and content.has_price_tag
						and not content.sold
						and mod:get("display_commodores_price_in_inventory") == true
					or false
			end,
		}

		local gear_item = ItemPassTemplates.gear_item

		for i = 1, #gear_item do
			local template = gear_item[i]

			if template then
				if template.style_id == "price_text" then
					gear_item[i] = price_text
				elseif template.style_id == "wallet_icon" then
					gear_item[i] = wallet_icon
				end
			end
		end
	end
end

mod:hook_require("scripts/ui/pass_templates/item_pass_templates", function(ItemPassTemplates)
	add_wishlist_icon(ItemPassTemplates)
	add_store_item_icon(ItemPassTemplates)
	adjust_display_store_price(ItemPassTemplates)
end)

local STORE_CATEGORY_BY_ARCHETYPE = {
	veteran = 2,
	zealot = 3,
	psyker = 4,
	ogryn = 5,
	adamant = 6,
	broker = 7,
	cryptic = 8,
}

Category_index = 1
InventoryCosmeticsView.cb_on_store_pressed = function(self)
	if not Selected_purchase_offer then
		return
	end

	local player = Managers.player and Managers.player:local_player(1)
	local archetype_name = player and player:archetype_name()

	if archetype_name then
		Category_index = STORE_CATEGORY_BY_ARCHETYPE[archetype_name] or 1
	end

	local ui_manager = Managers.ui

	if ui_manager then
		local context = {
			hub_interaction = true,
		}

		ui_manager:open_view("store_view", nil, nil, nil, nil, context)
	end
end

local Archetypes = require("scripts/settings/archetype/archetypes")
local category_button = table.clone(ButtonPassTemplates.menu_panel_button)

category_button[1].style = {
	on_hover_sound = UISoundEvents.tab_secondary_button_hovered,
	on_pressed_sound = UISoundEvents.tab_secondary_button_pressed,
}
local CATEGORY_LAYOUT = {
	{
		display_name = "loc_premium_store_category_title_catalogue",
		template = category_button,
		sub_category_ids = {
			"featured",
			"veteran",
			"zealot",
			"psyker",
			"ogryn",
		},
	},
	{
		display_name = "loc_premium_store_category_title_dlc",
		template = category_button,
		sub_category_ids = {
			"cryptic",
			"broker",
			"adamant",
		},
	},
}
local STORE_LAYOUT = {
	{
		display_name = "loc_premium_store_category_title_featured",
		id = "featured",
		storefront = "premium_store_featured",
		telemetry_name = "featured",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
		end_template = ButtonPassTemplates.terminal_tab_menu_button,
	},
	{
		display_name = "loc_premium_store_category_skins_title_veteran",
		id = "veteran",
		storefront = "premium_store_skins_veteran",
		telemetry_name = "veteran",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
		end_template = ButtonPassTemplates.terminal_tab_menu_button,
	},
	{
		display_name = "loc_premium_store_category_skins_title_zealot",
		id = "zealot",
		storefront = "premium_store_skins_zealot",
		telemetry_name = "zealot",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
		end_template = ButtonPassTemplates.terminal_tab_menu_button,
	},
	{
		display_name = "loc_premium_store_category_skins_title_psyker",
		id = "psyker",
		storefront = "premium_store_skins_psyker",
		telemetry_name = "psyker",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
		end_template = ButtonPassTemplates.terminal_tab_menu_button,
	},
	{
		display_name = "loc_premium_store_category_skins_title_ogryn",
		id = "ogryn",
		storefront = "premium_store_skins_ogryn",
		telemetry_name = "ogryn",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
		end_template = ButtonPassTemplates.terminal_tab_menu_button,
	},
	{
		display_name = "loc_premium_store_category_skins_title_adamant",
		id = "adamant",
		storefront = "premium_store_skins_adamant",
		telemetry_name = "adamant",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
		end_template = ButtonPassTemplates.terminal_tab_menu_button,
		require_archetype_ownership = Archetypes.adamant,
	},
	{
		display_name = "loc_premium_store_category_skins_title_broker",
		id = "broker",
		storefront = "premium_store_skins_broker",
		telemetry_name = "broker",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
		end_template = ButtonPassTemplates.terminal_tab_menu_button,
		require_archetype_ownership = Archetypes.broker,
	},
	{
		display_name = "loc_premium_store_category_skins_title_cryptic",
		id = "cryptic",
		storefront = "premium_store_skins_cryptic",
		telemetry_name = "cryptic",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
		end_template = ButtonPassTemplates.terminal_tab_menu_button,
		require_archetype_ownership = Archetypes.cryptic,
	},
}
local STORE_LAYOUT_BY_ID = {}

for i = 1, #STORE_LAYOUT do
	local store_layout = STORE_LAYOUT[i]

	store_layout.index = i
	STORE_LAYOUT_BY_ID[store_layout.id] = store_layout
end

for i = 1, #CATEGORY_LAYOUT do
	local category_layout = CATEGORY_LAYOUT[i]

	for ii = 1, #category_layout.sub_category_ids do
		local sub_category_id = category_layout.sub_category_ids[ii]
		local sub_category_layout = STORE_LAYOUT_BY_ID[sub_category_id]

		if sub_category_layout then
			sub_category_layout.category_index = i
			sub_category_layout.index_in_category = ii
		end
	end
end

local opened_store = false
StoreView._on_page_index_selected = function(self, page_index, select_element)
	local category_index = self._selected_sub_category_index
	local category_layout = STORE_LAYOUT[category_index]
	local category_pages_layout_data = self._category_pages_layout_data

	if not category_layout or not category_pages_layout_data then
		return
	end

	local category_name = category_layout.telemetry_name
	local page_layout = category_pages_layout_data[page_index]

	if type(page_layout) ~= "table" then
		return
	end

	if not select_element and Selected_purchase_offer and Selected_purchase_offer.offerId and not opened_store then
		opened_store = true

		for i = 1, #category_pages_layout_data do
			local page_elements = category_pages_layout_data[i] and category_pages_layout_data[i].elements

			if page_elements then
				for j = 1, #page_elements do
					local page_element = page_elements[j]
					local offer = page_element and page_element.offer

					if offer and offer.offerId == Selected_purchase_offer.offerId then
						if i == page_index then
							select_element = page_element
						else
							self:_on_page_index_selected(i, page_element)

							return
						end
					end
				end
			end
		end
	end

	local previous_page_index = self._selected_page_index

	self._selected_page_index = page_index

	self:_set_telemetry_name(category_name, page_index)

	local navigation_arrow_left = self._widgets_by_name and self._widgets_by_name.navigation_arrow_left
	local navigation_arrow_right = self._widgets_by_name and self._widgets_by_name.navigation_arrow_right

	if navigation_arrow_left and navigation_arrow_left.content then
		navigation_arrow_left.content.visible = page_index > 1
	end

	if navigation_arrow_right and navigation_arrow_right.content then
		navigation_arrow_right.content.visible = page_index < #category_pages_layout_data
	end

	if self._page_panel then
		self._page_panel:set_selected_index(page_index)
	end

	local grid_settings = page_layout.grid_settings
	local elements = page_layout.elements or {}
	local sequence_promise

	if self:_is_animation_active(self._grid_exit_animation_id) then
		sequence_promise = Promise.until_value_is_true(function()
			return self._grid_widgets == nil
		end)
	else
		sequence_promise = Promise.resolved():next(function()
			self:_destroy_current_grid()
		end)
	end

	sequence_promise:next(function()
		self:_setup_grid(elements, grid_settings)

		local image_promises = {}
		local grid_widgets = self._grid_widgets or {}

		for i = 1, #grid_widgets do
			local grid_widget = grid_widgets[i]

			if grid_widget then
				grid_widget.alpha_multiplier = 0

				local config = grid_widget.config
				local image_promise = config and config._texture_load_promise

				if image_promise then
					image_promises[#image_promises + 1] = image_promise
				end
			end
		end

		local promise

		if #image_promises > 0 then
			promise = Promise.race(Promise.delay(0.5), Promise.all(unpack(image_promises)))
		else
			promise = Promise.resolved()
		end

		promise
			:next(callback(self, "_show_grid_entries", page_index, previous_page_index), function()
				return
			end)
			:next(function()
				if select_element then
					self:_set_selected_grid_index(select_element.index)
					StoreView.cb_on_grid_entry_left_pressed(self, nil, select_element)
				end
			end)
	end)
end

mod:hook_safe(CLASS.StoreView, "on_exit", function(self)
	opened_store = false
	Selected_purchase_offer = {}
end)

StoreView._initialize_opening_page = function(self)
	local store_category_index = 1

	-- Go to selected item's category
	if Selected_purchase_offer and Selected_purchase_offer.offerId and Category_index then
		store_category_index = Category_index
	end

	local path = {
		sub_category_index = store_category_index,
		page_index = 1,
	}

	local context = self._context
	local target_storefront = context and context.target_storefront

	if target_storefront then
		for i = 1, #STORE_LAYOUT do
			if STORE_LAYOUT[i].storefront == target_storefront then
				path.sub_category_index = i

				break
			end
		end
	end

	self:_open_navigation_path(path)
end

local STOREFRONT_BY_ARCHETYPE = {
	veteran = "premium_store_skins_veteran",
	zealot = "premium_store_skins_zealot",
	psyker = "premium_store_skins_psyker",
	ogryn = "premium_store_skins_ogryn",
	adamant = "premium_store_skins_adamant",
	broker = "premium_store_skins_broker",
	cryptic = "premium_store_skins_cryptic",
}

mod.grab_current_commodores_items = function(self, archetype)
	local player = Managers.player and Managers.player:local_player(1)
	local archetype_name = player and player:archetype_name()
	local storefront = (archetype and STOREFRONT_BY_ARCHETYPE[archetype])
		or (archetype_name and STOREFRONT_BY_ARCHETYPE[archetype_name])
		or "premium_store_featured"

	local store_service = Managers.data_service and Managers.data_service.store

	if not store_service or not store_service.get_premium_store then
		return Promise.resolved()
	end

	local promises = {}
	local archetype_promise = store_service:get_premium_store(storefront)

	if archetype_promise then
		promises[#promises + 1] = archetype_promise
	end

	if storefront ~= "premium_store_featured" then
		local featured_promise = store_service:get_premium_store("premium_store_featured")

		if featured_promise then
			promises[#promises + 1] = featured_promise
		end
	end

	if #promises == 0 then
		return Promise.resolved()
	end

	return Promise.all(unpack(promises)):next(function(results)
		local seen = {}

		for i = 1, #current_commodores_offers do
			local offer = current_commodores_offers[i]
			local offer_id = offer and offer.offerId

			if offer_id then
				seen[offer_id] = true
			end
		end

		for r = 1, #results do
			local data = results[r]
			local offers = data and data.offers

			if offers then
				for i = 1, #offers do
					local offer = offers[i]
					local offer_id = offer and offer.offerId

					if offer_id and not seen[offer_id] then
						seen[offer_id] = true
						offer.layout_config = data.layout_config
						current_commodores_offers[#current_commodores_offers + 1] = offer
					end
				end
			end
		end
	end)
end

local function offer_description_matches(description, gearid, item_name)
	if not description then
		return false
	end

	if item_name and description.id == item_name then
		return true
	end

	if gearid and (description.gearid == gearid or description.gear_id == gearid or description.gearId == gearid) then
		return true
	end

	return false
end

mod.get_item_in_current_commodores = function(self, gearid, item_name)
	if not current_commodores_offers or (not gearid and not item_name) then
		return
	end

	for i = 1, #current_commodores_offers do
		local offer = current_commodores_offers[i]
		local bundle_info = offer and offer.bundleInfo

		if bundle_info then
			for j = 1, #bundle_info do
				local bundle_item = bundle_info[j]

				if offer_description_matches(bundle_item and bundle_item.description, gearid, item_name) then
					return offer
				end
			end
		elseif offer_description_matches(offer and offer.description, gearid, item_name) then
			return offer
		end
	end
end

local WIDGET_TYPE_BY_SLOT = {
	slot_animation_emote_1 = "ui_item",
	slot_animation_emote_2 = "ui_item",
	slot_animation_emote_3 = "ui_item",
	slot_animation_emote_4 = "ui_item",
	slot_animation_emote_5 = "ui_item",
	slot_animation_end_of_round = "gear_item",
	slot_character_title = "character_title_item",
	slot_companion_gear_full = "gear_item",
	slot_gear_extra_cosmetic = "gear_item",
	slot_gear_head = "gear_item",
	slot_gear_lowerbody = "gear_item",
	slot_gear_upperbody = "gear_item",
	slot_insignia = "ui_item",
	slot_portrait_frame = "ui_item",
}

local GEAR_SLOT_NAMES = {
	slot_gear_head = true,
	slot_gear_lowerbody = true,
	slot_gear_upperbody = true,
	slot_gear_extra_cosmetic = true,
}

-- Fill out the UI cosmetics grid with all unlocked, then locked cosmetics.
mod.list_premium_cosmetics = function(self)
	local selected_item_slot = self._selected_slot

	if selected_item_slot then
		local selected_slot_name = selected_item_slot.name
		local store_promise = mod.grab_current_commodores_items(self)

		if not store_promise then
			return
		end

		store_promise:next(function()
			local current_cosmetics = mod.get_cosmetic_items(self, selected_slot_name)

			if GEAR_SLOT_NAMES[selected_slot_name] then
				local layout = {}

				local unlocked_items = {}
				-- Add unlocked cosmetics
				local player = self._preview_player
				local profile = player and player.profile and player:profile()
				local currentarchetype = profile and profile.archetype
				local currentbreed = currentarchetype and currentarchetype.breed

				for i = 1, #self._inventory_items do
					local item = self._inventory_items[i]
					if item then
						local forcurrentbreed = false
						local master_item = item.__master_item or item

						if item.breeds then
							for x, breed in pairs(item.breeds) do
								if breed == currentbreed then
									if item.archetypes then
										for y, archetypename in pairs(item.archetypes) do
											if currentarchetype and archetypename == currentarchetype.name then
												forcurrentbreed = true
											end
										end
									else
										forcurrentbreed = true
									end
								end
							end
							local valid = true

							if forcurrentbreed then
								-- Remove incorrect background prisoner garbs
								if master_item.display_name and string.find(master_item.display_name, "prisoner") then
									if
										master_item.crimes
											and #master_item.crimes > 0
											and profile.lore
											and profile.lore.backstory
											and profile.lore.backstory.crime
										or item.crimes
											and #item.crimes > 0
											and profile.lore
											and profile.lore.backstory
											and profile.lore.backstory.crime
									then
										valid = false
										for i, crime in pairs(master_item.crimes) do
											if profile.lore.backstory.crime == crime then
												valid = true
											end
										end
									end
								end

								if valid then
									local gear_id = item.gear_id
									local is_new = self._context
										and self._context.new_items_gear_ids
										and self._context.new_items_gear_ids[gear_id]
									local remove_new_marker_callback

									-- remove purchased items from wishlist
									if is_on_wishlist(master_item.dev_name) then
										mod.remove_item_from_wishlist(master_item)
									end

									if is_new then
										remove_new_marker_callback = self._parent
											and callback(self._parent, "remove_new_item_mark")
									end

									unlocked_items[#unlocked_items + 1] = master_item.name
									layout[#layout + 1] = {
										widget_type = "gear_item",
										sort_data = item,
										item = item,
										locked = false,
										slot = selected_item_slot,
										new_item_marker = is_new,
										remove_new_marker_callback = remove_new_marker_callback,
										profile = profile,
										sort_group = 1,
									}
								end
							end
						end
					end
				end

				local locked_items = {}

				-- Add locked cosmetics
				for i = 1, #current_cosmetics do
					local item = _item_plus_overrides(
						current_cosmetics[i],
						current_cosmetics[i].__gear,
						current_cosmetics[i].__gear_id,
						false
					)
					if item then
						local continue = true

						local master_item = item.__master_item or item
						if item.__master_item then
							master_item = item.__master_item
						else
							master_item = item
						end

						local gear_id = item.gear_id
						local is_new = self._context
							and self._context.new_items_gear_ids
							and self._context.new_items_gear_ids[gear_id]
						local remove_new_marker_callback

						if is_new then
							remove_new_marker_callback = self._parent and callback(self._parent, "remove_new_item_mark")
						end

						-- filter out unlocked items
						for x, unlocked_item_name in pairs(unlocked_items) do
							if item.name == unlocked_item_name then
								continue = false
							end
						end

						-- Filter out unknown sources
						if not mod:get("show_unobtainable") then
							if mod.is_unobtainable(item) then
								continue = false
							end
						end

						-- Filter out "NONE" commodore filter
						if
							self._commodores_toggle == "loc_VPCC_show_no_commodores"
							and item.source == "premium_store"
						then
							continue = false
						end

						-- Get purchase offer if item is in store.
						local purchase_offer = nil
						purchase_offer = mod.get_item_in_current_commodores(self, gear_id, item.name)
						-- if the source isn't "commodores vestures" yet the item is available in store - set the correct source...
						if purchase_offer and item.source ~= "premium_store" then
							item.source = "premium_store"
						end

						if purchase_offer then
							local selected_item_cost = 0
							local bundle = purchase_offer.bundleInfo

							if bundle then
								for j = 1, #bundle do
									local bundle_item = bundle[j]

									if
										offer_description_matches(
											bundle_item and bundle_item.description,
											gear_id,
											item.name
										)
									then
										local bundle_price = bundle_item.price and bundle_item.price.amount

										selected_item_cost = (bundle_price and bundle_price.discounted_price)
											or (bundle_price and bundle_price.amount)
											or 0

										break
									end
								end
							else
								local offer_price = purchase_offer.price and purchase_offer.price.amount

								selected_item_cost = (offer_price and offer_price.discounted_price)
									or (offer_price and offer_price.amount)
									or 0
							end

							local display_offer = table.clone_instance(purchase_offer)

							display_offer.price = display_offer.price or {}
							display_offer.price.amount = display_offer.price.amount or {}
							display_offer.price.amount.amount = selected_item_cost
							item.offer = display_offer
						end

						-- show only available
						if
							self._commodores_toggle == "loc_VPCC_show_available_commodores"
							and item.source == "premium_store"
							and not purchase_offer
						then
							continue = false
						end

						local item_on_wishlist = is_on_wishlist(master_item.dev_name)

						-- remove purchased items from wishlist
						if item_on_wishlist and item.__locked == false then
							mod.remove_item_from_wishlist(master_item)
						end

						-- show only wishlisted
						if
							self._commodores_toggle == "loc_VPCC_show_wishlisted_commodores"
							and item.source == "premium_store"
							and not item_on_wishlist
						then
							continue = false
						end

						-- categorise locked items by their source
						if continue then
							locked_items[item.source] = locked_items[item.source] or {}
							table.insert(locked_items[item.source], item)
						end
					end
				end

				-- Add divider
				layout[#layout + 1] = {
					widget_type = "divider",
					sort_group = 2,
				}

				-- Add locked items to layout, grouped by source
				for source, items in pairs(locked_items) do
					-- 1 = Penance, 2 = Commisary, 3 = Commodore's Vestures, 4 = Hestia's Blessings
					local item_sort_group = 3

					if source == "penance" then
						item_sort_group = 3
					elseif source == "credits_store" then
						item_sort_group = 3
					elseif source == "premium_store" then
						item_sort_group = 5
						-- Add divider
						layout[#layout + 1] = {
							widget_type = "divider",
							sort_group = 4,
						}
					elseif source == "penance_track" then
						item_sort_group = 3
					end

					for _, item in ipairs(items) do
						layout[#layout + 1] = {
							widget_type = "gear_item",
							sort_data = item,
							item = item,
							slot = selected_item_slot,
							new_item_marker = item.is_new,
							remove_new_marker_callback = item.remove_new_marker_callback,
							locked = true,
							profile = profile,
							purchase_offer = item.offer,
							item_on_wishlist = item.item_on_wishlist,
							offer = item.offer,
							sort_group = item_sort_group,
						}
					end
				end

				if layout ~= nil then
					self._offer_items_layout = table.clone_instance(layout)
					self:_present_layout_by_slot_filter(nil, nil, selected_item_slot.display_name)
				end
			else
				-- anything other than hats, torso, legs, back
				local selected_slot_name = selected_item_slot.name
				local layout = {}

				local unlocked_items = {}

				-- Add unlocked cosmetics
				local player = self._preview_player
				local profile = player and player.profile and player:profile()
				local currentarchetype = profile and profile.archetype
				local currentbreed = currentarchetype and currentarchetype.breed

				for i = 1, #self._inventory_items do
					local item = self._inventory_items[i]
					if item then
						local forcurrentbreed = false
						local master_item = item.__master_item or item

						if item.breeds then
							for x, breed in pairs(item.breeds) do
								if breed == currentbreed then
									if item.archetypes then
										for y, archetypename in pairs(item.archetypes) do
											if currentarchetype and archetypename == currentarchetype.name then
												forcurrentbreed = true
											end
										end
									else
										forcurrentbreed = true
									end
								end
							end
							local valid = true

							if forcurrentbreed and master_item then
								local gear_id = item.gear_id
								local is_new = self._context
									and self._context.new_items_gear_ids
									and self._context.new_items_gear_ids[gear_id]
								local remove_new_marker_callback
								if is_new then
									remove_new_marker_callback = self._parent
										and callback(self._parent, "remove_new_item_mark")
								end

								if valid then
									unlocked_items[#unlocked_items + 1] = master_item.name
									layout[#layout + 1] = {
										widget_type = WIDGET_TYPE_BY_SLOT[selected_slot_name],
										sort_data = item,
										item = item,
										locked = false,
										slot = selected_item_slot,
										new_item_marker = is_new,
										remove_new_marker_callback = remove_new_marker_callback,
										profile = profile,
										sort_group = 1,
									}
								end
							end
						end
					end
				end

				-- Add divider
				layout[#layout + 1] = {
					widget_type = "divider",
					sort_group = 2,
				}

				-- add locked items
				for i = 1, #current_cosmetics do
					local item = _item_plus_overrides(
						current_cosmetics[i],
						current_cosmetics[i].__gear,
						current_cosmetics[i].__gear_id,
						false
					)

					local continue = true

					if item then
						local forcurrentbreed = false
						local master_item = item.__master_item or item

						if item.breeds then
							for x, breed in pairs(item.breeds) do
								if breed == currentbreed then
									if item.archetypes then
										for y, archetypename in pairs(item.archetypes) do
											if currentarchetype and archetypename == currentarchetype.name then
												forcurrentbreed = true
											end
										end
									else
										forcurrentbreed = true
									end
								end
							end
							local valid = true

							if forcurrentbreed and master_item then
								for x, unlocked_item_name in pairs(unlocked_items) do
									if item.name == unlocked_item_name then
										continue = false
									end
								end

								-- Filter out unknown sources
								if not mod:get("show_unobtainable") then
									if mod.is_unobtainable(item) then
										continue = false
									end
								end

								-- filter out broken/placeholder frames
								if not mod:get("show_unobtainable") then
									if selected_item_slot.name == "slot_portrait_frame" then
										local localized_name = Localize(item.display_name)
										-- unlocalised achievement frames
										if item.dev_name and string_starts(localized_name, "achievements_") then
											continue = false
										end
										-- unlocalized expedition frame
										if item.dev_name and string_starts(localized_name, "portrait_frame") then
											continue = false
										end
									end
								end

								if continue == true then
									local gear_id = item.gear_id
									local is_new = self._context
										and self._context.new_items_gear_ids
										and self._context.new_items_gear_ids[gear_id]
									local remove_new_marker_callback
									if is_new then
										remove_new_marker_callback = self._parent
											and callback(self._parent, "remove_new_item_mark")
									end

									layout[#layout + 1] = {
										widget_type = WIDGET_TYPE_BY_SLOT[selected_slot_name],
										sort_data = item,
										item = item,
										slot = selected_item_slot,
										new_item_marker = is_new,
										remove_new_marker_callback = remove_new_marker_callback,
										locked = true,
										profile = profile,
										purchase_offer = nil,
										item_on_wishlist = false,
										sort_group = 3,
									}
								end
							end
						end
					end
				end

				if layout ~= nil then
					self._offer_items_layout = table.clone_instance(layout)
					self:_present_layout_by_slot_filter(nil, nil, selected_item_slot.display_name)
				end
			end
		end)
	end
end

-- Get all cosmetics items available, from the MasterItems cache.
mod.get_cosmetic_items = function(self, selectedslot)
	local item_definitions = MasterItems and MasterItems.get_cached and MasterItems.get_cached()

	if not item_definitions then
		return {}
	end

	local cosmetic_items = {}
	local player = self._preview_player
	local profile = player and player.profile and player:profile()
	local currentarchetype = profile and profile.archetype
	local currentbreed = currentarchetype and currentarchetype.breed
	local archetype_name = currentarchetype and currentarchetype.name

	for item_name, item in pairs(item_definitions) do
		if item then
			local slots = item.slots
			local slot = slots and slots[1]
			local forcurrentbreed = false

			if slot and slot == selectedslot and item.breeds then
				for x, breed in pairs(item.breeds) do
					if breed == currentbreed then
						if item.archetypes then
							for y, archetypename in pairs(item.archetypes) do
								if archetype_name and archetypename == archetype_name then
									forcurrentbreed = true

									break
								end
							end
						else
							forcurrentbreed = true
						end
					end
				end

				if forcurrentbreed and item.display_name and item.display_name ~= "" and item.display_name ~= " " then
					cosmetic_items[#cosmetic_items + 1] = item
				end
			end
		end
	end

	return cosmetic_items
end

-- SETUP COMMODORES ITEM TOGGLES
InventoryCosmeticsView.cb_on_commodores_toggle_pressed = function(self)
	if self._commodores_toggle == "loc_VPCC_show_all_commodores" then
		self._commodores_toggle = "loc_VPCC_show_available_commodores"
	elseif self._commodores_toggle == "loc_VPCC_show_available_commodores" then
		self._commodores_toggle = "loc_VPCC_show_wishlisted_commodores"
	elseif self._commodores_toggle == "loc_VPCC_show_wishlisted_commodores" then
		self._commodores_toggle = "loc_VPCC_show_no_commodores"
	elseif self._commodores_toggle == "loc_VPCC_show_no_commodores" then
		self._commodores_toggle = "loc_VPCC_show_all_commodores"
	end

	mod:set("show_commodores", self._commodores_toggle)
	mod.list_premium_cosmetics(self)
	mod.focus_on_item(self, previewed_items)
end

local Definitions = mod:io_dofile(
	"character_cosmetics_view_improved/scripts/mods/character_cosmetics_view_improved/character_cosmetics_view_improved_definitions"
)
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
InventoryCosmeticsView._setup_input_legend = function(self)
	self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 10)

	if not self._input_legend_element then
		return
	end

	self._commodores_toggle = self._commodores_toggle or mod:get("show_commodores") or "loc_VPCC_show_all_commodores"

	local legend_inputs = Definitions.legend_inputs

	for i = 1, #legend_inputs do
		local legend_input = legend_inputs[i]
		local on_pressed_callback = legend_input.on_pressed_callback
			and callback(self, legend_input.on_pressed_callback)

		self._input_legend_element:add_entry(
			legend_input.display_name,
			legend_input.input_action,
			legend_input.visibility_function,
			on_pressed_callback,
			legend_input.alignment
		)
	end
end
