#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

include('staffkitProcs.ms');

_register_tabcomp_cmd('staffkit', closure() {
    return(_staffkit_getKitList());
});
_register_tabcomp_cmd('sk', closure() {
    return(_staffkit_getKitList());
});
