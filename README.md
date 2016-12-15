# Mobot
A bot for when you're in love with the mobo.

##Features
Use .help to get a list of features and commands in the bot.

These features currently include:
* .daily - Allows a user to claim 250 coins once per 24h
* .coins [user] - Shows a users current coins balance
* .purchase {item} [recipient] - Purchases an item from the .store list
* .store - Lists items available for purchase, currently being:
  * kick {recipient} - Kicks a target user, provided the bot has permission - 1000 coins
  * devoice {recipient} - Devoices a target user, provided the bot has permission - 2000 coins
  * DEX - Upgrades the users Dexterity attribute - 500 coins + 50 for each previous upgrade
  * STR - Upgrades the users Strength attribute - 500 coins + 50 for each previous upgrade
  * INT - Upgrades the users Intelligence attribute - 500 coins + 50 for each previous upgrade
  * LCK - Upgrades the users Luck attribute - 500 coins + 50 for each previous upgrade (This is the most useful attribute :3)
* .taytay - Deprecated, used to check taylorswift balance before she died
* .rob {user} - Attempts to rob another user
* .attr - Shows the current users attributes
* .quest - Attempts a quest
* .pvp - Toggles the users PvP status
* .bet {amount} - Bets an amount of coins, with a 40% chance to double your offer
* .crew {option} [user] - Operates crews, with commands as:
  * start - Starts a crew
  * join {username} - Joins another persons crew
  * open - Opens a crew to new members
  * close - Closes a crew to new members
  * leave - Leaves the current crew, or disbands it if you are captain
  * show - Shows the status of your current crew
#Contribute
Feature requests and bug reports welcome, along with pull requests - feel free to participate!

You can write a quest for mobot in the format of:

`["Quest Name", "TYPE", reward_amount, "Start of quest text", "Success text", "Failure text"]`

#To Do
* Add command attribute requirements (e.g 5DEX for robbing)
* Add PvP (Fight like rob but higher risk with stat use?)
* Add quests
* Add quest submission system
* Add inbuilt bug tracker w/ rewards
* Add timeouts to robbing (Per person?)
* Update flavour text per RPG theme
* Add usable skills (1% chance droppable, one for each attribute, only drops for 10+?)
* Add achievement style tutorial system (Rewards for using each feature the first time)
* Add admin system
* Fix SEND style commands per admin system
* Fix kick/devoice system
* Add voice to store
* Add dehop to store
* Fix quest <0 bug
* Modify quests to change netted to Gained/Lost

