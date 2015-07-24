#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon

### The help command.
proc _shops_help(@page=1, @player=player()) {
    
    ### All commands go here if they are to show up in the help command.
    @commands = array(
            '&5Help &f> &dShows all available commands.',
            '&5About &f> &dUseful information.',
            '&5All &f> &dShow all shops, sorted by likes.',
            '&5List &f> &dList random shops from categories.',
            '&5TP &f> &dTeleport to a shop number.',
            '&5Info &f> &dShow all information about a shop.',
            '&5Like &f> &dGive a shop some reputation.',
            '&5Buy &f> &dBuy a shop teleport.',
            '&5Edit &f> &dAdjust settings or pay rent.',
            '&5Remove &f> &dDelete your shop.';
        );

    ### Find the maximum amount of pages and ensure that the page selected is within the bounds, else set it to 1.
    @perpage = 5;
    @maxpage = ceil( array_size(@commands) / @perpage );
    if( !is_numeric(@page) || @page < 1 || @page > @maxpage )  {
        @page = 1;
    }

    ### Prints all the @commands from the selected page. The try() is in case there are not 5 on that page.
    tmsg(@player, colorize(' &7===== &5Options &7====='));
    for(@i = 0, @i < @perpage, @i++) {
        try(;
            tmsg(@player, colorize(@commands[@i + @perpage * (@page - 1)]) );
           );
    }
    tmsg(@player, colorize("&6Page &e@{page}/@{maxpage}&6. View more with &e/shop help <page>"));
}

###              ###
### Buy / Remove ###
###              ###

proc _shops_perday() { return(25); } ### Upkeep
proc _shops_purchase() { return(250); } ### Initial payment

### Buy a shop yo!
proc _shops_buy(@shop) {
    if( reg_count( '0', _rank(player()) ) > 0 ) {
        _error('You need to be at least a [1] to make a shop.');
    }

    if( _shops_has_info(@shop) && _shops_active(@shop) ) {
        _error('A player already owns this shop number.');
    }

    if( @shop > 9999 ) {
        _error('You cannot purchase a shop number above 9999.');
    }
    
    ### Check they have enough dosh, and prep the 7 free days of upkeep.
    @cost = _shops_purchase();
    @freepay = _shops_perday() * 7;
    if( acc_balance(player()) < @cost ) {
        _error("You need at least $@cost to buy a shop.");
    }

    ### Clear from categories, in case it was an expired shop before purchase.
    foreach( _shops_cat_list(), @cat ) {
        _shops_cat_off(@shop, @cat, true);
    }

    ### Clear TP history, for reason above.
    _shops_tphistory_clear(@shop);

    ### Take away their cash, and set up their shop.
    @UUID = _UUID_player_get(player());
    @info = _shops_generate_info(@UUID, ploc(), @freepay, time());
    acc_subtract(player(), @cost);
    _shops_store_info(@shop, @info);
    msg(colorize("&6You have successfully purchased &eShop @shop &6and have received 7 days rent free."));
    msg(colorize("&6Use the &e/Shop Edit &6command to add more money into your account."));
}

### Add money to a shop's balance.
proc _shops_addbalance(@shop, @money) {
    @info = _shops_get_info(@shop);
    if( !is_integral(@money) || @money < 1 ) {
        _error('You may only deposit whole dollars.');
    }

    if( acc_balance(player()) < @money ) {
        _error('You do not have enough money in your account.');
    }

    ### Means they ran out of rent.
    if( !_shops_active(@shop) ) {
        #_error("Sorry, but you have ran out of money in your account. You need to re-purchase a shop.")
        @info['balance'] = 0;
        @info['time'] = time();
    }

    ### Adds money to the "balance"
    @info['balance'] += @money;
    acc_subtract(player(), @money);
    _shops_store_info(@shop, @info);
    msg(colorize("&6You have added &e$@money &6to your shop's balance..."));
}

### Remove a shop
proc _shops_remove(@shop, @silent=false, @force=false) {
    @info = _shops_get_info(@shop);

    ### Only allow the owner or staff to remove shops.
    if( _UUID_player_get(player()) != @info['owner'] && !@force ) {
        _verify_staff('You do not own this shop.');
    }

    ### Fail-safe
    if( !import("shops.failsafe.@shop") && !@force ) {
        msg(colorize("&4Warning: &cYou are about to remove &4shop @shop&c.\nTo remove the shop, run the same command again."));
        export("shops.failsafe.@shop", true);
        die();
    }

    ### Clear from categories
    foreach( _shops_cat_list(), @cat ) {
        _shops_cat_off(@shop, @cat, true);
    }
    clear_value("shops.info.@shop");
    export("shops.info.@shop", null);
    export("shops.failsafe.@shop", null);

    if( !@silent ) {
        msg(colorize("&6Successfully removed Shop &e@{shop}&6..."));
    }
}

###          ###
### Teleport ###
###          ###

### Teleport to a shop, allowing use of Essentials' /back.
proc _shops_teleport(@shop, @silent=false) {
   
    ### Get a random shop if required
    @random = false;
    if( to_lower(@shop) == 'random' ) {
        @random = true;
        @list = array_keys(get_values('shops.info.'));
        for(@i = 0, @i < 5, @i++) {
            @shop = split('.', @list[array_rand(@list)[0]])[2];
            if( _shops_active(@shop) ) {
                break();
            }
        }
    }

    if( !_shops_active(@shop) ) {
        _error('The owner has not paid their rent!');
    }

    @self = player();
    @info = _shops_get_info(@shop);
    _teleport_bannedblocks(@info['ploc']); ### Check that the destination is not a death-trap.
    sudo("/tpo @self"); ### Force an essentials /back position.
    set_ploc(@self, @info['ploc']);
    pfacing(@info['ploc']['yaw'], @info['ploc']['pitch']);

    _shops_tphistory_add(@shop, _UUID_player_get(@self), @random);

    if( !@silent ) {
        @owner = _UUID_usernames_lastname(@info['owner']);
        msg(colorize("&6Teleporting to &e@{owner}&6's Shop @shop..."));
    }
}

###             ###
### Information ###
###             ###

### @shop = integer > 0
### @info = array(owner: UUID, ploc: ploc, balance: money, time: time(), likes: array(UUID))

### Store the information for a shop.
proc _shops_store_info(@shop, @info) {

    ### Simple error checking that should in theory never show up.
    if( !is_integral(@shop) || @shop <= 0 || @shop[0] == 0) {
        _error("'@shop' is not an integer, or is less than 1.");
    }
    if( !is_associative(@info) ) {
        _error("'@info' must be an associative array.");
    }

    _export_store("shops.info.@shop", @info);
}

### Generate the @info array.
proc _shops_generate_info(@UUID, @ploc, @money, @time=time(), @likes=array()) {
    _teleport_bannedblocks(@ploc); ### Testing if teleport location is legal.
    return( array(owner: @UUID, ploc: @ploc, balance: @money, time: @time, likes: @likes) );
}

### Get the information for a shop.
proc _shops_get_info(@shop) {
    if( !_shops_has_info(@shop) ) {
        _error("Shop '@shop' not found.");
    }
    return( _import_get("shops.info.@shop") );
}

### Check if a shop has information (i.e, exists).
proc _shops_has_info(@shop) {
    if( !is_integral(@shop) || @shop <= 0 || @shop[0] == 0) {
        _error("'@shop' is not an integer, or is less than 1.");
    }
    return( _import_get("shops.info.@shop") != null );
}

### Check if a person has enough money in their shop account.
proc _shops_active(@shop) {
    @daysleft = _shops_daysLeft(@shop);

    if( @daysleft <= 0 ) {
        _shops_expire_alert(@shop);
        return(false);
    } else {
        return(@daysleft);
    }
}

proc _shops_daysLeft(@shop) {
    @info = _shops_get_info(@shop);
    @hourdiff = round((time() - @info['time'])/3600000) ### Hours since they purchased the shop, rounded.
    @balance = @info['balance'];
    
    return(@balance/_shops_perday() - @hourdiff/24);
}

### Print the info
proc _shops_print_info(@shop) {
    @info = _shops_get_info(@shop);
    @owner = _UUID_usernames_lastname(@info['owner']);
    @purchased = simple_date('MMMM dd, yyyy', @info['time']);

    ### How many days left on their rent before someone else can claim it.
    @daysleft = _shops_daysLeft(@shop);
    if( @daysleft <= 0) {
        @status = "&cEXPIRED";
    } else {
        if( @daysleft >= 1 ) {
            @days = ceil(@daysleft);
            @status = "&a@days days left";
        }
        else {
            @hours = ceil(@daysleft*24);
            @status = "&a@hours hours left";
        }
    }

    ### Categories which this shop is a part of.
    @cats = array();
    foreach(@cat in _shops_cat_list()) {
        if( array_contains_ic( _shops_cat_get(@cat), @shop) ) {
            @cats[] = @cat;
        }
    }

    ### How many likes this shop has.
    @likes = array_size(@info['likes']);

    ### Rating
    @rating = _shops_rating(@shop, @info);

    msg(colorize(" &7===== &5Shop @shop &7====="));
    msg(colorize("&6Owner: &e@owner"));
    msg(colorize("&6Purchased: &e@purchased"));
    msg(colorize("&6Status: &e@status"));
    msg(colorize("&6Categories: &e@cats"));
    msg(colorize("&6Likes: &e@likes"));
    msg(colorize("&6Rating: &e@rating"));
}

###            ###
### Categories ###
###            ###

### @categories = array('Animals', 'Building', 'Food', 'Mining', 'Potions', 'Redstone', 'Tools', 'Weapons', 'Other')

### Get categories.
proc _shops_cat_list() {
    return( array('Animals', 'Building', 'Food', 'Mining', 'Potions', 'Redstone', 'Tools', 'Weapons', 'Other') );
}

### Check if supplied category is valid.
proc _shops_cat_check(@cat) {
    if( !array_contains_ic( _shops_cat_list(), @cat ) ) {
        _error("'@cat' is not a valid category in: ". _shops_cat_list());
    }
}

### Get list of shops in a category.
proc _shops_cat_get(@category) {
    @category = to_lower(@category);
    _shops_cat_check(@category);

    @list = get_value("shops.cat.@category");
    if( !is_array(@list) ) {
        @list = array();
    }

    return(@list);
}

### Toggle category on a shop.
proc _shops_cat_toggle(@shop, @category) {
    if( !_shops_has_info(@shop) ) {
        _error("Shop '@shop' not found.");
    }
    
    @list = _shops_cat_get(@category);
    if( array_contains_ic(@list, @shop) ) {
        _shops_cat_off(@shop, @category);
    } else {
        _shops_cat_on(@shop, @category);
    }
}

proc _shops_cat_off(@shop, @category, @silent=false) {
    @list = _shops_cat_get(@category);
    array_remove_values(@list, @shop);
    @lowcat = to_lower(@category);
    store_value("shops.cat.@lowcat", @list);
    
    if( !@silent ) {
        msg(colorize("&6Removed Shop &e@shop &6from category &e@category"));
    }
}

proc _shops_cat_on(@shop, @category, @silent=false) {
    @list = _shops_cat_get(@category);
    @list[] = @shop;
    @lowcat = to_lower(@category);
    store_value("shops.cat.@lowcat", @list);

    if( !@silent ) {
        msg(colorize("&6Added Shop &e@shop &6to category &e@category"));
    }
}

###       ###
### Likes ###
###       ###

### Toggle like on a shop.
proc _shops_likes_toggle(@shop, @UUID) {
    @info = _shops_get_info(@shop);
    @UUID = _UUID_unaltered(@UUID);
    @likes = @info['likes'];

    if( !is_array(@likes) ) {
        @likes = array();
    }

    if( array_contains_ic(@likes, @UUID) ) {
        array_remove_values(@likes, @UUID);
        msg(colorize("&6You have unliked &eShop @shop"));
    } else {
        array_push(@likes, @UUID);
        msg(colorize("&6You have liked &eShop @shop"));
    }

    @info['likes'] = @likes;
    _shops_store_info(@shop, @info);
}

### Prints the most likes shops, in page form.
proc _shops_likes_descending(@page=1) {
    @list = array_keys(get_values('shops.info.'));

    ### This is the ugliest method. But how do I do it better?
    # Just want a sorted array of shop numbers to send into pagination func. eg {1, 46, 27, 99, ...}

    ### Generates an array like: {40: {1, 99}, 0:{2, 3, 4}} where the index is the amount of likes.
#    @sorted = associative_array()
#    foreach(@shop in @list) {
#        @shop = split('.', @shop)[2]
#        @likes = array_size( _shops_get_info(@shop)['likes'] )
#        
#        try( @likeslist = @sorted[@likes],
#             @likeslist = array())
#
#        array_push(@likeslist, @shop)
#        @sorted[@likes] = @likeslist
#    }
#
#    ### Mashes the former array into a single assorted array, descending in likes.
#    @list = array()
#    @keys = array_sort(array_keys(@sorted), 'NUMERIC')
#    array_reverse(@keys)
#    foreach(@key in @keys) {
#        @list = array_merge(@list, @sorted[@key])
#    }

    ### HugglyBuggly fixed the above commented section yay.
    @shoparray = array();

    #Build array of shopnumbers.
    foreach (@shop in @list) {
        @shop = split('.',@shop)[2];
        array_push(@shoparray,@shop);
    }

    #Sort array by getting its number of likes.
    #@list = array_sort(@shoparray,
    #    closure(@left,@right){
    #            return( array_size(_shops_get_info(@left)['likes']) < array_size(_shops_get_info(@right)['likes']));
    #    }
    #);

    @list = array_sort(@shoparray,
        closure(@left,@right){
                return( _shops_rating(@shop, _shops_get_info(@left)) < _shops_rating(@shop, _shops_get_info(@right)));
        }
    );

    ### Pagination section.
    @perpage = 8;
    @maxpage = ceil( array_size(@list) / @perpage );
    if( !is_numeric(@page) || @page < 1 || @page > @maxpage )  {
        @page = 1;
    }

    msg(colorize("&6Showing you &eAll shops &6sorted by rating"));
    for(@i = 0, @i < @perpage, @i++) {
        try(;
            @shop = @list[@i + @perpage * (@page - 1)];
            _shops_printline(@shop);
           );
    }
    msg(colorize("&6Page &e@{page}/@{maxpage}&6. View more with &e/shop all <page>"));
}

###            ###
### Other Junk ###
###            ###

### Multi-line pagination
proc _shops_paginate(@title, @list, @split=false) {
    ### Make the first letter a capital.
    @title = to_upper(substr(@title, 0, 1)). to_lower(substr(@title, 1));

    msg(colorize("&6Showing you random shops from &e@title"));
    @size = array_size(@list);

    ### Loops a max of 8 times, or the size of the list, ignoring expired shop.
    @i = 0;
    while( @i < min(@size, 8) ) {
        
        try(
            @id = rand(array_size(@list)),
            @id = 0;
        )
        try(@shop = @list[@id],
            break();
        )
        array_remove_values(@list, @shop);
        
        if( @split ) { ### Split is for when it is "All Shops", as the supplied array is database keys.
            @shop = split('.', @shop)[2];
        }

        if( _shops_active(@shop) ) {
            _shops_printline(@shop);
            @i++;
        }
    }
}

### Prints a single line for the pagination and likes_descending functions.
proc _shops_printline(@shop) {

    @info = _shops_get_info(@shop);
    @owner = _UUID_usernames_lastname(@info['owner']);
    #@likes = array_size(@info['likes']);
    @active = _shops_active(@shop);

    @rating = _shops_rating(@shop, @info);

    ### Display normally, or in red if shop is expired.
    if( @active ) {
        msg(colorize("&5Shop @shop &dby &5@owner &7&o(Rating: @rating)"));
    } else {
        msg(colorize("&4&mShop @shop &c&mby &4&m@owner&7&o (Rating: @rating)"));
    }
}

proc _shops_expire_alert(@shop) {
    @info = _shops_get_info(@shop);
    @UUID = _UUID_altered( @info['owner'] );
    
    ### Delete shop outright if less than 5 likes, or expired over 20 days ago
    x
    if( (array_size(@info['likes']) < 5) || (_shops_daysLeft(@shop) < -20) ) {
        _shops_remove(@shop, true, true);
    } else {
        store_value("shops.expirenotify.@UUID", @shop);
    }
}

proc _shops_tphistory_add(@shop, @UUID, @random=false) {
    _shops_tphistory_clearall(); ### Test to see if scores need clearing.
    if(@random) {
        return();
    }


    @list = get_value("shops.tphistory.@shop");
    if(!is_array(@list)) {
        @list = associative_array();
    }

    if(array_index_exists(@list, @UUID)) {
        @list[@UUID] += 1;
    } else {
        @list[@UUID] = 1;
    }

    store_value("shops.tphistory.@shop", @list);
}

proc _shops_tphistory_clear(@shop) {
    clear_value("shops.tphistory.@shop");
}

proc _shops_tphistory_score(@shop) {
    @list = get_value("shops.tphistory.@shop");
    @score = 0;

    if(is_array(@list)) {
        foreach(@UUID: @count in @list) {
            if(@count > 1) {
                @score++;
            }
        }
    }

    return(@score);
}

proc _shops_tphistory_clearall() {
    @lastClear = get_value("shops.historylastcleared");
    if(!is_integral(@lastClear)) {
        @lastClear = 0;
    }

    @daysSinceLastClear = floor((time() - @lastClear) / 86400000);
    @dayOfMonth = integer(simple_date('d'));

    if(@dayOfMonth == 1 || (@dayOfMonth < 10 && @daysSinceLastClear > 31)) {
        store_value("shops.historylastcleared", time());
        foreach(@key in array_keys(get_values("shops.tphistory."))) {
            clear_value(@key);
        }
    }

}

proc _shops_rating(@shop, @info) {
    @likes = array_size(@info['likes']);
    @TPScore = _shops_tphistory_score(@shop);
    @daysSincePurchase = floor((time() - @info['time']) / 86400000);

    @rating = floor(***This information is hidden***);
    return(@rating);
}
