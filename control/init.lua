
local function initialize()
    if global.spidercontrol_spidersquad == nil then
        game.print("Create tables for spidertron control mod")
        global.spidercontrol_linked_s = {}
        global.spidercontrol_player_s = {}
        global.spidercontrol_spidertronwaypoints_patrol = {}
        for _, player in pairs(game.players) do
            global.spidercontrol_player_s[player.index] = {active = {}, inactive = {}} -- Some future-proofing here
        end
    end
    SpidertronWaypointsCompatibility()
end

script.on_init(initialize)
script.on_configuration_changed(initialize)
-- commands.add_command("spiderbot_initialize_variables", "debug: ensure that all global tables are not nil (should not happen in a normal game)", initialize)
