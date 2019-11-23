#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

## Notify online staff and send me a mail. This is called asynchronously.
proc _TH_notify(@player, @rg) {
    @last = import("trap_cooldown.@player.@rg");

    ## 45 seconds
    if (time() - @last < 45000) {
        die();
    }

    export("trap_cooldown.@player.@rg", time());

    foreach (@p in all_players()) {
        if (has_permission(@p, 'ch_staff')) {
            play_sound(ploc(@p), array(sound:'BLOCK_NOTE_BLOCK_HARP'), @p);
        }
    }

    @msg = "&c[&lTraphouse&r&c] &4@player &cis stealing from &4@rg";
    x_run_on_main_thread_later(closure() {
        _bc_janitor(@msg);
        runas('~console', "/mail send RobotoRaccoon @msg");
    });
}
