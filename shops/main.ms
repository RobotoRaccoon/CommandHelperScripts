#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon

bind(player_join, null, null, @e,
    @UUID = _UUID_altered( _UUID_player_get(player()) );
    @shop = get_value("shops.expirenotify.@UUID"); ### Ugly method but eh. Only an issue if they have more than one expired shop.

    include('shopsProcs.ms');
    if( @shop && is_numeric(@shop) && !_shops_active(@shop) ) {
        try(set_timeout(5000, closure(
            tmsg(player(), colorize("&4Notice: &cYour shop &4@shop&c has run out of rent. Please fill it up with the &4/shop edit &ccommand."));
            play_sound(ploc(), array(sound:NOTE_PIANO), player());
            clear_value("shops.expirenotify.@UUID");
        )))
    }
);
