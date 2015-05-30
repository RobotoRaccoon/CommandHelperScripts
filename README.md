# CommandHelperScripts
Here is a collection of CommandHelper scripts I have made, and am willing to share. These scripts will use functions that may or may not be available in the repository. However while these functions *should* be rather self-explanatory, some are explained below.

## Scripts
#### UUID
This is a localised UUID tracking system to allow the quick retrieval of players and UUIDs from within other scripts, as well as a few transformative utilities.

#### Book
A simple script whipped up in about an hour to allow the saving of book metadata. Books are saved under unique IDs, unrelated to the book's title. Books may also be assigned to be given out when a player joins the server for the first time.

#### Rap
RAP sheets for players, listing all of their offences. Follows their UUID rather than their username. Does not currently track jails, but that's not difficult to implement if you feel the need.

#### Shops
Creates a system for purchasing shop teleports, not actual shops. To be used in conjunction with a plugin like SignShop or ChestShop. Shops require a daily fee to operate, defaulting to $25/day.

## Misc. Functions
* **_error**: Calls a die() and displays a red error message to the user.
* **_no_console**: Cannot be run from console.
* **_verify_staff**: Calls an error if the player is not a staff rank.
* **_DailyCD**: A system for a daily cooldown.
