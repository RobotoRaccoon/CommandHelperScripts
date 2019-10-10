#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon ###
include('includes.library/includes.ms');
include('includes.library/commands.ms');

bind('player_interact', null, null, @event,
    if (pworld() != 'Event' || !array_contains_ic(sk_regions_at(ploc()), 'mine-whole')) {
        die();
    }

    @player = @event['player'];
    if(!_MS_isPlaying(@player)) {
        die();
    }

    @arena = _MS_getArena(@player);
    @y = _MS_corner(@arena)[1];
    @validBlock = array_contains(array('SNOW_BLOCK', 'FLOWER_POT'), @event['block']);
    if (@event['action'] == 'left_click_block' && !@validBlock) {
        @clicks = import("minesweeper.cheatclicks.@player");
        if (is_null(@clicks)) {
            @click = 0;
        }
        @clicks++;
        @max = 3;

        if(@clicks > @max) {
            @arena = _MS_getArena(@player);
            _MS_reset(@arena);
            msg(colorize('&4BZZT. &cYou have been kicked for attempted cheating. Do not attempt to break the floor.'));
        } else {
            msg(colorize("&cDo not break anything but snow and flowerpots. Continued breakage will result in your match being cancelled."))
            export("minesweeper.cheatclicks.@player", @clicks);
        }

        cancel();
    }
    else if(@event['action'] == 'right_click_block' && @validBlock) {
        @loc = @event['location'];
        _MS_toggleFlag(@loc['x'], @y+1, @loc['z']);
        cancel();
    }
)

bind('block_break', null, null, @event,
    if(pworld() != 'Event') {
        die()
    }

    @loc = @event['location']
    if(!array_contains_ic(sk_regions_at(@loc), 'mine-snow')) {
        die();
    }

    @player = @event['player'];
    if(!_MS_isPlaying(@player)) {
        cancel()
        _error('You are not currently playing.')

    }

    @block = @event['block'];
    @validBlock = array_contains(array('SNOW_BLOCK', 'FLOWER_POT'), @block);
    if(!@validBlock) {
        cancel();
        die();
    }

    if(@block != 'SNOW_BLOCK') {
        die();
    }

    @x = integer(@loc['x']);
    @y = integer(@loc['y']);
    @z = integer(@loc['z']);

    @arena = _MS_getArena(@player);
    @info = _MS_getInfo(@arena);
    @field = @info['field'];
    @pos = _MS_grid_getpos(@info, @x, @z);
    @xpos = @pos[0];
    @zpos = @pos[1];

    ### If this is the first break
    if(_MS_getSnow(@arena) == array_size(@field)) {
        @info = _MS_shuffleField(@info, @xpos, @zpos);

        ### Colour the rest of the field
        _MS_colourField(@info, @xpos, @zpos);

        @info['time'] = time(); ### Start time now
        _MS_storeInfo(@info);
    }

    if(_MS_isMine(@info, @xpos, @zpos)) {
        cancel();
        _MS_explode(@arena, @info, @x, @y, @z);
    } else {
        #_MS_setBlock(@x, @y, @z, 'AIR');
        _MS_decreaseSnow(@arena);
        _MS_updateInv(@info);
        _MS_checkwin(@arena, true);
    }
)

bind('block_place', null, null, @event,
    if(pworld() != 'Event') {
        die();
    }

    @loc = @event['location'];
    if(!array_contains_ic(sk_regions_at(@loc), 'mine-snow')) {
        die();
    }

    @player = @event['player'];
    if(!_MS_isPlaying(@player)) {
        cancel();
        _error('You are not currently playing.');
    }

    @cy = _MS_corner(_MS_getArena(@player))[1];
    @block = @event['block'];
    @against = @event['against'];
    if(@loc['y'] != @cy + 2 || @block != 'FLOWER_POT' || @against != 'SNOW_BLOCK') {
        cancel();
        _error('You can only place flower pots on snow.')
    }
)

###                         ###
### Shouldn't need to touch ###
###                         ###

bind('inventory_click', null, null, @event) {
    if (pworld() != 'Event' || !array_contains_ic(sk_regions_at(ploc()), 'mine-whole')) {
        die();
    }

    @player = @event['player'];
    if(_MS_isPlaying(@player)) {
        cancel();
    }
}

bind('item_held', null, null, @event) {
    if (pworld() != 'Event' || !array_contains_ic(sk_regions_at(ploc()), 'mine-whole')) {
        die();
    }

    @player = @event['player'];
    if(_MS_isPlaying(@player)) {
        modify_event('to', 0);
    }
}

bind('player_teleport', null, null, @event) {
    @player = @event['player'];
    if (@player == null || pworld(@player) != 'Event' || !array_contains_ic(sk_regions_at(ploc(@player)), 'mine-whole')) {
        die();
    }

    @player = @event['player'];
    if (_MS_isPlaying(@player)) {
        cancel();
        _error('You cannot teleport out of minesweeper. Blow yourself up or /mines quit');
    }
}

bind('player_quit', null, null, @event) {
    if(_MS_isPlaying(@event['player'])) {
        @arena = _MS_getArena(@event['player']);
        _MS_clear_values(@arena);
    }
}

