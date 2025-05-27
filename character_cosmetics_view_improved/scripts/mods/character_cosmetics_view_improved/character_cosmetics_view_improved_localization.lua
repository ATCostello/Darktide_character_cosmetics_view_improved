local mod = get_mod("character_cosmetics_view_improved")

mod:add_global_localize_strings({
	loc_VPCC_preview = {
		en = "Preview",
		ru = "Показать на игроке",
	},
	loc_VPCC_store = {
		en = "View In Store",
		ru = "Показать в магазине",
	},
	loc_VPCC_show_all_commodores = {
		en = "Show Commodores: All",
		ru = "Премиумные вещи: Все",
	},
	loc_VPCC_show_available_commodores = {
		en = "Show Commodores: Available",
		ru = "Премиумные вещи: Доступные",
	},
	loc_VPCC_show_no_commodores = {
		en = "Show Commodores: None",
		ru = "Премиумные вещи: Не показывать",
	}
})


return {
	mod_name = {
		en = "Character Cosmetics View Improved",
		ru = "Улучшенный осмотр косметических предметов на персонаже",
	},
	mod_description = {
		en = "Displays all premium cosmetics available through Commodore's Vestures in the character cosmetics screen, and allows you to preview them, and go directly to the items in the store (If they are in the current rotation) and much more!",
		ru =
		"Character Cosmetics View Improved - Отображает все премиумные-косметические предметы, доступные в магазине «Одеяние от Командора», на экране косметических предметов персонажа.",
	},
	show_commodores = {
		en = "Show Commodores Vesture's Items?",
		ru = "Показывать предметы из магазина «Одеяние от Командора»?",
	},
	All = {
		en = "All",
		ru = "Все",
	},
	OnlyAvailable = {
		en = "Only Available to Purchase",
		ru = "Только доступные для покупки",
	},
	None = {
		en = "None",
		ru = "Не показывать",
	},
	show_unobtainable = {
		en = "Show Unobtainable Cosmetics"
	}
}
