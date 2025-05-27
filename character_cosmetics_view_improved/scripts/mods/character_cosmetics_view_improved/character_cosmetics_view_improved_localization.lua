local mod = get_mod("character_cosmetics_view_improved")

mod:add_global_localize_strings({
	loc_VPCC_preview = {
		en = "Preview"
	},
	loc_VPCC_store = {
		en = "View In Store"
	},
	loc_VPCC_show_all_commodores = {
		en = "Show Commodores: All"
	},
	loc_VPCC_show_available_commodores = {
		en = "Show Commodores: Available"
	},
	loc_VPCC_show_no_commodores = {
		en = "Show Commodores: None"
	}
})


return {
	mod_description = {
		en = "Displays all premium cosmetics available through Commodore's Vestures in the character cosmetics screen.",
	},
	show_commodores = {
		en = "Show Commodores Vesture's Items?"
	},
	All = {
		en = "All"
	},
	OnlyAvailable = {
		en = "Only Available to Purchase"
	},
	None = {
		en = "None"
	}
}
