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

local function squad_center(spidersquad)
    local xbar=0
    local ybar=0
    local c=0
    for _, spider in pairs(spidersquad) do
        c=c+1
        xbar=xbar+spider.position.x
        ybar=ybar+spider.position.y
    end
    xbar=xbar/c
    ybar=ybar/c
    return {xbar,ybar}
end

local function spiderbot_designate(index, position_)
    validate_spiders(index)
    local spidersquad = global.spidercontrol_spidersquad[index]

    local posbar = squad_center(spidersquad)

    local dx=position_.x-posbar[1]
    local dy=position_.y-posbar[2]

    for _, spider in pairs(spidersquad) do
        local position = spider.position
        spider.autopilot_destination = {position.x+dx, position.y+dy}
    end
end

local function spiderbot_follow(player)
	if player.character then
		if player.is_shortcut_toggled("squad-spidertron-follow") then
			player.set_shortcut_toggled("squad-spidertron-follow", false)
        else
			player.set_shortcut_toggled("squad-spidertron-follow", true)
		end
	else
		player.print({"", {"error.error-message-box-title"}, ": ", {"player-doesnt-exist", {"gui.character"}}, " (", {"controller.god"}, "): ", {"gui-mod-info.status-disabled"}})
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
script.on_event(defines.events.on_player_used_spider_remote, function (event)
    local index = event.player_index
    local player = game.players[index]
    local cursor_stack = player.cursor_stack
    if cursor_stack.valid_for_read and cursor_stack.name == "squad-spidertron-remote" and event.success then
        player.set_shortcut_toggled("squad-spidertron-follow", false)
        spiderbot_designate(index, event.position)
    end
end)

script.on_event(defines.events.on_lua_shortcut, function (event)
    if event.prototype_name == "squad-spidertron-follow" then
        spiderbot_follow(game.players[event.player_index])
    end
end)

script.on_event("squad-spidertron-remote", function(event)
    local player = game.players[event.player_index]
    local stack = {name="squad-spidertron-remote-sel",count=1}
    if player.clean_cursor() and player.cursor_stack.can_set_stack(stack) then
        if player.get_main_inventory() then
            player.get_main_inventory().remove("squad-spidertron-remote-sel")
            player.get_main_inventory().remove("squad-spidertron-remote")
        end

        player.cursor_stack.set_stack(stack)
    end
end)

script.on_event("squad-spidertron-follow", function(event)
    spiderbot_follow(game.players[event.player_index])
end)

local mov_offset = settings.global["spidertron-follow-prediction-distance"].value --This is so the player stays within the spider squad when moving
local mov_offset_diagonal = math.sqrt(mov_offset^2/2)

local update_interval = settings.global["spidertron-follow-update-interval"].value

script.on_nth_tick(update_interval, function (event)
    for _, player in pairs(game.players) do
        if player.is_shortcut_toggled("squad-spidertron-follow") and global.spidercontrol_spidersquad[player.index] then
            local index = player.index
            local pos = player.position
            local pos_x = pos.x
            local pos_y = pos.y
            if player.walking_state.walking then
                local dir = player.walking_state.direction
                local def_dir = defines.direction
                if dir == def_dir.north then
                    pos_y = pos_y - mov_offset
                elseif dir == def_dir.northeast then
                    -- game.print("ne")
                    pos_x = pos_x + mov_offset_diagonal
                    pos_y = pos_y - mov_offset_diagonal
                elseif dir == def_dir.east then
                    -- game.print("e")
                    pos_x = pos_x + mov_offset
                elseif dir == def_dir.southeast then
                    -- game.print("se")
                    pos_x = pos_x + mov_offset_diagonal
                    pos_y = pos_y + mov_offset_diagonal
                elseif dir == def_dir.south then
                    -- game.print("s")
                    pos_y = pos_y + mov_offset
                elseif dir == def_dir.southwest then
                    -- game.print("sw")
                    pos_x = pos_x - mov_offset_diagonal
                    pos_y = pos_y + mov_offset_diagonal
                elseif dir == def_dir.west then
                    -- game.print("w")
                    pos_x = pos_x - mov_offset
                else -- northwest
                    -- game.print("nw")
                    pos_x = pos_x - mov_offset_diagonal
                    pos_y = pos_y - mov_offset_diagonal
                end
            end
            spiderbot_designate(index, {x=pos_x, y=pos_y})
            if player.vehicle then
                local vehicle = player.vehicle
                if vehicle.type == "spider-vehicle" then
                    vehicle.autopilot_destination = squad_center(global.spidercontrol_spidersquad[index])
                end
            end
        end
    end
end)