#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

## Every 20 seconds (initial 5)
set_interval(20000, 5000, closure() {
    try {
        @nonce = 'woof';
        @path = 'watchdog.'._getserver();
        store_value(@path, @nonce); ## Checks for READ-ONLY
        if (get_value(@path) != @nonce) { ## Checks for garbage returns from the DB
            throw('ms.lang.IOException', "Nonce value comparison has failed (@path)");
        }
    } catch (IOException @e) {
        @msg = @e['classType']. ' - '. @e['message'];
        @log = "&4Database Watchdog has failed with the message&c: \"@msg\"";
        _bc_janitor(@log);
    }
});
