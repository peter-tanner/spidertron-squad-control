--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control/give_remote.lua
 * Gives the various remotes (link tool, unlink tool, squad remote, selection tool) to the player.
--]]

require("control.functions")

local function giveTwoTool(index, stack0, stack1)
    local d = global.spidercontrol_player_s[index].active
    if (#d > 0 and d[1].spider.valid) then
        local player = game.players[index]
        if GiveStack(player, stack0) then
            player.cursor_stack.connected_entity = d[1].spider
        end
    else
        GiveStack(game.players[index], stack1)
    end
end

function GiveLinkTool(index, settings)
    local player = game.players[index]
    local value = settings["spidertron-default-link-remote"].value
    if value == SETTING_LINK then
        GiveStack(player, {name = "squad-spidertron-link-tool", count = 1})
    elseif value == SETTING_UNLINK then
        GiveStack(player, {name = "squad-spidertron-unlink-tool", count = 1})
    else    --  value == AUTOMATIC
        giveTwoTool(index,
            {name="squad-spidertron-link-tool",count=1},
            {name="squad-spidertron-unlink-tool",count=1}
        )
    end
end

function GiveSquadTool(index, settings)
    local player = game.players[index]
    local value = settings["spidertron-default-squad-remote"].value
    if value == SETTING_REMOTE_SEL then
        GiveStack(player, {name = "squad-spidertron-remote-sel", count = 1})
    elseif value == SETTING_LINK then
        GiveStack(player, {name = "squad-spidertron-remote", count = 1})
    else    --  value == AUTOMATIC
        giveTwoTool(
            index,
            {name="squad-spidertron-remote",count=1},
            {name="squad-spidertron-remote-sel",count=1}
        )
    end
end


script.on_event("squad-spidertron-switch-modes", function(event)
    local player = game.players[event.player_index]
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read then
        local name = cursor_stack.name
        if name == "squad-spidertron-remote" then
            GiveStack(player, {name="squad-spidertron-remote-sel",count=1})
        elseif name == "squad-spidertron-remote-sel" then
            local e = global.spidercontrol_player_s[event.player_index].active
            if e[1] and e[1].spider.valid and GiveStack(player, {name="squad-spidertron-remote",count=1}) then
                player.cursor_stack.connected_entity = e[1].spider
            end
        -- -- Link pair
        elseif name == "squad-spidertron-link-tool" then
            GiveStack(player, {name="squad-spidertron-unlink-tool",count=1})
        elseif name == "squad-spidertron-unlink-tool" then
            GiveStack(player, {name = "squad-spidertron-link-tool", count = 1})
        end
    end
end)


-- script.on_event(defines.events.on_lua_shortcut, function (event)
--     local name = event.prototype_name
--     if name == "squad-spidertron-follow" then
--         local index = event.player_index
--         squad_leader_state(index)
--         spiderbot_follow(game.players[index])
--     elseif name == "squad-spidertron-link-tool" then
--         GiveStack(player, {name = "squad-spidertron-link-tool", count = 1})
--     end
-- end)

