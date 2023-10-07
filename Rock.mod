return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Rock` encountered an error loading the Darktide Mod Framework.")

		new_mod("Rock", {
			mod_script       = "Rock/scripts/mods/Rock/Rock",
			mod_data         = "Rock/scripts/mods/Rock/Rock_data",
			mod_localization = "Rock/scripts/mods/Rock/Rock_localization",
		})
	end,
	packages = {},
}
