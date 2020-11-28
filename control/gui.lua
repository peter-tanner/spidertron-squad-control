--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control/gui.lua
 * I fucking hate gui code!
--]]

local mod_gui = require("mod-gui")
local function get_frame_flow_(player, direction)
    local gui = player.gui[direction] -- Left in mod-gui implementation (hardcoded.)
    local frame_flow = gui.mod_gui_frame_flow
    if not frame_flow then
        frame_flow = gui.add{type = "flow", name = "mod_gui_frame_flow", direction = "horizontal", style = "mod_gui_spacing_horizontal_flow"}
    end
    return frame_flow
end -- Adopted from 'mod-gui'


local function getOrigin(s)
    for i = 1, #s do
        local spider = s[i].spider
        if (spider.valid) then
            return util.positiontostr(IJSub(spider.position, s[i].delta))
        end
    end
    return "_invalid_" -- This should never occur
end

local function destroyRenameGui(frame_flow)
    if (frame_flow["squad-spidertron-list-frame"]) then
        return frame_flow["squad-spidertron-list-frame"].destroy()
    end
end

local function renameGui(num, frame_flow, index)
    local frame = frame_flow.add({
        type = "frame",
        name = "squad-spidertron-list-frame",
        direction = "vertical",
        caption = {"gui-map-editor-force-data-editor.edit-modifier-category", {"gui-mod-info.name"}},
        style = mod_gui.frame_style
    })

    local inner = frame.add{type = "frame", name = "inner", style = "inside_deep_frame"}
    inner.add({type = "textfield", name = "textfield", text = global.spidercontrol_player_s[index].inactive[num].name})
    inner.add({type = "sprite-button", name = "rename-accept-"..num, sprite = "utility/check_mark_white", style = "tool_button_green"})
end

local function guiTable(parent, player)
    local table = parent.add({
        type = "table",
        name = "table",
        column_count = 7,
        style = "removed_content_table"
    })
    for i = 2, 7 do
        table.style.column_alignments[i] = "center"
    end

    local t = global.spidercontrol_player_s[player.index].active
    table.add({type = "label", caption = {"gui-mod-info.name"}})
    table.add({type = "label", caption = {"gui-map-editor-script-editor.current-positions"}})
    table.add({type = "label", caption = "ID"})
    table.add({type = "label", caption = "#"})
    table.add({type = "label", caption = {"gui.save"}})
    table.add({type = "empty-widget"})
    table.add({type = "label", caption = {"gui-mod-info.delete"}})
    
    table.add({type = "label", caption = "ACTIVE"})
    table.add({type = "label", caption = getOrigin(t)})
    table.add({type = "label", caption = "ACTIVE"})
    table.add({type = "label", caption = #t})
    table.add({type = "sprite-button", name = "save-active-to-list", sprite = "utility/reassign", style = "tool_button_green"})
    table.add({type = "empty-widget"})
    table.add({type = "sprite-button", name = "delete-active", sprite = "utility/trash", style = "tool_button_red"})

    -- local frame = game.player.gui.top.add({type = "frame", style = "outer_frame"})
    -- local frame = frame.add({type = "frame", caption = "Change active squad", style = "inner_frame_in_outer_frame"})
    -- local table = frame.add({type="table", column_count = 3, style = "removed_content_table"})

    -- Headers
    table.add({type = "label", caption = {"gui-mod-info.name"}})
    table.add({type = "label", caption = "Saved Position"})
    table.add({type = "label", caption = "ID"})
    table.add({type = "label", caption = "#"})
    table.add({type = "label", caption = {"gui.load"}})
    table.add({type = "label", caption = {"gui-map-editor-force-data-editor.edit-modifier-category", {"gui-mod-info.name"}}})
    table.add({type = "label", caption = {"gui-mod-info.delete"}})

    local t = global.spidercontrol_player_s[player.index].inactive
    for i = 1, #t do
        table.add({type = "label", caption = t[i].name})
        table.add({type = "label", caption = t[i].position})
        table.add({type = "label", caption = i})
        table.add({type = "label", caption = #t[i].s})
        table.add({type = "sprite-button", name = "make-active-"..i, sprite = "utility/upgrade_blueprint", style = "tool_button_green"})
        table.add({type = "sprite-button", name = "rename-inactive-"..i, sprite = "utility/rename_icon_small_white", style = "tool_button_blue"})
        table.add({type = "sprite-button", name = "delete-inactive-"..i, sprite = "utility/trash", style = "tool_button_red"})
    end
end

local function gui(player)
    local frame_flow = mod_gui.get_frame_flow(player)
    frame_flow.style.left_padding = 4
    frame_flow.style.top_padding = 4

    local frame = frame_flow.add({
        type = "frame",
        name = "squad-spidertron-list-frame",
        direction = "vertical",
        caption = {"", {"gui.save"}, " ", {"and"}, " ", {"gui.load"}},
        style = mod_gui.frame_style
    })

    local inner = frame.add{type = "frame", name = "inner", style = "inside_deep_frame"}
    local scroll = inner.add{type = "scroll-pane", name = "scroll", direction = "vertical"}
    guiTable(scroll, player)
end

function UpdateGuiList(player)
    local gui_frame = mod_gui.get_frame_flow(player)
    if (gui_frame["squad-spidertron-list-frame"]) then
        local parent = gui_frame["squad-spidertron-list-frame"].inner.scroll
        parent.table.destroy()
        guiTable(parent, player)
    end
end

function ToggleGuiList(index)
    local player = game.players[index]
    local gui_frame = mod_gui.get_frame_flow(player)
    if (gui_frame["squad-spidertron-list-frame"]) then
        gui_frame["squad-spidertron-list-frame"].destroy()
    else
        gui(player)
    end
end


commands.add_command("ssc_gui", "Spidertron squad control configured squads gui toggle", function(cmd)
    ToggleGuiList(cmd.player_index)
end)

script.on_event(defines.events.on_gui_click, function(event)
    local gui = event.element
    local index = event.player_index
    local player = game.players[index]
    local limit = settings.global["spidertron-max-squads"].value
    if not (player and player.valid and gui and gui.valid) then
        return
    end

    local name = gui.name
    if (name == "save-active-to-list") then
        local s = global.spidercontrol_player_s[index]
        if (#s.active > 0) then
            if (#s.inactive < limit) then
                global.spidercontrol_player_s[index].inactive[#s.inactive+1] = {
                    name = game.tick,
                    position = getOrigin(s.active),
                    s = table.deepcopy(s.active)
                }
                UpdateGuiList(player)
                destroyRenameGui(get_frame_flow_(player, "center"))
            else
                player.print("You have too many saved templates! Remove some before adding more. Maximum amount is "..limit)
            end
        end
    elseif (name == "delete-active") then
        global.spidercontrol_player_s[index].active = {}
        local cursor_stack = player.cursor_stack
        if (cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == "squad-spidertron-remote") then
            player.clear_cursor()
        end
        UpdateGuiList(player)
    else
        local num = tonumber(string.match(name, '[0-9]+'))
        if num == nil then
            return
        end
        if name == "make-active-"..num then -- string.match(name, 'make[-]active[-][0-9]+') then
            destroyRenameGui(get_frame_flow_(player, "center"))
            local s = global.spidercontrol_player_s[index].inactive[num].s
            local spiders = {}
            for i = 1, #s do
                spiders[#spiders+1] = s[i].spider
            end
            SpiderDeSelect(spiders, player.force.index)
            global.spidercontrol_player_s[index].active = s
            global.spidercontrol_player_s[index].inactive[num].position = getOrigin(global.spidercontrol_player_s[index].inactive[num].s)
            UpdateGuiList(player)
        elseif name == "delete-inactive-"..num then -- string.match(name, 'delete[-]inactive[-][0-9]+') then
            destroyRenameGui(get_frame_flow_(player, "center"))
            global.spidercontrol_player_s[index].inactive = Remove(global.spidercontrol_player_s[index].inactive, {num})
            UpdateGuiList(player)
        elseif name == "rename-inactive-"..num then -- string.match(name, 'rename[-]inactive[-][0-9]+') then
            local frame_flow = get_frame_flow_(player, "center")
            destroyRenameGui(frame_flow)
            UpdateGuiList(player)
            renameGui(num, frame_flow, index)
        elseif name == "rename-accept-"..num then
            local frame_flow = get_frame_flow_(player, "center")
            if (frame_flow["squad-spidertron-list-frame"]) then
                local str = frame_flow["squad-spidertron-list-frame"].inner.textfield.text
                if global.spidercontrol_player_s[index].inactive[num] then
                    global.spidercontrol_player_s[index].inactive[num].name = str
                    UpdateGuiList(player)
                end
                frame_flow["squad-spidertron-list-frame"].destroy()
            end
        end
    end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    local elem = event.element
    if string.match(elem.name, "inactive[-]name[-][0-9]+") then
        local num = tonumber(string.match(elem.name, '[0-9]+'))
        global.spidercontrol_player_s[event.player_index].inactive[num].name = event.text
    end
end)