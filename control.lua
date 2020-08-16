--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control.lua
 * Spiderbot.
--]]

local function give_tool(player, stack)
    if player.clean_cursor() and player.cursor_stack.can_set_stack(stack) then
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
    for _, spider in pairs(spidersquad) do
        c=c+1
        local pos = spider.position
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
        for _, spider in pairs(spiders) do
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
        for i, spider_ in pairs(global.spidercontrol_spidersquad[index].spiders) do
            if not spider_.spider_entity.valid then
                global.spidercontrol_spidersquad[index].spiders[i] = nil
                c=c+1
            end
        end
        if c > 0 then
            game.players[index].print(c .. " units were destroyed or mined since the last position command was sent")
        end
        return true
    end
end

local function spiderbot_designate(index, position)
    if validate_spiders(index) then
        local spidersquad = global.spidercontrol_spidersquad[index].spiders
        for _, spider_ in pairs(spidersquad) do
            local spider = spider_.spider_entity
            local d = spider_.d
            spider.autopilot_destination = {position.x+d[1], position.y+d[2]}
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

script.on_event(defines.events.on_player_created, function (event)
    global.spidercontrol_spidersquad[event.player_index] = {}
end)

script.on_event("squad-spidertron-remote", function(event)
    give_tool(game.players[event.player_index], {name="squad-spidertron-remote-sel",count=1})
end)

script.on_event("squad-spidertron-follow", function(event)
    spiderbot_follow(game.players[event.player_index])
end)

script.on_event("squad-spidertron-switch-modes", function(event)
    local player = game.players[event.player_index]
    local cursor_stack = player.cursor_stack
    if cursor_stack.valid_for_read then
        if cursor_stack.name == "squad-spidertron-remote" then
            give_tool(player, {name="squad-spidertron-remote-sel",count=1})
        elseif cursor_stack.name == "squad-spidertron-remote-sel" then
            local e = global.spidercontrol_spidersquad[event.player_index]
            if e.spiders and e.spiders[1].spider_entity.valid and give_tool(player, {name="squad-spidertron-remote",count=1}) then
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
        if player.is_shortcut_toggled("squad-spidertron-follow") then
            local index = player.index
            if global.spidercontrol_spidersquad[index].spiders[1] then
                local pos = player.position
                if player.walking_state.walking then
                    local dir = player.walking_state.direction
                    pos = pos_offset(pos,dir)
                end
                spiderbot_designate(index, pos)
                if player.vehicle then
                    local vehicle = player.vehicle
                    if vehicle.type == "spider-vehicle" then
                        vehicle.autopilot_destination = pos
                    end
                end
            end
        end
    end
end)