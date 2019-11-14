#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

proc _ride_mobs() {
    ## http://wiki.sk89q.com/wiki/CommandHelper/Staged/API/entities_in_radius
    return(array('WITHER_SKULL','GUARDIAN','MUSHROOM_COW','SHULKER_BULLET','MINECART_COMMAND','WITHER','SKELETON','MINECART_FURNACE','FIREBALL','PIG_ZOMBIE','DRAGON_FIREBALL','MINECART_TNT','ENDERMAN','COW','MINECART_HOPPER','GHAST','IRON_GOLEM','SPIDER','SHULKER','ARMOR_STAND','GIANT','SNOWMAN','CREEPER','PIG','SMALL_FIREBALL','CAVE_SPIDER','SNOWBALL','MINECART_CHEST','RABBIT','CHICKEN','BOAT','MAGMA_CUBE','MINECART','HORSE','SQUID','OCELOT','ENDER_DRAGON','ENDER_CRYSTAL','BLAZE','VILLAGER','ENDERMITE','WOLF','SILVERFISH','SLIME','ZOMBIE','BAT','SHEEP','MINECART_MOB_SPAWNER','WITCH', 'POLAR_BEAR', 'CAT', 'FOX', 'PANDA'));
}

proc _ride_getMobID() {
    @IDs = entities_in_radius(pcursor(), 3, _ride_mobs());
    if (array_size(@IDs) == 0) {
        _error('Can\'t find a rideable mob');
    }
    return(@IDs[0]);
}

proc _ride_spawnMobID(@mob) {
    @mobs = _ride_mobs();
    if (!array_contains_ic(@mobs, @mob)) {
        _error("That's not a supported mob type (@mob)");
    }

    _ride_assertRegion();
    @ploc = ploc();
    @ploc['y'] += 1;
    try {
        @entID = spawn_entity(@mob, 1, @ploc)[0];
    } catch (Exception @e) {
        _error('Couldn\'t spawn that mob for some reason...');
    }
    return(@entID);
}

proc _ride_assertRegion() {
    @regions = sk_current_regions();
    foreach (@region in @regions) {
        @flags = sk_region_info(@region, pworld())[3];
        if (array_contains_ic(@flags, '{mob-spawning, DENY}')) {
            _error('This region has mob-spawning denied');
        }
    }
}

proc _ride_rideID(@player, @entID) {
    @playerID = pinfo(@player,13);
    set_entity_rider(@playerID, null);

    try {
        set_entity_rider(@entID, @playerID);
    } catch (Exception @e) {
        _error('Something went wrong. Try looking at the block the mob is standing on...');
    }
}

proc _ride_carryID(@player, @entID) {
    @playerID = pinfo(@player,13);
    set_entity_rider(@playerID, null);

    try {
        set_entity_rider(@playerID, @entID);
    } catch (Exception @e) {
        _error('Something went wrong. Try looking at the block the mob is standing on...');
    }
}
