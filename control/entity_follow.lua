--[[ Copyright (c) 2020 npc_strider
 * For direct use of code or graphics, credit is appreciated. See LICENSE.txt for more information.
 * This mod may contain modified code sourced from base/core Factorio
 * 
 * control/entity_follow.lua
 * Runs periodically to designate commands for each linked squad to move to the target entity's position.
--]]

require("control.2dvec")

function UpdateFollowEntity()
    local links = global.spidercontrol_linked_s
    for i = 1, #links do
        if (#links[i].s > 0) then
            GotoEntity(i)
        end
    end
end