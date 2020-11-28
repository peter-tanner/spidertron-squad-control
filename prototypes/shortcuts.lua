--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * shortcuts.lua
 * Shortcuts and required items etc for the spider controls
--]]

require('util')

------------------------------------------------------------------------
-- ITEMS
------------------------------------------------------------------------

local item_remote_sel = {
	type = "selection-tool",
	name = "squad-spidertron-remote-sel",
	icon = "__base__/graphics/icons/spidertron-remote.png",
	-- icon_color_indicator_mask = "__base__/graphics/icons/spidertron-remote-mask.png",
	icon_size = 64, icon_mipmaps = 4,
	subgroup = "other",
	flags = {"hidden", "not-stackable", "only-in-cursor"},
	order = "b[personal-transport]-c[spidertron]-b[squad-remote]",
	stack_size = 1,
	stackable = false,
	selection_color = { r = 1, g = 0, b = 0 },
	alt_selection_color = { r = 1, g = 0, b = 0 },
	selection_mode = {"same-force", "entity-with-health"},
	alt_selection_mode = {"same-force", "entity-with-health"},
	selection_cursor_box_type = "copy",
	alt_selection_cursor_box_type = "copy",
	entity_type_filters = {"spider-vehicle"},
	tile_filters = {"lab-dark-1"},
	entity_filter_mode = "whitelist",
	tile_filter_mode = "whitelist",
	alt_entity_type_filters = {"spider-vehicle"},
	alt_tile_filters = {"lab-dark-1"},
	alt_entity_filter_mode = "whitelist",
	alt_tile_filter_mode = "whitelist",
	always_include_tiles = false
}

local item_unlink_sel = util.table.deepcopy(item_remote_sel)
item_unlink_sel.name = "squad-spidertron-unlink-tool"
item_unlink_sel.icon = "__Spider_Control__/graphics/icons/spidertron-unlink-tool.png"

local item_remote = {
	type = "spidertron-remote",
	name = "squad-spidertron-remote",
	localised_name = "Spidertron squad remote",
	icon = "__base__/graphics/icons/spidertron-remote.png",
	icon_color_indicator_mask = "__base__/graphics/icons/spidertron-remote-mask.png",
	icon_size = 64, icon_mipmaps = 4,
	subgroup = "other",
	flags = {"hidden", "not-stackable", "only-in-cursor"},
	order = "b[personal-transport]-c[spidertron]-b[remote]",
	stack_size = 1
}

local item_link = util.table.deepcopy(item_remote)
item_link.name = "squad-spidertron-link-tool"
item_link.localised_name = "Spidertron link tool"
item_link.icon = "__Spider_Control__/graphics/icons/spidertron-link-tool.png"
item_link.icon_color_indicator_mask = "__Spider_Control__/graphics/icons/spidertron-link-tool-mask.png"

------------------------------------------------------------------------
-- SHORTCUTS
------------------------------------------------------------------------

local shortcut_remote = {
	type = "shortcut",
	name = "squad-spidertron-remote",
	order = "a[squad-spidertron-remote]",
	action = "lua",
	localised_name = "Spidertron squad remote",
	associated_control_input = "squad-spidertron-remote",
	technology_to_unlock = "spidertron",
	style = "red",
	icon =
	{
		filename = "__base__/graphics/icons/spidertron.png",
		priority = "extra-high-no-scale",
		size = 64,
		scale = 1,
		flags = {"icon"}
	},
	-- small_icon =
	-- {
	-- 	filename = "__Shortcuts__/graphics/artillery-targeting-remote-x24.png",
	-- 	priority = "extra-high-no-scale",
	-- 	size = 24,
	-- 	scale = 1,
	-- 	flags = {"icon"}
	-- },
	-- disabled_small_icon =
	-- {
	-- 	filename = "__Shortcuts__/graphics/artillery-targeting-remote-x24-white.png",
	-- 	priority = "extra-high-no-scale",
	-- 	size = 24,
	-- 	scale = 1,
	-- 	flags = {"icon"}
	-- },
}

local shortcut_follow = util.table.deepcopy(shortcut_remote)
shortcut_follow.name = "squad-spidertron-follow"
shortcut_follow.action = "lua"
shortcut_follow.localised_name = "Spidertron follow player"
shortcut_follow.associated_control_input = "squad-spidertron-follow"
shortcut_follow.style = "blue"
shortcut_follow.toggleable = true

local shortcut_link = util.table.deepcopy(shortcut_remote)
shortcut_link.name = "squad-spidertron-link-tool"
shortcut_link.action = "lua"
shortcut_link.localised_name = "Link spidertrons to entity"
shortcut_link.associated_control_input = "squad-spidertron-link-tool"
shortcut_link.style = "green"

local shortcut_list = util.table.deepcopy(shortcut_remote)
shortcut_list.name = "squad-spidertron-list"
shortcut_list.action = "lua"
shortcut_list.localised_name = "Manage saved spidertrons"
shortcut_list.associated_control_input = "squad-spidertron-list"
shortcut_list.style = nil

------------------------------------------------------------------------
-- CUSTOM INPUT
------------------------------------------------------------------------

local input_remote = {
	type = "custom-input",
	name = "squad-spidertron-remote",
	localised_name = "Spidertron squad remote",
	key_sequence = "ALT + X",
	consuming = "none"
}

local input_follow = util.table.deepcopy(input_remote)
input_follow.name = "squad-spidertron-follow"
input_follow.localised_name = "Follow player"
input_follow.key_sequence = "ALT + C"

local input_switch_modes = util.table.deepcopy(input_remote)
input_switch_modes.name = "squad-spidertron-switch-modes"
input_switch_modes.localised_name = "Switch modes (between selecting and commanding)"
input_switch_modes.key_sequence = "mouse-button-2"

local input_link = util.table.deepcopy(input_remote)
input_link.name = "squad-spidertron-link-tool"
input_link.localised_name = "Link spidertron squad to entity"
input_link.key_sequence = "ALT + Z"

local input_list = util.table.deepcopy(input_remote)
input_list.name = "squad-spidertron-list"
input_list.localised_name = "Manage saved spidertrons"
input_list.key_sequence = "ALT + V"

------------------------------------------------------------------------
-- EXTEND
------------------------------------------------------------------------

data:extend(
{
	shortcut_remote,
	shortcut_follow,
	shortcut_link,
	shortcut_list,

	item_remote_sel,
	item_unlink_sel,

	{
		type = "simple-entity",
		name = "spidertron-link-tool",
		icon = "__base__/graphics/icons/ship-wreck/small-ship-wreck.png",
		icon_size = 32,
		flags = {"placeable-off-grid"},
		selectable_in_game = false,
		map_color = {r=0, g=0, b=0},
		order = "a[spidertron-link-tool]",
		max_health = 1,
		collision_box = {{0, 0}, {0, 0}},
		collision_mask = {"layer-13"},
		picture =
		{
			filename = "__core__/graphics/empty.png",
			width = 1,
			height= 1
		}
	},
	{
		type = "item",
		name = "spidertron-link-tool",
		icon = "__base__/graphics/technology/laser.png",
		icon_size = 128,
		flags = {"only-in-cursor", "hidden"},
		place_result = "spidertron-link-tool",
		subgroup = "capsule",
		order = "zz",
		stack_size = 1,
		stackable = false
	},
	
	item_remote,
	item_link,

	input_remote,
	input_follow,
	input_switch_modes,
	input_link,
	input_list
})
