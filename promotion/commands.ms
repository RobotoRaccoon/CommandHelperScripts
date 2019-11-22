#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon
include('procs.ms');

#Added 12h cooldown. 2014-12-15. ~hug.
proc _promotion_submit(@player=player()) {
    @rank = _rank(@player);
    @UUID = _UUID_player_altered(@player, true);

    if (array_contains_ic(_req_get_banlist(), @UUID)) {
        _error('You are not allowed to make promotion requests. Please wait a week and submit a modreq and you might be unbanned.');
    }

    @cooldown = get_value("promotion.cooldown.@UUID");
    @cooldown = floor((@cooldown - time()) / 1000);
    if (@cooldown > 0) {
        @hours = floor(@cooldown / 3600);
        @minutes = floor(@cooldown%3600 / 60);
        @seconds = floor(@cooldown%60);
        _error("You cannot submit a request until the cooldown expires. You have @{hours}hrs, @{minutes}mins, and @{seconds}secs left to go.");
    }

    ### Assumes that all ranks have only one number in them (Or none for staff) ###
    if(reg_match('0', @rank)) {
        @nextRank = 1;
    }
    else if(reg_match('1', @rank)) {
        @nextRank = 2;
    }
    else if(reg_match('2', @rank)) {
        @nextRank = 3;
    }
    else if(reg_match('3', @rank)) {
        _error('You are already at the highest rank.');
    }
    else {
        _error('You are not a user or a donor, and thus cannot get promoted.');
    }

    ### Ensuring they do not already have a request.
    if (_req_info(@player) != null) {
        _error('You already have an outstanding request.');
    }

    _req_requirements(@player, @nextRank);
    _req_store(@player, @nextRank);

    msg(colorize("&6You have placed a request to be promoted to &e&lLevel @nextRank"));
    @staffMsg = colorize("&6A new promotion request has been filed by &e@{player}&6. Use /req for more info");
    _bc_janitor(@staffMsg);
}

proc _req_cmd_help(@page=1, @player=player()) {
    ### All commands go here if they are to show up in the help command.
    @commands = array('&5List &f> &dList all outstanding requests.');

    if (has_permission(@player, 'ch_janitor')) {
        @commands = array_merge(@commands, array(
            '&5TP &f> &dTeleport to a request location',
            '&5Info &f> &dView info of a request',
            '&5Approve &f> &dPromote the player',
            '&5Deny &f> &dSelf-explanatory',
            '&5Cancel &f> &dCancel the request silently',
            '&5Ban &f> &dStop someone from making requests',
            '&5Unban &f> &dInverse of Ban',
            '&5Banlist &f> &dView banned request makers',
            '&5Denies &f> &dView total denies for this level'
        ));
    }

    _page_vertical('Options', 'req help', @commands, @page, 5, @player);
}

proc _req_cmd_list(@rank) {
    @reqs = _req_list();
    @finalReqs = @reqs;
    @count = _req_list_size();

    msg(colorize("&b--------- @count Requests ---------"));
    if (@count == 0) {
        die(colorize('&6There are no requests right now.'));
    }

    if (!is_associative(@reqs)) {
        @finalReqs = associative_array();
        @finalReqs[@rank] = @reqs;
    }

    foreach(@key in array_keys(@finalReqs)) {
        if (array_size(@finalReqs[@key]) != 0) {
            msg(colorize("&e&lLevel @key: &6". array_implode( _UUID_array_to_username(@finalReqs[@key]), '&7, &6')));
        }
    }
}

proc _req_cmd_info(@player) {
    @info = _req_info(@player);
    if (!@info) {
        _error("No request found for @player");
    }

    @ploc = @info['ploc'];
    @loc = @ploc['world'].', '.floor(@ploc['x']).', '.floor(@ploc['y']).', '.floor(@ploc['z']);

    @approvals = array();
    foreach(@UUID in @info['approvals']) {
        @approvals[] = _UUID_usernames_lastname(@UUID);
    }

    @UUID = _UUID_player_altered(@info['name']);
    @denied = _req_getDeniedCount(@UUID);

    msg(colorize("&6Username: &e". @info['name']));
    msg(colorize("&6Location: &e@loc"));
    msg(colorize("&6Current Rank: &e". @info['rank']));
    msg(colorize("&6Next Level: &e". @info['level']));
    msg(colorize("&6Approved By: &e@approvals"));
    msg(colorize("&6Submitted: &e". _time_to_datediff(@info['time'])));
    msg(colorize("&6Denied count: &e@denied"));
}

proc _req_cmd_teleport(@player) {
    @player = _autocomplete_player(@player, false, true);
    @info = _req_info(@player);
    if (!@info) {
        _error("No request found for @player");
    }

    msg(colorize('&6Teleporting to &e'. @info['name']. '&6...'));
    set_ploc(@info['ploc']);
    pfacing(@info['ploc']['yaw'], @info['ploc']['pitch']);
}

proc _req_cmd_approve(@player, @msg) {
    _no_console();
    @player = _autocomplete_player(@player, false, true); #No die, silent warning
    @reqs = _req_list();
    @info = _req_info(@player);
    @UUID = _UUID_player_altered(@player, true);

    if (@info == null) {
        _error('This request does not exist.');
    }

    if (!reg_match('\\d', @info['rank'])) {
        _error('This user cannot be promoted. Please deny their request instead.');
    }

    ### Janitors can only do level 1.
    @level = @info['level'];
    if (@level != 1) {
        _verify_staff('Sorry, only staff can promote people above level 1.');
    }

    ### Process an approval, may exit the command if not enough approvals are present
    _req_processApproval(@level, @UUID, @info);

    ### Pre-conditions met, go and promote ###

    ### @ladder : Assumes user0, user1, donor3, etc.
    ### Ladder names are USER and DONOR.
    @ladder = reg_replace('\\d', '', @info['rank']);
    runas('~console','/promote '. @info['name']. ' '. @ladder);

    array_remove_values(@reqs[@level], @UUID);
    store_value('promotion.requests', @reqs);
    clear_value("promotion.info.@UUID");
    clear_value("promotion.deniedcount.@UUID");

    @msg = '&e[&6Promotion&e] '. @info['name']. " &6has been promoted to &e&lLevel @level";
    _bc(@msg);
    _req_firework(@player);
}

proc _req_cmd_deny(@player, @msg) {
    @player = _autocomplete_player(@player, false, true); #No die, silent warning
    @reqs = _req_list();
    @info = _req_info(@player);
    @UUID = _UUID_player_altered(@player, true);

    @level = @info['level'];
    @denied = _req_getDeniedCount(@UUID);

    if (@level == 1 && @denied >= 8) {
        _error('I think it''s about time for a pity promote to level 1...\nAny further levels do not get a pity promote. This is because level 1 is considered a "regular"');
    }

    if (length(@msg) < 20) {
        _error('Supply a reason - reasons must be at least 20 characters');
    }

    _req_clear(@player);

    ### Cooldown until user can submit a new request. ###
    @denied++;
    @delay = time() + @denied * 43200000;
    store_value("promotion.deniedcount.@UUID", @denied);
    store_value("promotion.cooldown.@UUID", @delay);

    ### Staff messaging ###
    @staffMsg = colorize("&e&lLevel @level &6promotion request for &e". @info['name']. ' &6was &cdenied &6by '. player());
    _bc_janitor(@staffMsg);

    ### Player messaging ###
    @personalMsg = colorize('&e[&6Promotion&e] &6Sorry, your build was not up to standard.');
    if (@msg) {
        @personalMsg = @personalMsg. colorize(' The responder left the comment: &e"'. @msg. '"');
    }

    run("/mail send @player @personalMsg");
    if (ponline(@info['name'])) {
        tmsg(@player, @personalMsg);
#    } else {
#        msg(colorize('&cPlayer offline; Sending the denied messages to them in a mail.'));
#        _req_mail(@player, @personalMsg);
    }
}

proc _req_cmd_denies(@player) {
    @player = _autocomplete_player(@player);
    @UUID = _UUID_player_altered(@player, true);
    @denied = _req_getDeniedCount(@UUID);
    msg(colorize("&6Username: &e@player"));
    msg(colorize("&6Denied count: &e@denied"));
}

proc _req_cmd_cancel(@player) {
    _req_clear(@player);
    msg(colorize("&eCleared the request for &6@player"));
}

proc _req_cmd_ban(@player) {
    @list = _req_get_banlist();
    @player = _autocomplete_player(@player);
    @UUID = _UUID_player_altered(@player, true);

    if (array_contains_ic(@list, @UUID)) {
        _error('This player is already banned from filing promotion requests.');
    }

    @list[] = @UUID;
    _req_store_banlist(@list);

    ## Staff messaging
    @staffMsg = colorize("&e@player &6has been banned from filing promotion requests.");
    _bc_janitor(@staffMsg);
}

proc _req_cmd_unban(@player) {
    @list = _req_get_banlist();
    @player = _autocomplete_player(@player);
    @UUID = _UUID_player_altered(@player, true);

    if (!array_contains_ic(@list, @UUID)) {
        _error('This player is not banned from filing promotion requests.');
    }

    array_remove_values(@list, @UUID);
    _req_store_banlist(@list);

    ## Staff messaging
    @staffMsg = colorize("&e@player &6has been unbanned from filing promotion requests.");
    _bc_janitor(@staffMsg);
}

proc _req_cmd_banlist(@page=1) {
    @list = _req_get_banlist();
    @players = array();

    foreach(@UUID in @list) {
        @players[] = _UUID_usernames_lastname(@UUID);
    }
    _paginate('Promotion bans', @players, @page);
}

proc _req_cmd_resetall() {
    _verify_op();
    @all = get_values('promotion');
    @keys = array_keys(@all);
    foreach (@key in @keys) {
        msg(colorize("&6Clearing &e@key..."));
        clear_value(@key);
    }
    @size = array_size(@keys);
    msg(colorize("&6Cleared &e@size &6keys"));
}
