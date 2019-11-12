#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

bind('player_join', array(priority: 'highest'), null, @event) {

    try(@player = _censor(player()),
        @player = player()
       )

    if (_getserver() != 'Vanilla') {
        modify_event('join_message', _join_message(@player));
    }

    if (has_permission('ch_staff')) {
        if (has_permission('mcau.silentjoin')) {
            modify_event('join_message', '')
            broadcast( colorize("&bSilent Join: &3@player"), 'ch_janitor' )
        }
    }
}

bind('player_quit', array(priority: 'highest'), null, @event) {

    try(@player = _censor(player()),
        @player = player()
       )

    if (_getserver() != 'Vanilla') {
        modify_event('message', _quit_message(@player));
    }

    if (has_permission('ch_staff')) {
        if (has_permission('mcau.silentjoin')) {
            modify_event('message', '')
            broadcast( colorize("&bSilent Quit: &3@player"), 'ch_janitor' )
        }
    }
}

