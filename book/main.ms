#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

### CodebotoCodecoon

bind(player_join, null, null, @e,
    if (@e['first_login'] != true) {
        die();
    }

    @list = get_value("CHBook.firstjoin")
    if (!is_array(@list)) {
        die();
    }

    foreach (@id in @list) {
        @meta = get_value("CHBook.meta.@id");
        pgive_item(array(name:'WRITTEN_BOOK', meta:@meta));
    }
)
