#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon

### @UUID    : 7413ff56_ea0c_45dc_8c1d_e32b923e90a8
### - Note the replacement of hyphens to underscores (Namespaces cannot handle hyphens)
### @section : ban, comment, jail, kick, mute
### @count   : 1, 2, etc.
### @info    : {reason: @, timestamp: @, staff: @, server: @, length: @=null}
### - Length is optional as kicks/comments do not have a length. Indefinite lengths shall be denoted 'Forever'

###              ###
### Housekeeping ###
###              ###

### Allowed sections
proc _RAP_section_list() {
    ### In a specific order (To be printed on rap sheet)
    return( array('kick', 'mute', 'jail', 'ban', 'comment') );
}

### Check if a section is l3g1t.
proc _RAP_section_check(@section) {
    @allowed = _RAP_section_list();
    if( !array_contains_ic(@allowed, @section) ) {
        _error('This section for a rap sheet record is not found. Allowed sections: '. array_implode(@allowed, ', '));
    }

    return( to_lower(@section) );
}

### Get the total number of added records
proc _RAP_count_get(@UUID, @section) {
    @UUID = _UUID_altered(@UUID);
    @section = _RAP_section_check(@section);
    @count = get_value('rapsheet', @UUID, @section, 'count');
    if( !is_integral(@count) ) {
        @count = 0;
    }

    return( @count );
}

### Add 1 to the count for a section
proc _RAP_count_increment(@UUID, @section) {
    @UUID = _UUID_altered(@UUID);
    @section = _RAP_section_check(@section);
    @count = _RAP_count_get(@UUID, @section);

    @count += 1;
    store_value('rapsheet', @UUID, @section, 'count', @count);
}

### Get a record
proc _RAP_entry_get(@UUID, @section, @count) {
    @UUID = _UUID_altered(@UUID);
    @section = _RAP_section_check(@section);
    return( get_value('rapsheet', @UUID, @section, @count) );
}

### Store a record
proc _RAP_entry_store(@UUID, @section, @count, @info) {
    @UUID = _UUID_altered(@UUID);
    @section = _RAP_section_check(@section);
    if( !is_array(@info) ) {
        _error('Cannot write to rap sheet. Information supplied was not an array.');
    }

    store_value('rapsheet', @UUID, @section, @count, @info);
}

### Clear a record
proc _RAP_entry_clear(@UUID, @section, @count, @reason) {
    _verify_op('What are you doing, get out.');
    @UUID = _UUID_altered(@UUID);
    @section = _RAP_section_check(@section);

    if( !has_value('rapsheet', @UUID, @section, @count) ) {
        _error('Specified entry does not exist.');
    }

    if( @reason == '' ) {
        _error('Please supply a short reason at the end.');
    }

    @info = get_value('rapsheet', @UUID, @section, @count);
    @player = player();

    clear_value('rapsheet', @UUID, @section, @count);
    msg(colorize("&eSuccessfully removed entry"));
    console(colorize("&4Warning: &cRap sheet entry cleared by @player &4|&7 rapsheet.@UUID.@section.@count &4|&7 @info &4|&c Reason: \"@reason\""));
}

### Turn info into an infoArray
proc _RAP_info_generate(@reason, @timestamp, @staff, @length=null) {

    ### Required information
    if( @reason == null || @reason == '' ) {
        _error('A reason must be supplied.');
    }
    else if( !is_integral(@timestamp) ) {
        _error('A timestamp must be supplied');
    }
    else if( @staff == null || @staff == '' ) {
        _error("The staff member's name must be supplied.");
    }

    @info = associative_array();
    @info['reason'] = @reason;
    @info['timestamp'] = @timestamp;
    @info['staff'] = @staff;
    @info['server'] = _getserver();

    ### Non-required information
    if( @length != null ) {
        @info['length'] = @length;
    }

    return(@info);
}

###                 ###
### Getting serious ###
###                 ###

### Append an entry to the next count for a section
proc _RAP_entry_append(@UUID, @section, @info) {
    @count = _RAP_count_get(@UUID, @section) + 1;
    _RAP_entry_store(@UUID, @section, @count, @info);
    _RAP_count_increment(@UUID, @section);
}

### Formats a specific record on one line
proc _RAP_entry_format(@UUID, @section, @count) {
    @info = _RAP_entry_get(@UUID, @section, @count);
    if( @info == null ) {
        return(colorize( "&5@count &7&oN/A" ));
    }

    @reason = @info['reason'];
    @staff = @info['staff'];
    @timestamp = _time_to_datediff(@info['timestamp']);

    ### Message formatting.
    @print = "&5@count";
    if( array_index_exists(@info, 'length') ) {
        @length = @info['length'];
        @print = "@print &7@length,";
    }
    @print = "@print &e\"@reason\",";
    @print = "@print &7@staff,";
    @print = "@print &7@timestamp";
    if( array_index_exists(@info, 'server') ) {
        if( @info['server'] != _getserver() ) {
            @server = @info['server'];
            @print = "@print &8(@server)";
        }
    }

    return(colorize(@print));
}

### Print an entire section
proc _RAP_print_section(@UUID, @section) {
    @count = _RAP_count_get(@UUID, @section);

    if( @count > 0 ) {
        @secTitle = to_upper(@section). 'S';
        msg(colorize("&4--------[ &c@secTitle &4]--------"));
        for( @i = 1, @i <= @count, @i++ ) {
            msg( _RAP_entry_format(@UUID, @section, @i) );
        }
    }
}

### Prints the entire rap sheet (UUID)
proc _RAP_print_UUID(@UUID) {
    _verify_janitor();
    @sections = _RAP_section_list();
    @AssociatedUsernames = _UUID_usernames_list(@UUID);

    msg(colorize("&eRap sheet for &6@UUID"));
    msg(colorize('&eKnown usernames: &6'. array_implode(@AssociatedUsernames, '&e, &6')));
    foreach(@sections, @section) {
        _RAP_print_section(@UUID, @section);
    }

    @kicks = _RAP_count_get(@UUID, 'kick');
    @mutes = _RAP_count_get(@UUID, 'mute');
    @jails = _RAP_count_get(@UUID, 'jail');
    @bans = _RAP_count_get(@UUID, 'ban');
    @total = @kicks + @mutes + @jails + @bans;

    if( @total == 0 ) {
        msg(colorize('&7This UUID has not committed any crimes.'));
    }
}

### Prints the entire rap sheet (Player)
proc _RAP_print_player(@player) {
    @player = _autocomplete_player(@player);
    _RAP_print_UUID( _UUID_player_get(@player, true) );
}

###                  ###
### The most serious ###
###                  ###

### From kick commands
proc _RAP_kick(@player, @info) {
    @UUID = _UUID_player_get(@player, true);
    
    @reason = @info['reason'];
    sudo("/ekick @player @reason");
    if( _getserver() == 'Survival' ) {
        _bc_irc("@player has been kicked for \"@reason\".");
    } 
    
    _RAP_entry_append(@UUID, 'kick', @info);
}

### From mute and tempmute commands.
proc _RAP_mute(@player, @info) {
    @UUID = _UUID_player_get(@player, true);
    
    @reason = @info['reason'];
    @length = @info['length'];
    if( to_lower(@length) == 'forever' ) {
        sudo("/emute @player");
    } else {
        sudo("/emute @player @length");
    }
    
    if( _getserver() == 'Survival' ) {
        _bc_irc("@player has been muted for @length for \"@reason\".");
    } 
    
    _RAP_entry_append(@UUID, 'mute', @info);
}

### From jail commands.
proc _RAP_jail(@player, @info) {
    _error('We do not use jails in MCAU.');
}

### From ban and tempban commands.
proc _RAP_ban(@player, @info) {
    @UUID = _UUID_player_get(@player, true);
    
    @reason = @info['reason'];
    @length = @info['length'];
    if( to_lower(@length) == 'forever' ) {
        sudo("/essentials:ban @player @reason");
    } else {
        sudo("/essentials:tempban @player @length @reason");
    }
    
    if( _getserver() == 'Survival' ) {
        _bc_irc("@player has been banned for @length for \"@reason\".");
    } 
    
    _RAP_entry_append(@UUID, 'ban', @info);
}

### From comment command.
proc _RAP_comment(@player, @info) {
    @UUID = _UUID_player_get(@player, true);
    _RAP_entry_append(@UUID, 'comment', @info);
    msg(colorize("&eSuccessfully added comment to &6@player"));
}

