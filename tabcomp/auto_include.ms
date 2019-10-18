#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

## For use by any external script
proc _register_tabcomp_cmd(@cmd, @callback) {
    if (!instanceof(@callback, closure)) {
        @callback = closure() { return(all_players()); }
    }

    try(unregister_command(@cmd));
    register_command(@cmd, array());

    # (alias, player, arguments, command_info, <code>)
    set_tabcompleter(@cmd, closure(@a, @p, @args, @c) {
        return(_TC_suggest(@cmd, @args, @callback));
    });
}

### Internal use only below ###

proc _TC_suggest(@cmd, @args, @callback) {
    ## Run the callback
    @possible = _TC_processCallback(@cmd, @callback);

    ## Get last argument (The one to tabcomplete)
    @partial = to_lower(@args[array_size(@args) - 1]);

    ## Empty? Then everything is a match
    if (@partial == '') {
        return(@possible);
    }

    @matches = array();
    foreach (@check in @possible) {
        @match = to_lower(@check);

        ## Currently matches any position ('!= -1')
        ## Change to '== 0' to match only starting characters
        if (string_position(@match, @partial) != -1) {
            ## Pushing to front of array if the first characters match
            if (substr(@match, 1) == substr(@partial, 1)) {
                array_insert(@matches, @check, 0);
            } else {
                @matches[] = @check;
            }
        }
    }
    return(@matches);
}

## Cache the results for 5 seconds server-side.
## Only useful for commands where we suggest a single array
## no matter the argument (Which is currently all of them anyway...)
proc _TC_processCallback(@cmd, @callback) {
    @cooldown = 5000; # 5 seconds
    @cache = import("tabcomp_cache.@cmd");

    if (is_array(@cache) && (time() - @cache['time'] < @cooldown)) {
        @list = @cache['list'];
    } else {
        @list = execute(@callback);
        export("tabcomp_cache.@cmd", array(time: time(), list: @list));
    }

    return(@list);
}

