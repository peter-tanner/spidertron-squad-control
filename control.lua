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

local function give_link_tool(index)
    local d = global.spidercontrol_spidersquad[index]
    if d then
        if #d.spiders > 0 and d.spiders[1].spider_entity.valid then    --- NEED TO CHECK THIS!!!!!!!!!!!!!!!!! CAN WE REMOVE IT?
            local player = game.players[index]
            if give_tool(player, {name="squad-spidertron-link-tool",count=1}) then
                player.cursor_stack.connected_entity=d.spiders[1].spider_entity
            end
            -- give_tool(player, {name="spidertron-link-tool",count=1})
        else
            give_tool(game.players[index], {name="squad-spidertron-unlink-tool",count=1})
        end
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
    elseif event.item == "squad-spidertron-unlink-tool" and #spiders > 0 then
        if #global.spidercontrol_linked_squads > 0 then
             -- This is highly unoptimised, because we're searching through the list of all spidertrons and comparing it to the spidertrons in the selection box. Not quite the worst case, because everytime we get a match we remove it from the search list and we terminate the search when nothing is left in the search list. Can have a large UPS impact spike for bases with many squads that are very large, when a large selection of spidertrons are to be unlinked
             -- Is there a way to attach an attribute directly to an entity, so that we don't need to search the whole global table?? That would improve speed by a lot
            local ids = {}
            local force = game.players[index].force.index
            for i=1, #spiders do
                ids[#ids+1] = spiders[i].unit_number
            end
            for i,t in pairs(global.spidercontrol_linked_squads) do
                if #ids == 0 then break end
                if force == t.force then 
                    local pos = t.target.position
                    local c = 0
                    for j, spider in pairs(t.spiders) do
                        if #ids == 0 then break end

                        for k,id in pairs(ids) do
                            if spider.spider_entity.unit_number == id then
                                global.spidercontrol_linked_squads[i].spiders[j] = nil
                                table.remove(ids,k)
                                c = c + 1
                            end
                        end
                    end
                    if c > 0 then
                        if t.target and t.target.valid then
                            game.forces[t.force].print({"", c.." spidertrons have been unlinked from a ", t.target.localised_name, " near [gps="..pos.x..","..pos.y.."]"})
                        else
                            game.forces[t.force].print(c.." spidertrons have been unlinked from an entity near [gps="..pos.x..","..pos.y.."]")
                        end
                    end
                end
            end
        end
    end
end

local function validate_spiders(t, msg)
    local c=0
    if t then
        --for i, spider_ in pairs(t.spiders) do
        for i, spider in pairs(t.spiders) do
            local spider_entity = spider.spider_entity
            if not spider_entity or not spider_entity.valid then
                t.spiders[i] = nil
                c=c+1
            end
        end
        if c > 0 then
            local str = c .. " units were destroyed or mined since the last position command was sent"
            if type(msg) == "boolean" and msg == true then  -- This is for messaging when a unit is destroyed
                local pos = t.target.position
                game.forces[t.force].print(str..". Position is near [gps="..pos.x..","..pos.y.."]")
            else
                game.players[msg].print(str)   --this is causing crashes for one user. states that the player does not exist (why?) needs more research
            end
        end
        return true
    elseif type(msg) ~= "boolean" then
        global.spidercontrol_spidersquad[msg] = {spiders={}}
    end
end

local function spiderbot_designate(index, position, force)
    local d_
    local msg
    if force then
        d_ = global.spidercontrol_linked_squads[index]
        msg = true
    else
        d_ = global.spidercontrol_spidersquad[index]
        msg = index
    end

    if validate_spiders(d_, msg) then
        local spidersquad = d_.spiders
        local leader
        local follow
        if not force then
            leader = d_.spider_leader
            follow = game.players[index].is_shortcut_toggled("squad-spidertron-follow")
        end
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

local function initialize()
    if global.spidercontrol_spidersquad == nil then
        game.print("Create tables for spidertron control mod")
        global.spidercontrol_linked_squads = {}
        global.spidercontrol_spidersquad = {}
        for _, player in pairs(game.players) do
            global.spidercontrol_spidersquad[player.index] = {spider_leader = nil, spiders={}}
        end
	end
end

local function squad_leader_state(index)
    local player = game.players[index]
    if player.vehicle and player.vehicle.type == "spider-vehicle" then
        local unit_no = player.vehicle.unit_number
        if validate_spiders(global.spidercontrol_spidersquad[index], index) then
            local d = global.spidercontrol_spidersquad[index].spiders
            if d then
                for i, spider in pairs(d) do
                    -- game.print(spider.spider_entity.unit_number)
                    if spider.spider_entity.unit_number == unit_no then
                        global.spidercontrol_spidersquad[index].spider_leader = i
                        break
                    end
                end
            end
        end
    elseif player.vehicle == nil and global.spidercontrol_spidersquad[index] ~= nil then -- Why is it possible for this to be nil?
        global.spidercontrol_spidersquad[index].spider_leader = nil
    end
end

script.on_init(initialize)
script.on_configuration_changed(initialize)
--commands.add_command("spiderbot_initialize_variables", "debug: ensure that all global tables are not nil (should not happen in a normal game)", initialize)

script.on_event(defines.events.on_player_alt_selected_area, spiderbot_select)
script.on_event(defines.events.on_player_selected_area, spiderbot_select)

script.on_event(defines.events.on_player_used_spider_remote, function(event)
    local index = event.player_index
    local player = game.players[index]
    local cursor_stack = player.cursor_stack
    if cursor_stack then    -- how can a player use a remote without a cursor_stack though???
        if cursor_stack.valid_for_read and event.success then
            local cname = cursor_stack.name
            if cname == "squad-spidertron-remote" then
                player.set_shortcut_toggled("squad-spidertron-follow", false)
                spiderbot_designate(index, event.position)
            elseif cname == "spidertron-remote" then -- WARNING: We're only overriding for the player's spidertron if it's the vanilla spidertron remote. Does not cover modded remotes!
                -- Alter dy and dx
                local unit_no = event.vehicle.unit_number
                local d_ = global.spidercontrol_spidersquad[index]  -- Note : Decided against doing checks on a linked squad because it would involve checking that table which can be massively large (larger than player table)
                if validate_spiders(d_, index) then
                    local spidersquad = d_.spiders
                    local leader = d_.spider_leader

                 -- HELLO: if you are reading this and have an idea how to optimize it pls let me know (Not really critical as it's not in the tick loop, but could be problematic for very large squads )
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
            elseif cname == "squad-spidertron-link-tool" then
                if player.selected and player.selected.valid then
                    local selected = player.selected
                    local pos = selected.position
                    player.print({"", "Linked ".. #global.spidercontrol_spidersquad[index].spiders .. " spiders to ", selected.localised_name, " near [gps=" .. pos.x .. "," .. pos.y .. "]"})
                    global.spidercontrol_linked_squads[#global.spidercontrol_linked_squads+1] = {
                        force=player.force.index,
                        target=selected, 
                        spiders=util.table.deepcopy(global.spidercontrol_spidersquad[index].spiders)
                    }
                    global.spidercontrol_spidersquad[index] = {spider_leader = nil, spiders = {}} -- We're taking away player control of this squad!
                    -- Probably should print the squad ID, the target entity id and other information
                else
                    local vehicle = event.vehicle
                    vehicle.autopilot_destination = vehicle.position
                end
            end
        end
    end
end)

script.on_event(defines.events.on_player_driving_changed_state, function (event)
    squad_leader_state(event.player_index)
end)

script.on_event(defines.events.on_player_died, function(event)
    squad_leader_state(event.player_index)
end)

script.on_event(defines.events.on_lua_shortcut, function (event)
    local name = event.prototype_name
    if name == "squad-spidertron-follow" then
        local index = event.player_index
        squad_leader_state(index)
        spiderbot_follow(game.players[index])
    elseif name == "squad-spidertron-link-tool" then
        give_link_tool(event.player_index)
    end
end)

script.on_event(defines.events.on_player_created, function (event)
    global.spidercontrol_spidersquad[event.player_index] = {spider_leader = nil, spiders = {}}
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
        local name = cursor_stack.name
        if name == "squad-spidertron-remote" then
            give_tool(player, {name="squad-spidertron-remote-sel",count=1})
        elseif name == "squad-spidertron-remote-sel" then
            local e = global.spidercontrol_spidersquad[event.player_index]
            if e.spiders[1] and e.spiders[1].spider_entity.valid and give_tool(player, {name="squad-spidertron-remote",count=1}) then
                player.cursor_stack.connected_entity=e.spiders[1].spider_entity
            end
        -- -- Link pair
        elseif name == "squad-spidertron-link-tool" then
            give_tool(player, {name="squad-spidertron-unlink-tool",count=1})
        elseif name == "squad-spidertron-unlink-tool" then
            give_link_tool(event.player_index)
        end
    end
end)

script.on_event("squad-spidertron-link-tool", function(event)
    give_link_tool(event.player_index)
end)



--     -- - This stuff handles the link tool
-- script.on_event(defines.events.on_put_item, function(event)
--     local player = game.players[event.player_index]
--     local cursor_stack = player.cursor_stack
--     if cursor_stack and cursor_stack.valid_for_read then
--         if cursor_stack.name == "spidertron-link-tool" then

--             game.print("HELLO")
--         end
--     end
-- end)

-- script.on_event(defines.events.on_built_entity, function(event)
--     if event.created_entity.name == "spidertron-link-tool" then
--         event.created_entity.destroy()
--         -- give_tool(player, {name="spidertron-link-tool",count=1}) -- Not using because this can cause UPS lag if someone click-drags it within placement range!
--         game.print("HELLO")
--     end
-- end)


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
            local chk = global.spidercontrol_spidersquad[index]
            if chk and chk.spiders and #chk.spiders > 0 then
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
    if #global.spidercontrol_linked_squads > 0 then -- Might put this on another update_interval loop so the lag can be adjusted accordingly. Use the old modulo trick for that.
        for i,t in pairs(global.spidercontrol_linked_squads) do
            -- local t = global.spidercontrol_linked_squads[i]
            if t.spiders then
                if t.target.valid then
                    if #t.spiders > 0 then
                        spiderbot_designate(i, t.target.position, true)
                    else
                        local pos = t.target.position
                        game.forces[t.force].print({"", "Spidertron squad has been destroyed or unlinked from ", t.target.localised_name, " near [gps="..pos.x..","..pos.y.."]"})    -- using force comms because this could be the death of a spidertron, not only removal
                        table.remove(global.spidercontrol_linked_squads,i)
                    end
                else
                    local pos = t.spiders[1].spider_entity.position
                    game.forces[t.force].print("Target entity of spidertron squad has been destroyed or removed near [gps="..pos.x..","..pos.y.."]")
                    table.remove(global.spidercontrol_linked_squads,i)
                end
            end
        end
    end
end)