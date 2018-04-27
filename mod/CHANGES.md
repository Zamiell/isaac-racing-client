# Racing+ Mod Changes

## Website

If you want to learn more about Racing+, you can visit [the official website](https://isaacracing.net). If you want to know the changes that are present in the in-game mod, read on.

<br />

## Table of Contents

1. [Design Goals](#design-goals)
2. [List of Main Changes](#list-of-main-changes)
3. [Other Mods Included](#other-mods-included)
4. [List of Minor Changes](#list-of-minor-changes)
5. [Additional Changes for Custom Race Rulesets](#additional-changes-for-custom-race-rulesets)
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
* Judas starts with a bomb instead of 3 coins (so that he can get a Treasure Room item without spending a soul heart).
* Samson no longer starts with the Child's Heart (a quality of life change).
* Eden starts with the Schoolbag. They will start with their random active item inside the bag. (This is to preserve the active item.))

### 2) No Curses

All curses are automatically disabled.

### 3) Devil Room & Angel Room Changes

Devil Rooms and Angel Rooms without item pedestals in them have been removed.

### 4) Wrath of the Lamb Style Room Clear

Rooms are considered cleared at the beginning of an enemy's death animation, rather than the end. (This was the way the game was originally intended to be, but it was incorrectly ported to Rebirth.)

### 5) Room Fixes

Hundreds of rooms with unavoidable damage or bugs have been fixed or deleted.

### 6) Room Flipping

While there are thousands of rooms in the game, many players have already seen them all. To increase run variety, asymmetrical rooms have a chance to be flipped on the X axis, Y axis, or both axises.

<br />

## Other Mods Included

* [Samael](http://steamcommunity.com/sharedfiles/filedetails/?id=897795840), a custom character created by [Ghostbroster](http://steamcommunity.com/id/ghostbrosterconnor). He is a melee character that uses his scythe to attack enemies. In Racing+, Samael starts with D6, the Schoolbag, the Wraith Skull, and 1 bomb.
* [Unique Card Backs](https://steamcommunity.com/sharedfiles/filedetails/?id=1120999933), a quality of life / sprite improvement mod by [piber20](https://steamcommunity.com/id/piber20).

<br />

## List of Minor Changes

### Custom Hotkeys

* Racing+ allows you to bind two new hotkeys via a custom challenge:
  * a drop button that will immediately drop all trinkets and pocket items
  * a dedicated Schoolbag switch button
* Binding these hotkeys is optional. If they are not bound, Racing+ will revert to the vanilla behavior.

### Gameplay & Quality of Life Changes

* Some items with no effect are removed:
  * the Karma trinket (all Donation Machines are removed when curses are disabled)
  * the Amnesia pill (this has no effect when curses are disabled)
  * the ??? pill (this has no effect when curses are disabled)
* Some things that are unseeded are now seeded:
  * rerolls on items after being touched or purchased
  * Teleport!, Undefined, Cursed Eye, Broken Remote, and Telepills teleports
  * heart drops from multi-segment bosses
  * Krampus items (with Gimpy)
  * cards from Sloth, Super Sloth, Pride, and Super Pride
* Void Portals are automatically deleted.
* The restart key immediately restarts the game. (To perform a fast-restart on floors 2 and beyond, you need to double tap R.)
* Special items are no longer special.
* Troll Bombs and Mega Troll Bombs always have a fuse timer of exactly 2 seconds.
* Knights, Selfless Knights, Floating Knights, Bone Knights, Eyes, Bloodshot Eyes, Wizoobs, Red Ghosts, and Lil' Haunts no longer have invulernability frames after spawning.
* Mom's Hands, Mom's Dead Hands, Wizoobs, and Red Ghosts have faster attack patterns.
* Betrayal no longer pauses the game and plays an animation before charming enemies.
* The disruptive teleport that occurs when entering a room with Gurdy, Mom, Mom's Heart, or It Lives! no longer occurs.
* The pickup delay on reloaded pedestal items is decreased from 18 frames to 15 frames.
* Having Duality now prevents getting a narrow boss room on floors 2 through 7.
* All Spike Chests will spawn as Mimics instead.
* Mushrooms can no longer spawn outside of floors 3 and 4. (They will spawn as Hosts instead.) This prevents instantaneous damage when you walk over a skull with Leo or Thunder Thighs.
* Hosts and Mobile Hosts are now immune to fear. This prevents bugs where feared Hosts will not properly play animations.
* The "Would you like to do a Victory Lap!?" popup no longer appears after defeating The Lamb.
* Spawning a co-op baby will automatically kill the baby, return the heart to you, and delete all item pedestals in the room. (This is to prevent various co-op baby-related exploits.)

### Streamlined Path

* The Polaroid or The Negative will be automatically removed depending on your run goal. By default, it will remove The Negative.
* The trapdoor or the beam of light on Womb 2 will be automatically removed depending on your run goal or which photo you have. By default, it will remove the trapdoor.

If you want, you can change the run goal manually in your "save1.dat" file, located in the Racing+ mod folder. By default, this is located at:
```
C:\Users\[YourUsername]\Documents\My Games\Binding of Isaac Afterbirth+ Mods\racing+_dev\save1.dat
```
(The "save1.dat" file corresponds to save slot #1. If you play on save slot #2 or #3, edit "save2.dat" or "save3.dat" accordingly.)

### Cutscene & Animation Removal

* The cutscenes that occur when you launch the game and you finish a run are removed.
* The cutscenes that occur before each boss are removed.
* Some animations are removed for the purposes of eliminating needless downtime:
  * the fade when entering a new floor (replaced with a custom animation)
  * the fade when entering or exiting crawlspaces (replaced with a normal room transition animation)
  * teleporting upwards
  * the use animation for Telepills
  * the use animation for Blank Card when you have a teleport card
  * various animations during the Satan fight
  * various animations during the Mega Satan fight
  * various animations during The Haunt fight
  * various animations during the Big Horn fight

### Bug Fixes

* Globins will permanently die upon the 5th regeneration to prevent Epic Fetus softlocks.
* Flaming Hoppers will now automatically die after 5 seconds of being immobile to prevent softlocks.
* Globins, Sacks, Fistula, and Teratoma will now properly die after defeating Mom, Mom's Heart, or It Lives!
* Dople's and Evil Twins will no longer shoot tears on the first frame after a room loads. (This is to prevent unavoidable damage, which can happen even if the player is not shooting.)
* The Book of Sin and Mystery Sack generate actual random pickups.
* Greed's Gullet works properly on Keeper.
* Double coins and nickels heal Keeper for their proper amount.
* Eden's Soul always properly starts at 0 charges.
* AAA Battery now properly synergizes with The Battery.
* 9 Volt now properly synergizes with The Battery.
* You will no longer take unavoidable damage when Mimics happen to spawn on top of you.
* You will no longer take unavoidable damage when Spiked Chests or Mimics spawn in rooms that only have a narrow path surrounded by walls or pits. (They will spawn as Brown Chests instead.)
* You no longer have a chance to be sent to the menu after defeating Mega Satan.
* The Lamb can no longer move while he is doing a brimstone attack. (This can cause unavoidable damage in certain situations.)
* Returning from a crawlspace in a Boss Rush or Devil Deal will no longer send you to the wrong room.

### Graphics & Sound Fixes

* Bosses will be faded during their death animation so that they do not interfere with seeing other items or enemies that happen to be behind them.
* The annoying vanilla in-game timer and score text will no longer appear.
* Charge bars are no longer obnoxiously big.
* The colors of some Purity auras have been changed to make them easier to see. Speed is now green and range is now yellow.
* The recharge sound will no longer play at the beginning of a run.
* The door opening sound will no longer play in crawlspaces.
* The bottom left hand corner of the title screen will now properly show.
* Fog is removed for the purposes of lag reduction. (Thanks goes to [Dan](https://moddingofisaac.com/user/255) for originally doing this in the [Fogless!](https://moddingofisaac.com/mod/950/fogless) mod.)
* Daemon's Tail, Error (404), Karma, and No! now have outlines. (Thanks goes to [O_o](http://steamcommunity.com/profiles/76561197993627005) for creating the sprites in the [Trinket Outlines](http://steamcommunity.com/sharedfiles/filedetails/?id=1138554495) mod.

<br />

## Additional Changes for Custom Race Rulesets

Historically, most speedruns and races have been unseeded with the goal of killing Blue Baby. However, there are other rulesets used:

### Seeded

* All characters start with The Compass and the Schoolbag in addition to their other items.
* If the character is supposed to start with an item that is not the D6, that item will be inside the Schoolbag.
* The Cain's Eye trinket is removed from the game.
* There is a custom death mechanic:
  * Instead of dying, players will respawn in the previous room with 1.5 soul hearts.
  * They will have a "debuff" effect that removes all of your items. The debuff will last 45 seconds.
  * This mechanic doesn't apply to deaths from devil deals or Sacrifice Rooms.

### Diversity

* Each racer starts with the same five random items. (This is in addition to the character's original passive items and resources.)
* For additional information, see [the documentation for diversity races](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/README-DIVERSITY.md).

### Unseeded (Lite)

* All Treasure Rooms on Basement 1 will have two items.
* Tech X, Mom's Knife, Epic Fetus, and Ipecac are automatically rerolled if you see them in a Basement 1 treasure room.
* The "fast-reset" feature is disabled.
* The "fast-clear" feature is disabled.
* Mom's Hands, Mom's Dead Hands, Wizoobs, and Red Ghosts are no longer sped up.

### Dark Room

* 4 gold chests will now spawn at the beginning of the Dark Room (instead of red chests).
* Teleporting to the Dark Room via a Sacrifice Room on floors 1 through 8 will send you to the next floor instead.

### Mega Satan

* The door to Mega Satan will automatically open upon reaching The Chest or the Dark Room.
* Teleporting to the Dark Room via a Sacrifice Room on floors 1 through 8 will send you to the next floor instead.

### Everything

* Both The Polaroid and The Negative will spawn after defeating Mom. Neither are required to complete the run.
* After defeating It Lives!, the beam of light will always spawn to take you to The Cathedral.
* After defeating Isaac, a trapdoor will spawn to take you to Sheol.
* After defeating Satan, a beam of light will spawn to take you to The Chest.
* After defeating Blue Baby, a trapdoor will spawn to take you to the Dark Room.
* After defeating The Lamb, backtrack to the starting room and the Mega Satan door will automatically open.
* Defeat Mega Satan to complete the run.
* Teleporting to the Dark Room via a Sacrifice Room on floors 1 through 8 will send you to the next floor instead.

<br />

## Additional Changes for Multi-Character Speedruns (Custom Challenges)

Racing+ has several custom challenges which are [documented on a separate page](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md).

<br />

## Individual Room Changes

The technical specifics of all of the individual room changes are listed in a [separate document](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-ROOM.md).

<br />
