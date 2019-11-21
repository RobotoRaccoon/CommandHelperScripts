#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

proc _wg_assertLimit() {
    @limits = array(
        user0: 5,
        user1: 10,
        user2: 20,
        user3: 35,
        donor0: 15,
        donor1: 20,
        donor2: 30,
        donor3: 50,
        janitor: 100,
        alumni: 100, op: 0);

    @rank = _rank();
    if (!array_index_exists(@limits, @rank)) {
        _error('Your rank does not support region claims. Staff are to use /rg define');
    }

    ## Get region count in all worlds
    @count = 0;
    foreach (@world in get_worlds()) {
        @rg = _userregions(player(), @world);
        @count += array_size(@rg['owner']);
    }

    ## Limit checking
    @limit = @limits[@rank];
    if (@count >= @limit) {
        _error("You have already maxed out your claim limit (@count/@limit). See /myregions for a list of regions");
    }
}

proc _wg_assertSize(@p1, @p2) {
    if (!is_array(@p1) || !is_array(@p2)) {
        _error('You must have a selection with //wand first! See /rhelp for help');
    }

    @size  = integer(abs(@p1[0] - @p2[0]) + 1);
    @size *= integer(abs(@p1[1] - @p2[1]) + 1);
    @size *= integer(abs(@p1[2] - @p2[2]) + 1);

    @limit = 200000;
    if (@size > @limit) {
        _error("Your selection is too large. (Larger than 200,000 blocks)");
    }
}

proc _wg_assertBorders(@p1, @p2) {
    if (!is_array(@p1) || !is_array(@p2)) {
        _error('You must have a selection with //wand first! See /rhelp for help');
    }

    ## Border checking
    # Assumes world is centered on 0,0
    @world = pworld();
    @wb = get_world_border(@world);
    @border = @wb['width'] / 2;
    if (abs(@p1[0]) > @border ||
        abs(@p1[2]) > @border ||
        abs(@p2[0]) > @border ||
        abs(@p2[2]) > @border) {

        _error('Region claims must be within the world border');
    }
}

proc _wg_assertIntersection(@p1, @p2, @rg) {
    if (!is_array(@p1) || !is_array(@p2)) {
        _error('You must have a selection with //wand first! See /rhelp for help');
    }

    @temp = player().'-'.time();
    sk_region_create(@temp, array(@p1, @p2));
    @intersects = sk_region_intersect(pworld(), @temp);
    sk_region_remove(@temp);

    ## Will always intersect with the original region
    array_remove_values(@intersects, @rg);
    if (array_size(@intersects) > 0) {
        _error("Your region selection intersects with existing region(s): @intersects");
    }
}
