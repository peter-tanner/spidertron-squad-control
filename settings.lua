--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * settings.lua
 * Mod settings
--]]

require("constants")

data:extend({
	--	server
    {
        type = "double-setting",
        name = "spidertron-follow-prediction-distance",
        localised_name = "Follow prediction distance",
        localised_description = "When in follow mode, the movement targets of the spider bot will be this far ahead of the player's position. Minimum value: 0.0, Maximum value: 500.0, Default value: 20.0",
        setting_type = "runtime-global",
        default_value = 20.0,
		minimum_value = 0.0,
		maximum_value = 500.0,
    },
    {
        type = "int-setting",
        name = "spidertron-follow-update-interval",
        localised_name = "Follow update interval",
        localised_description = "Rate at which the follow mode updates the target positions of the spidertrons. This value is in ticks. Larger values are less laggy but result in less responsive squad movement. Minimum value: 5, Default value: 20",
        setting_type = "runtime-global",
        default_value = 20,
		minimum_value = 5
    },
    {
        type = "int-setting",
        name = "spidertron-gui-update-interval",
        localised_name = "GUI update interval",
        localised_description = "Rate at which the spidertron save/load GUI is updated. This value is in ticks. Larger values are less laggy but result in less responsive information. Minimum value: 5, Default value: 60",
        setting_type = "runtime-global",
        default_value = 60,
		minimum_value = 5
    },
    {
        type = "int-setting",
        name = "spidertron-max-squads",
        localised_name = "Maximum templates per player",
        localised_description = "Maximum number of squad templates a player can save. Minimum value: 1, Default value: 20",
        setting_type = "runtime-global",
        default_value = 20,
		minimum_value = 1
    },
    --  player
    {
        type = "string-setting",
        name = "spidertron-default-squad-remote",
        localised_name = "Default squad tool",
        localised_description = "Type of remote to give when the squad remote shortcut is used. Default value: "..SETTING_REMOTE_SEL,
        setting_type = "runtime-per-user",
        default_value = SETTING_REMOTE_SEL,
        allowed_values = {
            SETTING_AUTOMATIC,
            SETTING_REMOTE_SEL,
            SETTING_REMOTE
        }
    },
    {
        type = "string-setting",
        name = "spidertron-default-link-remote",
        localised_name = "Default link tool",
        localised_description = "Type of remote to give when the Link shortcut is used. Default value: "..SETTING_AUTOMATIC,
        setting_type = "runtime-per-user",
        default_value = SETTING_AUTOMATIC,
        allowed_values = {
            SETTING_AUTOMATIC,
            SETTING_LINK,
            SETTING_UNLINK
        }
    }
})