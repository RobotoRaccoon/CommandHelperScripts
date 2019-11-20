## @RobotoRaccoon

bind('projectile_launch', null, array(type: 'ARROW', shootertype: 'PLAYER'), @e) {
    ## Ensure it is an arrow
    if (@e['type'] != 'ARROW') {
        die();
    }

    ## Ensure it is a player
    @player = @e['player'];
    if (!@player) {
        die();
    }

    @bow = pinv(@player, null);
    #{meta: {damage: 0, display: Bow of Flight, enchants: {feather_falling: {elevel: 10, etype: PROTECTION_FALL}}, flags: {}, lore: {I want to fly away...}, repair: 0, unbreakable: false}, name: BOW, qty: 1}

    ## Ensure name is correct
    if (!is_array(@bow) || @bow['meta'] == null || @bow['meta']['display'] != '§bBow of Flight') {
        die();
    }

    ## Ensure it has the enchantment
    if (@bow['meta']['enchants'] == null || @bow['meta']['enchants']['feather_falling']['elevel'] != 10) {
        die();
    }

    ## Validation passed, process flight
    cancel();
    @playerID = pinfo(@player, 13);
    @ploc = ploc(@player);
    @ploc[1] += 2;
    @ploc['y'] = @ploc[1];

    ## Spawn arrow, set no damage, set rider, set direction
    spawn_entity('ARROW', 1, @ploc, closure(@id) {
        set_arrow_damage(@id, 0);
        set_entity_rider(@id, @playerID);
        set_entity_velocity(@id, @e['velocity']);
    });
}

## Global dismount - may need to stricten if other things conflict
bind('projectile_hit', null, null, @e) {
    set_entity_rider(@e['id'], null);
}

add_recipe(
    array(
        key: 'flight_bow',
        type: 'SHAPELESS',
        ingredients: array('FEATHER', 'BLAZE_ROD', 'BOW'),
        result: array(
            name: 'BOW',
            qty: 1,
            enchants: array(array(etype: 'PROTECTION_FALL', elevel: 10)),
            meta: array(display: '§bBow of Flight', lore: array('§7I want to fly away...'))
        )
    )
);
