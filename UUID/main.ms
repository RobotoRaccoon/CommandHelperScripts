#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon

bind(player_join, null, null, @event, 

    @player = @event['player'];
    @UUID = puuid(@player);

    ### Store last used UUID for player name.
    _UUID_player_set(@player, @UUID);

    ### UUID checker against previous usernames.
    @nameList = _UUID_usernames_list(@UUID);
    if( @nameList == null ) {
        _UUID_usernames_add(@UUID, @player);
        die();
    }
    
    if( !array_contains_ic(@nameList, @player) ) {
        array_push(@nameList, @player);
        _bc_janitor("&4Warning: &cUUID match found other usernames for &4@UUID");
        _bc_janitor('&cUsernames: &6'. array_implode(@nameList, '&7, &6'));
        console(colorize("&4Warning: &cUUID match found other usernames for &4@UUID &c| Usernames: &6". array_implode(@nameList, '&7, &6')));
        
        _UUID_usernames_add(@UUID, @player);
    }
);
