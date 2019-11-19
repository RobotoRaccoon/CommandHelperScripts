#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

include('shopsProcs.ms');

## /shop help [page]
proc _shops_cmd_help(@page=1, @player=player()) {

    ### All commands go here if they are to show up in the help command.
    @commands = array(
            #'&5Help &f> &dShows all available commands',
            '&5About &f> &dUseful information',
            '&5All &f> &dShow all shops, sorted by rating',
            '&5List &f> &dList random shops from categories',
            '&5TP &f> &dTeleport to a shop number',
            '&5Info &f> &dShow all information about a shop',
            '&5Like &f> &dGive a shop some reputation',
            '&5Buy &f> &dBuy a shop teleport',
            '&5Edit &f> &dAdjust settings or pay rent',
            '&5Remove &f> &dDelete your shop'
        );

    _page_vertical('Options', 'shop help', @commands, @page, 5, @player);
}

## /shop about
proc _shops_cmd_about() {
    @cost = _shops_purchase();
    @upkeep = _shops_perday();
    @cats = _shops_cat_list();

    msg(colorize(" &7===== &5About Shops &7====="));
    msg(colorize("&eShops &6is a CommandHelper script written by &5RobotoRaccoon&6. \n&7Rank 1 users and above can purchase a shop warp for &e$@cost&7, with an additional daily upkeep cost of &e$@upkeep&7. Upon purchase, every user is given &e7 days &7of free upkeep. Add more funds to a shop with the &e/Shop Edit &7command. Shops also feature a range of toggleable categories which can be viewed more easily by using &e/Shop List <Category>&7. Available categories include: &e@cats&7. \n&7For more information visit&e http://wiki.mcau.org/help/shop"));
}

## /shop tp <id>
## Teleport to a shop, allowing use of Essentials' /back.
proc _shops_cmd_teleport(@shop, @silent=false) {

    ### Get a random shop if required
    @random = false;
    if (to_lower(@shop) == 'random') {
        _error('Random teleports disabled for spam');
        #@random = true;
        #@list = array_keys(get_values('shops.info.'));
        #for (@i = 0, @i < 5, @i++) {
        #    @shop = split('.', @list[array_rand(@list)[0]])[2];
        #    if( _shops_active(@shop) ) {
        #        break();
        #    }
        #}
    }

    if (!_shops_active(@shop)) {
        _error('The owner has not paid their rent!');
    }

    @self = player();
    @info = _shops_get_info(@shop);
    @ploc = @info['ploc'];

    if (@ploc == null) {
        _error("This shop does not have a location set...");
    }

    _teleport_bannedblocks(@ploc); ## Check that the destination is not a death-trap.
    sudo("/tpo @self"); ## Force an essentials /back position.
    set_ploc(@self, @ploc);
    pfacing(@ploc['yaw'], @ploc['pitch']);

    _shops_tphistory_add(@shop, _UUID_player_get(@self), @random);

    if (!@silent) {
        @owner = _UUID_usernames_lastname(@info['owner']);
        msg(colorize("&6Teleporting to &e@{owner}&6's Shop @shop..."));
    }
}

## /shop info <id>
proc _shops_cmd_info(@shop) {
    @info = _shops_get_info(@shop);
    @owner = _UUID_usernames_lastname(@info['owner']);
    @purchased = simple_date('MMMM dd, yyyy', @info['time']);

    ## How many days left on their rent before someone else can claim it.
    @daysleft = _shops_daysLeft(@shop); #float
    @days = abs(ceil(@daysleft));
    @hours = abs(ceil(@daysleft*24));

    if (@daysleft <= -2) {
        @status = "&cEXPIRED (@days days ago)";
    }
    else if (@daysleft <= 0) {
        @status = "&cEXPIRED (@hours hours ago)";
    }
    else if (@daysleft > 1) {
        @status = "&a@days days left";
    }
    else {
        @status = "&a@hours hours left";
    }

    ## Categories which this shop is a part of.
    ## TODO also store locally in the array
    @cats = array();
    foreach (@cat in _shops_cat_list()) {
        if (array_contains_ic(_shops_cat_get(@cat), @shop)) {
            @cats[] = @cat;
        }
    }

    @rating = _shops_rating(@shop, @info);

    msg(colorize(" &7===== &5Shop @shop &7====="));
    msg(colorize("&6Owner: &e@owner"));
    msg(colorize("&6Purchased: &e@purchased"));
    msg(colorize("&6Status: &e@status"));
    msg(colorize("&6Categories: &e@cats"));
    msg(colorize("&6Rating: &e@rating"));

    ## Staff and owner only info below
    if (_UUID_player_get(player()) != @info['owner'] && !has_permission('ch_staff')) {
        die();
    }
    @likes = array_size(@info['likes']);
    @ploc = @info['ploc'];
    @coords = 'x:'.floor(@ploc['x']). ' y:'.floor(@ploc['y']). ' z:'.floor(@ploc['z']);

    msg(colorize("&5Likes: &d@likes"));
    msg(colorize("&5Location: &d@coords"));

    ## Staff only info below
    if (!has_permission('ch_staff')) {
        die();
    }
    @TPScore = _shops_tphistory_score(@shop);
    msg(colorize("&4TP Score: &c@TPScore"));
}

## /shop like <id>
proc _shops_cmd_like(@shop) {
    @info = _shops_get_info(@shop);
    @UUID = puuid();
    @likes = @info['likes'];

    if (!is_array(@likes)) {
        @likes = array();
    }

    if (array_contains_ic(@likes, @UUID)) {
        array_remove_values(@likes, @UUID);
        msg(colorize("&6You have unliked &eShop @shop"));
    } else {
        @likes[] = @UUID;
        msg(colorize("&6You have liked &eShop @shop"));
    }

    @info['likes'] = @likes;
    _shops_store_info(@shop, @info);
}

## /shop buy <id>
proc _shops_cmd_buy(@shop) {
    if (reg_count( '0', _rank(player()) ) > 0) {
        _error('You need to be at least a [1] to make a shop.');
    }

    if (_shops_has_info(@shop) && _shops_active(@shop)) {
        _error('A player already owns this shop number.');
    }

    if (@shop > 9999) {
        _error('You cannot purchase a shop number above 9999.');
    }

    ## Check they have enough dosh, and prep the 7 free days of upkeep.
    @cost = _shops_purchase();
    @freepay = _shops_perday() * 7;
    if (acc_balance(player()) < @cost) {
        _error("You need at least $@cost to buy a shop.");
    }

    ## Clear from categories, in case it was an expired shop before purchase.
    foreach (_shops_cat_list(), @cat) {
        _shops_cat_off(@shop, @cat, true);
    }

    ## Clear TP history, for reason above.
    _shops_tphistory_clear(@shop);

    ## Take away their cash, and set up their shop.
    @UUID = _UUID_player_get(player());
    @info = _shops_generate_info(@UUID, ploc(), @freepay, time());
    acc_subtract(player(), @cost);
    _shops_store_info(@shop, @info);
    msg(colorize("&6You have successfully purchased &eShop @shop &6and have received 7 days rent free."));
    msg(colorize("&6Use the &e/Shop Edit &6command to add more money into your account."));
}

## /shop remove <id>
proc _shops_cmd_remove(@shop) {
    _shops_remove(@shop, false, false);
}

## /shops list <cat|all>
proc _shops_cmd_list(@cat) {
    if (@cat == 'all') {
        ## All shops
        @list = _shops_allShops();
        _shops_paginate('All shops', @list);
    }
    else {
        ## Specific category
        @list = _shops_cat_get(@cat);
        _shops_paginate(@cat, @list);
    }
}

## /shop all [page]
proc _shops_cmd_all(@page=1) {
    ## Sort by rating
    @list = _shops_getSorted();

    ## Pagination section
    @perpage = 8;
    @maxpage = ceil( array_size(@list) / @perpage );
    if (!is_numeric(@page) || @page < 1 || @page > @maxpage) {
        @page = 1;
    }

    msg(colorize("&6Showing you &eAll shops &6sorted by rating"));
    for (@i = 0, @i < @perpage, @i++) {
        try(
            @shop = @list[@i + @perpage * (@page - 1)];
            ,
            break();
        );
        _shops_printline(@shop);
    }
    msg(colorize("&6Page &e@{page}/@{maxpage}&6. View more with &e/shop all <page>"));
}

proc _shops_cmd_edit(@p2, @p3, @p4) {
    @info = _shops_get_info(@p2);
    if (_UUID_player_get(player()) != @info['owner']) {
        _verify_staff('You do not own this shop.');
    }

    switch(@p3) {
    case '':
    case 'help':
        msg(colorize(" &7===== &5/Shop edit @p2 &7====="));
        msg(colorize("&5Cat &f> &dToggle categories for your shop."));
        msg(colorize("&5Pay &f> &dAdd more money into your account."));
        msg(colorize("&5TP &f> &dSet the teleport location."));

    case 'cat':
    case 'category':
        if (@p4 == '') {
            _error("/shop edit @p2 @p3 <category>. Available categories:\n". _shops_cat_list());
        }
        _shops_cat_toggle(@p2, @p4);

    case 'pay':
        _no_console();
        if (@p4 == '') {
            _error("/shop edit @p2 @p3 <amount>");
        }
        _shops_addbalance(@p2, @p4);

    case 'tp':
    case 'teleport':
    case 'warp':
        _no_console();
        _teleport_bannedblocks(ploc());
        @info['ploc'] = ploc();
        _shops_store_info(@p2, @info);
        msg(colorize("&6Updated the teleport location for &eShop @{p2}&6..."));

    case 'setowner':
        _verify_staff();
        if (@p4 == '') {
            _error("/shop edit @p2 @p3 <newPlayer>");
        }
        @newOwner = _autocomplete_player(@p4);
        @info['owner'] = _UUID_player_get(@newOwner);
        _shops_store_info(@p2, @info);
        msg(colorize("&6Set the new owner for &eShop @p2 &6to &e@newOwner"));
    }
}

