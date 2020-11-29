--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control/player_select.lua
 * Handles selection tools for link and squad select.
--]]

require("control.functions")
require("control.2dvec")

local function messageSpiders(target, s, force, n)
    if target.valid then
        local pos = target.position
        game.forces[force].print({"", "[img=utility/warning_icon] "..n.." spidertrons have been unlinked from a ", target.localised_name, " near [gps="..pos.x..","..pos.y.."]"})
    else
        local e = FirstValid(s)
        if e then
            local pos = e.position
            game.forces[force].print("[img=utility/warning_icon] "..n.." spidertrons have been unlinked from an entity near [gps="..pos.x..","..pos.y.."]")
        else
            game.forces[force].print("[img=utility/warning_icon] "..n.." spidertrons have been unlinked from an entity")
        end
    end
end
local function messageS(target, s, force)
    if target.valid then
        local pos = target.position
        game.forces[force].print({"", "[img=utility/warning_icon] Spidertron squad has been unlinked from ", target.localised_name, " near [gps="..pos.x..","..pos.y.."]"})    -- using force comms because this could be the death of a spidertron, not only removal
    else
        local e = FirstValid(s)
        if e then
            local pos = e.position
            game.forces[force].print({"", "[img=utility/warning_icon] Spidertron squad has been unlinked from a target near [gps="..pos.x..","..pos.y.."]"})
        else
            game.forces[force].print({"", "[img=utility/warning_icon] Spidertron squad has been unlinked from a target"})
        end
    end
end


local function unitNumbers(entities)
    local ids = {}
    for i = 1, #entities do
        if entities[i].valid then
            ids[#ids+1] = entities[i].unit_number
        end
    end
    return ids
end

function SpiderDeSelect(spiders, force)
    local ids = unitNumbers(spiders)
    local t = global.spidercontrol_linked_s
    local rem_t = {}    --This part is really bad - I think it's O(N^3) worst case?
    for i = 1, #t do
        if (t[i].force == force and #ids > 0) then
            local s = t[i].s
            local rem_s = {}
            for j = 1, #s do
                local rem_id = {}
                for k = 1, #ids do
                    if (ids[k] == s[j].spider.unit_number) then
                        s[j].spider.autopilot_destination = nil
                        rem_id[#rem_id+1] = k
                        rem_s[#rem_s+1] = j
                    end
                end
                if (#rem_id > 0) then
                    ids = Remove(ids, rem_id)
                    if (#ids == 0) then
                        break
                    end
                end
            end
            if (#rem_s > 0) then
                local force = t[i].force
                local target = t[i].target
                for x = 1, #rem_s do
                    rendering.destroy(s[rem_s[x]].sprite)
                end
                s = Remove(s, rem_s)
                messageSpiders(target, s, force, #rem_s)
                if (#s == 0) then
                    rem_t[#rem_t+1] = i
                    messageS(target, s, force)
                else
                    global.spidercontrol_linked_s[i].s = s
                end
            end
            if (#ids == 0) then
                break
            end
        end
    end
    if (#rem_t > 0) then -- Need to remove sprite
        for x = 1, #rem_t do
            rendering.destroy(t[rem_t[x]].sprite)
        end
        global.spidercontrol_linked_s = Remove(global.spidercontrol_linked_s, rem_t)
    end
end


local function spiderSelect(spiders, index)

    local player = game.players[index]
    local mean = IJMeanEntity(spiders)
    global.spidercontrol_player_s[index].active = {}

    SpiderDeSelect(spiders, player.force.index) -- TO prevent double-linking (linking the same spider to 2 or more entities)
    if SPIDERTRON_WAYPOINTS then
        for i = 1, #spiders do
            remote.call("SpidertronWaypoints", "clear_waypoints", spiders[i].unit_number)
            spiders[i].autopilot_destination = nil
        end
    end
    -- spiderDeSelectPlayers(spiders, player.force.index) -- Y'know what, not sure if i can be arsed to deselect player squads...

    for i=1, #spiders do
        table.insert(global.spidercontrol_player_s[index].active, {
            spider = spiders[i],
            delta = IJDelta(mean, spiders[i].position)
        })
    end

    if GiveStack(player, {name="squad-spidertron-remote",count=1}) then
        player.cursor_stack.connected_entity=spiders[1]
    end
end


local function areaSelection(event)
    local index = event.player_index
    local spiders = event.entities -- We're only selecting spiders from our force (due to force filter)
    local item = event.item
    if #spiders > 0 then
        if item == "squad-spidertron-remote-sel" then
            spiderSelect(spiders, index)
            UpdateGuiList(game.players[index])
        elseif item == "squad-spidertron-unlink-tool" then
            SpiderDeSelect(spiders, spiders[1].force.index)
            UpdateGuiList(game.players[index])
        end
    end
end

script.on_event(defines.events.on_player_alt_selected_area, areaSelection)
script.on_event(defines.events.on_player_selected_area, areaSelection)