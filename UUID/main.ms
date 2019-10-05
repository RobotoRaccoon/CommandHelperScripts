#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### @RobotoRaccoon

_register_tabcomp_cmd('uuid');

bind('player_join', null, null, @event) {
    @player = @event['player'];
    @UUID = pinfo(@player, 20);

    ## Run asynchronously, not really sure how much it'll help. A few DB queries at least.
    x_new_thread("uuid.@UUID", closure() {
        ## Store last used UUID for player name.
        _UUID_player_set(@player, @UUID);

        ## First time joining? Just add and return.
        @nameList = _UUID_usernames_list(@UUID, false);
        if (@nameList == null || array_size(@nameList) == 0) {
            _UUID_usernames_add(@UUID, @player);
            die();
        }

        ## UUID checker against previous usernames.
        if (_UUID_usernames_lastname(@UUID) != @player) {
            @nameList[] = @player;
            _bc_janitor("&4Warning: &cName change detected for &4@UUID");
            _bc_janitor('&cUsernames: &6'. array_implode(@nameList, '&7, &6'));
            #console(colorize("&4Warning: &cUUID match found other usernames for &4@UUID &c| Usernames: &6". array_implode(@nameList, '&7, &6')));

            _UUID_usernames_add(@UUID, @player);
        }
    });
}

