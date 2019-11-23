#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon
include('includes.ms');

bind('block_break', null, null, @e) { x_new_thread('trapbreak.'.rand(), closure() {
    @loc = @e['location'];
    @rgs = sk_regions_at(array(@loc['x'],@loc['y'],@loc['z']));

    if (array_size(@rgs) < 1) {
        die();
    }

    foreach (@key : @info in get_values('traphouse.info.')) {
        if (array_contains(@rgs, @info['rg'])) {
            _TH_notify(@e['player'], @info['rg']);
        }
    }
})}
