#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

include('procs.ms');

_register_tabcomp_cmd('req', closure() {
    return(_req_list_squash());
});

#bind('player_join', null, null, @e,
#    @player = to_lower(@e['player'])
#    @UUID = _UUID_altered( _UUID_player_get(@player) )
#    @msg = get_value("promotion.mail.@UUID")
#
#    if( @msg ) {
#        set_timeout(2000, closure(
#            tmsg(@player, colorize(@msg))
#            clear_value("promotion.mail.@UUID")
#        ))
#    }
#)

## 5 minute notifier if a request is open.
set_interval(300000, 1000, closure() {

    ## Hacky touble timeout, so as to ignore the first closure
    set_timeout(50, closure() {
        if (_req_list_size() > 0) {
            ## Intentionally not _bc_janitor - don't want it going to #staff
            broadcast(colorize("&aA promotion request is still open, view with &2/req list"), 'ch_janitor');
        }
    });
})
