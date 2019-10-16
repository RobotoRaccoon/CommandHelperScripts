#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

###          ###
### Commands ###
###          ###

## /mines help [page]
proc _MS_help(@page) {
    @commands = array(
        '&5Start &f> &dStart a game',
        '&5Quit &f> &dLeave your game',
        '&5Top &f> &dView leaderboards',
        '&5Pb &f> &dView your best times',
        '&5Pack &f> &dResource Pack URL',
    );
    _page_vertical('Options', 'mines help', @commands, @page);
}

## /mines start <size>
proc _MS_start(@args) {
    if (array_size(@args) == 0) {
        _error('/mines start <size>');
    }
    @size = array_remove(@args, 0);
    @cfg = _MS_config(@size);

    if (array_size(@args) > 2) {
        @cfg['x'] = integer(@args[0]);
        @cfg['z'] = integer(@args[1]);
        @cfg['mines'] = integer(@args[2]);
    }

    @arena = _MS_firstArena(@cfg);
    ## Setup arena
    _MS_reset(@arena);
    ## Set floor to Coal Block
    _MS_setFloor(@arena, 'COAL_BLOCK');

    ## Get the config for the specified size
    _MS_assertConfig(@cfg);
    @gridx = @cfg['x'];
    @gridz = @cfg['z'];
    @mines = @cfg['mines'];

    if (array_size(@args) > 3) {
        @seed = @args[3];
    } else {
        @seed = _MS_genSeed();
    }

    @field = _MS_generate_field(@gridx, @gridz, @mines, @seed);
    @info = array('player': player(), 'arena': @arena, 'config': @cfg, 'field': @field, 'seed': @seed, 'time': null);

    @c = _MS_gridCorner(@info);
    ## Set clay and snow
    for (@x = 0, @x < @gridx, @x++) {
        for (@z = 0, @z < @gridz, @z++) {
            _MS_setBlock(@c[0] + @x, @c[1] + 1, @c[2] + @z, 'SNOW_BLOCK')
            _MS_setBlock(@c[0] + @x, @c[1], @c[2] + @z, 'COAL_BLOCK')
        }
    }

    _MS_resetSnow(@arena);

    ## Setup player
    set_pheld_slot(player(), 0);
    _MS_setInv(@info);
    ptake_item(array(name:'WOODEN_HOE'));
    set_ploc(player(), array(@c[0] - 2, @c[1] + 1, @c[2] + @gridz/2, 'Event'));
    set_pmode(player(), 'CREATIVE');

    _MS_storeInfo(@info);
    export('minesweeper.mineslist', _MS_fieldMineList(@info));
    #console("Minesweeper: Generating a @size game for ". player());
}

## /mines quit
proc _MS_quit(@player) {
    if (!_MS_isPlaying(@player)) {
        if(has_permission('ch_staff')) {
            _error('/mines quit <player>');
        }
        _error('Minesweeper is not running.');
    }

    @arena = _MS_getArena(@player);
    if (_MS_getInfo(@arena, 'player') == player()) {
        _MS_reset(@arena);
        die(colorize('&cYou have quit &4Minesweeper&c.'));
    }

    if (has_permission('ch_staff')) {
        _MS_reset(@arena);
        die(colorize('&cYou have &4forcefully &cended the current round of &4Minesweeper&c.'));
    }

    _error('You are not playing!');
}

## /mines seed
proc _MS_seed() {
    @player = player();
    if (!_MS_isPlaying(@player)) {
        _error('Minesweeper is not running.');
    }

    @seed = _MS_getInfo(_MS_getArena(@player), 'seed');
    msg(colorize("&eYou are playing with seed &6@seed"));
}

## /mines top <size> [page]
proc _MS_leaderboard_read(@args) {
    if (array_size(@args) == 0) {
        _error('/mines top <size> [page]');
    }
    @size = @args[0];
    _MS_config(@size);
    if (@size == 'custom') {
        _error('Custom games don\'t have a leaderboard');
    }

    @leader = get_value("minesweeper.leader.size.@size");
    if (!is_array(@leader)) {
        @leader = array();
    }

    @page = 1;
    if (array_size(@args) > 1) {
        @page = @args[1];
    }

    @perpage = 8;
    @maxpage = ceil(array_size(@leader) / @perpage);
    if (!is_numeric(@page) || @page < 1 || @page > @maxpage) {
        @page = 1;
    }

    msg(colorize('&e-- &cMinesweeper &fleaderboard: &5'. to_upper(@size). ' &e--'));
    for (@i = 0, @i < @perpage, @i++) {

        @pos = (@page - 1) * @perpage + @i;
        @realpos = @pos + 1;
        if (array_size(@leader) > @pos) {
            @time = _MS_timeString(@leader[@pos][1]);
            msg(colorize("&e@realpos. &5". @leader[@pos][0]. '&f: '. @time));
        } else {
            msg(colorize("&e@realpos. &cN/A"));
        }
    }
    msg(colorize("&6Page &e@page/@maxpage&6. View more with &e/mines top @size <page>"));
}

## /mines pb [player]
proc _MS_personalbest(@player=player()) {
    if (@player == '') {
        @UUID = _UUID_player_altered();
        @name = player();
    } else {
        @UUID = _UUID_player_altered(@player, true);
    }

    @pb = get_value("minesweeper.leader.uuid.@UUID");
    if (!is_array(@pb)) {
        @pb = associative_array();
    }

    msg(colorize("&e-- &cMinesweeper &fpersonal best: &5@player &e--"));
    foreach (@size in array('Small', 'Medium', 'Large', 'Massive')) {
        @low = to_lower(@size);
        if (!array_index_exists(@pb, @low)) {
            @time = '&cN/A&f';
        } else {
            @time = _MS_timeString(@pb[@low]);
        }
        msg(colorize("&5@size: &f@time"));
    }
}
