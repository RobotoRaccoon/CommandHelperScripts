#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

_register_tabcomp_cmd('shop', closure() {
    return(_shops_allShops());
});

include('shopsProcs.ms');

bind('player_join', null, null, @e) {
    @UUID = _UUID_player_altered(player());
    @shop = get_value("shops.expirenotify.@UUID"); ## Ugly method but eh. Only an issue if they have more than one expired shop.

    if (@shop && is_numeric(@shop) && !_shops_active(@shop)) {
        try(set_timeout(5000, closure() {
            tmsg(player(), colorize("&4Notice: &cYour shop &4@shop&c has run out of rent. Please fill it up with the &4/shop edit &ccommand."));
            play_sound(ploc(), array(sound:'BLOCK_NOTE_BLOCK_HARP'), player());
            clear_value("shops.expirenotify.@UUID");
        }))
    }
}
