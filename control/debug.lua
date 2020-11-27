
commands.add_command(
    "dvars",
    "debug: dump spider control vars", 
    function (cmd)    
        -- game.print(serpent.block(global.spidercontrol_player_s[cmd.player_index]))
        game.print(serpent.block(global.spidercontrol_linked_s))
    end
)
