# CommandHelperScripts
Here is a collection of CommandHelper scripts I have made, and am willing to share. These scripts will use functions that may or may not be available in the repository. However while these functions *should* be rather self-explanatory, some are explained below.

## Scripts
#### UUID
This is a localised UUID tracking system to allow the quick retrieval of players and UUIDs from within other scripts, as well as a few transformative utilities.

#### Book
A simple script whipped up in about an hour to allow the saving of book metadata. Books are saved under unique IDs, unrelated to the book's title. Books may also be assigned to be given out when a player joins the server for the first time.

#### Connect4
A recreation of four-in-a-row inside Minecraft. Configuration for this is not the best, some areas could still be improved if I could be bothered.

#### Daily Login
Track consecutive daily logins and give monetary rewards for logging in

#### Fun Stuff
Assorted collection of scripts that don't really serve a purpose:
* ArrowJourney: Ride arrows that you shoot from a custom bow
* Manipulation: Explode, punt, or make a player super-jump
* Riding: Ride/sit on players, entities, or spawned entities

#### Join/Quit
Alter join and quit messages for players to pick a random message each time.
Includes commands to disable messages for players with a given silentjoin permission, and announce fake join/quit messages.

#### Messages
Personal messaging, with socialspy abilities.

#### Minesweeper
Minesweeper in Minecraft! I really shouldn't have done this using CommandHelper, but here we are. It supports multi-sized arenas, multiple arenas, monetary payouts, leaderboards, and configurable preset modes.

#### Promotion
MCAU's promotion system

#### Rap
RAP sheets for players, listing all of their offences. Follows their UUID rather than their username. Does not currently track jails, but that's not difficult to implement if you feel the need.

#### Shops
Creates a system for purchasing shop teleports, not actual shops. To be used in conjunction with a plugin like SignShop or ChestShop. Shops require a daily fee to operate, defaulting to $25/day.

#### Staff Kit
Quick and easy script to save and load complete loadouts, including the armor slots.

#### Tab Complete
Register commands with the Minecraft auto-completer, and allow for generic argument completions. Completions can be supplied as a string array via a closure. If no closure is supplied the list of online players is used by default.
Currently there is no way to specify different completions given the argument number or arguments that come before it.

#### Traphouse
Simple notifier for when a designated region is being griefed. First /wild sends a player to a traphouse

#### Watchdog
Monitor that a database connection exists and is not returning garbage data. (Used on a Redis instance where a slave can be in READ-ONLY mode and break everything)

#### WorldGuard
WorldGuard fixes for region claiming. Only allow regions inside the world border, & up to a global maximum (not per-world).
Create an alias to add the ability to re-claim regions without having to delete and re-create with the existing flags and members.

## Misc. Functions
These may come one day, but for now they're just stubbed
* **_error**: Calls a die() and displays a red error message to the user.
* **_no_console**: Cannot be run from console.
* **_verify_staff**: Calls an error if the player is not a staff rank.
* **_DailyCD**: A system for a daily cooldown.
* **_page_vertical**: Display an array of strings paginated over new lines, over multiple pages if necessary.
