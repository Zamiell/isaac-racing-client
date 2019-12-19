# Racing+ Mod Changes

## Website

If you want to learn more about Racing+, you can visit [the official website](https://isaacracing.net). If you want to know the changes that are present in the in-game mod, read on.

<br />

## Table of Contents

1. [Design Goals](#design-goals)
2. [List of Main Changes](#list-of-main-changes)
3. [Other Mods Included](#other-mods-included)
4. [List of Minor Changes](#list-of-minor-changes)
5. [Additional Changes for Races](#additional-changes-for-races)
6. [Additional Changes for Multi-Character Speedruns (Custom Challenges)](#additional-changes-for-multi-character-speedruns-custom-challenges)
7. [Individual Room Changes](#individual-room-changes)

<br />

## Design Goals

In terms of what to change about the game, the mod has several goals, and attempts to strike a balance between them. However, certain things are prioritized. The goals are listed below in order of importance:

1) to reward skillful play (in the context of speedrunning and racing)
2) to make the game more fun to play
3) to fix bugs and imperfections
4) to keep the game as "vanilla" as possible

<br />

## List of Main Changes

### 1) Character Changes

* All characters now start with the D6. (Much of the strategy in the game is centered around having this item and it heavily mitigates run disparity.)
* Certain characters have their starting health changed so that they can consistently take a devil deal:
  * Judas starts with half a red heart and half a soul heart.
  * Blue Baby starts with an extra half soul heart.
  * Azazel starts with an extra half soul heart.
* Judas starts with a bomb instead of 3 coins.
* Samson no longer starts with the Child's Heart. (This is a quality of life change, since the Child's Heart is usually immediately dropped.)
* Eden starts with the Schoolbag. They will start with their random active item inside the bag. (This is to preserve the active item.)

### 2) No Curses

All curses are automatically disabled.

### 3) Devil Room & Angel Room Rebalancing

Since Devil Rooms and Angel Rooms are the most skill-based component of the game, their rewards have been [slightly rebalanced](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-ROOM.md#devil-room-rebalancing).

### 4) Wrath of the Lamb Style Room Clear

Rooms are considered cleared at the beginning of an enemy's death animation, rather than the end. (This was the way the game was originally intended to be, but it was incorrectly ported to Rebirth.)

### 5) Room Fixes

Hundreds of rooms with unavoidable damage or bugs have been fixed or deleted.

### 6) Room Flipping

While there are thousands of rooms in the game, many players have already seen them all. To increase run variety, asymmetrical rooms have a chance to be flipped on the X axis, Y axis, or both axes.

<br />

## Other Mods Included

* [Samael](http://steamcommunity.com/sharedfiles/filedetails/?id=897795840), a custom character created by [Ghostbroster](http://steamcommunity.com/id/ghostbrosterconnor). He is a melee character that uses his scythe to attack enemies. In Racing+, Samael starts with D6, the Schoolbag, the Wraith Skull, and 1 bomb.

<br />

## List of Minor Changes

### Custom Hotkeys

* Racing+ allows you to bind two new hotkeys via a custom challenge:
  * a drop button that will immediately drop all trinkets and pocket items
  * a dedicated Schoolbag switch button
* Binding these hotkeys is optional. If they are not bound, Racing+ will use the vanilla behavior.

### Gameplay & Quality of Life Changes

* The Polaroid or The Negative will be automatically removed depending on your run goal.
* The trapdoor or the beam of light on Womb 2 will be automatically removed depending on your run goal or which photo you have.
* Some items with no effect are removed:
  * the Karma trinket (all Donation Machines are removed when curses are disabled)
  * the Amnesia pill (this has no effect when curses are disabled)
  * the ??? pill (this has no effect when curses are disabled)
* Some things that are unseeded are now seeded:
  * rerolls on items after being touched or purchased
  * Teleport!, Undefined, Cursed Eye, Broken Remote, and Telepills teleports
  * Dead Sea Scrolls item selection
  * cards from Sloth, Super Sloth, Pride, and Super Pride
* Void Portals are automatically deleted.
* The restart key immediately restarts the game. (To perform a fast-restart on the second floor and beyond, you need to double tap R.)
* [Special items](https://bindingofisaacrebirth.gamepedia.com/Special_Item) are no longer special.
* Items that drop pickups on the ground will now automatically insert them into your inventory instead, if there is room. (However, Purple Heart, Mom's Toenail, The Tick, Faded Polaroid, and Ouroboros Worm are never inserted automatically.) This effect also applies to the Spun! transformation.
* You will always be able to take an item in the Basement 1 Treasure Room without spending a bomb or being forced to walk on spikes.
* Troll Bombs and Mega Troll Bombs always have a fuse timer of exactly 2 seconds.
* Identified pills (up to 7) will be shown when the player presses Tab.
* Diagonal knife throws have a 3-frame window instead of a 1-frame window.
* Duplicate rooms will no longer appear on the same run. (Basement 1 is exempt. All floors on set seeds are exempt.)
* The Boss Rush is modified to include the Afterbirth+ bosses and Chapter 4 bosses.
* Teleport, Broken Remote, and Cursed Eye no longer have a chance to teleport you to the same room that you are in.
* Pin's first attack happens on the 15th frame (instead of the 73rd frame).
* Cod Worms are replaced with Para-Bites.
* Wizoobs, Red Ghosts, and Lil' Haunts no longer have invulnerability frames after spawning.
* Mom's Hands, Mom's Dead Hands, Wizoobs, and Red Ghosts have faster attack patterns.
* Death will no longer perform his slow attack.
* The disruptive teleport that occurs when entering a room with Gurdy, Mom, Mom's Heart, or It Lives! no longer occurs.
* The pickup delay on reloaded pedestal items is decreased from 18 frames to 15 frames.
* Having Duality will now always give you both the Devil Room and the Angel Room. (This does not happen consistently on vanilla like you would expect.)
* All Spike Chests will spawn as Mimics instead. (Since they are so similar, there is little reason for Spike Chests to exist.)
* The Chub that spawns after The Matriarch will be automatically stunned for a few frames to prevent unavoidable damage.
* Hosts and Mobile Hosts are now immune to fear. (This prevents bugs where feared Hosts will not properly play animations.)
* The Forsaken is now immune to fear. (This prevents the bug where it will not attack.)
* Blastocyst is now immmune to freeze. (This prevents delays during the death animation.)
* The "Would you like to do a Victory Lap!?" popup no longer appears after defeating The Lamb.
* All pills can now be used to cancel pedestal pickup animations.
* The door to Hush is now automatically opened.
* The devil statue will be faded if there is an item pedestal hiding behind it.

### Cutscene & Animation Removal

* The cutscenes that occur when you launch the game and when you finish a run are removed.
* The cutscenes that occur before each boss are removed.
* Some animations are removed for the purposes of eliminating needless downtime:
  * the fade when entering a new floor (replaced with a custom animation)
  * the fade when entering or exiting crawlspaces (replaced with a normal room transition animation)
  * all "giantbook" animations (with the exception of Book of Revelations, Satanic Bible, eternal hearts, and black hearts)
  * the pause and unpause animations
  * teleporting upwards
  * traveling upwards in a beam of light (replaced with a faster version)
  * the use animation for Telepills
  * the use animation for Blank Card when you have a teleport card
  * various animations during the Satan fight
  * various animations during the Mega Satan fight
  * various animations during The Haunt fight
  * various animations during the Big Horn fight
  * Hush's appear animation
  * Ultra Greed's appear and death animation

### Bug Fixes

* Angels will drop key pieces even if another angel is still alive in the room.
* Globins will permanently die upon the 5th regeneration to prevent Epic Fetus softlocks.
* Flaming Hoppers will now automatically die after 5 seconds of being immobile to prevent softlocks.
* Globins, Sacks, Fistula, and Teratoma will now properly die after defeating Mom, Mom's Heart, or It Lives!
* The Book of Sin and Mystery Sack generate actual random pickups.
* 9 Volt now properly synergizes with The Battery.
* Greed's Gullet works properly on Keeper.
* Taking Divorce Papers now causes Mysterious Paper to be removed from the trinket pool.
* AAA Battery now properly synergizes with The Battery.
* Double coins and nickels heal Keeper for their proper amount.
* Spiked Chests and Mimics that spawns in rooms that only have a narrow walkable path will spawn as normal chests to prevent unavoidable damage.
* Defeating Mega Satan no longer has a chance to immediately end the run.
* Returning from a crawlspace in a Boss Rush or Devil Deal will no longer send you to the wrong room.
* The Pony / White Pony can no longer be abused to steal Devil Room items.
* The babies on the Isaac fight can no longer spawn inside the hitbox of the player and will now randomly spawn throughout the room (as originally intended).
* The random beams of light from Isaac and Conquest are fixed such that they will now target the player.
* Multi-segment bosses will no longer drop more than one black heart when killed with Maw of the Void or Athame.

### Graphics & Sound Fixes

* The annoying vanilla in-game timer and score text will no longer appear. (Hold Tab to see a custom in-game timer.)
* Bosses will be faded during their death animation so that they do not interfere with seeing other items or enemies that happen to be behind them.
* Scared Hearts and Sticky Nickels now have unique sprites.
* The Distant Admiration, Forever Alone, and Friend Zone collectibles now match the color of the actual familiars.
* The Abaddon collectible is replaced with the pre-Booster Pack 5 version.
* The 20/20 collectible is now easier to see.
* The colors of some Purity auras have been changed to make them easier to see. Speed is now green and range is now yellow.
* The red spotted pill sprite has been changed to an all-red sprite so that it is easier to distinguish from other red pills.
* Pill sprites now have consistent orientations. (Thanks goes to [Nioffe](https://steamcommunity.com/id/nioffe) for creating the sprites in the [Consistent Pills](https://steamcommunity.com/sharedfiles/filedetails/?id=1418510121) mod.)
* The Locust of Famine graphic now matches the color of the flies.
* Daemon's Tail and Error now have outlines. (Thanks goes to [O_o](http://steamcommunity.com/profiles/76561197993627005) for creating the sprites in the [Trinket Outlines](http://steamcommunity.com/sharedfiles/filedetails/?id=1138554495) mod.)
* There are now unique card backs for Rules, Suicide King, ?, Blank Rune, and Black Rune. (Thanks goes to [piber20](https://steamcommunity.com/id/piber20) for creating the sprites in the [Unique Card Backs](https://steamcommunity.com/sharedfiles/filedetails/?id=1120999933) mod.)
* Charge keys have custom animations to help distinguish them from normal keys.
* Enemy fires are now red instead of yellow (so that players can distinguish between friendly fires).
* Enemy red creep is changed to green (so that it is easier to see).
* Friendly green creep is changed to red (so that it is easier to distinguish from enemy creep).
* Fog is removed for the purposes of lag reduction. (Thanks goes to [Dan](https://moddingofisaac.com/user/255) for creating the graphics for this in the [Fogless!](https://moddingofisaac.com/mod/950/fogless) mod.)
* The door opening sound will no longer play in crawlspaces.

<br />

## Additional Changes for Races

Racing+ allows players to perform [several different types of races](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-RACES.md) against each other. Some race formats may introduce additional changes.

<br />

## Additional Changes for Multi-Character Speedruns (Custom Challenges)

Racing+ has [several custom challenges](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md), each of which introduces additional changes to the game.

<br />

## Individual Room Changes

The technical specifics of all of the individual room changes are listed in a [separate page](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-ROOM.md).
