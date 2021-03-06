#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### @RobotoRaccoon

### @UUID    : 7413ff56_ea0c_45dc_8c1d_e32b923e90a8
### - Note the replacement of hyphens to underscores (Namespaces cannot handle hyphens)
### @section : ban, comment, jail, kick, mute
### @count   : 1, 2, etc.
### @info    : {reason: @, timestamp: @, staff: @, server: @, length: @=null}
### - Length is optional as kicks/comments do not have a length. Indefinite lengths shall be denoted 'Forever'

###              ###
### Housekeeping ###
###              ###

## Allowed sections
proc _RAP_section_list() {
    ### In a specific order (To be printed on rap sheet)
    return(array('kick', 'mute', 'jail', 'ban', 'comment'));
}

## Check if a section is l3g1t
proc _RAP_section_check(@section) {
    @allowed = _RAP_section_list();
    if (!array_contains_ic(@allowed, @section)) {
        _error("Section '@section' does not exist. Allowed sections: ". array_implode(@allowed, ', '));
    }

    return(to_lower(@section));
}

## Get the total number of added records
proc _RAP_count_get(@UUID, @section) {
    @section = _RAP_section_check(@section);
    @UUID = _UUID_altered(@UUID);
    @count = get_value('rapsheet', @UUID, @section, 'count');
    if (!is_integral(@count)) {
        @count = 0;
    }

    return(@count);
}

## Add 1 to the count for a section
proc _RAP_count_increment(@UUID, @section) {
    @section = _RAP_section_check(@section);
    @UUID = _UUID_altered(@UUID);
    @count = _RAP_count_get(@UUID, @section);

    @count += 1;
    store_value('rapsheet', @UUID, @section, 'count', @count);
}

## Get a record
proc _RAP_entry_get(@UUID, @section, @count) {
    @UUID = _UUID_altered(@UUID);
    @section = _RAP_section_check(@section);
    return( get_value('rapsheet', @UUID, @section, @count) );
}

## Store a record
proc _RAP_entry_store(@UUID, @section, @count, @info) {
    @UUID = _UUID_altered(@UUID);
    @section = _RAP_section_check(@section);
    if( !is_array(@info) ) {
        _error('Cannot write to rap sheet. Information supplied was not an array.');
    }

    store_value('rapsheet', @UUID, @section, @count, @info);
}

## Clear a record
proc _RAP_entry_clear(@UUID, @section, @count, @reason) {
    _verify_op('What are you doing, get out.');
    @UUID = _UUID_altered(@UUID);
    @section = _RAP_section_check(@section);

    if (!has_value('rapsheet', @UUID, @section, @count)) {
        _error('Specified entry does not exist.');
    }

    if (@reason == '') {
        _error('Please supply a short reason at the end.');
    }

    @info = get_value('rapsheet', @UUID, @section, @count);
    @player = player();

    clear_value('rapsheet', @UUID, @section, @count);
    msg(colorize("&eSuccessfully removed entry"));
    console(colorize("&4Warning: &cRap sheet entry cleared by @player &4|&7 rapsheet.@UUID.@section.@count &4|&7 @info &4|&c Reason: \"@reason\""));
}

## Turn info into an infoArray
proc _RAP_info_generate(@reason, @timestamp, @staff, @length=null) {

    ## Required information
    if (@reason == null || @reason == '') {
        _error('A reason must be supplied.');
    }
    else if (!is_integral(@timestamp)) {
        _error('A timestamp must be supplied');
    }
    else if (@staff == null || @staff == '') {
        _error("The staff member's name must be supplied.");
    }

    @info = associative_array();
    @info['reason'] = @reason;
    @info['timestamp'] = @timestamp;
    @info['staff'] = @staff;
    @info['server'] = _getserver();

    ## Non-required information
    if (@length != null) {
        @info['length'] = @length;
    }

    return(@info);
}

## Turn info into an infoArray w/ a required length
proc _RAP_info_generate_timed(@reason, @timestamp, @staff, @length) {

    ## Given this is time, a length must be supplied in the format:
    # {length}{qualifier}, where qualifiers are m(inutes), d(ays), w(eeks), y(ears)
    # Given an essential issue, the reason may not start with a digit
    if (@length == null || @length == '') {
        _error('A length must be supplied');
    }
    else if (!reg_match('^[1-9][0-9]*[mhdwy]$', @length)) {
        _error("Length must be a number follow by either m,h,d,w,y (e.g. 10m for 10 minutes)\nYou gave: @length");
    }
    else if (is_numeric(@reason[0])) {
        _error('The reason cannot start with a number, due to an Essentials bug');
    }
    ## Perform the regular info generation & return
    return(_RAP_info_generate(@reason, @timestamp, @staff, @length));
}

proc _RAP_parse_args(@args) {
    @args = split(' ', @args);
    @params = associative_array(full: false, sections: null);

    while (array_size(@args) > 0) {
        @word = array_remove(@args, 0);
        switch(@word) {
        case 'full':
            @params['full'] = true;

        case 'show':
            if (array_size(@args) == 0) {
                _error('Argument error, requires a comma separated list of sections');
            }
            @params['sections'] = array_unique(split(',', array_remove(@args, 0)));
        }
    }

    return(@params);
}

###                 ###
### Getting serious ###
###                 ###

## Append an entry to the next count for a section
proc _RAP_entry_append(@UUID, @section, @info) {
    @count = _RAP_count_get(@UUID, @section) + 1;
    _RAP_entry_store(@UUID, @section, @count, @info);
    _RAP_count_increment(@UUID, @section);
}

## Formats a specific record on one line
proc _RAP_entry_format(@UUID, @section, @count) {
    @info = _RAP_entry_get(@UUID, @section, @count);
    if (@info == null) {
        return(colorize("&5@count &7&oN/A"));
    }

    @reason = @info['reason'];
    @staff = @info['staff'];
    @timestamp = _time_to_datediff(@info['timestamp']);

    ## Message formatting
    @print = "&5@count";
    if (array_index_exists(@info, 'length')) {
        @length = @info['length'];
        @print = "@print &7@length,";
    }
    @print = "@print &e\"@reason\",";
    @print = "@print &7@staff,";
    @print = "@print &7@timestamp";
    if (array_index_exists(@info, 'server')) {
        if( @info['server'] != _getserver() ) {
            @server = @info['server'];
            @print = "@print &8(@server)";
        }
    }

    return(colorize(@print));
}

## Print an entire section, returns number of records printed
proc _RAP_print_section(@UUID, @section, @trunc=true) {
    @count = _RAP_count_get(@UUID, @section);
    if (@count > 0) {
        @start = 1;
        if (@trunc && @count >= 6) {
            @start = @count - 3;
        }

        @secTitle = to_upper(@section). 'S';
        msg(colorize("&4--------[ &c@secTitle &4]--------"));
        if (@start > 1) {
            msg(colorize('&8... (view full rap with /rap <player> full)'));
        }
        for (@i = @start, @i <= @count, @i++) {
            msg(_RAP_entry_format(@UUID, @section, @i));
        }
    }
    return(@count);
}

## Prints the entire rap sheet (UUID)
proc _RAP_print_UUID(@UUID, @args) {
    _verify_janitor();
    if (length(@UUID) != 36) {
        _error("Expected a valid UUID, got '@UUID'");
    }

    @params = _RAP_parse_args(@args);
    @trunc = !@params['full']

    if (@params['sections']) {
        @sections = @params['sections'];
    } else {
        @sections = _RAP_section_list();
    }

    @AssociatedUsernames = _UUID_usernames_list(@UUID);
    msg(colorize("&eRap sheet for &6@UUID"));
    msg(colorize('&eKnown usernames: &6'. array_implode(@AssociatedUsernames, '&e, &6')));
    @printed = 0;
    foreach (@sections, @section) {
        @printed += _RAP_print_section(@UUID, @section, @trunc);
    }

    if (@printed == 0) {
        msg(colorize('&7This UUID has not committed any crimes.'));
    }
}

## Prints the entire rap sheet (Player)
proc _RAP_print_player(@player, @args) {
    @player = _autocomplete_player(@player, false, true);
    _RAP_print_UUID(_UUID_player_get(@player, true), @args);
}

###                  ###
### The most serious ###
###                  ###

## From kick commands
proc _RAP_kick(@player, @info) {
    @UUID = _UUID_player_get(@player, true);

    @reason = @info['reason'];
    sudo("/ekick @player @reason");
    _bc_irc("@player has been kicked for \"@reason\".");

    _RAP_entry_append(@UUID, 'kick', @info);
}

## From mute and tempmute commands.
proc _RAP_mute(@player, @info) {
    @UUID = _UUID_player_get(@player, true);

    @reason = @info['reason'];
    @length = @info['length'];
    if (to_lower(@length) == 'forever') {
        sudo("/emute @player");
    } else {
        sudo("/emute @player @length");
    }
    _bc_irc("@player has been muted for @length for \"@reason\".");

    _RAP_entry_append(@UUID, 'mute', @info);
}

## From jail commands.
proc _RAP_jail(@player, @info) {
    _error('We do not use jails in MCAU');
}

## From ban and tempban commands.
proc _RAP_ban(@player, @info) {
    @UUID = _UUID_player_get(@player, true);

    @reason = @info['reason'];
    @length = @info['length'];
    if (to_lower(@length) == 'forever') {
        sudo("/essentials:ban @player @reason");
    } else {
        sudo("/essentials:tempban @player @length @reason");
    }
    _bc_irc("@player has been banned for @length for \"@reason\".");

    _RAP_entry_append(@UUID, 'ban', @info);
}

## From comment command.
proc _RAP_comment(@player, @info) {
    @UUID = _UUID_player_get(@player, true);
    _RAP_entry_append(@UUID, 'comment', @info);
    msg(colorize("&eSuccessfully added comment to &6@player"));
}

