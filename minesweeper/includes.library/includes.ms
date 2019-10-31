#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## The smallest valued corner for the field. (Larger negatives are smaller, of course)
proc _MS_corner(@arena) {
    return(_MS_arenas()[@arena]['corner']);
}

proc _MS_arenaSize(@arena) {
    return(_MS_arenas()[@arena]['size']);
}

proc _MS_arenas() {
    @arenas = array(
        array('corner': array(-1380, 3, 1440), 'size': array('x': 30, 'z': 16)),
        array('corner': array(-1379, 3, 1484), 'size': array('x': 10, 'z': 10)),
        array('corner': array(-1361, 3, 1484), 'size': array('x': 10, 'z': 10)),
        array('corner': array(-1380, 3, 1462), 'size': array('x': 30, 'z': 16)),
        array('corner': array(-1461, 3, 1440), 'size': array('x': 54, 'z': 54)),
    );
    return(@arenas);
}

proc _MS_arenaCount() {
    return(array_size(_MS_arenas()));
}

## Pre-defined level sizes
proc _MS_config(@size=null) {
    @config = array(
        'small':    array('x': 10, 'z': 10, 'mines': 12, 'mult': 1,  'type': 'small'),
        'medium':   array('x': 16, 'z': 16, 'mines': 40, 'mult': 4,  'type': 'medium'),
        'large':    array('x': 30, 'z': 16, 'mines': 99, 'mult': 16, 'type': 'large'),
        'massive':  array('x': 54, 'z': 54, 'mines':600, 'mult':128, 'type': 'massive'),
        'custom':   array('x': 30, 'z': 16, 'mines':  0, 'mult': 0,  'type': 'custom'),
    );

    ## Return entire array if no size specified.
    if (@size == null) {
        return(@config);
    }
    if (array_index_exists(@config, @size)) {
        return(@config[@size]);
    }
    array_remove(@config, 'custom');
    _error('The specified size does not exist. Sizes: &4'. array_keys(@config));
}

proc _MS_assertConfig(@cfg) {
    if (@cfg['x'] <= 0) { _error('Grid size x must be positive'); }
    if (@cfg['z'] <= 0) { _error('Grid size z must be positive'); }
    if (@cfg['mines'] <= 0) { _error('Mines count must be positive'); }
    @size = @cfg['x'] * @cfg['z'];
    if (@cfg['mines'] > @size) { _error('Mines count must fit in grid'); }
}

proc _MS_assertWorld(@player=player()) {
    if (@player == null || pworld(@player) != 'Event') { die(); }
}

proc _MS_assertRegion(@loc, @region) {
    if (!is_array(@loc) || !array_contains_ic(sk_regions_at(@loc), @region)) { die(); }
}

## Get the smallest valued corner for the specified config.
proc _MS_gridCorner(@info) {
    @cfg = @info['config'];
    @size = _MS_arenaSize(@info['arena']);
    @c = _MS_corner(@info['arena']);
    @c[0] += floor((@size['x'] - @cfg['x']) / 2);
    @c[2] += floor((@size['z'] - @cfg['z']) / 2);
    return(@c);
}

proc _MS_reset(@arena=0) {
    _MS_clear_values(@arena)

    ## Clear clay, snow, markers
    _MS_setFloor(@arena, 'AIR');
    _MS_setFloor(@arena, 'AIR', 2);
    _MS_setFloor(@arena, 'AIR', 1);
}

proc _MS_clear_values(@arena) {
    @player = _MS_getInfo(@arena, 'player');

    clear_value("minesweeper.arena.@arena");
    export("minesweeper.arena.@arena", null);

    clear_value("minesweeper.player.@player");
    export("minesweeper.player.@player", null);

    ## Temp saved data
    export("minesweeper.antibreak.@player", null);
    export("minesweeper.snow.@arena", null);

    if (ponline(@player)) {
        runas(@player, '/warp minesweeper');
        set_pmode(@player, 'SURVIVAL');
        clear_pinv(@player);
    }
}

proc _MS_storeInfo(@info) {
    @arena = @info['arena'];
    @player = @info['player'];
    _export_store("minesweeper.arena.@arena", @info);
    _export_store("minesweeper.player.@player", @arena);
}

proc _MS_getInfo(@arena, @setting=null) {
    @info = _import_get("minesweeper.arena.@arena");
    if (is_null(@setting)) {
        return(@info);
    }

    if (is_array(@info) && array_index_exists(@info, @setting)) {
        return(@info[@setting]);
    }

    return(null);
}

proc _MS_getArena(@player) {
    return(_import_get("minesweeper.player.@player"));
}

proc _MS_isPlaying(@player=player()) {
    return(!is_null(_MS_getArena(@player)));
}

## Convert coordinates into grid locations
proc _MS_grid_getpos(@info, @x, @z) {
    @c = _MS_corner(@info['arena']);
    @size = _MS_arenaSize(@info['arena']);
    @cfg = @info['config'];

    @xpos = @x - @c[0] - floor((@size['x'] - @cfg['x'])/2);
    @zpos = @z - @c[2] - floor((@size['z'] - @cfg['z'])/2);

    return(array(@xpos, @zpos));
}

proc _MS_genSeed() {
    return(floor(rand() * (10 ** 10)) + 1);
}

## Generate a playing field as a 1D array, to be treated as a 2D. Just allows quicker creation.
proc _MS_generate_field(@x, @z, @mines, @seed) {
    @field = array();
    array_resize(@field, @x * @z - @mines, false);

    for (@i = 0, @i < @mines, @i++) {
        @index = @seed % array_size(@field);
        array_insert(@field, true, @index);
    }
    return(@field);
}

proc _MS_isMine(@info, @x, @z) {
    @gridz = @info['config']['z'];
    return(@info['field'][@x * @gridz + @z]);
}

## Get the number of mines in the radius. @x and @z are grid indices.
#proc _MS_minesInRadius(@info, @field, @x, @z) {
#    @gridx = @info['config']['x'];
#    @gridz = @info['config']['y'];
#    @tnt = 0;
#
#    for(@i = @x-1, @i <= @x+1, @i++) {
#        for(@j = @z-1, @j <= @z+1, @j++) {
#            if(@i >= 0 && @i < @gridx && @j >= 0 && @j < @gridz && _MS_isMine(@field, @i, @j)) {
#                @tnt++;
#            }
#        }
#    }
#    return(@tnt);
#}

proc _MS_fieldMineList(@info) {
    @x = @info['config']['x'];
    @z = @info['config']['z'];
    @list = array();
    array_resize(@list, @x*@z, 0);

    ## Produce @list[x][z]
    for (@i = 0, @i < @x, @i++) {
        for (@j = 0, @j < @z, @j++) {
            if(!_MS_isMine(@info, @i, @j)) {
                continue();
            }

            ## We're a mine, increment the surrounding area by 1
            for (@i2 = @i-1, @i2 <= @i+1, @i2++) {
                for (@j2 = @j-1, @j2 <= @j+1, @j2++) {
                    if (@i2 >= 0 && @i2 < @x && @j2 >= 0 && @j2 < @z) {
                        @list[@i2 * @z + @j2]++;
                    }
                }
            }
        }
    }
    return(@list);
}

proc _MS_checkwin(@arena) {
    @info = _MS_getInfo(@arena);
    @player = @info['player'];
    @cfg = @info['config'];
    @tntcount = @cfg['mines'];

    @snowcount = _MS_getSnow(@arena);
    if (@tntcount == @snowcount) {
        @time = time() - _MS_getInfo(@arena, 'time');
        @time = round((@time / 1000), 2);

        @size = @cfg['type'];
        @elapse = _MS_timeString(@time);
        broadcast(colorize("&5@player &fbeat a &e@size &flevel of &cMinesweeper&f in &c@elapse!"));

        @payout = _MS_payout(@cfg, ceil(@time));
        if (@payout > 0) {
            acc_add(@player, @payout);
            msg(colorize("&a$@payout has been added to your account!"));
        }

        _MS_leaderboard_write(@size, _UUID_player_get(@player), @time);
        _MS_clear_values(@arena);
    }
}

proc _MS_payout(@cfg, @time) {
    @mult = @cfg['mult'];

    @base = 5 * @mult;
    @timelim = 80 * @mult; ## 80 seconds per mult

    @bonus = (@timelim - @time) / 8;
    @bonus = max(@bonus, 0);
    return(@base + @bonus);
}

proc _MS_timeString(@time) {
    @mins = integer(@time / 60);
    @secs = @time - 60.0 * @mins;
    @secs = round(@secs, 2);

    if (@mins > 0) {
        return("@{@mins}m @{secs}s");
    } else {
        return("@{secs}s");
    }
}

proc _MS_leaderboard_write(@size, @UUID, @time, @force=false) {
    @size = to_lower(@size);
    @player = _UUID_usernames_lastname(@UUID);
    @UUID = _UUID_altered(@UUID);

    if (@size == 'custom') {
        return();
    }

    ## Personal insert ##
    @personal = get_value("minesweeper.leader.uuid.@UUID");
    if (is_null(@personal)) {
        @personal = associative_array();
    }

    @oldTime = null;
    @update = false;

    if (!array_index_exists(@personal, @size)) {
        @personal[@size] = @time;
        @update = true;
    } else {
        if (@time <= @personal[@size]) {
            @oldTime = @personal[@size];
            @personal[@size] = @time;
            @update = true;
        }
    }
    store_value("minesweeper.leader.uuid.@UUID", @personal);

    ## Leaderboard insert ##
    @leader = get_value("minesweeper.leader.size.@size");
    if (!is_array(@leader)) {
        @leader = array()
    }

    if (@update || @force) {
        @data = array(@player, @time)
        if (!is_null(@oldTime)) {
            array_remove_values(@leader, array(@player, @oldTime))
        }

        ## TODO binary insertion
        @last = array_size(@leader);
        @insert = @last;
        for (@pos = 0, @pos < @last, @pos++) {
            if (@time < @leader[@pos][1]) {
                @insert = @pos;
                break();
            }
        }

        array_insert(@leader, @data, @insert);
        _bc("&5@player &fachieved position &c". (@insert + 1). " &fon a &e@size &flevel of &cMinesweeper.");
        store_value("minesweeper.leader.size.@size", @leader);
    }
}

proc _MS_getSnow(@arena) {
    @snow = import("minesweeper.snow.@arena");
    if (@snow == null || @snow < 1) {
        _MS_resetSnow(@arena);
    }
    return(import("minesweeper.snow.@arena"));
}
proc _MS_decreaseSnow(@arena) {
    export("minesweeper.snow.@arena", _MS_getSnow(@arena) - 1);
}
proc _MS_resetSnow(@arena) {
    export("minesweeper.snow.@arena", _MS_calculateSnow(@arena));
}

proc _MS_calculateSnow(@arena) {
    @c = _MS_corner(@arena);
    @size = _MS_arenaSize(@arena);

    @snow = 0;
    @y = @c[1] + 1;
    for (@x = @c[0], @x < @c[0] + @size['x'], @x++) {
        for (@z = @c[2], @z < @c[2] + @size['z'], @z++) {
            if (_MS_getBlock(@x,@y,@z) == 'SNOW_BLOCK') {
                @snow++;
            }
        }
    }
    return(@snow);
}

proc _MS_clayColours() {
    ## Last element is 9 in radius, including self.
    ## Additional 10 count (In case randomisation is already at 9)
    return(array(
        'WHITE_TERRACOTTA',
        'LIGHT_BLUE_TERRACOTTA',
        'LIME_TERRACOTTA',
        'YELLOW_TERRACOTTA',
        'ORANGE_TERRACOTTA',
        'PURPLE_TERRACOTTA',
        'BROWN_TERRACOTTA',
        'BLACK_TERRACOTTA',
        'LIGHT_GRAY_TERRACOTTA',
        'LIGHT_GRAY_TERRACOTTA',
        'LIGHT_GRAY_TERRACOTTA'));
}

proc _MS_antiBreak(@player) {
    @clicks = import("minesweeper.antibreak.@player");
    if (is_null(@clicks)) {
        @clicks = 0;
    }
    @clicks++;
    @max = 4;

    if (@clicks > @max) {
        @arena = _MS_getArena(@player);
        _MS_reset(@arena);
        msg(colorize('&4BZZT. &cYou have been kicked for attempted cheating\nDo not attempt to break the floor'));
    } else {
        msg(colorize('&4Do not break anything but snow and flowerpots\n&cContinued attempts will result in your match being cancelled'));
        export("minesweeper.antibreak.@player", @clicks);
    }
}

proc _MS_firstArena(@cfg) {
    for (@arena = 0, @arena < _MS_arenaCount(), @arena++) {
        @size = array_normalize(_MS_arenaSize(@arena));
        @custom = array(@cfg['x'], @cfg['z']);

        ## Temp - Have to allow for auto-orienting arenas first
        if (@custom[0] > @size[0] || @custom[1] > @size[1]) {
        #if(max(@custom) > max(@size) || min(@custom) > min(@size)) {
            continue();
        }

        @info = _MS_getInfo(@arena);
        if (!is_array(@info)) {
            return(@arena);
        }

        @player = @info['player'];
        if (!ponline(@player) || !array_contains_ic(sk_current_regions(@player), 'mine-whole')) {
            return(@arena);
        }
    }
    _error('There are no available arenas...');
}

proc _MS_explode(@arena, @info, @x, @y, @z) {
    _MS_clear_values(@arena);
    @time = round((time() - @info['time']) / 1000, 2);
    @elapse = _MS_timeString(@time);
    msg(colorize("&cUh-oh, boom time! &fTime elapsed: &c@elapse"));
    _MS_setBlock(@x, @y, @z, 'TNT');
    _MS_setBlock(@x, @y-1, @z, 'TNT');
}

###                   ###
### Inventory Manager ###
###                   ###

proc _MS_setInv(@info) {
    @player = @info['player'];
    @inv = associative_array();
    @inv[0] = array(name: 'FLOWER_POT', meta: array(display: colorize('&3Flag')));
    @inv[1] = _MS_invShovel();
    @inv[2] = null;
    @inv[3] = null;
    @inv[4] = null;
    @inv[5] = null;
    @inv[6] = null;
    @inv[7] = null;
    @inv[8] = _MS_invSnow(@info);
    set_pinv(@player, @inv);
}

proc _MS_updateInv(@info) {
    @player = @info['player'];
    @inv = associative_array();
    @inv[8] = _MS_invSnow(@info);
    set_pinv(@player, @inv);
}

proc _MS_invShovel() {
    @lore = array(
        colorize('&fRight-click a snow block to'),
        colorize('&fsee if it is a mine for a'),
        colorize('&b30 second time penalty')
    );
    return(array(name: 'GOLDEN_SHOVEL', meta: array(display: colorize('&3The Decider'), lore: @lore)));
}

proc _MS_invSnow(@info) {
    @cfg = @info['config'];
    @arena = @info['arena'];

    @snowLeft = _MS_getSnow(@arena) - @cfg['mines'];
    @snowQty = @snowLeft;
    if (@snowQty > 64) {
        @snowQty = 1;
    }

    return(array(name: 'SNOW_BLOCK', qty: @snowQty, meta: array(display: colorize("&3Remaining Snow: &b@snowLeft"))));
}

###                 ###
### Arena modifiers ###
###                 ###

proc _MS_getBlock(@x, @y, @z) {
    return(get_block(array(x:@x, y:@y, z:@z, world:'Event')));
}

proc _MS_setBlock(@x, @y, @z, @block) {
    set_block(array(x:@x, y:@y, z:@z, world:'Event'), @block);
}

## player_interact event - already cancelled before we get to this method
proc _MS_rightClick(@event) {
    ## Right-clicking with nothing does nothing
    if (is_null(@event['item'])) {
        return();
    }

    @player = @event['player'];
    @arena = _MS_getArena(@player);
    @info = _MS_getInfo(@arena);

    ## If the arena has not started, don't do anything
    if (@info['time'] == null) {
        return();
    }

    @loc = @event['location'];
    @x = integer(@loc['x']);
    @y = _MS_corner(@arena)[1] + 1; ## Snow layer Y
    @z = integer(@loc['z']);

    @holding = @event['item']['name'];
    @clicked = @event['block'];

    switch(@holding) {
    case 'FLOWER_POT':
        if (@clicked == 'SNOW_BLOCK' || @clicked == 'FLOWER_POT') {
            ## Toggle the flag
            _MS_toggleFlag(@x, @y, @z);
        }
        break();

    case 'GOLDEN_SHOVEL':
        if (@clicked == 'SNOW_BLOCK') {
            ## Remove a single shovel
            ptake_item(@player, array(name: @holding, qty: 1));

            ## 30 second penalty (subtract 30,000ms from start time)
            @info['time'] -= 30000;
             _MS_storeInfo(@info);

            @pos = _MS_grid_getpos(@info, @x, @z);
            if (_MS_isMine(@info, @pos[0], @pos[1])) {
                _MS_setBlock(@x, @y+1, @z, 'FLOWER_POT');
            } else {
                _MS_setBlock(@x, @y, @z, 'AIR');
                _MS_snowBroken(@arena, @info, @x, @y, @z);
            }
        }
        break();
    }
}

## x,y,z of the snow block
proc _MS_toggleFlag(@x, @y, @z) {
    @block =  _MS_getBlock(@x, @y+1, @z);
    switch(@block) {
    case 'AIR':
        @set = 'FLOWER_POT';
        break();
    default:
        @set = 'AIR';
        break();
    ## Have question mark equivalent?
    }
    _MS_setBlock(@x,@y+1,@z,@set);
}

proc _MS_snowBroken(@arena, @info, @x, @y, @z) {
    _MS_setBlock(@x, @y+1, @z, 'AIR');
    _MS_decreaseSnow(@arena);
    _MS_updateInv(@info);
    _MS_checkwin(@arena, true);
}

proc _MS_setFloor(@arena, @block, @adjust=0) {
    @c = _MS_corner(@arena);
    @size = _MS_arenaSize(@arena);
    @cx = @c[0];
    @cz = @c[2];

    @y = @c[1] + @adjust;
    for (@x = @cx, @x < @cx + @size['x'], @x++) {
        for (@z = @cz, @z < @cz + @size['z'], @z++) {
            _MS_setBlock(@x,@y,@z,@block);
        }
    }
}

proc _MS_colourField(@info, @xpos, @zpos) {
    @cfg = @info['config'];
    @gridx = @cfg['x'];
    @gridz = @cfg['z'];

    ## Arena settings
    @minesList = _MS_fieldMineList(@info);
    @c = _MS_gridCorner(@info);
    @y = @c[1];

    @lastx = @c[0] + @gridx;
    @lastz = @c[2] + @gridz;
    for (@x = @c[0], @x < @lastx, @x++) {
        for (@z = @c[2], @z < @lastz, @z++) {
            _MS_colourClay(@info, @minesList, @x, @y, @z);
        }
    }
}

proc _MS_colourClay(@info, @minesList, @x, @y, @z) {
    @block = _MS_getBlock(@x, @y, @z);
    ## Ignore already coloured blocks
    ## TODO better, as getting the block is probably a bottleneck
    if (@block != 'COAL_BLOCK') {
        return();
    }

    @cfg = @info['config'];
    @pos = _MS_grid_getpos(@info, @x, @z);
    @xpos = @pos[0];
    @zpos = @pos[1];

    @tntcount = @minesList[@xpos * @cfg['z'] + @zpos];
    ## Randomise the mine numbering a little. Still cheatable without it.
    if (_MS_isMine(@info, @xpos, @zpos)) {
        if (rand() < 0.6) {
            if (rand() < 0.6) {
                @tntcount -= 1;
            } else {
                @tntcount += 1;
            }
        }
    }

    @block = _MS_clayColours()[@tntcount];
    _MS_setBlock(@x, @y, @z, @block);
}

proc _MS_shuffleField(@info, @xpos, @zpos) {
    @minesList = _MS_fieldMineList(@info);

    @cfg = @info['config'];
    @gridx = @cfg['x'];
    @gridz = @cfg['z'];

    @clicked = @xpos * @gridz + @zpos;
    if (@minesList[@clicked] != 0) {

        @field = @info['field'];
        ## Search entire field for first 0, ignoring edges.
        for (@i = 1, @i < @gridx-1, @i++) {
            for (@j = 1, @j < @gridz-1, @j++) {
                @found = @i * @gridz + @j;
                if (@minesList[@found] != 0) {
                    continue();
                }

                @s = array_size(@field);

                @adjust = @found-@clicked;
                if (@adjust < 0) {
                    @adjust += @s;
                }
                @field = array_merge(@field[cslice(@adjust, @s-1)],
                                     @field[cslice(0, @adjust-1)]);
                break(2);
            }
        }

        @info['field'] = @field;
    }
    return(@info);
}
