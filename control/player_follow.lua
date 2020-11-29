--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control/player_follow.lua
 * Stuff here runs periodically to move the player's active squad to their position in follow mode. Also incorporate some comaptibility with spidertron waypoints.
--]]

local function spidertronWaypointsOverride(s)
    if SPIDERTRON_WAYPOINTS then
        for i = 1, #s do
            if (s[i] and s[i].spider) then
                remote.call("SpidertronWaypoints", "clear_waypoints", s[i].spider.unit_number)
            end
        end
    end
end

function SpiderbotFollow(player)
	if player.character then
		if player.is_shortcut_toggled("squad-spidertron-follow") then
            player.set_shortcut_toggled("squad-spidertron-follow", false)
            local index = player.index
            GotoPlayer(index, player.position)
            spidertronWaypointsOverride(global.spidercontrol_player_s[index].active)
        else
            if SPIDERTRON_WAYPOINTS and player.is_shortcut_toggled("spidertron-remote-patrol") then
                return
            end
            player.set_shortcut_toggled("squad-spidertron-follow", true)
            global.spidercontrol_player_s[player.index].p_pos = nil
		end
	else
		player.print({"", "[img=utility/danger_icon] ", {"error.error-message-box-title"}, ": ", {"player-doesnt-exist", {"gui.character"}}, " (", {"controller.god"}, "): ", {"gui-mod-info.status-disabled"}})
	end
end



local mov_offset = settings.global["spidertron-follow-prediction-distance"].value --This is so the player stays within the spider squad when moving

function UpdateFollow() 
    for _, player in pairs(game.players) do
        if (player.controller_type ~= 0 and player.is_shortcut_toggled("squad-spidertron-follow")) then -- 0 => defines.character.ghost (DEAD)
            local index = player.index
            local active = global.spidercontrol_player_s[index].active
            if (active and #active > 0) then
                local p_pos = global.spidercontrol_player_s[index].p_pos
                local pos = player.position
                if ( p_pos == nil or p_pos.x ~= pos.x or p_pos.y ~= pos.y ) then
    
                    local vehicle = player.vehicle
                    if (vehicle and vehicle.type == "spider-vehicle") then
                        local un = vehicle.unit_number
                        for i = 1, #active do
                            if (active[i].spider.unit_number == un) then
                                pos = IJSub(vehicle.position, active[i].delta)
                                break
                            end
                        end
                    end
    
                    if player.walking_state.walking then
                        local dir = player.walking_state.direction
                        pos = IJAhead(pos, dir, mov_offset)
                    end
                    GotoPlayer(index, pos)
                    spidertronWaypointsOverride(global.spidercontrol_player_s[index].active)
                    global.spidercontrol_player_s[index].p_pos = player.position
                end
            end
        end
    end
end
