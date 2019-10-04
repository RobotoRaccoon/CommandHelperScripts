#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### @RobotoRaccoon
include('dlProcs.ms');

bind('player_join', null, null, @e) {
    _dl_add(@e['player']);
}

