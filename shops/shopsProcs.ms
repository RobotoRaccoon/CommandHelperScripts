#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### @RobotoRaccoon

###              ###
### Buy / Remove ###
###              ###

proc _shops_perday() { return(25); } ### Upkeep
proc _shops_purchase() { return(250); } ### Initial payment

### Add money to a shop's balance.
proc _shops_addbalance(@shop, @money) {
    @info = _shops_get_info(@shop);
    if (!is_integral(@money) || @money < 1) {
        _error('You may only deposit whole dollars.');
    }

    if (acc_balance(player()) < @money) {
        _error('You do not have enough money in your account.');
    }

    ### Means they ran out of rent.
    if (!_shops_active(@shop)) {
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
    if (_UUID_player_get(player()) != @info['owner'] && !@force) {
        _verify_staff('You do not own this shop.');
    }

    ### Fail-safe
    if (!import("shops.failsafe.@shop") && !@force) {
        msg(colorize("&4Warning: &cYou are about to remove &4shop @shop&c.\nTo remove the shop, run the same command again."));
        export("shops.failsafe.@shop", true);
        die();
    }

    ### Clear from categories
    foreach (_shops_cat_list(), @cat) {
        _shops_cat_off(@shop, @cat, true);
    }
    clear_value("shops.info.@shop");
    export("shops.info.@shop", null);
    export("shops.failsafe.@shop", null);

    if (!@silent) {
        msg(colorize("&6Successfully removed Shop &e@{shop}&6..."));
    }

    _shops_sortShops();
}

proc _shops_remove_all() {
    _verify_op();
    @vals = array_keys(get_values("shops"));
    foreach (@val in @vals) {
        clear_value(@val);
        msg("Removed @val");
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
    if (!is_integral(@shop) || @shop <= 0 || @shop[0] == 0) {
        _error("'@shop' is not an integer, or is less than 1.");
    }
    if (!is_associative(@info)) {
        _error("'@info' must be an associative array.");
    }

    _export_store("shops.info.@shop", @info);
}

### Generate the @info array.
proc _shops_generate_info(@UUID, @ploc, @money, @time=time(), @likes=array()) {
    _teleport_bannedblocks(@ploc); ### Testing if teleport location is legal.
    return (array(owner: @UUID, ploc: @ploc, balance: @money, time: @time, likes: @likes));
}

### Get the information for a shop.
proc _shops_get_info(@shop) {
    if (!_shops_has_info(@shop)) {
        _error("Shop '@shop' not found.");
    }
    return(_import_get("shops.info.@shop"));
}

### Check if a shop has information (i.e, exists).
proc _shops_has_info(@shop) {
    if (!is_integral(@shop) || @shop <= 0 || @shop[0] == 0) {
        _error("'@shop' is not an integer, or is less than 1.");
    }
    return(_import_get("shops.info.@shop") != null);
}

### Check if a person has enough money in their shop account.
proc _shops_active(@shop) {
    @daysleft = _shops_daysLeft(@shop);

    if (@daysleft <= 0) {
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


###            ###
### Categories ###
###            ###

### @categories = array('Animals', 'Building', 'Food', 'Mining', 'Potions', 'Redstone', 'Tools', 'Weapons', 'Other')

### Get categories.
proc _shops_cat_list() {
    return(array('Animals', 'Building', 'Food', 'Mining', 'Potions', 'Redstone', 'Tools', 'Weapons', 'Other'));
}

### Check if supplied category is valid.
proc _shops_cat_check(@cat) {
    if (!array_contains_ic(_shops_cat_list(), @cat)) {
        _error("'@cat' is not a valid category in: ". _shops_cat_list());
    }
}

### Get list of shops in a category.
proc _shops_cat_get(@category) {
    @category = to_lower(@category);
    _shops_cat_check(@category);

    @list = get_value("shops.cat.@category");
    if (!is_array(@list)) {
        @list = array();
    }

    return(@list);
}

### Toggle category on a shop.
proc _shops_cat_toggle(@shop, @category) {
    if (!_shops_has_info(@shop)) {
        _error("Shop '@shop' not found.");
    }

    @list = _shops_cat_get(@category);
    if (array_contains_ic(@list, @shop)) {
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

    if (!@silent) {
        msg(colorize("&6Removed Shop &e@shop &6from category &e@category"));
    }
}

proc _shops_cat_on(@shop, @category, @silent=false) {
    @list = _shops_cat_get(@category);
    @list[] = @shop;
    @lowcat = to_lower(@category);
    store_value("shops.cat.@lowcat", @list);

    if (!@silent) {
        msg(colorize("&6Added Shop &e@shop &6to category &e@category"));
    }
}

###       ###
### Likes ###
###       ###

### Re-evaluate the likes list for every player
proc _shops_likes_refreshLists() {
    @list = _shops_getSorted();

    ### Clear all player lists
    @keys = array_keys(get_values("shops.likes."));
    foreach (@key in @keys) {
        clear_value(@key);
    }

    ### To be continued if I still feel like it. This shitty vim and syntax highlighter ruins everything
}

### Returns a sorted, by rating.
proc _shops_getSorted() {
    @sorted = import("shops.sorted");

    ### Update every 30 minutes
    if (!is_array(@sorted) || (time() - @sorted['time']) > 1800000) {
        @sorted = _shops_sortShops();
    }

    return(@sorted['list']);
}

### Get all the shops, not sorted.
proc _shops_getShops() {
    @list = array_keys(get_values('shops.info.'));
    @shoparray = array();

    #Build array of shopnumbers.
    foreach (@shop in @list) {
        @shop = split('.',@shop)[2];
        @shoparray[] = @shop;
    }

    return(@shoparray);
}

proc _shops_sortShops() {
    _shops_tphistory_clearall(); ### Test if clearing is needed.
    @shoparray = _shops_getShops();

    #Sort array by getting its number of likes.
    #@list = array_sort(@shoparray,
    #    closure(@left,@right){
    #            return( array_size(_shops_get_info(@left)['likes']) < array_size(_shops_get_info(@right)['likes']));
    #    }
    #);

    @list = array_sort(@shoparray,
        closure(@left,@right) {
            return( _shops_rating(@left, _shops_get_info(@left)) < _shops_rating(@right, _shops_get_info(@right)));
        }
    );

    @sorted = array(time: time(), list: @list);
    export("shops.sorted", @sorted);
    return(@sorted);
}

###            ###
### Other Junk ###
###            ###

## TODO: Store array of shops in own entry, update with buy/delete. Use _export_store for local caching.
proc _shops_allShops() {
    @keys = array_keys(get_values('shops.info.'));
    @list = array();
    foreach (@key in @keys) {
        @list[] = split('.', @key)[2];
    }
    #_export_store('shops.list', @list);
    return(@list);
}

### Multi-line pagination
proc _shops_paginate(@title, @list) {
    ### Make the first letter a capital.
    @title = to_upper(substr(@title, 0, 1)). to_lower(substr(@title, 1));

    msg(colorize("&6Showing you random shops from &e@title"));
    @size = array_size(@list);

    ### Loops a max of 8 times, or the size of the list, ignoring expired shop.
    @i = 0;
    while (@i < min(@size, 8)) {

        if (@size == 0) {
            break();
        }

        @id = rand(@size);
        @shop = @list[@id];

        array_remove_values(@list, @shop);
        @size = array_size(@list);

        if (_shops_active(@shop)) {
            _shops_printline(@shop, false);
            @i++;
        }
    }
}

### Prints a single line for the pagination and likes_descending functions.
proc _shops_printline(@shop, @showRating=true) {

    @info = _shops_get_info(@shop);
    @owner = _UUID_usernames_lastname(@info['owner']);
    @active = _shops_active(@shop);
    @rating = _shops_rating(@shop, @info);
    #@likes = array_size(@info['likes']);

    ### Produce rating string
    if (@showRating) {
        @ratingMsg = " &7&o(Rating: @rating)";
    } else {
        @ratingMsg = '';
    }

    ### Display normally, or in red if shop is expired.
    if (@active) {
        msg(colorize("&5Shop @shop &dby &5@{owner}@{ratingMsg}"));
    } else {
        msg(colorize("&4&mShop @shop &c&mby &4&m@{owner}@{ratingMsg}"));
    }
}

proc _shops_expire_alert(@shop) {
    @info = _shops_get_info(@shop);
    @UUID = _UUID_altered( @info['owner'] );

    ### Delete shop outright if less than 5 likes and expired more than 2 days ago, or just expired over 20 days ago
    @likes = array_size(@info['likes']);
    @days = _shops_daysLeft(@shop);
    if ((@likes < 5 && @days < -2) || @days < -20) {
        _shops_remove(@shop, true, true);
    } else {
        store_value("shops.expirenotify.@UUID", @shop);
    }
}

###                        ###
### TP History and Ratings ###
###                        ###
proc _shops_tphistory_add(@shop, @UUID, @random=false) {
    if (@random) {
        return();
    }

    if (@UUID == _shops_get_info(@shop)['owner']) {
        return();
    }

    @shop = integer(@shop);
    @list = get_value("shops.tphistory.@shop");
    if (!is_array(@list)) {
        @list = associative_array();
    }

    if (array_index_exists(@list, @UUID)) {
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

    if (is_array(@list)) {
        foreach(@UUID: @count in @list) {
            @base = 2;
            @inc = 10;
            if(@count >= @base + @inc) {
                @score += 1;
            }
            else if(@count > @base) {
                @score += (@count - @base) / @inc;
            }
        }
    }

    return(ceil(@score));
}

proc _shops_tphistory_clearall() {
    @lastClear = get_value("shops.historylastcleared");
    if (!is_integral(@lastClear)) {
        @lastClear = 0;
    }

    @daysSinceLastClear = floor((time() - @lastClear) / 86400000);
    @dayOfMonth = integer(simple_date('d'));

    if ((@dayOfMonth == 1 && @daysSinceLastClear > 1) || @daysSinceLastClear > 31) {
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
