# Racing+ Mod Changes

## Website

If you want to learn more about Racing+, you can visit [the official website](https://isaacracing.net). If you want to know the changes that are present in the in-game mod, read on.

<br />

## Design Goals

In terms of what to change about the game, the mod has several goals, and attempts to strike a balance between them. However, certain things are prioritized. The goals are listed below in order of importance:

1) to reward skillful play (in the context of speedrunning and racing)
2) to make the game more fun to play
3) to fix bugs and imperfections
4) to make every character have at least one significantly unique thing about them
5) to keep the game as "vanilla" as possible

<br />

## List of Main Changes

### 1) Character Changes

(Most races are done with Judas. The changes to the other characters are mostly done for the [R+9](http://www.speedrun.com/afterbirthplus/full_game#R%2B_9_char) and R+14 speedrun categories.)

* All characters now start with the D6.
* Certain characters have their starting health changed so that they can consistently take a devil deal:
  * Judas starts with half a red heart and half a soul heart.
  * Blue Baby starts with three and a half soul hearts.
  * Azazel starts with half a red heart and half a soul heart.
* Isaac starts with The Battery.
* Maggy starts with the Soul Jar, a new passive item with the following effects:
  * You no longer gain health from soul/black hearts.
  * You gain a red heart container after picking up 4 soul/black hearts.
  * You always have a 100% devil deal chance if no damage is taken.
* Judas starts with a bomb instead of 3 coins.
* Eden starts with the Schoolbag. She will start with her random active item inside the bag.
* Lilith starts with the Schoolbag. She will start with Box of Friends inside the bag.
* Keeper starts with Greed's Gullet, Duality, and 50 cents.
* Apollyon now starts with the Schoolbag. He will start with Void inside the bag.

### 2) No Curses

All curses are automatically disabled.

### 3) Devil Room & Angel Room Changes

Devil Rooms and Angel Rooms without item pedestals in them have been removed.

### 4) Wrath of the Lamb Style Room Clear

Room clear was incorrectly ported from Wrath of Lamb to Rebirth; doors are intended to open at the beginning of an enemy's death animation, not at the end. The Racing+ mod fixes this to be the way it was originally intended.

### 5) Room Fixes

Hundreds of rooms with unavoidable damage or bugs have been fixed or deleted.

<br />

## Other Minor Bug Fixes & Quality of Life Changes

* Some items with no effect at all are removed:
  * the Karma trinket (all Donation Machines are removed when mods are enabled)
  * the Amnesia pill (this has no effect with curses disabled)
  * the ??? pill (this has no effect with curses disabled)
* Cutscenes are removed. (However, there is an option in the client to re-enable boss cutscenes for racers with cutscene skip muscle memory.)
* Some useless animations are removed:
  * teleporting upwards
  * the fade when entering a trapdoor
  * the fade when entering or exiting crawlspaces
  * the use animation for Telepills
  * the use animation for Blank Card when you have a teleport card
* Some things that are unseeded are now seeded:
  * Pandora's Box boss item rerolls
  * rerolls on items after being touched
  * rerolls on items after being purchased
  * Teleport!, Undefined, Cursed Eye, Broken Remote, and Telepills teleports
  * drops from Lil Chest and Crystal Ball
  * the number of enemies spawned from Portals (as a side effect of this, Portals will always spawn 5 enemies instead of 1-5 enemies.)
  * heart drops from multi-segment bosses
  * Krampus items (with Gimpy)
* Void Portals will automatically be deleted.
* The "drop" button will now immediately drop cards and trinkets. (This won't happen if you have the Schoolbag, Starter Deck, Little Baggy, Deep Pockets, or Polydactyly.)
* Troll Bombs and Mega Troll Bombs now always have a fuse timer of exactly 2 seconds.
* Special items are no longer special.
* Globins will permanently die upon the 5th regeneration to prevent Epic Fetus softlocks.
* Knights, Selfless Knights, Floating Knights, Bone Knights, Eyes, Bloodshot Eyes, Wizoobs, Red Ghosts, and Lil' Haunts no longer have invulernability frames after spawning.
* Mom's Hands, Mom's Dead Hands, Wizoobs, and Red Ghosts will now have faster attack patterns.
* The Book of Sin and Mystery Sack will now generate actual random pickups.
* Greed's Gullet will now properly work on Keeper.
* Double coins and nickels now heal Keeper for their proper amount.
* Eden's Soul will now always properly start at 0 charges.
* AAA Battery will now synergize with The Battery.
* 9 Volt will now synergize with The Battery.
* Betrayal no longer pauses the game and plays an animation before charming enemies.
* Reduced the pickup delay on all pedestal items from 0.67 seconds to 0.5 seconds.
* Maw of the Void and Athame will no longer be canceled upon exiting a room.
* All Spike Chests will now spawn as Mimics instead.
* Mimics are no longer rediculously trivial to spot.
* Fixed the unavoidable damage when Mimics happen to spawn on top of you.
* Fixed the unavoidable damage when Spiked Chests or Mimics happen to spawn in specific rooms that only have a narrow path surrounded by walls or pits.
* Hosts and Mobile Hosts are now immune to fear.
* Returning from a crawlspace in a Boss Rush will no longer send you to the wrong room.
* The recharge sound will no longer play at the beginning of a run.
* The door opening sound will no longer play in crawlspaces.
* Fixed the spelling of Humbling Bundle.
* Fixed the bug where the main menu would not show the bottom left hand corner of the title screen.
* Spawning a co-op baby will automatically kill the baby, return the heart to you, and delete all item pedestals in the room. (This is to prevent various co-op baby-related exploits.)
* Teleporting to the Dark Room via a Sacrifice Room will send you to the next floor instead. (This is to prevent exploiting races to The Lamb or Mega Satan.)
* The Polaroid or The Negative will be automatically removed depending on your run goal. By default, it will remove The Negative.
* The trapdoor or the beam of light on Womb 2 will be automatically removed depending on your run goal. By default, it will remove the trapdoor.

If you want, you can change the run goal manually in your "save.dat" file, located in the Racing+ mod folder. By default, this is located at:
```
C:\Users\[YourUsername]\Documents\My Games\Binding of Isaac Afterbirth+ Mods\racing+_dev\save.dat
```

<br />

## Additional Changes for Custom Rulesets

Historically, most speedruns and races have been unseeded with the goal of killing Blue Baby. However, there are other rulesets used:

### Seeded

* All characters start with The Compass in addition to their other items.
* The Cain's Eye trinket is removed from the game.
* All characters start with the Schoolbag (from Antibirth). (This is experimental and is subject to change.)

### Diversity

* Each racer starts with the same five random passive items. (This is in addition to the character's original passive items and resources.)
* For additional information, see [the documentation for diversity races](https://github.com/Zamiell/isaac-racing-mod/blob/master/README-DIVERSITY.md).

### Dark Room

* 4 gold chests will now spawn at the beginning of the Dark Room (instead of red chests).

### Mega Satan

* A Get out of Jail Free Card will now spawn next to the Mega Satan door on both The Chest and the Dark Room.

<br />

## Individual Room Changes

The [technical specifics of all of the individual room changes are listed in a separate document](https://github.com/Zamiell/isaac-racing-mod/blob/master/CHANGES-ROOM.md), for those who care to know the nitty-gritty details.

<br />
