
require("control.2dvec")

function UpdateFollowEntity()
    local links = global.spidercontrol_linked_s
    for i = 1, #links do
        if (#links[i].s > 0) then
            GotoEntity(i)
        end
    end
end