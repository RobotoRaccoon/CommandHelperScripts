#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

# ns   = Namespace to use (e.g. 'dwarp', 'promotion')
# key  = Key to store the info (e.g. An altered UUID)
# loc  = An associative array of the location. (e.g. That of `ploc()`)

proc _WL_get(@ns, @key) {
    @loc = get_value("warplib.@ns.@key");
    if (is_array(@loc) && is_associative(@loc)) {
        return(@loc);
    } else {
        return(null);
    }
}

proc _WL_exists(@ns, @key) {
    return(has_value("warplib.@ns.@key"));
}

proc _WL_store(@ns, @key, @loc) {
    if (!is_associative(@loc)) {
        _error('Invalid array: Must be associative');
    }
    store_value("warplib.@ns.@key", @loc);
}

proc _WL_remove(@ns, @key) {
    clear_value("warplib.@ns.@key");
}

proc _WL_values(@ns) {
    return(get_values("warplib.@ns."));
}

proc _WL_keys(@ns) {
    return(array_keys(_WL_values(@ns)));
}

proc _WL_keyNames(@ns) {
    @keys = _WL_keys(@ns);
    @names = array();
    foreach (@key in @keys) {
        @names[] = split('.', @key, 2)[2];
    }
    return(@names);
}

proc _WL_teleport(@ns, @key, @safeCheck=true, @error=true) {
    _no_console();

    if (!_WL_exists(@ns, @key)) {
        _error('This location does not exist');
    }

    @loc = _WL_get(@ns, @key);

    ## Only test banned blocks if we're doing the check
    @unsafe = @safeCheck && _teleport_bannedblocks(@loc, false, false);
    if (@unsafe) {
        if (pmode() != 'SURVIVAL') {
            msg(colorize("&4Warning: &cThis teleport location is unsafe, but you're not in survival mode. Teleporting anyway..."));
        }
        else if (@error) {
            _error('This warp destination is unsafe');
        }
        else {
            return(false);
        }
    }

    ## Perform the teleport, utilising Essentials' /back
    @self = player();
    runas('~console', "/tp @self @self");
    set_ploc(@loc);
    pfacing(@loc['yaw'], @loc['pitch']);

    return(true);
}
