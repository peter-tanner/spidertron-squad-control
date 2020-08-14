--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control.lua
 * Spiderbot.
--]]

local function spiderbot_select(event)
    local index = event.player_index
    local spiders = event.entities
    if event.item == "squad-spidertron-remote-sel" and #spiders > 0 then
        global.spidercontrol_spidersquad[index] = spiders
        local player = game.players[index]
        local stack = {
            name="squad-spidertron-remote",
            count=1
        }
        -- game.print(spiders[1])
        if player.cursor_stack.can_set_stack(stack) then
            player.cursor_stack.set_stack(stack)
            player.cursor_stack.connected_entity=spiders[1]
        end
    end
end

local function validate_spiders(index)
    local c=0
    for i, spider in pairs(global.spidercontrol_spidersquad[index]) do
        if not spider.valid then
            global.spidercontrol_spidersquad[index][i] = nil
            c=c+1
        end
    end
    if c > 0 then
        game.players[index].print(c .. " units were destroyed since the last position command was sent")
    end
end

local function spiderbot_designate(event)
    local index = event.player_index
    local player = game.players[index]
    if player.cursor_stack.valid_for_read and player.cursor_stack.name == "squad-spidertron-remote" then
        validate_spiders(index)
        local spidersquad = global.spidercontrol_spidersquad[index]
        local xbar=0
        local ybar=0
        local c=0
        for _, spider in pairs(spidersquad) do
            c=c+1
            -- game.print(spider.position)
            xbar=xbar+spider.position.x
            ybar=ybar+spider.position.y
       end
        xbar=xbar/c
        ybar=ybar/c

        dy=event.position.y-ybar
        dx=event.position.x-xbar

        for _, spider in pairs(spidersquad) do
            local position = spider.position
            spider.autopilot_destination = {position.x+dx, position.y+dy}
        end
    end
end

local function initialize()
	if global.spidercontrol_spidersquad == nil then
		global.spidercontrol_spidersquad = {}
	end
end

script.on_init(initialize)
script.on_configuration_changed(initialize)
--commands.add_command("spiderbot_initialize_variables", "debug: ensure that all global tables are not nil (should not happen in a normal game)", initialize)

script.on_event(defines.events.on_player_alt_selected_area, spiderbot_select)
script.on_event(defines.events.on_player_selected_area, spiderbot_select)
script.on_event(defines.events.on_player_used_spider_remote, spiderbot_designate)

script.on_event("squad-spidertron-remote", function(event)
    local player = game.players[event.player_index]
    local stack = {name="squad-spidertron-remote-sel",count=1}
    if player.clean_cursor() and player.cursor_stack.can_set_stack(stack) then
        player.get_inventory(2).remove("squad-spidertron-remote-sel")
        player.get_inventory(2).remove("squad-spidertron-remote")
        player.cursor_stack.set_stack(stack)
    end
end)