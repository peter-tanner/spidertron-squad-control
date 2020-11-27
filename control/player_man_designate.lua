require("control.functions")

local function moveTo(player, index, position)
    game.players[index].set_shortcut_toggled("squad-spidertron-follow", false)
    GotoPlayer(index, position)
end

local function realign(s, vehicle, position, target)
    local unit_number = vehicle.unit_number
    for i = 1, #s do
        if (s[i].spider.unit_number == unit_number) then
            -- This commented-out targeting works relative to the mean of the group, not the target entity. It has its benefits but ultimately I preferred the target-based modification, so i've left this uncommented.
            -- if (s[i+1]) then -- Use another spidertron as a reference vector/position
            --     local origin = IJSub(s[i+1].spider.position, s[i+1].delta)
            --     s[i].delta = IJSub(position, origin)
            -- elseif (s[i-1]) then
            --     local origin = IJSub(s[i-1].spider.position, s[i-1].delta)
            --     s[i].delta = IJSub(position, origin)
            -- else
            --     -- spider list should never be a sparse list, so if nothing's adjacent it's a single spidertron
            --     s[i].delta = IJSub(position, vehicle.position) -- Not really good without a ref vector
            -- end
            s[i].delta = IJSub(position, target.position)
            return s
        end
    end
    return false
end

local function drawSprite(target, scale, force, tint, target_offset)
    return rendering.draw_sprite({
        sprite="item/squad-spidertron-link-tool",
        target = target,
        surface = target.surface,
        x_scale = scale,
        y_scale = scale,
        only_in_alt_mode = true,
        forces = {force},
        tint = (tint or {r=1,g=1,b=1}),
        target_offset = (target_offset or {x=0,y=0})
    })
end

local function link(index, vehicle)
    local player = game.players[index]
    local n = #global.spidercontrol_player_s[index].active
    if player.selected and player.selected.valid and n > 0 then
        local selected = player.selected
        local pos = selected.position
        local scale = 1.5
        local force = player.force
        player.print({"", "Linked ".. n .. " spiders to ", selected.localised_name, " near [gps=" .. pos.x .. "," .. pos.y .. "]"})
        local sprite = drawSprite(selected, scale, force)
        local s = util.table.deepcopy(global.spidercontrol_player_s[index].active)
        for i = 1, #s do
            s[i].sprite = drawSprite(s[i].spider, scale, force, {r=1,g=0,b=0}, {x=0,y=-0.3})
        end
        global.spidercontrol_linked_s[#global.spidercontrol_linked_s+1] = {
            force=player.force.index,
            target=selected,
            sprite=sprite,
            s=s
        }
        global.spidercontrol_player_s[index].active = {} -- We're taking away player control of this squad!
        -- Probably should print the squad ID, the target entity id and other information
        GiveStack(player, {name="squad-spidertron-unlink-tool",count=1})
    end
    vehicle.autopilot_destination = vehicle.position    -- Just to look better
end


script.on_event(defines.events.on_player_used_spider_remote, function(event)
    local index = event.player_index
    local player = game.players[index]
    local cursor_stack = player.cursor_stack
    if cursor_stack then    -- how can a player use a remote without a cursor_stack though???
        if cursor_stack.valid_for_read and event.success then
            local cname = cursor_stack.name
            if cname == "squad-spidertron-remote" then
                moveTo(player, index, event.position)
            elseif cname == "spidertron-remote" then -- WARNING: We're only overriding for the player's spidertron if it's the vanilla spidertron remote. Does not cover modded remotes!
                local vehicle = event.vehicle
                local position = event.position
                local s = realign(global.spidercontrol_player_s[index].active, vehicle, position, player)
                if s then
                    global.spidercontrol_player_s[index].active = s
                else
                    local t = global.spidercontrol_linked_s
                    for i = 1, #t do
                        if realign(t[i].s, vehicle, position, t[i].target) then
                            global.spidercontrol_linked_s[i].t = t
                        end
                    end
                end
            elseif cname == "squad-spidertron-link-tool" then
                link(index, event.vehicle)
            end
        end
    end
end)