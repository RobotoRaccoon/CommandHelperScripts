#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon

### Used for namespace storing, hyphens are not allowed in namespaces.
proc _UUID_altered(@UUID) {
    return( reg_replace('-', '_', @UUID) );
}

### Reverse _UUID_altered.
proc _UUID_unaltered(@UUID) {
    return( reg_replace('_', '-', @UUID) );
}

### Get the last seen UUID of a player.
proc _UUID_player_get(@player=player(), @die=true) {
    @player = to_lower(@player);
    @UUID = _import_get("uuid.player.@player");

    if( @UUID == null && @die ) {
        _error('This player has not logged in since UUID tracking started.');
    }

    return(@UUID);
}

### Set the last seen UUID for a username
proc _UUID_player_set(@player, @UUID) {
    @player = to_lower(@player);
    if( _UUID_player_get(@player) != @UUID ) {
        _export_store("uuid.player.@player", @UUID);
    }
}

### Get all usernames associated with a UUID.
proc _UUID_usernames_list(@UUID, @die=true) {
    @alteredUUID = _UUID_altered(@UUID);
    @nameList = get_value('uuid.usernames', @alteredUUID);
    
    if( @nameList == null && @die ) {
        _error('This UUID has no associated usernames.');
    }

    return(@nameList);
}

### Add another username to the list for a UUID. -- Earliest username in first index.
proc _UUID_usernames_add(@UUID, @player) {
    @nameList = _UUID_usernames_list(@UUID);
    @alteredUUID = _UUID_altered(@UUID);
    if( @nameList == null ) {
        @nameList = array();
    }

    if( !array_contains_ic(@nameList, @player) ) {
        array_push(@nameList, @player);
        store_value("uuid.usernames.@alteredUUID", @nameList);
    }
}

### Completely re-write the usernames list. Use with caution. ie, not in anything but /onlineuuid
#proc _UUID_usernames_set(@UUID, @nameList) {
#    @alteredUUID = _UUID_altered(@UUID)
#    if( !is_array(@nameList) || array_size(@nameList) == 0 ) {
#        _error('Cannot run _UUID_usernames_set() with an empty list.')
#    }
#
#    @oldList = _UUID_usernames_list(@UUID)
#    store_value("uuid.usernames.@alteredUUID", @nameList)
#    console(colorize("&4Warning: &cCH username list for &4@UUID &coverwritten. | Old list &7@oldList &c| New list &7@nameList"))
#}

### Get the last username used by a specific UUID.
proc _UUID_usernames_lastname(@UUID) {
    @nameList = _UUID_usernames_list(@UUID);
    return( @nameList[array_size(@nameList) - 1] );
}

### Get all other usernames by supplying a username.
proc _UUID_alternate_accounts(@player) {
    return( _UUID_usernames_list( _UUID_player_get(@player) ) );
}

### Transform a normal array of UUIDs into player names.
proc _UUID_array_to_username(@UUIDs) {
    @players = array();
    foreach(@UUID in @UUIDs) {
        array_push(@players, _UUID_usernames_lastname(@UUID));
    }

    return(@players);
}

### Transform a normal array of player names into UUID.
proc _UUID_array_to_UUID(@players) {
    @UUIDs = array();
    foreach(@player in @players) {
        array_push(@UUIDS, _UUID_player_get(@player));
    }

    return(@UUIDS);
}
