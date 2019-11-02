#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

###          ###
### Settings ###
###          ###

## Setting for which was the board runs, either x or z.
proc _C4_getAxis() {
    return('z');
}

## The least-most corner of the board. Lowest possible x, y, and z coords where more negative is lower.
proc _C4_corner() {
    return(array('x':-1253, 'y':9, 'z':1461));
}

###
###
###

proc _C4_isEnabled(@die=true) {
    @enabled = _import_get('cnct4.enabled');
    if (@enabled != true) {
        if (@die) {
            _error('The Connect 4 arena is not enabled.');
        }
        return(false);
    }
    return(true);
}

proc _C4_isPlaying(@user=player()) {
    @pl1 = _import_get('cnct4.player1');
    @pl2 = _import_get('cnct4.player2');
    return(@pl1 == @user || @pl2 == @user);
}

proc _C4_getPlayer(@user=player()) {
    @pl1 = _import_get('cnct4.player1');
    @pl2 = _import_get('cnct4.player2');

    if (@pl1 == @user) {
        return(1);
    }
    else if (@pl2 == @user) {
        return(2);
    }
    else {
        _error('Specified player is not playing...');
    }
}

proc _C4_reset() {

    ## DO: Teleport players out
    _C4_clearvalues();

    _C4_podiumLight(1, false);
    _C4_podiumLight(2, false);

    @corner = _C4_corner();
    @cx = @corner['x'];
    @cy = @corner['y'];
    @cz = @corner['z'];

    ## Clear the board
    if (_C4_getAxis() == 'x') {
        for (@x = 0, @x < 7, @x++) {
            for (@y = 0, @y < 6, @y++) {
                _C4_setBlock(@cx + @x, @cy + @y, @cz, 'AIR');
            }
        }
    } else {
        for (@z = 0, @z < 7, @z++) {
            for (@y = 0, @y < 6, @y++) {
                _C4_setBlock(@cx, @cy + @y, @cz + @z, 'AIR');
            }
        }
    }
}

proc _C4_clearvalues() {
    _export_store('cnct4.enabled', false);
    _C4_setLastPlayer(null);
    _export_store('cnct4.player1', null);
    _export_store('cnct4.player2', null);
}

proc _C4_enable() {
    ## Turn on player 1's podium light and allow pieces to be played
    _C4_setLastPlayer(2);
    _export_store('cnct4.enabled', true);
}

proc _C4_getlastPlayer() {
    @pl = _import_get('cnct.lastPlayer');
    ## If null, 0, 2, etc... set to 2
    if (@pl != 1) { @pl = 2; }
    return(@pl);
}

proc _C4_setLastPlayer(@pl) {
    _export_store('cnct4.lastPlayer', @pl);
    ## Opposite player's move. Show neither if null
    _C4_podiumLight(1, @pl == 2);
    _C4_podiumLight(2, @pl == 1);
}

###        ###
### Podium ###
###        ###

proc _C4_podium(@pl) {
    switch(@pl) {
    case 1:
        return(array(-1236.5, 9, 1464.5));
    case 2:
        return(array(-1268.5, 9, 1464.5));
    default:
        _error('Specificed player number is not 1 or 2.');
    }
}

proc _C4_podiumTeleport(@pl, @user=player()) {
    set_ploc(@user, _C4_podium(@pl));
    pfacing(@user, @pl*2 - 1); ## 1->1, 2->3. Would have to modify depending on where your podiums face
}

proc _C4_podiumLight(@pl, @on) {
    if (@on) {
        @block = 'REDSTONE_BLOCK';
    } else {
        @block = 'AIR';
    }
    @pod = _C4_podium(@pl);
    _C4_setBlock(@pod[0], @pod[1] - 2, @pod[2], @block);
}

###               ###
### Win/Lose/Draw ###
###               ###

proc _C4_win(@winner) {
    @p1 = _import_get('cnct4.player1');
    @p2 = _import_get('cnct4.player2');

    if (@winner == @p1) {
        @color = '&5';
        @loser = @p2;
    } else {
        @color = '&e';
        @loser = @p1;
    }

    _C4_stat(@winner, 'win');
    _C4_stat(@loser, 'loss');

    _C4_clearvalues();
    runas(@winner, '/warp connect4');
    runas(@loser, '/warp connect4');

    broadcast(colorize("@{color}@{winner} &fhas won &cFour in a row!"));
    ## Disabled due to potential cheating for money by constantly quitting, making other person get money.
    #acc_add(@winner, 10)
    #tmsg(@winner, colorize('&a$10 has been added to your account!'))
}

proc _C4_draw() {
    @pl1 = _import_get('cnct4.player1');
    @pl2 = _import_get('cnct4.player2');

    _C4_stat(@pl1, 'draw');
    _C4_stat(@pl2, 'draw');

    _C4_clearvalues();
    broadcast(colorize('&cStalemate! &fNo one won &cFour in a row!'));
}

proc _C4_isStalemate() {
    @corner = _C4_corner();
    @cx = @corner['x'];
    @y = @corner['y'] + 5;
    @cz = @corner['z'];
    if (_C4_getAxis() == 'x') {
        return(
            _C4_getBlock(@cx + 0, @y, @cz) != 'AIR' &&
            _C4_getBlock(@cx + 1, @y, @cz) != 'AIR' &&
            _C4_getBlock(@cx + 2, @y, @cz) != 'AIR' &&
            _C4_getBlock(@cx + 3, @y, @cz) != 'AIR' &&
            _C4_getBlock(@cx + 4, @y, @cz) != 'AIR' &&
            _C4_getBlock(@cx + 5, @y, @cz) != 'AIR' &&
            _C4_getBlock(@cx + 6, @y, @cz) != 'AIR');
    } else {
        return(
            _C4_getBlock(@cx, @y, @cz + 0) != 'AIR' &&
            _C4_getBlock(@cx, @y, @cz + 1) != 'AIR' &&
            _C4_getBlock(@cx, @y, @cz + 2) != 'AIR' &&
            _C4_getBlock(@cx, @y, @cz + 3) != 'AIR' &&
            _C4_getBlock(@cx, @y, @cz + 4) != 'AIR' &&
            _C4_getBlock(@cx, @y, @cz + 5) != 'AIR' &&
            _C4_getBlock(@cx, @y, @cz + 6) != 'AIR');
    }
}

###            ###
### Statistics ###
###            ###

## Increments a stat type for a player
proc _C4_stat(@player, @type) {
    #if (@type != 'no') { return(); } ## Debugging

    ## Get the stats, turns into UUID if not already
    @UUID = _UUID_altered( _UUID_player_get(@player) );
    @stats = get_value("cnct4.stats.@UUID");
    if (@stats == null) {
        @stats = get_value('cnct4.stats.'. to_lower(@player));
    }

    if (@stats == null) {
        @stats = array(win: 0, loss: 0, draw: 0);
    }

    try( @stats[@type]++,
        console(colorize('&4Error: &cAn error occurred when trying to increment a stat.'));
        console(colorize("&5Player: &f@{player}&5, Type: &f@type"));
    );

    store_value("cnct4.stats.@UUID", @stats);
    clear_value('cnct4.stats.'. to_lower(@player));
}

## Print the user stats to the screen.
proc _C4_printStats(@user) {
    ## Get the stats, turns into UUID if not already
    @UUID = _UUID_altered( _UUID_player_get(@user, true) );
    @stats = get_value("cnct4.stats.@UUID");
    if (@stats == null) {
        console('Erasing player-stored stats and storing in UUID');
        @stats = get_value('cnct4.stats.'. to_lower(@user));
        store_value("cnct4.stats.@UUID", @stats);
        clear_value('cnct4.stats.'. to_lower(@user));
    }

    if (@stats == null) {
        _error('Player has not played a game yet.');
    }

    @name = _UUID_usernames_lastname(@UUID);
    ## Get more data
    @total = @stats['win'] +  @stats['loss'] +  @stats['draw'];
    @ratio = round(@stats['win'] / (@stats['win'] + @stats['loss']) * 100, 0);

    ## Print the stats
    msg(colorize("&e-- &cFour in a Row &fstats: &5@name &e--"));
    msg(colorize('&5Wins&f: '. @stats['win']. " &6(@{ratio}%)"));
    msg(colorize('&5Losses&f: '. @stats['loss']));
    msg(colorize('&5Draws&f: '. @stats['draw']));
    msg(colorize("&5Total&f: @total"));
}

###                            ###
### Checking for four in a row ###
###                            ###
proc _check4row(@cx, @cy, @cz, @block) {
    for (@y = 0, @y < 6, @y++) {
        for (@z = 0, @z < 7, @z++) {

            ## Defaults to z-axis, swaps to x-axis if needed inside the method.
            @curblock = _C4_getBlock(@cx, @cy + @y, @cz + @z);
            if (@block == @curblock) {
                if (_C4_checkline(@cx, @cy + @y, @cz + @z, 'N', @block)) {
                    return(true);
                }
                if (_C4_checkline(@cx, @cy + @y, @cz + @z, 'E', @block)) {
                    return(true);
                }
                if (_C4_checkline(@cx, @cy + @y, @cz + @z, 'NW', @block)) {
                    return(true);
                }
                if (_C4_checkline(@cx, @cy + @y, @cz + @z, 'NE', @block)) {
                    return(true);
                }
            }
        }
    }
    return(false);
}

## TODO have an internally stored list, don't need to query the world for the block
proc _C4_checkline(@x, @y, @z, @dir, @block) {
    @count = 0;

    @newx = @x;
    @newy = @y;
    @newz = @z;

    while (true) {
        switch(@dir) {
            case 'N':
                @newy = @y + @count;
            case 'E':
                @newz = @z + @count;
            case 'NW':
                @newy = @y + @count;
                @newz = @z - @count;
            case 'NE':
                @newy = @y + @count;
                @newz = @z + @count;
        }

        ## Direction correction
        if (_C4_getAxis() == 'x') {
            @newx = @newz;
            @newz = @z;
        }

        @curblock = _C4_getBlock(@newx, @newy, @newz);
        if (@block != @curblock) {
            break();
        }
        @count++;
    }
    return(@count >= 4);
}

###         ###
### Helpers ###
###         ###
proc _C4_getBlock(@x, @y, @z) {
    @world = 'Event';
    @block = get_block(array('x':@x, 'y':@y, 'z':@z, 'world':@world));
    return(@block);
}

proc _C4_setBlock(@x, @y, @z, @block) {
    @world = 'Event';
    @loc = array('x':@x, 'y':@y, 'z':@z, 'world':@world);
    set_block(@loc, @block);
}
