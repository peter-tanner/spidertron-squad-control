--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control.lua
 * Spiderbot.
--]]

-- /c for i=0,5 do game.player.insert("spidertron"); end; for i=0,2 do game.player.insert("spidertron-remote") end
require("util")


local function give_tool(player, stack)
    if player.clean_cursor() and player.cursor_stack and player.cursor_stack.can_set_stack(stack) then
        if player.get_main_inventory() then
            player.get_main_inventory().remove("squad-spidertron-remote-sel")
            player.get_main_inventory().remove("squad-spidertron-remote")
        end
        player.cursor_stack.set_stack(stack)
        return true
    end
end

local function squad_center(spidersquad)
    local xbar=0
    local ybar=0
    local c=0
    for i=1, #spidersquad do
        c=c+1
        local pos = spidersquad[i].position
        xbar=xbar+pos.x
        ybar=ybar+pos.y
    end
    return {xbar/c,ybar/c}
end

local function spiderbot_select(event)
    local index = event.player_index
    local spiders = event.entities
    if event.item == "squad-spidertron-remote-sel" and #spiders > 0 then
        local center = squad_center(spiders)
        global.spidercontrol_spidersquad[index] = {spiders={}} -- some future proofing here
        for i=1, #spiders do
            local spider = spiders[i]
            local pos = spider.position
            table.insert(global.spidercontrol_spidersquad[index].spiders, {
                spider_entity=spider,
                d={pos.x-center[1],pos.y-center[2]} -- dx and dy
            })
        end
        local player = game.players[index]
        if give_tool(player, {name="squad-spidertron-remote",count=1}) then
            player.cursor_stack.connected_entity=spiders[1]
        end
    end
end

local function validate_spiders(index)
    local c=0
    if global.spidercontrol_spidersquad[index] then
        --for i, spider_ in pairs(global.spidercontrol_spidersquad[index].spiders) do
        for i, spider in pairs(global.spidercontrol_spidersquad[index].spiders) do
            if not spider.spider_entity or not spider.spider_entity.valid then
                global.spidercontrol_spidersquad[index].spiders[i] = nil
                c=c+1
            end
        end
        if c > 0 then
            game.players[index].print(c .. " units were destroyed or mined since the last position command was sent")   --this is causing crashes for one user. states that the player does not exist (why?) needs more research
        end
        return true
    end
end

local function spiderbot_designate(index, position)
    if validate_spiders(index) then
        local d_ = global.spidercontrol_spidersquad[index]
        local spidersquad = d_.spiders
        local leader = d_.spider_leader
        local l_d = {0,0}
        if leader then
            if spidersquad[leader] and spidersquad[leader].spider_entity.valid then
                -- game.players[index].print("Leader "..leader)
                l_d = spidersquad[leader].d
            else
                game.players[index].print("Leader destroyed") -- In case destroyed by biters/nuke/whatever
                global.spidercontrol_spidersquad[index].spider_leader = nil
                leader = nil
            end
        end


        local follow = game.players[index].is_shortcut_toggled("squad-spidertron-follow")
        for i, spider_ in pairs(spidersquad) do
            if i ~= leader or not follow then
                local spider = spider_.spider_entity
                local d = spider_.d
                spider.autopilot_destination = {position.x+d[1]-l_d[1], position.y+d[2]-l_d[2]} -- leader dy and dx offsets so that the leader itself becomes the new mean of the squad.
            end
        end
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

local function spidertron_waypoints_compatability()
    -- Compatability for Spidertron Waypoints
    if remote.interfaces["SpidertronWaypoints"] then
        local event_ids = remote.call("SpidertronWaypoints", "get_event_ids")
        local on_spidertron_given_new_destination = event_ids.on_spidertron_given_new_destination
        SPIDERTRON_WAYPOINTS = true
        script.on_event(on_spidertron_given_new_destination, function(event) game.print("New destination") spiderbot_designate(event.player_index, event.position) end)
    end
end


local function initialize()
    if global.spidercontrol_spidersquad == nil then
        game.print("Create tables for spidertron control mod")
        global.spidercontrol_spidersquad = {}
        for _, player in pairs(game.players) do
            global.spidercontrol_spidersquad[player.index] = {spider_leader = nil, spiders={}}
        end
    end
    spidertron_waypoints_compatability()
end

script.on_init(initialize)
script.on_configuration_changed(initialize)
script.on_load(function() spidertron_waypoints_compatability() end)
--commands.add_command("spiderbot_initialize_variables", "debug: ensure that all global tables are not nil (should not happen in a normal game)", initialize)

script.on_event(defines.events.on_player_alt_selected_area, spiderbot_select)
script.on_event(defines.events.on_player_selected_area, spiderbot_select)

script.on_event(defines.events.on_player_used_spider_remote, function(event)
    local index = event.player_index
    local player = game.players[index]
    local cursor_stack = player.cursor_stack
    if cursor_stack then    -- how can a player use a remote without a cursor_stack though???
        if cursor_stack.valid_for_read and cursor_stack.name == "squad-spidertron-remote" and event.success then
            game.print("squad-spidertron-remote")
            player.set_shortcut_toggled("squad-spidertron-follow", false)
            if not SPIDERTRON_WAYPOINTS then spiderbot_designate(index, event.position) end
        elseif cursor_stack.valid_for_read and cursor_stack.name == "spidertron-remote" and event.success then -- WARNING: We're only overriding for the player's spidertron if it's the vanilla spidertron remote. Does not cover modded remotes!
            -- Alter dy and dx
            game.print("spidertron-remote")
            local unit_no = event.vehicle.unit_number
            local d_ = global.spidercontrol_spidersquad[index]
            local spidersquad = d_.spiders
            local leader = d_.spider_leader

            if spidersquad then -- HELLO: if you are reading this and have an idea how to optimize it pls let me know (Not really critical as it's not in the tick loop, but could be problematic for very large squads )
                for i, spider in pairs(spidersquad) do  --something something premature debugging evil, but seriously the amount of loops are worrying (for large squds).
                    if i ~= leader and spider.spider_entity.unit_number == unit_no then -- Don't alter dy and dx for the squad leader (leads to infinite walking)
                        local dest = event.position
                        local flat = {} -- repack the array (which is divided because of us storing dy and dx) into a flat one
                        for j, spider_ in pairs(spidersquad) do 
                            if j == i then
                                flat[#flat+1] = {position = dest}   -- need to predict where it will be and use that as a mean, not current location
                            else
                                flat[#flat+1] = spider_.spider_entity
                            end
                        end
                        local center = squad_center(flat)
                        -- tried to do something without calling this loop but it's the most reliable option

                        --very interesting problem : because the mean of the squad is dependent on the positions of each squad member, varying the dy/dx parameters of only one spider (originally the one we're moving) results in this one being scaled off the 'actual' target location - at very far distances from the squad mean this becomes very noticeable. This means we need to calculate the mean of the entire squad if one has changed position. I noticed this error because of the fact that the offset was not constant but proportional to distance away from the mean
                        for k, spider_ in pairs(spidersquad) do 
                            if k == i then
                                global.spidercontrol_spidersquad[index].spiders[k].d = {
                                    dest.x - center[1], --dx
                                    dest.y - center[2]  --dy
                                }
                            else
                                local pos = spider_.spider_entity.position
                                global.spidercontrol_spidersquad[index].spiders[k].d = {
                                    pos.x - center[1], --dx
                                    pos.y - center[2]  --dy
                                }
                            end
                        end
                        -- game.print("dx"..dest.x - center[1].."dy"..dest.y - center[2])
                        break
                    end
                end
            end
        end
    end
end)

local function squad_leader_state(index)
    local player = game.players[index]
    if player.vehicle and player.vehicle.type == "spider-vehicle" then
        local unit_no = player.vehicle.unit_number
        local d = global.spidercontrol_spidersquad[index].spiders
        if d then
            for i, spider in pairs(d) do
                -- game.print(spider.spider_entity.unit_number)
                if spider.spider_entity.valid and spider.spider_entity.unit_number == unit_no then
                    global.spidercontrol_spidersquad[index].spider_leader = i
                    break
                end
            end
        end
    elseif player.vehicle == nil then
        global.spidercontrol_spidersquad[index].spider_leader = nil
    end
end

script.on_event(defines.events.on_player_driving_changed_state, function (event)
    squad_leader_state(event.player_index)
end)

script.on_event(defines.events.on_player_died, function(event)
    squad_leader_state(event.player_index)
end)

script.on_event(defines.events.on_lua_shortcut, function (event)
    if event.prototype_name == "squad-spidertron-follow" then
        local index = event.player_index
        squad_leader_state(index)
        spiderbot_follow(game.players[index])
    end
end)

script.on_event(defines.events.on_player_created, function (event)
    global.spidercontrol_spidersquad[event.player_index] = {spiders={}}
end)

script.on_event("squad-spidertron-remote", function(event)
    give_tool(game.players[event.player_index], {name="squad-spidertron-remote-sel",count=1})
end)

script.on_event("squad-spidertron-follow", function(event)
    squad_leader_state(event.player_index)
    spiderbot_follow(game.players[event.player_index])
end)

script.on_event("squad-spidertron-switch-modes", function(event)
    local player = game.players[event.player_index]
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read then
        if cursor_stack.name == "squad-spidertron-remote" then
            give_tool(player, {name="squad-spidertron-remote-sel",count=1})
        elseif cursor_stack.name == "squad-spidertron-remote-sel" then
            local e = global.spidercontrol_spidersquad[event.player_index]
            if e.spiders[1] and e.spiders[1].spider_entity.valid and give_tool(player, {name="squad-spidertron-remote",count=1}) then
                player.cursor_stack.connected_entity=e.spiders[1].spider_entity
            end
        end
    end
end)


local mov_offset = settings.global["spidertron-follow-prediction-distance"].value --This is so the player stays within the spider squad when moving
local mov_offset_diagonal = math.sqrt(mov_offset^2/2)

local function pos_offset(position,dir)
    local def_dir = defines.direction
    local pos_x = position.x
    local pos_y = position.y

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

    return {x=pos_x, y=pos_y}
end

local update_interval = settings.global["spidertron-follow-update-interval"].value

script.on_nth_tick(update_interval, function(event)
    for _, player in pairs(game.players) do
        if player.is_shortcut_toggled("squad-spidertron-follow") and player.controller_type ~= 0 then -- 0 => defines.character.ghost (DEAD)
            local index = player.index
            if global.spidercontrol_spidersquad[index].spiders[1] then
                local p_pos = player.position
                local pos = p_pos
                if player.walking_state.walking then
                    local dir = player.walking_state.direction
                    pos = pos_offset(p_pos,dir)
                end
                spiderbot_designate(index, pos)
            end
        end
    end
end)