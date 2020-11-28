
Initialize()

game.print("WARNING: Only player-links are being migrated - Spidertron entity-links are NOT being migrated! (As they were only implemented in the experimental 0.4.0 mod release)")

local player_squads = global.spidercontrol_spidersquad
if player_squads then
    for i, t in pairs(player_squads) do
        local newsquad = {}
        for j, s in pairs(t.spiders) do
            newsquad[#newsquad+1] = {
                spider = s.spider_entity,
                delta = {x=s.d[1],y=s.d[2]}
            }
        end
        global.spidercontrol_player_s[i].active = newsquad
    end
end