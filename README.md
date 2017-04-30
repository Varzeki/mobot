# Mobot
For when you're in love with the mobo.

##Dependencies

```
gem install cinch cinch-identify yaml
```

##Introduction
Mobot is an IRC bot written in Ruby, with the help of the cinch library. It allows users to gain currency through the user of other bots, and ultimately spend it to use administration commands they don't have privileges for.

##Usage, Maths, and Strategies
For convenience, here is a list of all valid mobot commands:
* pvp
* mission
* help
* faction create {FACTION NAME}
* faction join {FACTION NAME}
* faction leave
* faction invite {USER}
* faction bank {AMOUNT}
* faction show
* crew start
* crew open
* crew close
* crew show
* crew join {USER}
* rob {USER}
* give {USER} {AMOUNT}
* purchase {[kick {USER}] / [dex] / [str] / [int] / [lck] / [psi] / [acc] / [access]}
* JOIN {CHANNEL}
* MESSAGE {USER} {MESSAGE}
* SEND {CHANNEL} {MESSAGE}
* MIGRATE
* CMOD {AMOUNT} {USER}
* ADMIN {USER}

Each user of mobot has 6 stats: DEX, STR, INT, LCK, PSI, and ACC.
Each stat has an accompanying element - Aer, Terra, Aques, Fyr, Flux, and Alica, respectively.
You can level these stats using credits, which are obtained by doing missions.
Each mission has a stat assigned to it - for instance mining an asteroid might measure your luck, so your LCK stat will affect the result.
No matter your stats, missions always have a 70% chance of success - however, having a high stat and doing a matching mission will award you more credits at the end!
The exact calculation for mission rewards is
```
BASE MISSION REWARD + (STAT * 7)
```
So, doing a LCK mission with a base reward of 100, while having a LCK skill of 5, will award you 135 credits.

Every time you successfully complete a mission, there is a 30% chance of aquiring an item.
Items have 6 rarities - Regulation, Industrial, Aftermarket, Illegal, Starframed, and Zekiforged
Each rarity increases your stats by 20% more than the last, starting at 10%, except for Zekiforged which increases them by 150%.
Every item also has an element attuned to it, which will increase the matching stat by an additional 20%.

Missions can be performed as a group by creating a party.
Unlike performing missions alone, the result of each mission is determined by the HIGHEST INSTANCE of each stat in your group.
Consider 6 people.
Adam has spread 10000 credits into his skills evenly.
Bob has put all 10000 of his credits into LCK.
Charlotte, Daniel, Ethan, and Fiona have each spent all their money on STR, INT, DEX, and PSI in a similar fashion to Bob, and created a party.
Adam does 10 missions, and makes a moderate amount of money from each one because all of his skills are equal.
Bob does 10 missions, and makes slightly less money than Adam because his total skill level isn't as high.
Now, each member of the party does 10 missions, making 40 missions total. They make a lot of money because their total skillset is the highest, but it is split between the four of them. Even after splitting, each member has made more money than Adam or Bob.
However, if Charlotte goes on holiday and doesn't do any missions, she will still receive money, but the crew can only do 3/4 as many missions, putting each members income beneath both Adam and Bob.
The crews income can be increased even more if two of their members decide to put half of their money in to 2 different skills, covering all 6 attributes and maximising the crews skill level per credit.

Eventually, users may accrue enough credits to buy ACCESS levels. ACCESS in #mobot goes up to 9999, and at regular intervals users with high enough access are awarded with cosmetic Voice, Halfoperator, Operator, or Admin flags.
Kicks and bans are disabled for everyone but mobot, though if your access level is higher than someone else, you may pay credits to have them kicked from the channel.

Action Points are awarded to all users hourly, and can be spent to attempt a mission, or rob. Action Points stack up to 16, at which point they will stop being automatically awarded.

##Channel Rules
* Do not break any Rizon global Rules
* Do not exercise the use of exploits to abuse mobot
* Botting is allowed, but only one bot per person unless otherwise discussed
* Do not abuse access levels
* Off topic and NSFW discussion is allowed
* Do not mass invite or mass hilight
* Do not not abuse mink

##Contribute
Feature requests and bug reports welcome, along with pull requests - feel free to participate!

You can submit a VALID and UNDISCUSSED issue into the tracker
You can painstakingly go through my subpar code and correct the 1000 odd ruby code standard infractions
You can complete ANY of the tasks on the To Do list below and submit a pull request - i'll accept most anything
You can pm me generic SciFi weapon names to add to the item generation list
You can write a mission for mobot using one of the premade missions as a format <--- really need people to do this
You can do anything else you can think of, or don't, i'm not your boss, don't be a sheep.

Any of the above contributions will be rewarded with ACCESS levels

##To Do
* Change kick system to respect access
* Automate access syncing
* Add PvP system - party battlegrounds? Bot integration based objectives? Rob objectives? fun interactive PvP rather than RNG style PvE
* Add missions
* Add mission submission system - With wget?
* Remove devoice feature
* Add tempban feature (60s)
* Tie AP updates to hours
* Add EXP system
* Add boss feature - 5AP per person, parties only
* Add ability to sell items
* Change give system to gift system, take AP
* Add bank system per person
* Rework factions
* Move methods to seperate files
* Write equip command
* Write show inventory command
* Reset stats and reward legacy users 25 skill points into a skill of their choice and 10 access levels
* Check if the channel is actually mode +R?
* Maybe i should actually license this thing at some point
* Find out if black science man has an email
