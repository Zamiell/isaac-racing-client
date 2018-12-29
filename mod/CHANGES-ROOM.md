# Racing+ Mod Room Changes

## Table of Contents

1. [Balance Changes](#balance-changes)
2. [Softlock Fixes](#softlock-fixes)
3. [Unavoidable Damage Fixes](#unavoidable-damage-fixes)
3. [Bug Fixes](#bug-fixes)
4. [Miscellaneous Changes](#miscellaneous-changes)
5. [Rooms That Were Deliberately Not Changed](#rooms-that-were-deliberately-not-changed)

<br />





## Balance Changes

Firstly, some rooms were purely changed for balance (racing) reasons. Rooms that were changed for other reasons are listed in different sections.

<br />

### Devil Room Rebalancing

* Items per room have been redistributed for consistency. The average item per room is increased from 1.53 to 1.86.
* All enemies are removed.
* Extra hazards have been added to some rooms.
* It is no longer possible to get heart drops from fires in Devil Rooms.
* All rooms with 1 item have an additional reward:
  * #16: 4 bombs
  * #4: ? card
  * #7: black rune
  * #11: Devil Beggar
* All rooms with 2 or more item pedestals have no extra rewards.
* Rooms without 4 exits have been changed to have 4 exits.
* Some rooms have custom weight.

<br />

### Angel Room Rebalancing

* Items per room have been redistributed for consistency. The average item per room is increased from 1.65 to 1.88.
* All rooms with 1 item pedestal have 2 Angel Statues.
* All rooms with 2 item pedestals have 1 Angel Statue.
* Rooms without 4 exits have been changed to have 4 exits.
* Rooms without a weight of 1.0 have been changed to have weight 1.0.

<br />

### Trapdoor Room

On Sheol, there exists a room with a trapdoor that takes you directly to the Dark Room without having to fight Satan. This puts too much of an extreme lower bound on the clear time of the floor.

The removed room is as follows:
* Sheol: #290

<br />





## Softlock Fixes

A softlock is a condition where:
* it is impossible to beat the run
* the player is forced to save and quit to beat the run
* the player is forced to stand still for an unreasonable amount of time to beat the run

There are several softlocks in the vanilla game.

<br />

### Low Range Fix

Low range builds softlock in certain rooms. The rooms are fixed by moving the enemies closer.

The changed rooms are as follows:
* Caves/Flooded: #226
* Caves/Catacombs/Flooded: #305
* Depths/Necropolis/Dank: #226, #417
* Womb/Utero/Scarred: #458, #459

<br />

### Pooter Fix

On certain rooms in the Basement/Cellar, some Pooters can fly over rocks, causing a pseudo-softlock.

The changed rooms are as follows:
* Basement/Burning: #135, #391

The deleted room is as follows:
* Basement/Burning: #811

<br />

### Boil Fix

In one room, there are Boils behind a Key Block, which can lead to a softlock if you have no keys or bombs. The stacked Boils have been removed.

The changed room is as follows:
* Womb/Utero/Scarred: #692

<br />

### Stone Grimace Fix

In certain rooms, having very large tears causes a softlock in rooms with Stone Grimaces next to poops and/or fires. This is because the Stone Grimace hitbox takes priority.

The changed rooms are as follows:
* Necropolis: #936 (deleted the fire)
* Womb/Utero/Scarred: #705 (moved the Red Poops to the side and added missing spikes)
* Womb: #847 (removed the Red Poop)

<br />

### Bomb Puzzle Room Fix

The bomb puzzle room with four entrances has many problems with it:
* The random bomb drops (5.40.0) were replaced with set bomb drops (5.40.1) to prevent troll bombs from spawning, which can softlock the room.
* A rock was also removed to prevent a softlock if the player enters from the left side.
* On the Dank Depths, any rocks that are randomly replaced with spikes are removed in order to prevent unavoidable damage.

The changed room is as follows:
* Depths/Necropolis/Dank: #41

<br />





## Unavoidable Damage Fixes

Racing+ is somewhat conservative with what it classifies as unavoidable damage. Difficult rooms are not considered unavoidable damage. Many hours have been spent testing the viability of rooms with various builds.

<br />

### Unfair Narrow Room Adjustment

While not technically unavoidable, many narrow rooms have near-impossible attack patterns, especially on Dr. Fetus builds.

The changed rooms are as follows:
* Burning: #755 (Rag Man) (removed a pot)
* Depths/Necropolis/Dank: #639 (Mom's Dead Hand) (deleted)
* Womb/Utero/Scarred: #611 (Mom's Dead Hand) (deleted)
* Cathedral: #286 (Uriel) (changed to 1x1)
* Cathedral: #291 (Gabriel) (changed to 1x1)
* Chest: #262 (Headless Horseman Head x2) (changed to 1x1)
* Chest: #269 (Mega Maw) (changed to 1x1)
* Chest: #264 (Monstro x2) (changed to 1x1)
* Chest: #273 (Monstro x2) (deleted)
* Chest: #275 (The Fallen) (changed to 1x1)
* Chest: #283 (Gurdy Jr.) (deleted)
* Chest: #309 (Monstro x4) (deleted)
* Dark Room: #255, #274 (Teratoma) (deleted)
* Dark Room: #256, #275 (The Fallen) (deleted)
* Dark Room: #270 (4 Nulls) (deleted)
* Dark Room: #312 (5 Nulls) (deleted)
* Boss: #2305 (Krampus) (deleted)
* Boss: #2306 (Krampus) (deleted)
* Boss: #4036 (War) (deleted)
* Boss: #5035 (Mega Maw) (deleted)
* Boss: #5043 (The Gate) (deleted)
* Miniboss: #2064 (Pride) (deleted)
* Miniboss: #2065 (Pride) (deleted)

<br />

### TNT Barrel Fix

One room has TNT barrels that will immediately explode if the player is holding Mom's Knife. This has been fixed by replacing the barrels with bomb rocks.

The changed rooms are as follows:
* Basement/Cellar/Burning: #748

<br />

### Adversary Fix

If two Adversaries get close to a wall, the Brimstone attack can be unavoidable. This is mitigated by moving the Adversaries closer to the middle of the room.

The changed rooms are as follows:
* Chest: #41
* Dark Room: #7
* Dark Room: #50 (double Adversary, 2x1)
* Dark Room: #78 (triple Adversary, 2x2)

<br />

### Maneuverability Fix

Some rooms are so packed with entities that they are unavoidable damage on Dr. Fetus and Ipecac. In such rooms, space has been cleared near the doors.

The changed room is as follows:
* Womb/Utero/Scarred: #825 (narrow room with Nerve Endings)
* The Chest: #289 (narrow room filled with Red Poop)

<br />

### Leaper & Pokey Room Fix

On the room with the two Leapers and two Pokeys, certain attack patterns can lead to unavoidable damage. The room has been made slightly more spacious to account for this.

The changed room is as follows:
* Depths/Dank: #110

<br />

### Red Fire Puzzle Room Removal

The puzzle rooms with the red fires along the sides of the room have no consistent strategy with which to avoid the random shots.

The removed room is as follows:
* Basement/Cellar/Burning: #771

<br />

### Close Fires Fix

In one room, fires spawn close to the entrance. If the fire becomes a champion red fire, then the player can take unavoidable damage. This bug has been fixed by replacing the Fire with Fire Places, which are guaranteed to not spawn as red fires.

The changed rooms are as follows:
* Depths/Necropolis/Dank: #863

<br />

### Hive Fix

In one room, the Drowned Chargers that spawn from a Hive can be unavoidable damage. The Hives have been slightly moved to accommodate for this.

The changed room is as follows:
* Caves/Flooded: #519

<br />





## Bug Fixes

The Racing+ mod tries to fix as many bugs as possible.

<br />

### Boss Room Door Fix (Part 1)

It is not possible for Devil Room doors to spawn on boss rooms that only have one entrance. For this reason, several rooms were adjusted to allow for at least two entrances.

The changed rooms are as follows:
* #2065 (Fistula)
* #5026 (Dingle)
* #5044 (The Gate)
* #5145 (Gurglings)

<br />

### Boss Room Door Fix (Part 2)

If you have Duality and there is only 2 entrances to a boss room, the Angel Room will not spawn. For this reason, all non-narrow rooms were adjusted to allow for a third door where possible.

* #1025, #1027, #1028, #1048, #1049 (Larry Jr.)
* #1045 (Monstro)
* #1057 (Chub)
* #1089, #1095 (Little Horn)
* #1099 (Brownie)
* #2064 (Fistula)
* #3264, #3265, #3266 (The Hollow)
* #3701, #3713, #3714, #3716, #3756, #3760, #3762, #3765, #3766, #3767, #3769, #3807, #3811 (Double Trouble)
* #4012 (Famine)
* #4033 (Conquest)
* #5033 (Mega Maw)
* #5083 (Dark One)
* #5106 (Polycephalus)

<br />

### Invisible Hitbox Fix

On Pin, Frail, and Scolex fights, there is an invisible hitbox at the spawn point shortly after they are loaded. On some rooms, this is near the entrance. This is fixed by moving the spawn to the center of the room.

The changed rooms are as follows:
* #3370 (Pin)
* #3371 (Pin)
* #3372 (Pin)
* #3374 (Pin)
* #3376 (Pin)
* #3388 (Frail)
* #1070 (Scolex)
* #1071 (Scolex)
* #1073 (Scolex)
* #1074 (Scolex)

<br />

### Boss Room Maneuverability Fix

If the player is out of bombs and a Devil Room spawns in certain orientations of certain rooms, they will either not be able to access it or be forced to take the boss item in order to see the deal. Alternatively, a player may be forced to take the boss item in order to exit the floor. This bug is fixed by moving/deleting the rocks/pits respectively.

The changed rooms are as follows:
* #1066 (Gurdy)
* #2031 (Loki)
* #3311 (Lokii)
* #4041 (Death)
* #5106 (Polycephalus)

<br />

### Door Fixes

On certain rooms, doors were poorly placed so that they are either too close to entities or disabled for no good reason.

The changed rooms are as follows:
* Basement/Cellar/Burning: #772
* Chest: #39 (double Mega Maw)
* Larry Jr.: #1125

<br />

### Entity Stacking Fixes

On one room, [Edmund forgot to implement entity stacking](http://bindingofisaac.com/post/90431619124/insert-size-matters-joke-here).

The changed rooms are as follows:
* Caves/Flooded: #267

<br />

### Duplicate Rooms

Some rooms are incorrectly duplicated.

The deleted rooms are as follows:
* Basement/Burning: #968 (duplicated from #883)
* Cellar: #955 (duplicated from #866)
* Caves/Catacombs/Flooded: #814 (duplicated from #794)
* Caves/Catacombs/Flooded: #815 (duplicated from #795)
* Caves/Catacombs/Flooded: #816 (duplicated from #796)
* Caves/Catacombs/Flooded: #817 (duplicated from #797)
* Caves/Catacombs/Flooded: #819 (duplicated from #799)
* Caves/Catacombs/Flooded: #820 (duplicated from #800)
* Caves/Catacombs/Flooded: #821 (duplicated from #801)
* Caves/Catacombs/Flooded: #822 (duplicated from #802)
* Caves/Catacombs/Flooded: #823 (duplicated from #803)
* Caves/Catacombs/Flooded: #824 (duplicated from #784)
* Caves/Catacombs/Flooded: #825 (duplicated from #785)
* Caves/Catacombs/Flooded: #826 (duplicated from #786)
* Caves/Catacombs/Flooded: #827 (duplicated from #787)
* Caves/Catacombs/Flooded: #828 (duplicated from #788)
* Caves/Catacombs/Flooded: #829 (duplicated from #789)
* Caves/Catacombs/Flooded: #830 (duplicated from #790)
* Caves/Catacombs/Flooded: #831 (duplicated from #791)
* Caves/Catacombs/Flooded: #832 (duplicated from #792)
* Caves/Catacombs/Flooded: #833 (duplicated from #793)
* Caves/Catacombs/Flooded: #834 (duplicated from #775)
* Caves/Catacombs/Flooded: #835 (duplicated from #776)
* Caves/Catacombs/Flooded: #836 (duplicated from #777)
* Caves/Catacombs/Flooded: #837 (duplicated from #778)
* Caves/Catacombs/Flooded: #838 (duplicated from #779)
* Caves/Catacombs/Flooded: #839 (duplicated from #780)
* Caves/Catacombs/Flooded: #840 (duplicated from #781)
* Caves/Catacombs/Flooded: #841 (duplicated from #782)
* Caves/Catacombs/Flooded: #842 (duplicated from #783)
* Depths/Necropolis/Dank: #859 (duplicated from #518)
* Depths/Necropolis/Dank: #858 (duplicated from #775)
* Depths/Necropolis/Dank: #857 (duplicated from #776)
* Depths/Necropolis/Dank: #856 (duplicated from #777)
* Depths/Necropolis/Dank: #855 (duplicated from #778)
* Depths/Necropolis/Dank: #854 (duplicated from #779)
* Depths/Necropolis/Dank: #853 (duplicated from #780)
* Depths/Necropolis/Dank: #852 (duplicated from #781)
* Depths/Necropolis/Dank: #851 (duplicated from #782)
* Depths/Necropolis/Dank: #850 (duplicated from #783)
* Depths/Necropolis/Dank: #849 (duplicated from #784)
* Depths/Necropolis/Dank: #848 (duplicated from #785)
* Depths/Necropolis/Dank: #847 (duplicated from #786)
* Depths/Necropolis/Dank: #846 (duplicated from #519)
* Depths/Necropolis/Dank: #845 (duplicated from #520)
* Depths/Necropolis/Dank: #844 (duplicated from #521)
* Depths/Necropolis/Dank: #843 (duplicated from #522)
* Depths/Necropolis/Dank: #842 (duplicated from #523)
* Depths/Necropolis/Dank: #841 (duplicated from #524)
* Depths/Necropolis/Dank: #840 (duplicated from #525)
* Depths/Necropolis/Dank: #839 (duplicated from #526)
* Depths/Necropolis/Dank: #838 (duplicated from #527)
* Depths/Necropolis/Dank: #837 (duplicated from #692)
* Depths/Necropolis/Dank: #836 (duplicated from #738)
* Depths/Necropolis/Dank: #835 (duplicated from #739)
* Depths/Necropolis/Dank: #834 (duplicated from #740)
* Depths/Necropolis/Dank: #833 (duplicated from #741)
* Depths/Necropolis/Dank: #832 (duplicated from #742)
* Depths/Necropolis/Dank: #831 (duplicated from #743)
* Depths/Necropolis/Dank: #830 (duplicated from #744)
* Depths/Necropolis/Dank: #829 (duplicated from #745)
* Depths/Necropolis/Dank: #828 (duplicated from #746)
* Depths/Necropolis/Dank: #827 (duplicated from #747)
* Depths/Necropolis/Dank: #826 (duplicated from #748)
* Depths/Necropolis/Dank: #825 (duplicated from #749)
* Depths/Necropolis/Dank: #824 (duplicated from #774)
* Womb/Utero/Scarred: #822 (duplicated from #797)
* Womb/Utero/Scarred: #821 (duplicated from #798)
* Womb/Utero/Scarred: #820 (duplicated from #799)
* Womb/Utero/Scarred: #819 (duplicated from #800)
* Womb/Utero/Scarred: #818 (duplicated from #801)
* Womb/Utero/Scarred: #817 (duplicated from #802)
* Womb/Utero/Scarred: #816 (duplicated from #803)
* Womb/Utero/Scarred: #815 (duplicated from #804)
* Womb/Utero/Scarred: #814 (duplicated from #805)
* Womb/Utero/Scarred: #813 (duplicated from #806)
* Womb/Utero/Scarred: #812 (duplicated from #807)
* Womb/Utero/Scarred: #811 (duplicated from #808)
* Womb/Utero/Scarred: #810 (duplicated from #809)
* Womb/Utero/Scarred: #796 (duplicated from #515)
* Womb/Utero/Scarred: #795 (duplicated from #516)
* Womb/Utero/Scarred: #794 (duplicated from #517)
* Womb/Utero/Scarred: #793 (duplicated from #518)
* Womb/Utero/Scarred: #792 (duplicated from #519)
* Womb/Utero/Scarred: #791 (duplicated from #520)
* Womb/Utero/Scarred: #790 (duplicated from #521)
* Womb/Utero/Scarred: #789 (duplicated from #522)
* Womb/Utero/Scarred: #788 (duplicated from #523)
* Womb/Utero/Scarred: #787 (duplicated from #524)
* Womb/Utero/Scarred: #786 (duplicated from #525)
* Womb/Utero/Scarred: #785 (duplicated from #526)
* Womb/Utero/Scarred: #784 (duplicated from #527)
* Womb/Utero/Scarred: #783 (duplicated from #738)
* Womb/Utero/Scarred: #782 (duplicated from #739)
* Womb/Utero/Scarred: #781 (duplicated from #740)
* Womb/Utero/Scarred: #779 (duplicated from #742)
* Womb/Utero/Scarred: #778 (duplicated from #743)
* Womb/Utero/Scarred: #777 (duplicated from #744)
* Womb/Utero/Scarred: #776 (duplicated from #745)
* Womb/Utero/Scarred: #775 (duplicated from #746)
* Womb/Utero/Scarred: #774 (duplicated from #747)
* Womb/Utero/Scarred: #748 (duplicated from #748)

<br />





## Miscellaneous Changes

### Graphics

Props were removed from the starting room for better visibility.

<br />

### Donation Machine Room Removal

One room in the Necropolis has a donation machine in it. Since removing curses also removes donation machines from the game, this room is largely useless.

The removed room is as follows:
* Necropolis: #469

<br />

### Empty Room Removal

A small number of rooms in the game do not have anything in them. Some other rooms do not have anything in them except for a few rocks.

The removed rooms are as follows:
* Basement/Burning: #315
* Basement/Cellar/Burning: #39
* Caves/Flooded: #170
* Depths/Dank: #428
* Cathedral: #57
* Cathedral/Sheol: #73, #89
* Chest: #42

Some rooms have the chance to be empty because of stacked entities.

The changed rooms are as follows:
* Basement/Cellar/Burning: #875 (Portal)

<br />

### Close Enemies Fix

Due to recent bug fixes in May 2018, most enemies that spawn near an entrance are no longer completely unavoidable damage. However, enemies that spawn very close to doors are unfair in certain circumstances, and it is more reasonable to have enemies spawn at least 2 squares away from the player.

The changed rooms are as follows:
* Basement/Burning: #393, #359 (Mulligan)
* Basement/Cellar/Burning: #129 (Mulligoon)
* Basement/Cellar/Burning: #130 (Mulligan/Mulligoon)
* Cellar: #359 (Mulligan)
* Caves/Flooded: #50 (Boom Fly)
* Caves/Flooded: #141 (Clotty)
* Caves/Flooded: #167 (Attack Fly)
* Caves/Flooded: #255 (Maggot)
* Caves/Flooded: #553 (Hive)
* Caves/Catacombs/Flooded: #46, #440, #518 (Boom Fly)
* Caves/Catacombs/Flooded: #548 (Drowned Hive)
* Caves/Catacombs/Flooded: #919 (Maggot)
* Catacombs: #267 (Night Crawler)
* Flooded: #974 (Boom Fly)
* Flooded: #993 (removed top door)
* Flooded: #994 (removed bottom door)
* Flooded: #998, #1017, #1028 (deleted the room)
* Flooded: #999 (Red Maw)
* Flooded: #1003, #1010, #1015, #1044 (deleted the left and right doors)
* Flooded: #1004, #1008, #1013, #1014, #1020, #1027, #1049 (top and bottom doors)
* Depths/Dank: #11 (Boom Fly)
* Depths/Dank: #16 (Brain)
* Womb/Utero/Scarred: #182, #471, #733 (Gurglings)
* Womb/Utero/Scarred: #203 (Lump)
* Womb/Utero/Scarred: #333 (Fistula)
* Womb/Utero/Scarred: #410 (Sucker)
* Womb/Utero/Scarred: #757 (Guts)
* Womb/Scarred: #507 (Blastocyst)
* Womb/Scarred: #555 (Gurglings)
* Utero: #5 (Guts)
* Utero: #133 (Gurdy Jr.)
* Cathedral/Sheol: #30 (Kamikaze Leech)
* Sheol: #212 (Cage)
* Chest: #35, #87, #301 (Gurglings)
* Chest: #53, #72, #84 (Fistula)
* Chest: #54 (Blastocyst)
* The Dark Room: #104 (Sisters Vis)
* Dark Room: #238, #272 (Kamikaze Leech)
* Dark Room: #264 (Bone Knight)
* Chub: #1033 (Charger)
* Carrion Queen: #3272
* Carrion Queen: #3273
* I AM ERROR: #26 (moved pickups)

<br />

### Hush Fly Fix

* The Hush Flies that are placed in some rooms are given the same armor scaling that Hush is, so they have been replaced with Attack Flies.

The changed rooms are as follows:
* Depths/Necropolis/Dank: #866, #894

<br />

### Out of Bounds Fix

Rooms with entities that have negative coordinates (out of bounds) have been placed in-bounds. This does not affect gameplay in any way.

The changed rooms are as follows:
* Caves/Flooded: #203, #303
* Caves/Catacombs/Flooded: #406, #427, #428, #429
* Depths/Dank: #457, #460, #463, #471, #472
* Depths/Necropolis/Dank: #455

<br />

### Symmetry Fix

Certain rooms in the game were probably meant to be symmetrical, but one entity or tile was incorrectly placed. This is fixed.

The changed rooms are as follows:
* Basement/Burning: #581
* Caves/Flooded: #28, #120, #416, #541
* Flooded: #939
* Cathedral: #11, #12, #23, #41, #60
* Monstro II: #1051
* The Gate: #5042
* Headless Horseman: #4050

<br />

### Miscellaneous

* Double Trouble room #3762 was changed to move the skulls away from the trapdoor (so that spawned Hosts would not interact with the trapdoor).
* Boss room #9999 was added for the "Choose Char Order" custom challenge.
* Boss room #9998 was added for the "Jr. Fetus Practice" and the "Mahalath Practice" custom challenges.

<br />





## Rooms That Were Deliberately Not Changed

* Basement/Cellar/Burning #401 - This is a 2x1 room with 4 Pooters. If there is a tinted rock in the room, you should ignore it and hustle to kill the Pooters before they get into a softlock position.
* Basement/Cellar/Burning #603 - This is a narrow room with 2 Mullibooms. On base speed, you have enough room to dodge them.
* Cellar/Burning #752 - This is a narrow room with 3 Mega Troll Bombs. This room is not unavoidable with deterministic fuse timers.
* Basement/Cellar/Burning #767 - This is a room with 2 Mega Troll Bombs. This room is not unavoidable with deterministic fuse timers.
* Cellar #766 - This is a 1x1 room with 3 mega troll bombs, but if you stand completely still, they will not damage you.
* Caves/Flooded #161, #271, #553 - If the enemy by the top door is a explosive champion, the player will not be hit. If the enemy by the top door is a tear champion, the player has a full second to react upon entering.
* Caves/Flooded #692 - This is a narrow 1x1 room filled with poops. With Ipecac, you can safely shoot left from the top right-hand corner. With Dr. Fetus, you can walk diagonally through the poops to plant your first bomb. With Dr. Fetus and Bomber Boy, it is unavoidable damage.
* Caves/Catacombs/Flooded #862 - This is a room with 5 Crazy Long Legs. On a low damage build, it is possible for the spiders to come at you from every angle and cause unavoidable damage. However, spider movement is RNG dependent and actual unavoidable damage is rare.
* Necropolis #699 - This is a room with 2 Mega Troll Bombs and 4 Troll Bombs. This room is not unavoidable with deterministic fuse timers.
* Sheol #285 - This is a narrow room with 3 Mega Troll Bombs and 1 Troll Bomb. You can simply leave this room, as there are no enemies that cause the doors to become closed.
* Dark Room #287 - This is a room with 3 Mega Troll Bombs and an Imp. If you stand completely still, the troll bombs will not damage you.
* Chest #39 - This is a room with 2 Mega Maws. Even with the champion version, there is enough time to react to the patterns.
* Mama Gurdy - You have enough time to dodge the spikes before the hitbox appears.
* Daddy Long Legs - You have enough time to dodge the multiple stomp attack.
