#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon

### The help command.
proc _C4_help(@page=1, @player=player()) {
    
    ### All commands go here if they are to show up in the help command.
    @commands = array(
            '&5Help &f> &dShows all available commands.',
            '&5Join &f> &dJoin a match.',
            '&5Quit &f> &dForfeit the match.',
            '&5Stats &f> &dView a player\'s stats.'
        )
    if( has_permission(@player, 'ch_staff') ) {
        @commands = array_merge(@commands, array(
                '&5Reset &f> &dForcefully end the arena.'
            ))
    }

    ### Find the maximum amount of pages and ensure that the page selected is within the bounds, else set it to 1.
    @perpage = 5
    @maxpage = ceil( array_size(@commands) / @perpage )
    if( !is_numeric(@page) || @page < 1 || @page > @maxpage )  {
        @page = 1
    }

    ### Prints all the @commands from the selected page. The try() is in case there are not 5 on that page.
    tmsg(@player, colorize(' &7===== &5Options &7====='))
    for(@i = 0, @i < @perpage, @i++) {
        try(
            tmsg(@player, colorize(@commands[@i + @perpage * (@page - 1)]) )
           )
    }
    #tmsg(@player, colorize("&6Page &e@{page}/@{maxpage}&6. View more with &e/connect4 help <page>"))
}

###          ###
### Settings ###
###          ###

### Setting for which was the board runs, either x or z.
proc _C4_getAxis() {
    return('z')
}

### The least-most corner of the board. Lowest possible x, y, and z coords where more negative is lower.
proc _C4_corner(@axis=false) {
    @result = array(-1253, 9, 1461);
    if(@axis) {
        switch(@axis) {
        case 'x':
            @result = @result[0];
        case 'y':
            @result = @result[1];
        case 'z':
            @result = @result[2];
        default:
            _error("Invalid argument for C4_corner; @axis");
        }
    }
    return(@result);
}

###
###
###

proc _C4_isEnabled(@die=true) {
    @enabled = _import_get('cnct4.enabled');
    if(@enabled != true ) {
        if( @die ) {
            _error('The Connect 4 arena is not enabled.');
        }
        return(false);
    }
    return(true);
}

proc _C4_isPlaying(@user=player()) {
    @pl1 = _import_get('cnct4.player1');
    @pl2 = _import_get('cnct4.player2');
    return( @pl1 == @user || @pl2 == @user );
}

proc _C4_getPlayer(@user=player()) {
    @pl1 = _import_get('cnct4.player1')
    @pl2 = _import_get('cnct4.player2')

    if( @pl1 == @user ) {
        return(1)
    }
    else if( @pl2 == @user ) {
        return(2)
    }
    else {
        _error('Specified player is not playing...')
    }
}

proc _C4_reset() {

    ### DO: Teleport players out
    _C4_clearvalues()

    _C4_podiumLight(1, false)
    _C4_podiumLight(2, false)

    @cornerx = _C4_corner('x')
    @cornery = _C4_corner('y')
    @cornerz = _C4_corner('z')

    ### Clear the board.
    if( _C4_getAxis() == 'x') {
        for(@x = 0, @x < 7, @x++) {
            for(@y = 0, @y < 6, @y++) {
                _C4_setBlock(@cornerx + @x, @cornery + @y, @cornerz, 'AIR')
            }
        }
    } else {
        for(@z = 0, @z < 7, @z++) {
            for(@y = 0, @y < 6, @y++) {
                _C4_setBlock(@cornerx, @cornery + @y, @cornerz + @z, 'AIR')
            }
        }
    }
}

proc _C4_clearvalues() {
    _export_store('cnct4.enabled', false)
    _export_store('cnct4.lastPlayer', null)
    _export_store('cnct4.player1', null)
    _export_store('cnct4.player2', null)
}

proc _C4_enable() {
    ### Turn on player 1's podium light and allow pieces to be played.
    _C4_podiumLight(1, true)
    _export_store('cnct4.enabled', true)
}

###        ###
### Podium ###
###        ###

proc _C4_podium(@pl) {
    switch(@pl) {
        case 1:
            return( array(-1236.5, 9, 1464.5) )
        case 2:
            return( array(-1268.5, 9, 1464.5) )
        default:
            _error('Specificed player number is not 1 or 2.')
    }
}

proc _C4_podiumTeleport(@pl, @user=player()) {
    set_ploc(@user, _C4_podium(@pl))
    pfacing(@user, @pl*2 - 1) ### 1->1, 2->3. Would have to modify depending on where your podiums face.
}

proc _C4_podiumLight(@pl, @on) {
    if( @on ) {
        @block = 'REDSTONE_BLOCK'
    } else {
        @block = 'AIR'
    }
    _C4_setBlock( _C4_podium(@pl)[0], _C4_podium(@pl)[1] - 2, _C4_podium(@pl)[2], @block)
}

###           ###
### Join/Quit ###
###           ###
proc _C4_join(@user=player()) {
    _no_console()
    if( pworld() != 'Event' ) {
        _error('You must be in the event world.')
    }

    if( _C4_isPlaying() ) {
        _error('You have already joined!')
    }

    if( _C4_isEnabled(false) ) {
        _error('This minigame already has two people playing!')
    }

    @pl1 = _import_get('cnct4.player1')
    @pl2 = _import_get('cnct4.player2')
    if( @pl1 == null ) {
        @pl = 1
        _C4_reset()
        _export_store("cnct4.player1", @user)
    } else {
        @pl = 2
        _export_store("cnct4.player2", @user)
        tmsg(@pl1, colorize("&f@user has joined &cConnect 4 &fas &ePlayer 2"))
    }

    _C4_podiumTeleport(@pl)
    set_pmode(@user, SURVIVAL)
    tmsg(@user, colorize("&fYou have joined &cFour in a row &fas &5Player @pl"))
    tmsg(@user, colorize('&4Right click &con the slabs to place a piece.'))

    ### Needs to run after teleport
    if( @pl == 2 ) {
        _C4_enable()
    }
}

proc _C4_quit() {
    _no_console()
    if( _C4_isPlaying() ) {
    
        @pl1 = _import_get('cnct4.player1')
        @pl2 = _import_get('cnct4.player2')
    
        try( if( @pl1 == player() ) {
            tmsg(@pl2, colorize("&5@pl1 &fhas quit &cFour in a Row."))
            _C4_win(@pl2)
        } else {
            tmsg(@pl1, colorize("&e@pl2 &fhas quit &cFour in a Row."))
            _C4_win(@pl1)
        } )
    
        _C4_reset()
        die(colorize('&cYou have quit &4Four in a Row'))
    
    }
    _error('You are not playing!')
}
###      ###
### Play ###
###      ###

proc _C4_play(@column) {
    _no_console()
    _C4_isEnabled()
    
    ### Only allow the two people who have joined to play.
    if( !_C4_isPlaying() ) {
        _error('You are not currently playing!')
    }

    @pl = _C4_getPlayer()
    @lastPlayer = _import_get('cnct4.lastPlayer')
    if( @lastPlayer == @pl || (@lastPlayer == null && @pl != 1) ) {
        _error('Please wait for your turn.')
    }

    if( @pl == 1 ) {
        @block = '159:10'
    } else {
        @block = '159:4'
    }
    
    switch(@column) {
        case 'a':
            @column = 0
        case 'b':
            @column = 1
        case 'c':
            @column = 2
        case 'd':
            @column = 3
        case 'e':
            @column = 4
        case 'f':
            @column = 5
        case 'g':
            @column = 6
        default:
            _error('Invalid column.')
    }
    
    @cornerx = _C4_corner('x')
    @cornery = _C4_corner('y')
    @cornerz = _C4_corner('z')

    ### Place piece in topmost, or error if column is full.
    for(@y = 0, @y <= 5, @y++) {
	@block = get_block(array('x':@cornerx, 'y':@cornery + @y, 'z':@cornerz + @column, 'world':'Event'));
        if(@block == 'AIR') {
            
            _C4_setBlock(@cornerx, @cornery + @y, @cornerz + @column, @block)
            _export_store('cnct4.lastPlayer', @pl)

            if( @pl == 1 ) {
                _C4_podiumLight(1, false)
                _C4_podiumLight(2, true)
            } else {
                _C4_podiumLight(1, true)
                _C4_podiumLight(2, false)
            }
            break()
        }
        else if( @y == 5 ) {
            _error('This column is full.')
        }
    }
      
    ### If four in a row for @block.
    if( _check4row(@cornerx, @cornery, @cornerz, @block) ) {
        _C4_win(player())
    }
    else if( _C4_isStalemate() ) {
        _C4_draw()
    }
}

###               ###
### Win/Lose/Draw ###
###               ###

proc _C4_win(@player) {

    @pl1 = _import_get('cnct4.player1')
    @pl2 = _import_get('cnct4.player2')
    
    if( @player == @pl1 ) {
        @color = '&5'

        _C4_stat(@pl1, 'win')
        _C4_stat(@pl2, 'loss')
        try( pkill(@pl2) )
    } else {
        @color = '&e'
        
        _C4_stat(@pl1, 'loss')
        _C4_stat(@pl2, 'win')
        try( pkill(@pl1) )
    }

    _C4_clearvalues()
    runas(~console, "/warp connect4 @player")

    broadcast(colorize("@{color}@{player} &fhas won &cFour in a row!"))
    ### Disabled due to potential cheating for money by constantly quitting, making other person get money.
    #acc_add(@player, 10)
    #tmsg(@player, colorize('&a$10 has been added to your account!'))

}

proc _C4_draw() {
    @pl1 = _import_get('cnct4.player1')
    @pl2 = _import_get('cnct4.player2')

    _C4_stat(@pl1, 'draw')
    _C4_stat(@pl2, 'draw')
    
    _C4_clearvalues()
    broadcast(colorize('&cStalemate! &fNo one won &cFour in a row!'))
}

proc _C4_isStalemate() {
    @cornerx = _C4_corner('x')
    @cornery = _C4_corner('y')
    @cornerz = _C4_corner('z')
    if( _C4_getAxis() == 'x') {
        return(
            get_block(array('x':@cornerx + 0, 'y':@cornery + 5, 'z':@cornerz, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx + 1, 'y':@cornery + 5, 'z':@cornerz, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx + 2, 'y':@cornery + 5, 'z':@cornerz, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx + 3, 'y':@cornery + 5, 'z':@cornerz, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx + 4, 'y':@cornery + 5, 'z':@cornerz, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx + 5, 'y':@cornery + 5, 'z':@cornerz, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx + 6, 'y':@cornery + 5, 'z':@cornerz, 'world':'Event')) != 'AIR')
    } else {
        return(
            get_block(array('x':@cornerx, 'y':@cornery + 5, 'z':@cornerz + 0, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx, 'y':@cornery + 5, 'z':@cornerz + 1, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx, 'y':@cornery + 5, 'z':@cornerz + 2, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx, 'y':@cornery + 5, 'z':@cornerz + 3, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx, 'y':@cornery + 5, 'z':@cornerz + 4, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx, 'y':@cornery + 5, 'z':@cornerz + 5, 'world':'Event')) != 'AIR' &&
            get_block(array('x':@cornerx, 'y':@cornery + 5, 'z':@cornerz + 6, 'world':'Event')) != 'AIR')
    }
}

###            ###
### Statistics ###
###            ###

### Increments a stat type for a player.
proc _C4_stat(@player, @type) {
    
    ### Get the stats, turns into UUID if not already. ###
    @UUID = _UUID_altered( _UUID_player_get(@player) )
    @stats = get_value("cnct4.stats.@UUID")
    if( @stats == null ) {
        @stats = get_value('cnct4.stats.'. to_lower(@player))
    }

    if( @stats == null ) {
        @stats = array(win: 0, loss: 0, draw: 0)
    }

    try( @stats[@type]++,
        console(colorize('&4Error: &cAnd error occurred when trying to increment a stat.'))
        console(colorize("&5Player: &f@{player}&5, Type: &f@type"))
    )

    store_value("cnct4.stats.@UUID", @stats)
    clear_value('cnct4.stats.'. to_lower(@player))
}

### Print the user stats to the screen.
proc _C4_printStats(@user) {

    ### Get the stats, turns into UUID if not already. ###
    @UUID = _UUID_altered( _UUID_player_get(@user, true) )
    @stats = get_value("cnct4.stats.@UUID")
    if( @stats == null ) {
        console('Erasing player-stored stats and storing in UUID')
        @stats = get_value('cnct4.stats.'. to_lower(@user))
        store_value("cnct4.stats.@UUID", @stats)
        clear_value('cnct4.stats.'. to_lower(@user))
    }
    
    if( @stats == null ) {
        _error('Player has not played a game yet.')
    }
    
    @name = _UUID_usernames_lastname(@UUID)
    ### Get more data ###
    @total = @stats['win'] +  @stats['loss'] +  @stats['draw']
    @ratio = round(@stats['win'] / (@stats['win'] + @stats['loss']) * 100, 0)
    
    ### Print the stats
    msg(colorize("&e-- &cFour in a Row &fstats: &5@name &e--"))
    msg(colorize('&5Wins&f: '. @stats['win']. " &6(@{ratio}%)"))
    msg(colorize('&5Losses&f: '. @stats['loss']))
    msg(colorize('&5Draws&f: '. @stats['draw']))
    msg(colorize("&5Total&f: @total"))
}

###                            ###
### Checking for four in a row ###
###                            ###
proc _check4row(@cornerx, @cornery, @cornerz, @block) {
    for(@y = 0, @y < 6, @y++) {
        for(@z = 0, @z < 7, @z++) {
    
            ### Defaults to z-axis, swaps to x-axis if needed inside the method.
            @curblock = get_block(array('x':@cornerx, 'y':@cornery + @y, 'z':@cornerz + @z, 'world':'Event'))
            if(@block == @curblock) {
                if( _C4_checkline(@cornerx, @cornery + @y, @cornerz + @z, 'N', @block) ) {
                    return(true)
                }
                if( _C4_checkline(@cornerx, @cornery + @y, @cornerz + @z, 'E', @block) ) {
                    return(true)
                }
                if( _C4_checkline(@cornerx, @cornery + @y, @cornerz + @z, 'NW', @block) ) {
                    return(true)
                }
                if( _C4_checkline(@cornerx, @cornery + @y, @cornerz + @z, 'NE', @block) ) {
                    return(true)
                }
            }
        }
    }
    return(false)
}

proc _C4_checkline(@x, @y, @z, @dir, @block) {
    @count = 0

    @newx = @x
    @newy = @y
    @newz = @z

    while(true) {
        switch(@dir) {
            case 'N':
                @newy = @y + @count
            case 'E':
                @newz = @z + @count
            case 'NW':
                @newy = @y + @count
                @newz = @z - @count
            case 'NE':
                @newy = @y + @count
                @newz = @z + @count
        }

        ### Direction correction.
        if( _C4_getAxis() == 'x' ) {
            @newx = @newz
            @newz = @z
        }

        @curblock = get_block(array('x':@newx, 'y':@newy, 'z':@newz, 'world':'Event'))
        if(@block != @curblock) {
            break()
        }
        @count++
    }

    return(@count >= 4)
}

###         ###
### Helpers ###
###         ###
proc _C4_setBlock(@x, @y, @z, @block) {
    @world = 'Event';
    @loc = array('x':@x, 'y':@y, 'z':@z, 'world':@world);
    set_block(@loc, @block);
}
