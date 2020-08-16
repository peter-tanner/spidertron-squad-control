if global.spidercontrol_spidersquad ~= nil then
    for i,_ in pairs(global.spidercontrol_spidersquad) do
        global.spidercontrol_spidersquad[i] = {spiders={}}
    end
    game.print("Spider control 0.3.0 migration: Reset squads")
end