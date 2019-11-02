#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

proc _C4_cmd_help(@page=1) {
    @commands = array(
        '&5Help &f> &dShows all available commands',
        '&5Join &f> &dJoin a match',
        '&5Quit &f> &dForfeit the match',
        '&5Stats &f> &dView a player\'s stats'
    );
    if (has_permission('ch_staff')) {
        @commands = array_merge(@commands, array(
            '&5Reset &f> &dForcefully end the arena'
        ));
    }
    _page_vertical('Options', 'connect4 help', @commands, @page);
}

proc _C4_cmd_stats(@player) {
    if (@player == '') {
        _no_console('/connect4 stats <player>');
        @player = player();
    } else {
        @player = _autocomplete_player(@player);
    }
    _C4_printStats(@player);
}

proc _C4_cmd_reset() {
    _verify_staff();
    _C4_reset();
    msg(colorize('&cYou have forcefully ended the current round of &4Connect 4'));
}

proc _C4_cmd_join(@user=player()) {
    _no_console();
    if (pworld() != 'Event') {
        _error('You must be in the event world.');
    }

    if (_C4_isPlaying()) {
        _error('You have already joined!');
    }

    if (_C4_isEnabled(false)) {
        _error('This minigame already has two people playing!');
    }

    @pl1 = _import_get('cnct4.player1');
    @pl2 = _import_get('cnct4.player2');
    if (@pl1 == null) {
        @pl = 1;
        _C4_reset();
        _export_store("cnct4.player1", @user);
    } else {
        @pl = 2;
        _export_store("cnct4.player2", @user);
        tmsg(@pl1, colorize("&f@user has joined &cConnect 4 &fas &ePlayer 2"));
    }

    _C4_podiumTeleport(@pl);
    set_pmode(@user, 'SURVIVAL');
    tmsg(@user, colorize("&fYou have joined &cFour in a row &fas &5Player @pl"));
    tmsg(@user, colorize('&4Right click &con the slabs to place a piece.'));

    ## Needs to run after teleport
    if (@pl == 2) {
        _C4_enable();
    }
}

proc _C4_cmd_quit() {
    _no_console();
    if (_C4_isPlaying()) {

        @pl1 = _import_get('cnct4.player1');
        @pl2 = _import_get('cnct4.player2');

        try( if (@pl1 == player()) {
            tmsg(@pl2, colorize("&5@pl1 &fhas quit &cFour in a Row."));
            _C4_win(@pl2);
        } else {
            tmsg(@pl1, colorize("&e@pl2 &fhas quit &cFour in a Row."));
            _C4_win(@pl1);
        } );

        _C4_reset();
        die(colorize('&cYou have quit &4Four in a Row'));
    }
    _error('You are not playing!');
}

proc _C4_cmd_play(@column) {
    _no_console();
    _C4_isEnabled();

    ## Only allow the two people who have joined to play
    if (!_C4_isPlaying()) {
        _error('You are not currently playing!');
    }

    @pl = _C4_getPlayer();
    @lastPlayer = _C4_getLastPlayer();
    if (@lastPlayer == @pl) {
        _error('Please wait for your turn');
    }

    if (@pl == 1) {
        @block = 'PURPLE_TERRACOTTA';
    } else {
        @block = 'YELLOW_TERRACOTTA';
    }

    switch(@column) {
    case 'a':
        @column = 0;
    case 'b':
        @column = 1;
    case 'c':
        @column = 2;
    case 'd':
        @column = 3;
    case 'e':
        @column = 4;
    case 'f':
        @column = 5;
    case 'g':
        @column = 6;
    default:
        _error('Invalid column.');
    }

    @corner = _C4_corner();
    @cx = @corner['x'];
    @cy = @corner['y'];
    @cz = @corner['z'];

    ## Place piece in topmost, or error if column is full.
    for (@y = 0, @y <= 5, @y++) {
        @curblock = _C4_getBlock(@cx, @cy + @y, @cz + @column);
        if (@curblock == 'AIR') {

            _C4_setBlock(@cx, @cy + @y, @cz + @column, @block);
            _C4_setLastPlayer(@pl);
            break();
        }
        else if (@y == 5) {
            _error('This column is full.');
        }
    }

    ## If four in a row for @block.
    if (_check4row(@cx, @cy, @cz, @block)) {
        _C4_win(player());
    }
    else if (_C4_isStalemate()) {
        _C4_draw();
    }
}
