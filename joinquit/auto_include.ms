#########################
#                       #
# THIS IS A MASTER FILE #
#  ~/minecraft/master   #
#                       #
#########################

## @RobotoRaccoon

proc _join_message(@player) {
    @msg = colorize('&a >>&7 '. _random_greeting(). ", &8@{player}&7! ". _random_smiley());
    return(@msg);
}

proc _quit_message(@player) {
    @msg = colorize('&c <<&7 '. _random_farewell(). ", &8@{player}&7. ". _random_sadface());
    return(@msg);
}

proc _random_smiley() {
    return(array_rand(
        array(':)', '(:', 'c:', ':D', ':>', ';-D', ':B', '^.^', '^_^', '=D', '=^..^=', ';-}', ':]', '8^)', '8)'),
        1, false)[0])
}
proc _random_greeting() {
    return(array_rand(
        array('Hello','G\'day', 'Greetings', 'Howdy', 'What\'s up', 'Heya', 'What\'s Poppin\'', 'Ahoy-hoy', 'Hey', 'Bonjour', 'Hola'),
        1, false)[0])
}
proc _random_sadface() {
    return(array_rand(
        array(':(', '):', ':c', ':C', ':<', 'D:', ';-[', ':[', '8(', '=('),
        1, false)[0])
}
proc _random_farewell() {
    return(array_rand(
        array('See you later', 'Farewell', 'Goodbye', 'Seeya', 'Ta-ta', 'Cheerio', 'Bye', 'Later', 'Toodlepoops', 'Au revoir', 'Sayonara', 'Arrivederci'),
        1, false)[0])
}

