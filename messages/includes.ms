#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

proc _pmessage(@receiver, @message, @isReply=false) {
    ## Async
    x_new_thread('msg', closure() {
        _pmessage_x(@receiver, @message, @isReply);
    });
}

## Internal async call
proc _pmessage_x(@receiver, @message, @isReply) {
    @sender = player();

    if (is_null(@receiver) || @receiver == '') {
        _error('You need to message someone before using /r');
    }

    if (to_lower(@receiver) != 'console' && @receiver != '~console') {
        @receiver = _autocomplete_player(@receiver, true);
        @uuid = puuid(@receiver);
        ## Don't allow new threads to vanished players
        if (!@isReply && get_metadata(@uuid, 'vanished', 'VanishNoPacket')) {
            _verify_staff('Specified player is offline. Please ensure their name is exact.');
        }
    } else {
        @receiver = '~console';
    }

    @lcsender = reg_replace('~', '', to_lower(@sender));
    @lcreceiver = reg_replace('~', '', to_lower(@receiver));

    ## Can't message yourself, fool.
    if (@lcsender == @lcreceiver) {
        _error('Maybe try messaging a friend instead of yourself');
    }

    ## Ignore lists
    @ignoreSender = _msg_getIgnoreList(@lcsender);
    @ignoreReceiver =  _msg_getIgnoreList(@lcreceiver);
    if (array_contains_ic(@ignoreSender, @lcreceiver)) {
        _error('You have this person ignored.');
    }

    @message = _msg_processColours(@sender, @message);
    msg(colorize("&5To @receiver: &d@message"));
    ## If the other players has them ignored, don't let them know
    if (!array_contains_ic(@ignoreReceiver, @lcsender)) {
        tmsg(@receiver, colorize("&5From @{sender}: &d@message"));
    }

    _msg_updateReplier(@lcsender, @lcreceiver);
    _socialspy(@sender, @receiver, @message);
}

proc _msg_getIgnoreList(@user) {
    @user = to_lower(@user);
    @list = get_value("pmessage.ignores.@user");
    if (!is_array(@list)) {
        @list = array();
    }
    return(@list);
}

proc _msg_setIgnoreList(@user, @list=array()) {
    @user = to_lower(@user);
    store_value("pmessage.ignores.@user", @list);
}

proc _msg_processColours(@sender, @message) {
    @message = colorize(reg_replace('&[lmnok]','',@message));
    if (!has_permission(@sender, 'ch_donor0')) {
        @message = strip_colors(@message);
    }
    return(@message);
}

proc _msg_updateReplier(@user1, @user2) {
    @user1 = to_lower(@user1);
    @user2 = to_lower(@user2);
    _export_store("pmessage.@user1", @user2);
    _export_store("pmessage.@user2", @user1);
}

proc _socialspy(@sender, @receiver, @message) {
    @ignored = _ss_is_ignored(@sender, @receiver);
    @message = strip_colors(@message);

    if (@ignored) {
        ## Change arrow colour and only send to console
        @message = colorize("&8@sender &4-> &8@receiver: @message");
        tmsg('~console', @message);
        return();
    }

    @message = colorize("&8@sender &5-> &8@receiver: @message");

    tmsg('~console', @message);
    foreach (@user in all_players()) {
        if (has_permission(@user, 'ch_staff') && @user != @sender && @user != @receiver) {
            @UUID = _UUID_player_altered(@user);
            if (_import_get("socialspy.@UUID")) {
                tmsg(@user, @message);
            }
        }
    }
}

proc _ss_ignore(@p1, @p2) {
    @uuid1 = _UUID_player_altered(@p1, true);
    @uuid2 = _UUID_player_altered(@p2, true);

    @key1 = "@{uuid1}@{uuid2}";
    @key2 = "@{uuid2}@{uuid1}";

    @ignored = _ss_is_ignored(@p1, @p2);
    if (@ignored) {
        @status = '&aun-ignored';
    } else {
        @status = '&cignored';
    }
    _export_store("socialignore.@key1", !@ignored);
    _export_store("socialignore.@key2", !@ignored);
    _bc_staff("&eSocialSpy messages between &6@p1 &eand &6@p2 &eare now @status");
}

proc _ss_is_ignored(@p1, @p2) {
    @uuid1 = _UUID_player_altered(@p1);
    @uuid2 = _UUID_player_altered(@p2);

    @key = "@{uuid1}@{uuid2}";
    return(_import_get("socialignore.@key") == true); # True check in-case it's null
}

proc _ss_clear_all() {
    _verify_op();
    foreach (@key in array_keys(get_values('socialignore.'))) {
        clear_value(@key);
    }
}
