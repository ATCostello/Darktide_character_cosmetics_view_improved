--[[
    Name: View Premium Character Cosmetics
    Author: Alfthebigheaded
]]
local mod = get_mod("character_cosmetics_view_improved")
local MasterItems = require("scripts/backend/master_items")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UISettings = require("scripts/settings/ui/ui_settings")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local InventoryCosmeticsView = require("scripts/ui/views/inventory_cosmetics_view/inventory_cosmetics_view")
local StoreView = require("scripts/ui/views/store_view/store_view")
local CCVIData = mod:io_dofile("character_cosmetics_view_improved/scripts/mods/character_cosmetics_view_improved/character_cosmetics_view_improved_data")

local previewed_items = {}
Selected_purchase_offer = {}

mod:hook_safe(
    CLASS.InventoryCosmeticsView, "_start_show_layout", function(self, element)
        mod.list_premium_cosmetics(self)
        mod.focus_on_item(self, previewed_items)
        self._commodores_toggle = mod:get("show_commodores") or "loc_VPCC_show_all_commodores"
    end
)

mod:hook_safe(
    CLASS.InventoryView, "on_exit", function(self, element)
        previewed_items = {}
        Selected_purchase_offer = {}
    end
)

mod.focus_on_item = function(self, items)
    if not items then
        return
    end

    local item_grid = self._item_grid
    local widgets = item_grid:widgets()

    for slot, item in pairs(items) do
        for i = 1, #widgets do
            local widget = widgets[i]
            local content = widget.content
            local element_item = content.item

            if element_item and element_item.__master_item and item.__master_item then
                if element_item and element_item.__master_item.name == item.__master_item.name then
                    local widget_index = item_grid:widget_index(widget) or 1
                    local scrollbar_animation_progress = item_grid:get_scrollbar_percentage_by_index(widget_index)
                    local instant_scroll = true

                    item_grid:focus_grid_index(widget_index, scrollbar_animation_progress + 0.05, instant_scroll)

                    if not Managers.ui:using_cursor_navigation() then
                        item_grid:select_grid_index(widget_index)
                    end

                    break
                end
            end
        end
    end
end

InventoryCosmeticsView.cb_on_preview_pressed = function(self)
    local previewed_item = self._previewed_item
    local presentation_profile = self._presentation_profile
    local presentation_loadout = presentation_profile.loadout
    local preview_profile_equipped = self._preview_profile_equipped_items

    if previewed_item and presentation_loadout then
        local item_type = previewed_item.item_type
        local ITEM_TYPES = UISettings.ITEM_TYPES

        if item_type == ITEM_TYPES.GEAR_LOWERBODY or item_type == ITEM_TYPES.GEAR_UPPERBODY then
            self:_play_sound(UISoundEvents.apparel_equip)
        elseif item_type == ITEM_TYPES.GEAR_HEAD or item_type == ITEM_TYPES.EMOTE or item_type == ITEM_TYPES.END_OF_ROUND or item_type == ITEM_TYPES.GEAR_EXTRA_COSMETIC then
            self:_play_sound(UISoundEvents.apparel_equip_small)
        elseif item_type == ITEM_TYPES.PORTRAIT_FRAME or item_type == ITEM_TYPES.CHARACTER_INSIGNIA then
            self:_play_sound(UISoundEvents.apparel_equip_frame)
        elseif item_type == ITEM_TYPES.CHARACTER_TITLE then
            self:_play_sound(UISoundEvents.title_equip)
        else
            self:_play_sound(UISoundEvents.apparel_equip)
        end

        presentation_loadout[previewed_item.slots[1]] = previewed_item
        preview_profile_equipped[previewed_item.slots[1]] = previewed_item
        previewed_items[previewed_item.slots[1]] = previewed_item
        local widgets_by_name = self._widgets_by_name
        widgets_by_name.preview_button.content.hotspot.disabled = true
    end
end

mod:hook_safe(
    CLASS.InventoryCosmeticsView, "_update_equip_button_status", function(self)
        -- If the equip button is enabled, do not show the preview button.
        self._preview_button_disabled = not self._equip_button_disabled
    end
)

mod:hook_safe(
    CLASS.InventoryCosmeticsView, "_register_button_callbacks", function(self)
        local widgets_by_name = self._widgets_by_name

        widgets_by_name.preview_button.content.hotspot.pressed_callback = callback(self, "cb_on_preview_pressed")
        widgets_by_name.store_button.content.hotspot.pressed_callback = callback(self, "cb_on_store_pressed")
    end)


mod:hook_safe(
    CLASS.InventoryCosmeticsView, "_set_preview_widgets_visibility", function(self, visible, allow_equip_button)
        local widgets_by_name = self._widgets_by_name

        if self._selected_slot.name == "slot_gear_head" or self._selected_slot.name == "slot_gear_upperbody" or self._selected_slot.name == "slot_gear_lowerbody" or self._selected_slot.name == "slot_gear_extra_cosmetic" then
            widgets_by_name.preview_button.content.visible = allow_equip_button and false or not visible
        else
            widgets_by_name.preview_button.content.visible = false
        end
    end)

mod:hook_safe(
    CLASS.InventoryCosmeticsView, "_preview_element", function(self, element)
        local is_locked = element.locked
        if is_locked then
            self._item_name_widget.offset[2] = self._item_name_widget.offset[2] - 80
        end

        local is_item_previewed = false
        for slot, previewed_item in pairs(previewed_items) do
            if self._previewed_item and self._previewed_item.__master_item and previewed_item.__master_item then
                if self._previewed_item.__master_item.name == previewed_item.__master_item.name then
                    is_item_previewed = true
                end
            end
        end

        local widgets_by_name = self._widgets_by_name
        if element.purchase_offer then
            widgets_by_name.store_button.content.visible = true
        else
            widgets_by_name.store_button.content.visible = false
        end
        Selected_purchase_offer = element.purchase_offer

        widgets_by_name.preview_button.content.hotspot.disabled = is_item_previewed
    end)

local add_definitions = function(definitions)
    if not definitions then
        return
    end

    definitions.scenegraph_definition = definitions.scenegraph_definition or {}
    definitions.widget_definitions = definitions.widget_definitions or {}
    local equip_button_size = {
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
        size = equip_button_size,
        position = {
            0,
            -8,
            1,
        },
    }

    definitions.widget_definitions.preview_button = UIWidget.create_definition(ButtonPassTemplates.default_button,
        "preview_button", {
            gamepad_action = "confirm_pressed",
            visible = false,
            original_text = Utf8.upper(Localize("loc_VPCC_preview")),
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

    definitions.widget_definitions.store_button = UIWidget.create_definition(ButtonPassTemplates.default_button,
        "store_button", {
            gamepad_action = "confirm_pressed",
            visible = false,
            original_text = Utf8.upper(Localize("loc_VPCC_store")),
            hotspot = {},
        })
end

mod:hook_require("scripts/ui/views/inventory_cosmetics_view/inventory_cosmetics_view_definitions", function(definitions)
    add_definitions(definitions)
end)

local FALLBACK_ITEMS_BY_SLOT = {
    slot_animation_emote_1 = "content/items/animations/emotes/emote_human_greeting_001_wave_01",
    slot_animation_emote_2 = "content/items/animations/emotes/emote_human_greeting_001_wave_01",
    slot_animation_emote_3 = "content/items/animations/emotes/emote_human_greeting_001_wave_01",
    slot_animation_emote_4 = "content/items/animations/emotes/emote_human_greeting_001_wave_01",
    slot_animation_emote_5 = "content/items/animations/emotes/emote_human_greeting_001_wave_01",
    slot_animation_end_of_round = "content/items/animations/emotes/emote_human_greeting_001_wave_01",
    slot_body_arms = "content/items/characters/player/human/attachments_default/slot_body_arms",
    slot_body_eye_color = "content/items/characters/player/eye_colors/eye_color_blue_01",
    slot_body_face = "content/items/characters/player/human/attachments_default/slot_body_face",
    slot_body_face_hair = "content/items/characters/player/human/attachments_default/slot_body_face",
    slot_body_face_implant = "content/items/characters/player/human/attachments_default/slot_body_face",
    slot_body_face_scar = "content/items/characters/player/human/attachments_default/slot_body_face",
    slot_body_face_tattoo = "content/items/characters/player/human/attachments_default/slot_body_face",
    slot_body_hair = "content/items/characters/player/human/attachments_default/slot_body_hair",
    slot_body_hair_color = "content/items/characters/player/hair_colors/hair_color_brown_01",
    slot_body_legs = "content/items/characters/player/human/attachments_default/slot_body_legs",
    slot_body_skin_color = "content/items/characters/player/skin_colors/skin_color_pale_01",
    slot_body_tattoo = "content/items/characters/player/human/attachments_default/slot_body_torso",
    slot_body_torso = "content/items/characters/player/human/attachments_default/slot_body_torso",
    slot_character_title = "content/items/titles/title_default",
    slot_device = "content/items/devices/empty_device",
    slot_gear_extra_cosmetic = "content/items/characters/player/human/attachments_default/slot_attachment",
    slot_gear_head = "content/items/characters/player/human/attachments_default/slot_gear_head",
    slot_gear_lowerbody = "content/items/characters/player/human/attachments_default/slot_gear_legs",
    slot_gear_upperbody = "content/items/characters/player/human/attachments_default/slot_gear_torso",
    slot_insignia = "content/items/2d/insignias/insignia_default",
    slot_pocketable = "content/items/pocketable/empty_pocketable",
    slot_pocketable_small = "content/items/pocketable/empty_pocketable",
    slot_portrait_frame = "content/items/2d/portrait_frames/portrait_frame_default",
    slot_primary = "content/items/weapons/player/melee/unarmed",
    slot_secondary = "content/items/weapons/player/melee/unarmed",
    slot_skin_set = "content/items/characters/player/sets/empty_set",
    slot_trinket_1 = "content/items/weapons/player/trinkets/empty_trinket",
    slot_unarmed = "content/items/weapons/player/melee/unarmed",
    slot_weapon_skin = "content/items/weapons/player/skins/lasgun/lasgun_p1_m001",
}

if BUILD == "release" then
    FALLBACK_ITEMS_BY_SLOT.slot_body_face_tattoo = "content/items/characters/player/human/face_tattoo/empty_face_tattoo"
    FALLBACK_ITEMS_BY_SLOT.slot_body_face_scar = "content/items/characters/player/human/face_scars/empty_face_scar"
    FALLBACK_ITEMS_BY_SLOT.slot_body_face_hair = "content/items/characters/player/human/face_hair/empty_face_hair"
    FALLBACK_ITEMS_BY_SLOT.slot_body_hair = "content/items/characters/player/human/hair/empty_hair"
    FALLBACK_ITEMS_BY_SLOT.slot_body_tattoo = "content/items/characters/player/human/body_tattoo/empty_body_tattoo"
    FALLBACK_ITEMS_BY_SLOT.slot_body_eye_color = "content/items/characters/player/eye_colors/eye_color_blue_01"
    FALLBACK_ITEMS_BY_SLOT.slot_body_hair_color = "content/items/characters/player/hair_colors/hair_color_brown_01"
    FALLBACK_ITEMS_BY_SLOT.slot_gear_extra_cosmetic = "items/characters/player/human/backpacks/empty_backpack"
    FALLBACK_ITEMS_BY_SLOT.slot_gear_head = "content/items/characters/player/human/gear_head/empty_headgear"
    FALLBACK_ITEMS_BY_SLOT.slot_gear_lowerbody = "content/items/characters/player/human/gear_lowerbody/empty_lowerbody"
    FALLBACK_ITEMS_BY_SLOT.slot_gear_upperbody = "content/items/characters/player/human/gear_upperbody/empty_upperbody"
end

local function _fallback_item(gear)
    local instance_id = gear.masterDataInstance.id

    Log.error("MasterItemCache", string.format("No master data for item with id %s", instance_id))

    local slot = gear.slots and gear.slots[1]
    local fallback_name = slot and FALLBACK_ITEMS_BY_SLOT[slot]

    if not fallback_name then
        Log.error("MasterItemCache", string.format("No fallback item found for %s in slot %s", instance_id, slot))

        return nil
    end

    Log.warning("MasterItemCache", string.format("Using fallback with name %s", fallback_name))

    local fallback = rawget(MasterItems.get_cached(), fallback_name)

    return fallback
end

local _merge_item_data_recursive

function _merge_item_data_recursive(dest, source)
    for key, value in pairs(source) do
        local is_table = type(value) == "table"

        if value == source then
            dest[key] = dest
        elseif is_table and type(dest[key]) == "table" then
            _merge_item_data_recursive(dest[key], value)
        else
            dest[key] = value
        end
    end

    return dest
end

local function _validate_overrides(overrides)
    local traits = overrides.traits

    if traits then
        for i = #traits, 1, -1 do
            local data = traits[i]
            local trait_id = data.id
            local trait_exists = rawget(MasterItems.get_cached(), trait_id)

            if not trait_exists then
                table.remove(traits, i)
            end
        end
    end

    local perks = overrides.perks

    if perks then
        for i = #perks, 1, -1 do
            local data = perks[i]
            local perk_id = data.id
            local perk_exists = rawget(MasterItems.get_cached(), perk_id)

            if not perk_exists then
                table.remove(perks, i)
            end
        end
    end
end

local function _update_master_data(item_instance)
    rawset(item_instance, "__master_ver", MasterItems.get_cached_version())

    local gear = rawget(item_instance, "__gear")
    local item = rawget(MasterItems.get_cached(), gear.masterDataInstance.id)

    item = item or _fallback_item(gear)

    if item then
        local clone = table.clone(item)
        local overrides = gear.masterDataInstance.overrides

        if overrides then
            _validate_overrides(overrides)
            _merge_item_data_recursive(clone, overrides)
        end

        local count = gear.count

        if count then
            clone.count = count
        end

        local temp_overrides = rawget(item_instance, "__temp_overrides")

        if temp_overrides then
            _merge_item_data_recursive(clone, temp_overrides)
        end

        rawset(item_instance, "__master_item", clone)
        rawset(item_instance, "set_temporary_overrides", function(self, new_temp_overrides)
            rawset(item_instance, "__temp_overrides", new_temp_overrides)

            return _update_master_data(item_instance)
        end)

        return true
    end

    return false
end

local function _item_plus_overrides(item, gear, gear_id, is_preview_item)
    local gearid = math.uuid() or gear_id

    local masterDataInstance = {
        id = item.name
    }

    local slots = {
        item.slots
    }

    local __gear = {
        uuid = gearid,
        masterDataInstance = masterDataInstance,
        slots = slots
    }

    local item_instance = {
        __master_item = item,
        __gear = __gear,
        __gear_id = gearid,
        __original_gear_id = is_preview_item and gear_id,
        __is_preview_item = is_preview_item and true or false,
        __locked = true
    }

    setmetatable(item_instance, {
        __index = function(t, field_name)
            local master_ver = rawget(item_instance, "__master_ver")

            if master_ver ~= MasterItems.get_cached_version() then
                local success = _update_master_data(item_instance)

                if not success then
                    Log.error("MasterItems", "[_item_plus_overrides][1] could not update master data with %s",
                        gear.masterDataInstance.id)

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
                Log.warning("MasterItemCache",
                    string.format("No master data for item with id %s", gear.masterDataInstance.id))

                return nil
            end

            local field_value = master_item[field_name]

            if field_name == "rarity" and field_value == -1 then
                return nil
            end

            return field_value
        end,
        __newindex = function(t, field_name, value)
            if is_preview_item then
                rawset(t, field_name, value)
            else
                ferror("Not allowed to modify inventory items - %s[%s]", rawget(item_instance, "__gear_id"), field_name)
            end
        end,
        __tostring = function(t)
            local master_item = rawget(item_instance, "__master_item")

            return string.format("master_item: [%s] gear_id: [%s]", tostring(master_item and master_item.name),
                tostring(rawget(item_instance, "__gear_id")))
        end,
    })


    local success = _update_master_data(item_instance)

    if not success then
        Log.error("MasterItems", "[_item_plus_overrides][2] could not update master data with %s",
            gear.masterDataInstance.id)

        return nil
    end

    return item_instance
end

local add_store_item_icon = function(ItemPassTemplates)
    if not ItemPassTemplates then
        return
    end

    local ColorUtilities = require("scripts/utilities/ui/colors")
    local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

    ItemPassTemplates.gear_item = ItemPassTemplates.gear_item or {}

    local function _symbol_text_change_function(content, style)
        local hotspot = content.hotspot
        local is_selected = hotspot.is_selected
        local is_focused = hotspot.is_focused
        local is_hover = hotspot.is_hover
        local default_text_color = style.default_color
        local hover_color = style.hover_color
        local text_color = style.text_color
        local selected_color = style.selected_color
        local color

        if is_selected or is_focused then
            color = selected_color
        elseif is_hover then
            color = hover_color
        else
            color = default_text_color
        end

        local progress = math.max(math.max(hotspot.anim_hover_progress or 0, hotspot.anim_select_progress or 0),
            hotspot.anim_focus_progress or 0)

        ColorUtilities.color_lerp(text_color, color, progress, text_color)
    end

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
        0,
        7,
    }

    ItemPassTemplates.gear_item[#ItemPassTemplates.gear_item + 1] =
    {
        pass_type = "text",
        value = "$",
        style = item_store_icon_text_style,
        visibility_function = function(content, style)
            if content.entry and content.entry.purchase_offer then
                return true
            else
                return false
            end
        end,
        change_function = _symbol_text_change_function,
    }
end

mod:hook_require("scripts/ui/pass_templates/item_pass_templates", function(ItemPassTemplates)
    add_store_item_icon(ItemPassTemplates)
end)

Category_index = 1
InventoryCosmeticsView.cb_on_store_pressed = function(self)
    local previewed_item = self._previewed_item
    local presentation_profile = self._presentation_profile
    local presentation_loadout = presentation_profile.loadout
    local preview_profile_equipped = self._preview_profile_equipped_items

    local offer = Selected_purchase_offer
    if offer then
        local player = Managers.player:local_player(1)
        local character_id = player:character_id()
        local archetype_name = player:archetype_name()

        local page_index = 1

        if archetype_name == "veteran" then Category_index = 2 elseif archetype_name == "zealot" then Category_index = 3 elseif archetype_name == "psyker" then Category_index = 4 elseif archetype_name == "ogryn" then Category_index = 5 end

        local ui_manager = Managers.ui

        if ui_manager then
            local context = {
                hub_interaction = true
            }
            
            ui_manager:open_view("store_view", nil, nil, nil, nil, context)
        end
    end
end

local STORE_LAYOUT = {
	{
		display_name = "loc_premium_store_category_title_featured",
		storefront = "premium_store_featured",
		telemetry_name = "featured",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
	},
	{
		display_name = "loc_premium_store_category_skins_title_veteran",
		storefront = "premium_store_skins_veteran",
		telemetry_name = "veteran",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
	},
	{
		display_name = "loc_premium_store_category_skins_title_zealot",
		storefront = "premium_store_skins_zealot",
		telemetry_name = "zealot",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
	},
	{
		display_name = "loc_premium_store_category_skins_title_psyker",
		storefront = "premium_store_skins_psyker",
		telemetry_name = "psyker",
		template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
	},
	{
		display_name = "loc_premium_store_category_skins_title_ogryn",
		storefront = "premium_store_skins_ogryn",
		telemetry_name = "ogryn",
		template = ButtonPassTemplates.terminal_tab_menu_button,
	},
}
local opened_store = false
StoreView._on_page_index_selected = function(self, page_index)
    self._selected_page_index = page_index

    local category_index = self._selected_category_index
    local category_layout = STORE_LAYOUT[category_index]
    local category_name = category_layout.telemetry_name

    self:_set_telemetry_name(category_name, page_index)

    if self._page_panel then
        self._page_panel:set_selected_index(page_index)
    end

    local category_pages_layout_data = self._category_pages_layout_data

    if not category_pages_layout_data then
        return
    end

    local page_layout = category_pages_layout_data[page_index]
    local grid_settings = page_layout.grid_settings
    local elements = page_layout.elements
    local storefront_layout = self:_debug_generate_layout(grid_settings)

    self:_setup_grid(elements, grid_settings)
    self:_start_animation("grid_entry", self._grid_widgets, self)

    local grid_index = self:_get_first_grid_panel_index()

    if not self._using_cursor_navigation and grid_index then
        self:_set_selected_grid_index(grid_index)
    end

    self._widgets_by_name.navigation_arrow_left.content.visible = page_index > 1
    self._widgets_by_name.navigation_arrow_right.content.visible = page_index < #category_pages_layout_data
    if Selected_purchase_offer and not opened_store then
        opened_store = true
        for i = 1, #self._category_pages_layout_data do
            local page_elements = self._category_pages_layout_data[i].elements
            for j = 1, #page_elements do
                local page_element = page_elements[j]
                if page_element.offer and page_element.offer.offerId == Selected_purchase_offer.offerId then
                    self:_on_page_index_selected(i)
                    self:_set_selected_grid_index(page_element.index)
                    StoreView.cb_on_grid_entry_left_pressed(self, nil, page_element)
                end
            end
        end
    end
end


StoreView.on_exit = function(self)
    self:_clear_telemetry_name()

    if self._world_spawner then
        self._world_spawner:release_listener()
        self._world_spawner:destroy()

        self._world_spawner = nil
    end

    if self._input_legend_element then
        self._input_legend_element = nil

        self:_remove_element("input_legend")
    end

    if self._store_promise then
        self._store_promise:cancel()
    end

    if self._purchase_promise then
        self._purchase_promise:cancel()
    end

    if self._wallet_promise then
        self._wallet_promise:cancel()
    end

    self:_destroy_offscreen_gui()
    self:_unload_url_textures()
    StoreView.super.on_exit(self)

    if self._hub_interaction then
        local level = Managers.state.mission and Managers.state.mission:mission_level()

        if level then
            Level.trigger_event(level, "lua_premium_store_closed")
        end
    end

    opened_store = false
    Selected_purchase_offer = {}
end

StoreView._initialize_opening_page = function(self)
    local store_category_index = 1

    -- Go to selected item's category
    if Selected_purchase_offer then
        store_category_index = Category_index
    end

    local path = {
        category_index = store_category_index,
        page_index = 1,
    }

    self:_open_navigation_path(path)
end

local current_commodores_offers = {}
mod.grab_current_commodores_items = function(self)
    local player = Managers.player:local_player(1)
    local character_id = player:character_id()
    local archetype_name = player:archetype_name()
    local storefront = "premium_store_featured"
    if archetype_name == "veteran" then
        storefront = "premium_store_skins_veteran"
    elseif archetype_name == "zealot" then
        storefront = "premium_store_skins_zealot"
    elseif archetype_name == "psyker" then
        storefront = "premium_store_skins_psyker"
    elseif archetype_name == "ogryn" then
        storefront = "premium_store_skins_ogryn"
    end

    local store_service = Managers.data_service.store

    local _store_promise = store_service:get_premium_store(storefront)

    if not _store_promise then
        return Promise:resolved()
    end

    return _store_promise:next(function(data)
        for i = 1, #data.offers do
            data.offers[i]["layout_config"] = data.layout_config
            table.insert(current_commodores_offers, data.offers[i])
        end
    end)
end

mod.get_item_in_current_commodores = function(self, gearid, item_name)
    if not current_commodores_offers then
        return
    end

    for i = 1, #current_commodores_offers do
        if current_commodores_offers[i].bundleInfo then
            -- For bundles
            for j = 1, #current_commodores_offers[i].bundleInfo do
                local bundle_item = current_commodores_offers[i].bundleInfo[j]

                if bundle_item.description.id == item_name or bundle_item.description.gearid == gearid then
                    return current_commodores_offers[i]
                end
            end
        else
            -- for single items
            if current_commodores_offers[i].description.id == item_name or current_commodores_offers[i].description.gearid == gearid then
                return current_commodores_offers[i]
            end
        end
    end
end

-- Fill out the UI cosmetics grid with all unlocked, then locked cosmetics.
mod.list_premium_cosmetics = function(self)
    local selected_item_slot = self._selected_slot
    local _store_promise = mod.grab_current_commodores_items(self)
    _store_promise:next(function()
        if selected_item_slot.name == "slot_gear_head" or selected_item_slot.name == "slot_gear_lowerbody" or selected_item_slot.name == "slot_gear_upperbody" or selected_item_slot.name == "slot_gear_extra_cosmetic" then
            local current_cosmetics = mod.get_cosmetic_items(self, selected_item_slot.name)

            local layout = {}

            local unlocked_items = {}
            -- Add unlocked cosmetics
            local player = self._preview_player
            local profile = player:profile()
            local currentarchetype = profile.archetype
            local currentbreed = currentarchetype.breed

            for i = 1, #self._inventory_items do
                local item = self._inventory_items[i]
                if item then
                    local forcurrentbreed = false
                    if item.breeds then
                        for x, breed in pairs(item.breeds) do
                            if breed == currentbreed then
                                if item.archetypes then
                                    for y, archetypename in pairs(item.archetypes) do
                                        if archetypename == currentarchetype.name then
                                            forcurrentbreed = true
                                        end
                                    end
                                else
                                    forcurrentbreed = true
                                end
                            end
                        end
                        if forcurrentbreed then
                            local gear_id = item.gear_id
                            local is_new = self._context and self._context.new_items_gear_ids and
                                self._context.new_items_gear_ids[gear_id]
                            local remove_new_marker_callback

                            if is_new then
                                remove_new_marker_callback = self._parent and
                                    callback(self._parent, "remove_new_item_mark")
                            end

                            unlocked_items[#unlocked_items + 1] = item.__master_item.name
                            layout[#layout + 1] = {
                                widget_type = "gear_item",
                                sort_data = item,
                                item = item,
                                slot = selected_item_slot,
                                new_item_marker = is_new,
                                remove_new_marker_callback = remove_new_marker_callback,
                                profile = profile
                            }
                        end
                    end
                end
            end

            -- Add divider
            layout[#layout + 1] = {
                widget_type = "divider"
            }

            -- Add locked cosmetics
            for i = 1, #current_cosmetics do
                local item = _item_plus_overrides(current_cosmetics[i], current_cosmetics[i].__gear,
                    current_cosmetics[i].__gear_id, false)
                if item then
                    local continue = true

                    local gear_id = item.gear_id
                    local is_new = self._context and self._context.new_items_gear_ids and
                        self._context.new_items_gear_ids[gear_id]
                    local remove_new_marker_callback

                    if is_new then
                        remove_new_marker_callback = self._parent and
                            callback(self._parent, "remove_new_item_mark")
                    end

                    -- filter out unlocked items
                    for x, unlocked_item_name in pairs(unlocked_items) do
                        if item.name == unlocked_item_name then
                            continue = false
                        end
                    end

                    -- Filter out unknown sources
                    if item.source == nil or item.source < 1 then
                        continue = false
                    end

                    -- Filter out "NONE" commodore filter
                    if self._commodores_toggle == "loc_VPCC_show_no_commodores" and item.source == 3 then
                        continue = false
                    end

                    -- Filter out all not available items
                    local purchase_offer = mod.get_item_in_current_commodores(self, gear_id, item.name)

                    if self._commodores_toggle == "loc_VPCC_show_available_commodores" and item.source == 3 and not purchase_offer then
                        continue = false
                    end

                    if continue then
                        layout[#layout + 1] = {
                            widget_type = "gear_item", -- item_icon
                            sort_data = item,
                            item = item,
                            slot = selected_item_slot,
                            new_item_marker = is_new,
                            remove_new_marker_callback = remove_new_marker_callback,
                            locked = true,
                            profile = profile,
                            purchase_offer = purchase_offer
                        }
                    end
                end
            end

            self._offer_items_layout = table.clone_instance(layout)
            self:_present_layout_by_slot_filter(nil, nil, selected_item_slot.display_name)
        end
    end)
end

-- Get all cosmetics items available, from the MasterItems cache.
mod.get_cosmetic_items = function(self, selectedslot)
    local item_definitions = MasterItems.get_cached()
    local cosmetic_items = {}

    local player = self._preview_player
    local profile = player:profile()
    local currentarchetype = profile.archetype
    local currentbreed = currentarchetype.breed

    for item_name, item in pairs(item_definitions) do
        repeat
            local slots = item.slots
            local slot = slots and slots[1]
            if slot == "slot_gear_head" or slot == "slot_gear_lowerbody" or slot == "slot_gear_upperbody" or slot == "slot_gear_extra_cosmetic" then
                local gearid = item.__gear_id
                if gearid then
                    gearid[#gearid + 1] = gearid
                end

                local forcurrentbreed = false
                if slot and slot == selectedslot and item.breeds then
                    for x, breed in pairs(item.breeds) do
                        if breed == currentbreed then
                            if item.archetypes then
                                for y, archetypename in pairs(item.archetypes) do
                                    if archetypename == currentarchetype.name then
                                        forcurrentbreed = true
                                    end
                                end
                            else
                                forcurrentbreed = true
                            end
                        end
                    end
                    if forcurrentbreed then
                        cosmetic_items[#cosmetic_items + 1] = item
                    end
                end
            end
        until true
    end

    return cosmetic_items
end

-- SETUP COMMODORES ITEM TOGGLES
InventoryCosmeticsView.cb_on_commodores_toggle_pressed = function(self)
    if self._commodores_toggle == "loc_VPCC_show_all_commodores" then
        self._commodores_toggle = "loc_VPCC_show_available_commodores"
    elseif self._commodores_toggle == "loc_VPCC_show_available_commodores" then
        self._commodores_toggle = "loc_VPCC_show_no_commodores"
    elseif self._commodores_toggle == "loc_VPCC_show_no_commodores" then
        self._commodores_toggle = "loc_VPCC_show_all_commodores"
    end

    mod:set("show_commodores", self._commodores_toggle)
    mod.list_premium_cosmetics(self)
    mod.focus_on_item(self, previewed_items)
end

local Definitions = mod:io_dofile(
    "character_cosmetics_view_improved/scripts/mods/character_cosmetics_view_improved/character_cosmetics_view_improved_definitions")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
InventoryCosmeticsView._setup_input_legend = function(self)
    self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 10)

    local legend_inputs = Definitions.legend_inputs

    for i = 1, #legend_inputs do
        local legend_input = legend_inputs[i]
        local on_pressed_callback = legend_input.on_pressed_callback and callback(self, legend_input.on_pressed_callback)

        self._input_legend_element:add_entry(legend_input.display_name, legend_input.input_action,
            legend_input.visibility_function, on_pressed_callback, legend_input.alignment)
    end
end
