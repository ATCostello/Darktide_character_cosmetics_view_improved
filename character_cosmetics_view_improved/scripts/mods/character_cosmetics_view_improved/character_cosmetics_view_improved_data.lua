local mod = get_mod("character_cosmetics_view_improved")

return {
	name = "Character Cosmetics View Improved",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "show_commodores",
				type = "dropdown",
				default_value = "loc_VPCC_show_all_commodores",
				options = {
					{ text = "All",       value = "loc_VPCC_show_all_commodores" },
					{ text = "OnlyAvailable", value = "loc_VPCC_show_available_commodores" },
					{ text = "None",        value = "loc_VPCC_show_no_commodores" },
				}
			}
		}
	}
}