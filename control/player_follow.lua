
local function spidertronWaypointsOverride(s)
    if SPIDERTRON_WAYPOINTS then
        for i = 1, #s do
            remote.call("SpidertronWaypoints", "clear_waypoints", s[i].spider.unit_number)
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
            player.set_shortcut_toggled("squad-spidertron-follow", true)
            global.spidercontrol_player_s[player.index].p_pos = nil
		end
	else
		player.print({"", {"error.error-message-box-title"}, ": ", {"player-doesnt-exist", {"gui.character"}}, " (", {"controller.god"}, "): ", {"gui-mod-info.status-disabled"}})
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
    
                    -- player.print("running" .. game.tick)
                    if player.walking_state.walking then
                        local dir = player.walking_state.direction
                        pos = IJAhead(pos, dir, mov_offset)
                    end
                    GotoPlayer(index, pos)
                    spidertronWaypointsOverride(active)
                    global.spidercontrol_player_s[index].p_pos = player.position
                end
            end
        end
    end
end
