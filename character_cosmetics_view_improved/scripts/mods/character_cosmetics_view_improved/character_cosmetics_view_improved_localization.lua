local mod = get_mod("character_cosmetics_view_improved")
mod.version = "4.7.04"
mod:info("Character Cosmetics View Improved is installed, using version: " .. tostring(mod.version))

local colours = {
	title = "200,140,20",
	subtitle = "226,199,126",
	text = "169,191,153",
}

-- Colors for the gradient of the mod name
local gradient_start = { 76, 255, 201 }
local gradient_end = { 0, 146, 255 }

local function lerp(a, b, t)
	return a + (b - a) * t
end

mod.gradientText = function(text, startColor, endColor, colorSpaces)
	local result = ""
	local length = #text
	local visibleIndex = 0

	-- Count visible characters
	for i = 1, length do
		local char = text:sub(i, i)
		if colorSpaces or char ~= " " then
			visibleIndex = visibleIndex + 1
		end
	end

	local currentIndex = 0

	for i = 1, length do
		local char = text:sub(i, i)

		if not colorSpaces and char == " " then
			result = result .. char
		else
			currentIndex = currentIndex + 1
			local t = (visibleIndex <= 1) and 0 or (currentIndex - 1) / (visibleIndex - 1)

			local r = math.floor(lerp(startColor[1], endColor[1], t))
			local g = math.floor(lerp(startColor[2], endColor[2], t))
			local b = math.floor(lerp(startColor[3], endColor[3], t))

			result = result .. string.format("{#color(%d,%d,%d)}%s", r, g, b, char)
		end
	end

	result = "{#color(" .. colours.title .. ")} " .. result .. "{#reset()}"
	return result
end

--local name = mod.gradientText("Alf's DMF Extensions", { 255, 255, 0 }, { 255, 0, 255 }, true)
--Clipboard.put(name)
--mod:echo(name)

local mod_name = {
	en = "Character Cosmetics View Improved",
	ru = "Улучшенный осмотр косметических предметов",
	["zh-cn"] = "角色装饰品视图改进",
}

mod:add_global_localize_strings({

	loc_VPCC_preview = {
		en = "Preview",
		ru = "Показать на игроке",
		["zh-cn"] = "预览",
	},
	loc_VPCC_store = {
		en = "View In Store",
		ru = "Показать в магазине",
		["zh-cn"] = "在商店中查看",
	},
	loc_VPCC_wishlist = {
		en = "",
		["zh-cn"] = "",
	},
	loc_VPCC_in_store = {
		en = "",
		["zh-cn"] = "",
	},
	loc_VPCC_wishlist_added = {
		en = " has been added to your wishlist.",
		ru = " добавляется в список желаемого.",
		["zh-cn"] = "已被添加至愿望单",
	},
	loc_VPCC_wishlist_removed = {
		en = " has been removed from your wishlist.",
		ru = " убирается из списка желаемого.",
		["zh-cn"] = "已被从愿望单中移除",
	},
	loc_VPCC_wishlist_notification = {
		en = "The following cosmetic(s) from your wishlist are available for purchase: ",
		ru = "Следующие косметические предметы из вашего списка желаемого доступны для покупки: ",
		["zh-cn"] = "愿望单中的装饰品现已可购买",
	},
	loc_VPCC_show_all_commodores = {
		en = "Show Commodores: All",
		ru = "Премиумные вещи: Все",
		["zh-cn"] = "全部",
	},
	loc_VPCC_show_available_commodores = {
		en = "Show Commodores: Available",
		ru = "Премиумные вещи: Доступные",
		["zh-cn"] = "可用",
	},
	loc_VPCC_show_wishlisted_commodores = {
		en = "Show Commodores: Wishlisted",
		ru = "Премиумные вещи: В списке желаемого",
	},
	loc_VPCC_show_no_commodores = {
		en = "Show Commodores: None",
		ru = "Премиумные вещи: Не показывать",
		["zh-cn"] = "不显示",
	},
})

mod.localisation = {
	mod_name = {
		en = mod_name["en"],
		ru = mod_name["ru"],
	},
	mod_name_pizazz = {
		en = mod.gradientText(mod_name["en"], { 76, 255, 201 }, { 0, 146, 255 }, true),
		ru = mod.gradientText(mod_name["ru"], { 76, 255, 201 }, { 0, 146, 255 }, true),
	},
	mod_name_boring = {
		en = mod_name["en"],
		ru = mod_name["ru"],
	},
	mod_description = {
		en = "{#color("
			.. colours.text
			.. ")}"
			.. "See all Commodore's Vestures items, data mined items, wishlisting and more, to improve the character cosmetics screen."
			.. "{#reset()}\n\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Author: "
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Version: {#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
		ru = "{#color("
			.. colours.text
			.. ")}"
			.. "Character Cosmetics View Improved - Отображает все премиум-предметы из магазина «Одеяния от Командора» и добавляет удобные функции."
			.. "{#reset()}\n\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Автор: "
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Версия: {#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
		["zh-cn"] = "{#color("
			.. colours.text
			.. ")}"
			.. "显示「准将的服装」所有物品，并增加预览、愿望单等功能。"
			.. "{#reset()}\n\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}作者: "
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}版本: {#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
	},
	mod_name_pizazz_toggle = {
		en = "Enable Name Pizazz",
		ru = "Включить красочное название",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
		ru = "Включает радужный эффект на тексте названия мода. Требуется перезагрузка.\nЕсли включено, вы получите небольшой эйфорический опыт каждый раз, когда прокручиваете меню модов,\nЕсли выключено - вы будете Джоном Дарктайдом и не будете иметь радужных посыпок (но я всё равно буду любить вас).",
	},
	show_commodores = {
		en = "Show Commodores Vesture's Items?",
		ru = "Показывать предметы из магазина «Одеяния от Командора»?",
		["zh-cn"] = "是否显示「准将的服装」中的物品",
	},
	All = {
		en = "All",
		ru = "Все",
		["zh-cn"] = "全部",
	},
	OnlyAvailable = {
		en = "Only Available to Purchase",
		ru = "Только доступные для покупки",
		["zh-cn"] = "仅可购买",
	},
	OnlyWishlisted = {
		en = "Only Wishlisted Items",
		ru = "Только в списке желаемого",
	},
	None = {
		en = "None",
		ru = "Не показывать",
		["zh-cn"] = "不显示",
	},
	show_unobtainable = {
		en = "Show Unobtainable Cosmetics",
		ru = "Показывать недоступные косметические предметы",
		["zh-cn"] = "显示无法获取的装饰品",
	},
	display_commodores_price_in_inventory = {
		en = "Show Aquila price in inventory?",
		ru = "Показывать цену в аквилах в инвентаре?",
	},
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
		ru = "{#color(" .. colours.title .. ")}Основные настройки{#reset()}",
	},

	show_commodores_tooltip = {
		en = "Choose how much of the locked Commodore's Vestures items you wish to be shown in the character cosmetics screen.\n\nAll: See EVERY item, including those out of rotation.\nOnly Available: See only those in rotation\nNone: Show no commodore's items at all.",
		ru = "Выберите, сколько заблокированных предметов из магазина «Одеяния от Командора» вы хотите показывать на экране косметики персонажа.\n\nВсе: Показывать ВСЕ предметы, включая те, что не в ротации.\nТолько доступные: Показывать только те, что в ротации.\nНе показывать: Не показывать предметы Командора вообще.",
	},
	show_unobtainable_tooltip = {
		en = "Toggle showing of unobtainable items. These are items that have been datamined, but have no set sources yet.\n\nThis mostly includes items that may come in future updates, or are debug/placeholders. ",
		ru = "Включить отображение недоступных предметов. Это предметы, которые были найдены в данных игры, но пока не имеют источников.\n\nВ основном это предметы, которые могут появиться в будущих обновлениях, или отладочные/заглушки.",
	},
	display_commodores_price_in_inventory_tooltip = {
		en = "Toggle displaying the aquila price of Commodore's Vestures items in the character cosmetics screen.",
		ru = "Включить отображение цены в аквилах предметов из магазина «Одеяния от Командора» на экране косметики персонажа.",
	},
}

mod.toggle_pizazz = function()
	for key, values in pairs(mod.localisation) do
		if key == "mod_name" then
			for language, _ in pairs(values) do
				if mod:get("mod_name_pizazz_toggle") then
					mod.localisation[key][language] = mod.localisation["mod_name_pizazz"][language]
				else
					mod.localisation[key][language] = mod.localisation["mod_name_boring"][language]
				end
			end
		end
	end
end

mod.toggle_pizazz()

return mod.localisation
