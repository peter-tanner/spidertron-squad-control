--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control/init.lua
 * Runs when installed/config changes. Incorporate intermod compatibility here.
--]]

function Initialize()
    game.print("Create tables for spidertron control mod")
    if global.spidercontrol_linked_s == nil then
        global.spidercontrol_linked_s = {}
    end
    if global.spidercontrol_player_s == nil then
        global.spidercontrol_player_s = {}
        for _, player in pairs(game.players) do
            global.spidercontrol_player_s[player.index] = {active = {}, inactive = {}} -- Some future-proofing here
        end
    end
    if global.spidercontrol_spidertronwaypoints_patrol == nil then
        global.spidercontrol_spidertronwaypoints_patrol = {} 
    end
    SpidertronWaypointsCompatibility()
end

script.on_init(Initialize)
script.on_configuration_changed(Initialize)
-- commands.add_command("spiderbot_Initialize_variables", "debug: ensure that all global tables are not nil (should not happen in a normal game)", Initialize)

script.on_event(defines.events.on_player_created, function (event)
    if global.spidercontrol_player_s == nil then
        Initialize()
    end
    global.spidercontrol_player_s[event.player_index] = {active = {}, inactive = {}}
end)