#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon

###          ###
### Commands ###
###          ###
proc _book_help(@page=1, @player=player()) {

    ### All commands go here if they are to show up in the help command.
    @commands = array(
            '&5List &f> &dDisplays available books',
            '&5Get &f> &dGet a book to read'
        )
    if( has_permission(@player, 'ch_staff') ) {
        @commands = array_merge(@commands, array(
                '&5Save &f> &dStore a book',
                '&5Delete &f> &dDelete a stored book',
                '&5Author &f> &dChange the Author of the book',
                '&5Title &f> &dChange the Title of the book',
                '&5Unwrite &f> &dTurns a book into a writable state',
                '&5Firstjoin &f> &dToggle which books are given on arrival'
            ))
    }

    _page_vertical('Options', 'book help', @commands, @page, 5, @player);
}

proc _book_get(@id, @player=player()) {
    _no_console()

    ### Ensure the book DOES exist, or error if no ID is supplied.
    if( !_book_exists(@id) ) {
        _error('A book under this ID cannot be found. Try /book list')
    }

    ### One per day.
    @UUID = _UUID_player_get(@player)
    if( _DailyCD_diff("book.@id", @UUID) < 1 && !has_permission('ch_staff') ) {
        _error('You may only get one of each book per day...')
    }
    _DailyCD_update("book.@id", @UUID)

    @meta = get_value("CHBook.meta.@id")
    pgive_item(array(name:'WRITTEN_BOOK', meta:@meta))
    tmsg(@player, colorize("&6Enjoy your new book!"))
}

proc _book_save(@id) {
    _verify_staff()
    _no_console()

    ### Error if book exists already, or no ID is supplied.
    _book_exists(@id, true)

    ### Make sure player is holding a written book.
    _book_isHolding(true)
    @meta = get_itemmeta(pinfo(player(), 15))

    ### Store the meta to the DB.
    store_value("CHBook.meta.@id", @meta)
    msg(colorize("&6Successfully saved book &e@{id}&6."))
}

proc _book_delete(@id) {
    _verify_staff()

    ### Ensure the book DOES exist, or error if no ID is supplied.
    if( !_book_exists(@id) ) {
        _error('A book under this ID cannot be found. Try /book list')
    }

    ### Clear the meta from the DB.
    clear_value("CHBook.meta.@id")
    msg(colorize("&6Successfully deleted book &e@{id}&6."))
}

proc _book_setTitle(@newTitle) {
    _verify_staff()
    _no_console()

    ### Make sure player is holding a written book.
    _book_isHolding(true)
    @meta = get_itemmeta(pinfo(player(), 15))

    @meta['title'] = @newTitle
    set_itemmeta(pinfo(player(), 15), @meta)
}

proc _book_setAuthor(@newAuthor) {
    _verify_staff()
    _no_console()

    ### Make sure player is holding a written book.
    _book_isHolding(true)
    @meta = get_itemmeta(pinfo(player(), 15))

    @meta['author'] = @newAuthor
    set_itemmeta(pinfo(player(), 15), @meta)
}

proc _book_unwrite() {
    _verify_staff()
    _no_console()

    ### Make sure player is holding a written book.
    _book_isHolding(true)
    @slot = pinfo(player(), 15)
    @meta = get_itemmeta(@slot)

    ### Set the hotbar slot to an unwritten book (386, not 387).
    @array = associative_array()
    @array[@slot] = array(type: 386, qty: 1, meta: @meta)
    set_pinv(@array)
}

proc _book_firstJoin(@id) {
    _verify_staff();

    ### Error if book exists already, or no ID is supplied.
    if (!_book_exists(@id)) {
        _error('A book under this ID cannot be found. Try /book list');
    }

    ### Get the list as an array.
    @list = get_value("CHBook.firstjoin");
    if (!is_array(@list)) {
        @list = array();
    }

    ### Toggle whether the ID is in the list.
    if (array_contains_ic(@list, @id)) {
        array_remove_values(@list, @id);
        msg(colorize("&6Removed book &e@id &6from the list."));
    } else {
        @list[] = @id;
        msg(colorize("&6Added book &e@id &6to the list."));
    }

    store_value("CHBook.firstjoin", @list);
}

#proc _book_implode(@id) {
#    _verify_op()
#
#    ### Ensure the book DOES exist, or error if no ID is supplied.
#    if( !_book_exists(@id) ) {
#        _error('A book under this ID cannot be found. Try /book list')
#    }
#
#    @meta = get_value("CHBook.meta.@id")
#    msg(strip_colors(@meta))
#}

###                 ###
### Other functions ###
###                 ###
proc _book_getList() {
    @keys = array_keys(get_values('CHBook.meta.'));
    @list = array();
    foreach(@key in @keys) {
        @list[] = split('.', @key, 2)[2];
    }
    return(@list);
}

### Does the meta for this book exist?
proc _book_exists(@id, @die=false) {
    if (@id == null || @id == '') {
        _error('Please supply a book name.');
    }

    if (has_value("CHBook.meta.@id")) {
        if (@die) {
            _error('A book with this ID already exists.');
        }
        return(true);
    }
    return(false);
}

### Is player holding a written book?
proc _book_isHolding(@die=false) {
    try(if( pinv(player(), null)['name'] == 'WRITTEN_BOOK' ) {
        return(true)
    })
    if(@die) {
        _error('You are not holding a written book!')
    }
    return(false)
}

