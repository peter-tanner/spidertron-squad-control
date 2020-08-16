--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * shortcuts.lua
 * Shortcuts and required items etc for the spider controls
--]]

require('util')

local shortcut_remote = {
	type = "shortcut",
	name = "squad-spidertron-remote",
	order = "a[squad-spidertron-remote]",
	action = "create-blueprint-item",
	localised_name = "Spidertron squad remote",
	associated_control_input = "squad-spidertron-remote",
	technology_to_unlock = "spidertron",
	item_to_create = "squad-spidertron-remote-sel",
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
shortcut_follow.localised_name = "Follow player"
shortcut_follow.associated_control_input = "squad-spidertron-follow"
shortcut_follow.style = "blue"
shortcut_follow.toggleable = true

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

data:extend(
{
	shortcut_remote,
	shortcut_follow,

	{
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
	},
	{
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
	},

	input_remote,
	input_follow,
	input_switch_modes
})
