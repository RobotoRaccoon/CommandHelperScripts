#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### Main proc to test if it's a new day
proc _dl_add(@player) {
    @UUID = _UUID_player_altered(@player);

    @update = _dl_checkUpdate(@UUID);
    if (!@update) {
        ### Don't need to update, return no change
        return(false);
    }

    _dl_updateLast(@UUID);
    _dl_updateConsecutive(@UUID);

    @con = _dl_getConsecutive(@UUID);
    @amount = _dl_getPayout(@con);

    set_timeout(2000, closure() {
        _dl_addAmount(@player, @amount, @con);
    });

    return(true);
}

proc _dl_getPayout(@con) {
    ### Base rates for 7 weeks, 1 week, 1 day
    if (@con % 49 == 0) {
        @amount = 50;
    }
    else if (@con % 7 == 0) {
        @amount = 10;
    }
    else {
        @amount = 5;
    }

    @today = _dl_getToday();
    if (@today == 18255) { ### 2019-12-25
        @amount += 100;
    }

    return(@amount);
}

##
# Check if the consecutive count needs to update for a player. Resets the counts if more than one day has elapsed
# @param UUID UUID of the player
# @return True if the player hasn't logged in today
#
proc _dl_checkUpdate(@UUID) {
    @diff = _dl_getDiff(@UUID);
    if (@diff <= 0) {
        ### Don't do anything, we haven't progressed a day
        return(false);
    }

    if (@diff > 1) {
        ### Didn't log in for a whole day, reset
        _dl_resetConsecutive(@UUID);
    }

    return(true);
}

proc _dl_getDiff(@UUID) {
    @lastLogin = _dl_getLast(@UUID);
    @today = _dl_getToday();
    @diff = @today - @lastLogin;
    return(@diff);
}

proc _dl_addAmount(@player, @amount, @con) {
    acc_add(@player, @amount);
    tmsg(@player, colorize("&a$@amount has been added to your account for logging in today"));
    if (@con > 1) {
        tmsg(@player, colorize("&aYou have logged in for @con consecutive days!"));
    }
}

proc _dl_checkConsecutive(@UUID) {
    _dl_checkUpdate(@UUID);
    return(_dl_getConsecutive(@UUID));
}

proc _dl_cmd_top(@page) {
    ## Call asynchronously
    x_new_thread('dailylogin.top', closure() {
        _dl_cmd_top_x(@page, 'top');
    });
}

proc _dl_cmd_current(@page) {
    ## Call asynchronously
    x_new_thread('dailylogin.current', closure() {
        _dl_cmd_top_x(@page, 'current');
    });
}

proc _dl_cmd_top_x(@page, @cmd) {
    @top = _dl_topList(@cmd == 'top');

    @perpage = 8;
    @maxpage = ceil(array_size(@top) / @perpage);
    if (!is_numeric(@page) || @page < 1 || @page > @maxpage) {
        @page = 1;
    }

    msg(colorize('&e-- &cDaily login &fleaderboard &e--'));
    for (@i = 0, @i < @perpage, @i++) {

        @pos = (@page - 1) * @perpage + @i;
        @realpos = @pos + 1;

        if(array_size(@top) > @pos) {
            @info = @top[@pos];
            @player = _UUID_usernames_lastname(@info['uuid']);
            @count = @info['count'];
            @current = @info['streak'];
            msg(colorize("&e@realpos. &5@player&f: @count days &7&o(current: @current)"));
        } else {
            msg(colorize("&e@realpos. &cN/A"));
        }
    }
    msg(colorize("&6Page &e@page/@maxpage&6. View more with &e/dailylogin @cmd <page>"));
}

proc _dl_topList(@best) {
    @saved = "dailylogin.top.@best";
    @top = import(@saved);

    ### Reset every 6 minutes
    if (is_array(@top)) {
        if (time() - 360000 < @top['time']) {
            return(@top['list']);
        }
    }

    @list = array();
    @values = get_values('dailylogin.best'); ### Everyone who has a streak
    foreach (@key : @value in @values) {
        @UUID = split('.', @key)[2];
        @count = _dl_getBest(@UUID);
        @streak = _dl_checkConsecutive(@UUID);
        if (@count > 1) {
            @list[] = array(uuid: @UUID, count: @count, streak: @streak);
        }
    }

    if (@best) {
        @key = 'count';
    } else {
        @key = 'streak';
    }
    array_sort(@list, closure(@left, @right) {
        return(@left[@key] < @right[@key]);
    });

    @top = array(time: time(), list: @list);
    export(@saved, @top);

    return(@list);
}

###           ###
### Get & Set ###
###           ###

proc _dl_getToday() {
    @hours = floor(time()/3600000) + 10; ### Milliseconds to hours since 1970-01-01 00:00:00 (UTC+10)
    @today = floor(@hours/24); ### Convert to days
    return(@today);
}

proc _dl_getLast(@UUID) {
    @lastLogin = _import_get("dailylogin.last.@UUID");
    if (!is_numeric(@lastLogin)) {
        @lastLogin = 0;
    }
    return(@lastLogin);
}

proc _dl_setLast(@UUID, @day) {
    _export_store("dailylogin.last.@UUID", @day);
}

proc _dl_updateLast(@UUID) {
    _dl_setLast(@UUID, _dl_getToday());
}

proc _dl_getConsecutive(@UUID) {
    @con = _import_get("dailylogin.consecutive.@UUID");
    if (is_null(@con) || !is_numeric(@con) || @con < 0) {
        @con = 0;
    }
    return(@con);
}

proc _dl_updateConsecutive(@UUID) {
    @count =  _dl_getConsecutive(@UUID) + 1;
    _export_store("dailylogin.consecutive.@UUID", @count);
    _dl_updateBest(@UUID, @count);
}

proc _dl_resetConsecutive(@UUID) {
    export("dailylogin.consecutive.@UUID", null);
    clear_value("dailylogin.consecutive.@UUID");
}

proc _dl_getBest(@UUID) {
    @best = _import_get("dailylogin.best.@UUID");
    if (is_null(@best) || !is_numeric(@best) || @best < 0) {
        @best = _dl_getConsecutive(@UUID);
    }
    return(@best);
}

proc _dl_updateBest(@UUID, @count) {
    @previous = _import_get("dailylogin.best.@UUID");
    if (@count > @previous) {
        _export_store("dailylogin.best.@UUID", @count);
    }
}

