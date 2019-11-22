#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

###                ###
### Ladder changes ###
###                ###

proc _ladder_list() {
    return(array('user', 'donor'));
}

proc _ladder_change(@player, @ladder) {
    if (!array_contains_ic( _ladder_list(), @ladder)) {
        _error('Unknown ladder. The only ladders we support are: '. _ladder_list());
    }

    if (has_permission(@player, 'ch_user3')) {
        @level = 3;
    }
    else if (has_permission(@player, 'ch_user2')) {
        @level = 2;
    }
    else if (has_permission(@player, 'ch_user1')) {
        @level = 1;
    }
    else {
        @level = 0;
    }

    @rank = @ladder. @level;
    runas('~console', "/permissions player @player settrack @ladder");
    runas('~console', "/permissions player @player setgroup @rank");
}

###          ###
### Requests ###
###          ###

proc _req_list(@level='all') {
    @reqs = get_value('promotion.requests');
    if (!is_array(@reqs)) {
        @reqs = array();
    }

    @finalReqs = @reqs;
    if (@level != 'all') {
        try(
            @finalReqs = @reqs[@level],
            @finalReqs = array()
        )
    }

    return(@finalReqs);
}

## Squash all leves into a 1D array of player names
proc _req_list_squash() {
    @squash = array();
    @list = _req_list();
    foreach (@level in array_keys(@list)) {
        @squash = array_merge(@squash, _UUID_array_to_username(@list[@level]));
    }
    return(@squash);
}

proc _req_list_size(@level='all') {
    @reqs = _req_list(@level);
    @count = 0;

    foreach(array_keys(@reqs), @index) {
        @count += array_size(@reqs[@index]);
    }

    return(@count);
}

proc _req_store(@player, @level) {
    @reqs = _req_list();
    @UUID = _UUID_player_altered(@player, true);

    if (!array_index_exists(@reqs, @level)) {
        @reqs[@level] = array();
    }

    ### Add UUID to the list for the given level
    @reqs[@level][] = @UUID;
    store_value('promotion.requests', @reqs);

    ### Store info about the request
    @info = array(name: @player, rank: _rank(@player), level: @level, ploc: ploc(@player), approvals: array(), time: time());
    _req_store_info(@UUID, @info);
}

proc _req_store_info(@UUID, @info) {
    store_value("promotion.info.@UUID", @info);
}

proc _req_info(@player) {
    @player = _autocomplete_player(@player, false, true);
    @UUID = _UUID_player_altered(@player, true);
    return(get_value("promotion.info.@UUID"));
}

proc _req_info_uuid(@UUID) {
    return(get_value("promotion.info.@UUID"));
}

### Using Essentials' mail as it's persistent until clearing.
#proc(_req_mail, @player, @msg) {
#    @UUID = _UUID_altered( _UUID_player_get(@player, true) )
#    store_value("promotion.mail.@UUID", @msg)
#}

### Requirements the player needs to progress to the next 'case' level ###
proc _req_requirements(@player, @nextRank) {

    for(@i = @nextRank, @i > 0, @i--) {
        switch(@i) {
            case 1:
                @regList = sk_current_regions();
                @ownerOrMem = false;
                foreach(@regList, @reg) {
                    if( array_contains_ic( sk_region_owners(@reg, pworld(@player))['players'], _UUID_player_get(@player)) ||
                        array_contains_ic( sk_region_members(@reg, pworld(@player))['players'], _UUID_player_get(@player)) ) {
                        @ownerOrMem = true;
                        break();
                    }
                }
                if(!@ownerOrMem) {
                    _error('You must be standing a region you own to submit a promotion request.');
                }

                break();
            case 2:
                break();
            case 3:
                break();
        }
    }

}

proc _req_getDeniedCount(@UUID) {
    @denied = get_value("promotion.deniedcount.@UUID");
    if (@denied == null || !is_integral(@denied)) { @denied = 0; }
    return(@denied);
}

proc _req_processApproval(@level, @UUID, @info) {
    if (!array_index_exists(@info, 'approvals')) {
        @info['approvals'] = array();
    }

    @staffUUID = _UUID_player_get(player());
    if (array_contains_ic(@info['approvals'], @staffUUID)) {
        _error('You have already given your approval for this player. Please get another staff to assist you.');
    }

    @info['approvals'][] = @staffUUID;

    ### 1 for a [1], 3 staff for a [2], 5 staff for a [3]
    @required = @level * 2 - 1;
    @remaining = @required - array_size(@info['approvals']);
    if (@remaining > 0) {
        _req_store_info(@UUID, @info);
        msg(colorize("&eApproval processed. &6This promotion request requires @remaining more staff approvals before the user is promoted."));
        die();
    }

    ### RobotoRaccoon must approve a 3, as well as all previous requirements
    if (@level >= 3 && !array_contains_ic(@info['approvals'], '7413ff56-ea0c-45dc-8c1d-e32b923e90a8')) {
        _req_store_info(@UUID, @info);
        msg(colorize("&eApproval processed. &6This promotion request requires RobotoRaccoon to approve before the user is promoted."));
        die();
    }
}

proc _req_firework(@player) {
    try(@ploc = ploc(@player), return())

    @loc1 = array(@ploc['x'] - 2, @ploc['y'], @ploc['z'] - 2, @ploc['world'])
    @loc2 = array(@ploc['x'] - 2, @ploc['y'], @ploc['z'] + 2, @ploc['world'])
    @loc3 = array(@ploc['x'] + 2, @ploc['y'], @ploc['z'] - 2, @ploc['world'])
    @loc4 = array(@ploc['x'] + 2, @ploc['y'], @ploc['z'] + 2, @ploc['world'])

    @fwork = array(strength:2, flicker:true, trail:true, colors:'YELLOW', fade:array('WHITE', 'FUCHSIA'), type:'BALL_LARGE')

    launch_firework(@loc1, @fwork)
    launch_firework(@loc2, @fwork)
    launch_firework(@loc3, @fwork)
    launch_firework(@loc4, @fwork)
}

proc _req_clear(@player) {
    @player = _autocomplete_player(@player, false, true); #No die, silent warning
    @reqs = _req_list();
    @info = _req_info(@player);
    @level = @info['level'];
    @UUID = _UUID_player_altered(@player, true);

    if (@info == null) {
        _error('This request does not exist.');
    }

    array_remove_values(@reqs[@level], @UUID);
    store_value('promotion.requests', @reqs);
    clear_value("promotion.info.@UUID");
}

###              ###
### Request bans ###
###              ###

proc _req_get_banlist() {
    @list = get_value('promotion.banned');
    if (!is_array(@list)) {
        @list = array();
    }
    return(@list);
}

proc _req_store_banlist(@list) {
    if (!is_array(@list)) {
        _error('The list must be an array. Please notify an operator.');
    }
    store_value('promotion.banned', @list);
}
