#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

bind('player_teleport', null, null, @event) {
    @player1 = _import_get('cnct4.player1');
    @player2 = _import_get('cnct4.player2');

    if (player() == @player1 || player() == @player2) {
        cancel();
        _error('You must quit Connect 4 before being able to leave.');
    }
}

bind('player_quit', null, null, @event) {
    @player1 = _import_get('cnct4.player1');
    @player2 = _import_get('cnct4.player2');

    if (player() == @player1 || player() == @player2) {
        try( if( @player1 == player() ) {
            tmsg(@player2, colorize("&5@player1 &fhas quit &cConnect 4."));
            _C4_win(@player2);
        } else {
            tmsg(@player1, colorize("&e@player2 &fhas quit &cConnect 4."));
            _C4_win(@player1);
        } )
        _C4_reset();
    }
}
