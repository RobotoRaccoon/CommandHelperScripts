#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### @RobotoRaccoon

###          ###
### Commands ###
###          ###
proc _staffkit_help(@args) {

    if(array_size(@args) == 0) {
        @page = 1;
    } else {
        @page = @args[0];
    }

    ### All commands go here if they are to show up in the help command.
    @commands = array(
            '&5List &f> &dDisplay all kits',
            '&5Save &f> &dSave your currently inventory',
            '&5Delete &f> &dRemove a certain kit',
            '&5Equip &f> &dPut on a kit',
            '&5SetDefault &f> &dSets the default kit for all staff'
        );

    _page_vertical('Option', 'sk help', @commands, @page, 5);
}

proc _staffkit_list(@args) {
    @kits = _staffkit_getKitList();
    @page = 1;
    if(array_size(@args) > 0) {
        @page = @args[0];
    }

    _paginate('Staff kits', @kits, @page);
}

proc _staffkit_save(@args) {
    if(array_size(@args) < 1) {
        _error('/staffkit save <name>');
    }

    @name = to_lower(@args[0]);
    _staffkit_errorExists(@name);
    _staffkit_saveKit(@name, pinv());
    msg(colorize("&6Successfully saved your current inventory as &e@name"));
}

proc _staffkit_delete(@args) {
    if(array_size(@args) < 1) {
        _error('/staffkit delete <name>');
    }

    @name = to_lower(@args[0]);
    _staffkit_errorNotExists(@name);
    _staffkit_deleteKit(@name);
    msg(colorize("&6Successfully deleted the kit &e@name"));
}

proc _staffkit_equip(@args) {
    if(array_size(@args) < 1) {
        @name = _staffkit_getDefaultKit();
    } else {
        @name = to_lower(@args[0]);
    }

    _staffkit_errorNotExists(@name);
    set_pinv( _staffkit_getKit(@name) );
    msg(colorize("&6Equipping &e@name"));
}

proc _staffkit_setDefault(@args) {
    if(array_size(@args) < 1) {
        _error('/staffkit setDefault <name>');
    }

    @name = to_lower(@args[0]);
    _staffkit_errorNotExists(@name);
    _staffkit_setDefaultKit(@name);
    msg(colorize("&6Setting &e@name &6as the default kit"));
}

###                 ###
### Other functions ###
###                 ###

proc _staffkit_getKitList() {
    @kits = get_value('staffkit.kitlist');
    if (!is_array(@kits)) {
        @kits = array();
    }
    return(@kits);
}

proc _staffkit_saveKitList(@kits) {
    store_value('staffkit.kitlist', @kits);
}

proc _staffkit_getKit(@name) {
    @kit = get_value("staffkit.kit.@name");
    return(@kit);
}

proc _staffkit_saveKit(@name, @kit) {
    store_value("staffkit.kit.@name", @kit);
    @kits = _staffkit_getKitList();
    if(!array_contains_ic(@kits, @name)) {
        @kits[] = @name;
        _staffkit_saveKitList(@kits);
    }
}

proc _staffkit_deleteKit(@name) {
    clear_value("staffkit.kit.@name");
    @kits = _staffkit_getKitList();
    array_remove_values(@kits, @name);
    _staffkit_saveKitList(@kits);
}

proc _staffkit_errorExists(@name) {
    if( _staffkit_getKit(@name) != null) {
        _error('This Staff Kit already exists');
    }
}

proc _staffkit_errorNotExists(@name) {
    if( _staffkit_getKit(@name) == null) {
        _error('A Staff Kit by this name does not exist, have a look in /staffkit list');
    }
}

proc _staffkit_getDefaultKit() {
    @default = get_value('staffkit.default');
    if(@default == null) {
        _error('No default kit has been defined');
    }
    return(@default);
}

proc _staffkit_setDefaultKit(@name) {
    store_value('staffkit.default', @name);
}

