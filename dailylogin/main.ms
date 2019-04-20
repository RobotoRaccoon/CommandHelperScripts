#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon
bind(player_join, null, null, @e,
    include('dlProcs.ms');
    _dl_add(@e['player']);
)

