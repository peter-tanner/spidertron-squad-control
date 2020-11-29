--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control/functions.lua
 * General/commonly used/important functions.
--]]

function AlertPlayer(player, str)
    local enabled = settings.get_player_settings(player)["spidertron-alerts"].value
    if (enabled) then
        player.print(str)
        return true
    else
        return false
    end
end

function SpidertronWaypointsCompatibility()
    -- Compatability for Spidertron Waypoints
    if remote.interfaces["SpidertronWaypoints"] then
        SPIDERTRON_WAYPOINTS = true
        -- local event_ids = remote.call("SpidertronWaypoints", "get_events")
        -- local on_spidertron_given_new_destination = event_ids.on_spidertron_given_new_destination
        -- script.on_event(on_spidertron_given_new_destination, function(event)
        --     game.print("New destination")
        --     Goto(global.spidercontrol_player_s[event.player_index].active, event.position)
        -- end)
    end
end

function GiveStack(player, stack)
    if player.clear_cursor() and player.cursor_stack and player.cursor_stack.can_set_stack(stack) then
        if player.get_main_inventory() then
            local inv = player.get_main_inventory()
            inv.remove("squad-spidertron-remote-sel")
            inv.remove("squad-spidertron-remote")
        end
        player.cursor_stack.set_stack(stack)
        return true
    end
end

function Remove(table, indices)
    local n = #table
    for i = 1, #indices do
        table[indices[i]] = nil
    end
    
    local tmp = {}
    for i = 1, n do
        if (table[i] ~= nil) then
            tmp[#tmp+1] = table[i]
        end
    end

    return tmp
end

function Goto(spiders, center)
    local invalid = {}
    for i = 1, #spiders do
        if spiders[i] then
            local spider = spiders[i].spider
            local d = spiders[i].delta
            if spider.valid then
                spider.autopilot_destination = IJAdd(center, d)
            else
                invalid[#invalid+1] = i
            end
        end
    end
    return Remove(spiders, invalid) -- We return an updated spider list (Remove any invalid spiders)
end

local function drawSprite(surface, target, scale, force, tint)
    return rendering.draw_sprite({
        sprite="item/squad-spidertron-link-tool",
        target = target,
        surface = (target.surface or surface),
        x_scale = scale,
        y_scale = scale,
        only_in_alt_mode = true,
        forces = {force},
        tint = (tint or {r=1,g=1,b=1})
    })
end
-- rendering.draw_sprite({sprite="item/squad-spidertron-link-tool", target = game.player.selected, surface = game.player.surface, only_in_alt_mode = true, forces = {game.player.force}, tint = {r=1,g=1,b=1}})
local function resetSprites(indices)
    if indices then
        for i = 1, #indices do
            rendering.destroy(indices[i])
        end
    end
end
-- Original GotoPlayer function before waypoints compat.
function GotoPlayerUpdate(index, position)
    local active = global.spidercontrol_player_s[index].active
    local active_n = #active
    local active_updated = Goto(active, position)
    global.spidercontrol_player_s[index].active = active_updated

    if (active_n > #active_updated) then
        local str = "[img=utility/warning_icon] " .. (active_n - #active_updated) .. " units were destroyed or mined"
        AlertPlayer(game.players[index], str)
    end
end

local function GotoPlayerSW(index, position)
    local active = global.spidercontrol_player_s[index].active
    local player = game.players[index]
    local linear = player.is_shortcut_toggled("spidertron-remote-waypoint")
    local cyclic = player.is_shortcut_toggled("spidertron-remote-patrol")
    if (cyclic) then
        if player.is_shortcut_toggled("squad-spidertron-follow") then
            return
        end
        active[1].spider.autopilot_destination = nil
        local patrol = global.spidercontrol_spidertronwaypoints_patrol[index]
        if (patrol) then
            local start = rendering.get_target(patrol[1]).position
            if (util.distance(position, start) < 5) then
                for j = 1, #active do
                    if (active[j] and active[j].spider.valid) then
                        local waypoints = {}
                        for i = 1, #patrol do
                            local position = IJAdd(
                                rendering.get_target(patrol[i]).position,
                                active[j].delta
                            )
                            waypoints[#waypoints+1] = {position = position}
                        end
                        
                        remote.call("SpidertronWaypoints", "assign_patrol", active[j].spider, waypoints)
                    end
                end
                resetSprites(patrol)
                global.spidercontrol_player_s[index].active = {}
                UpdateGuiList(player)
                GiveStack(player, {name="squad-spidertron-remote-sel",count=1})
                player.set_shortcut_toggled("spidertron-remote-patrol", false)
                patrol = nil
            else
                patrol[#patrol+1] = drawSprite(player.surface, position, 1.5, player.force, {r=1.0,g=0.0,b=1.0})
            end
        else
            patrol = {drawSprite(player.surface, position, 1.5, player.force, {r=1.0,g=1.0,b=1.0})}
        end
        global.spidercontrol_spidertronwaypoints_patrol[index] = patrol
    elseif (linear) then
        local active_updated = Goto(active, position)
        for i = 1, #active_updated do
            local position = IJAdd(position, active_updated[i].delta)
            local waypoint = {{position = position}}
            remote.call("SpidertronWaypoints", "assign_waypoints", active_updated[i].spider, waypoint)
        end

        resetSprites(global.spidercontrol_spidertronwaypoints_patrol[index])
        global.spidercontrol_spidertronwaypoints_patrol[index] = nil
    else
        GotoPlayerUpdate(index, position)
        
        resetSprites(global.spidercontrol_spidertronwaypoints_patrol[index])
        global.spidercontrol_spidertronwaypoints_patrol[index] = nil
    end
end

function GotoPlayer(index, position)
    if SPIDERTRON_WAYPOINTS then
        GotoPlayerSW(index, position)
    else
        GotoPlayerUpdate(index, position)
    end
end

function GotoEntity(index)
    local t = global.spidercontrol_linked_s[index]
    local entity = t.target
    local active = t.s
    if entity.valid then
        local active_n = #active
        local pos = entity.position

        local active_updated = Goto(active, pos)

        global.spidercontrol_linked_s[index].s = active_updated
        
        if (active_n > #active_updated) then
            local str = {"", "[img=utility/warning_icon] " .. (active_n - #active_updated) .. " units were destroyed or mined near [gps="..pos.x..","..pos.y.."], linked to ", entity.localised_name}
            game.forces[t.force].print(str)
        end

        if (#active_updated == 0) then
            local str = {"", "[img=utility/warning_icon] Spidertron squad has been destroyed or unlinked from ", entity.localised_name, " near [gps="..pos.x..","..pos.y.."]"}
            game.forces[t.force].print(str)    -- using force comms because this could be the death of a spidertron, not only removal
        end
    else
        local e = false
        for i = 1, #active do
            if (active[i].spider.valid) then
                e = active[i].spider
            end
        end
        if (e) then
            local pos = e.position
            game.forces[t.force].print("[img=utility/warning_icon] Target entity of spidertron squad has been destroyed or removed near [gps="..pos.x..","..pos.y.."]")
        else
            game.forces[t.force].print("[img=utility/warning_icon] Target entity of spidertron squad has been destroyed or removed")
        end

        global.spidercontrol_linked_s = Remove(global.spidercontrol_linked_s, {index})
    end
end

function FirstValid(entities)
    for i = 1, #entities do
        if entities[i] and entities[i].valid then
            return entities[i]
        end
    end
    return false
end

-- local function squad_center(spidersquad)
--     local xbar=0
--     local ybar=0
--     local c=0
--     for i=1, #spidersquad do
--         c=c+1
--         local pos = spidersquad[i].position
--         xbar=xbar+pos.x
--         ybar=ybar+pos.y
--     end
--     return {xbar/c,ybar/c}
-- end

function Mean(list)
    local sum = 0
    for i=1, #list do
        sum=sum+list[i]
    end
    return sum/#list
end