# Racing+ Mod Version History

Note that the Racing+ Mod version will almost always match the client version. This means that the version number of the mod may increase, but have no actual new in-game changes. All gameplay related changes will be listed below.

* *0.3.3* - Unreleased
  * ?
* *0.3.2* - March 27th
  * Pressing the reset key will now instantly reset the game.
  * The long and annoying fade out / fade in animation between floors has been replaced with something better.
  * The Schoolbag will now work properly with the new Booster Pack items.
  * Fixed the unavoidable damage when Spiked Chests or Mimics spawn in Caves/Catacombs room #19.
  * If Eden starts with Book of Sin, Crystal Ball, Betrayal, or Smelter, she will now start with the Racing+ custom version of the item.
* *0.2.78* - March 19th
  * Special items are no longer special. This means you won't be negatively affected anymore by seeing a D100 or The Ludovico Technique.
  * Fixed the bug where items that are not fully decremented on sight will no longer mostly reroll into themselves.
* *0.2.77* - March 19th
  * Fixed the bug where starting the Boss Rush would not grant a charge to the Schoolbag item. Note that actually clearing the Boss Rush still won't give any charges, due to limiations with the Afterbirth+ API.
  * Fixed the bug where fart-reroll items would start at 0 charges.
* *0.2.74* - March 18th
  * Fixed the bug where the Depths STB was not being loaded properly.
* *0.2.73* - March 17th
  * Fixed the bug where Keeper would lose a coin container under certain conditions.
* *0.2.72* - March 17th
  * Fixed the (vanilla) unavoidable damage when a Mimic spawns on top of you.
  * All Spike Chests will now spawn as Mimics instead, since there isn't really a point in having both of them.
  * Mimics are rediculously trivial to spot, so their graphics have been experimentally reverted back to the pre-nerf graphics. You can tell them apart from normal chests by just looking for the beginnings of the spikes protruding from them. It's fairly easy to see if you just pay attention and look for it.
  * Fixed the unavoidable damage that occurs when Spiked Chests and Mimics spawn in very specific rooms that only have a narrow path surrounded by walls or pits (Caves #12, Caves #244, Caves/Catacombs #518, Caves #519, Womb/Utero #489). In these rooms, all Spiked Chests / Mimics will be converted to normal chests.
  * Hosts and Mobile Hosts are now immune to fear.
  * Fixed the (vanilla) bug where having Gimpy causes the Krampus item to be different than it otherwise would have been.
  * Fixed the seeded boss heart drops to be more accurate to how the vanilla game does it.
  * Maw of the Void and Athame will no longer be canceled upon exiting a room.
* *0.2.71* - March 16th
  * Previously, pickup delay on pedestals was only reduced for freshly spawned pedestals. Pedestal delay is also set to 18 upon entering a new room, so this class of delay is reduced to 10 as well.
  * Fixed the bug where Keeper would get stuck on 24, 49, or 74 cents.
  * Fixed the bug with Schoolbag where if you took damage at the same time as picking up a second active item, it would delete it.
  * Fixed the bug with Mom's Hands and Mom's Dead Hands where they would stack on top of each other when falling at the exact same time. Instead of falling with a 30 frame timer, they will now fall with a random 25 to 35 frame timer.
  * Fixed the bug where the Lil' Haunts on The Haunt fight would be messed up.
* *0.2.70* - March 15th
  * Increased the pickup delay on pedestal items from 0 to 10. (On vanilla, it is 20.)
  * All boss heart drops are now seeded.
  * Mom's Hands and Mom's Dead Hands will now fall faster even if there is more than 1 in the room.
  * Cursed Eye no longer overrides Cursed Skull.
  * Cursed Eye no longer overrides Devil Room teleports from Red Chests.
  * The Schoolbag will now work properly with the Glowing Hour Glass.
* *0.2.69* - March 14th
  * Fixed the bug where some items would not render properly in the Schoolbag.
  * Changed the caves room with the black heart surrounded by blocks (#267) to the way that Edmund intended it to be.
* *0.2.68* - March 13th
  * The Soul Jar effects are now based on whether you hold the item (instead of being tied to the Magdalene character specifically).
  * Fixed the bug where the AAA Battery did not work with the Schoolbag.
* *0.2.67* - March 13th
  * Removed the (vanilla) delay where you are not able to take a pedestal item immediately after it spawns.
  * Fixed the (vanilla) bug where double coins and nickels would not heal Keeper for their proper amount.
  * All shop items are now seeded.
* *0.2.66* - March 12th
  * Fixed the bug where the game would softlock if you entered a crawlspace from a Bossh Rush.
  * Fixed the bug where the AAA Battery would not do anything.
  * Fixed the (vanilla) bug where the AAA Battery would not synergize with The Battery.
  * Fixed the (vanilla) bug where the 9 Volt would not synergize with The Battery.
* *0.2.65* - March 10th
  * Fixed the bug where the trophy would drop instead of a chest when you were not in a race.
  * Fixed the bug with The Book of Sin taking away charges when the player had The Battery.
* *0.2.64* - March 10th
  * Isaac now starts with The Battery.
  * Maggy now starts with the Soul Jar, a new passive item with the following effects:
    * You no longer gain health from soul/black hearts.
    * You gain a red heart container after picking up 4 soul/black hearts.
    * You always have a 100% devil deal chance if no damage is taken.
  * Eden now starts with the Schoolbag. She will start with her random active item inside the bag.
  * Lilith now starts with the Schoolbag. She will start with Box of Friends inside the bag.
  * Apollyon now starts with the Schoolbag. He will start with Void inside the bag.
  * Fixed the bug where in certain specific situations red chest teleports could kill you.
  * Fixed the bug where Eden would incorrectly retain the stats from her starting active item.
  * Fixed the bug where the Joker card would not work if you had Cursed Eye.
* *0.2.62* - March 9th
  * Betrayal no longer pauses the game and plays an animation before charming enemies.
  * Fixed the crash when you teleported to an L room.
* *0.2.59* - March 4th
  * Fixed the (vanilla) bug with Eden's Soul where it would not start off at 0 charges.
  * Crystal Ball is now seeded.
  * Portals are now seeded. (As a side effect of this, Portals will always spawn 5 enemies instead of 1-5 enemies.)
  * Mom's Hand and Mom's Dead hand will now immediately attack you if there is only one of them in the room.
  * Removed Mom's Hand from Devil Room #13.
* *0.2.58* - March 4th
  * Fixed some various bugs with the new crawlspace stuff.
  * Non-purchasable item pedestals in shops are now seeded.
* *0.2.57* - March 2nd
  * Made crawlspaces use normal room transition animations instead of the long fade.
  * Removed the Blank Card animation after you use it with teleportation cards.
  * Centered the Mega Maw in the single Mega Maw room on the Chest (#269).
  * Added a door to the double Mega Maw room on the Chest (#39).
  * Fixed the (vanilla) bug where the door opening sound effect would play in crawlspaces.
  * Fixed the bug where the Mega Blast placeholder was showing up in item pools instead of The Book of Sin.
* *0.2.55* - March 2nd
  * Greatly sped up the attack patterns of Wizoobs and Red Ghosts.
  * Removed invulernability frames from Lil' Haunts.
  * Cursed Eye is now seeded.
  * Broken Remote is now seeded.
  * Broken Remote is no longer removed from seeded races.
  * Fixed the bug with Schoolbag where items would have more charges than they were supposed to at the beginning of a race.
  * Fixed the bug where The Book of Sin did not show up in the Schoolbag.
  * Fixed the bug where the Mega Blast placeholder did not show up in the Schoolbag.
  * Fixed the bug where The Book of Sin would not count towards the Book Worm transformation.
  * Fixed the bug where The Polaroid / The Negative would not be removed sometimes.
  * Fixed the bug where if you consumed a D6 with a Void and then tried to consume another pedestal, it would sometimes duplicate that pedestal.
* *0.2.54* - February 28th
  * Fast-clear now works with puzzle rooms.
  * Fixed a Larry Jr. room that should not have an entrance from the top.
  * Added better save file graphics, thanks to Gromfalloon.
* *0.2.53* - February 27th
  * Holding R on Eden no longer kills her.
  * The "drop" button will now immediately drop cards and trinkets. (This won't happen if you have the Schoolbag, Starter Deck, Little Baggy, Deep Pockets, or Polydactyly.)
  * Fixed the Strength card on Keeper. Note that it will only permanently give you a coin container if you are at 0 or less base coin containers.
  * Fixed the crash that occured with Schoolbag when you swapped at the same time as picking up a new item.
  * You will no longer recieve the Polaroid and get teleported to Womb 1 if you arrive at the Void floor.
  * Removed the "use" animation from Telepills.
  * Fixed a Basement/Cellar room that had a chance to spawn empty because of stacked entities.
  * Added two new graphics for save files (fully unlocked and not fully unlocked).
* *0.2.49* - February 24th
  * Keeper now starts with the D6, Greed's Gullet, Duality, and 50 cents.
  * Fixed the bug with Keeper and Greed's Gullet where he would not be able to pick up health ups.
  * Teleport! is now seeded (per floor). This item is no longer removed in seeded races.
  * Undefined is now seeded (per floor). This item is no longer removed in seeded races.
  * Telepills is now seeded (per floor, separately from Teleport!).
  * Broken Remote is now banned during seeded races. (I forgot to do this initially.)
  * When you spawn a co-op baby, it will now automatically kill the baby and delete all item pedestals in the room.
  * When you use a Sacrifice Room to teleport directly to the Dark Room, it will instead send you to the next floor.
  * Fixed an unavoidable damage I AM ERROR room where you would teleport on top of a Spiked Chest.
  * Cleaned up the door placements on some miscellaneous I AM ERROR rooms to ensure that the player always teleports to an intended location.
  * Fixed the I AM ERROR room without any entrances.
  * Fast-clear has been recoded to fix the bug where the doors would open if you killed two splitting enemies at the same time.
  * The title screen has been updated to a beautiful new one created by Gromfalloon.
  * Fixed some more out of bounds entities.
  * Fixed an asymmetric Scarred Guts on a Womb/Utero L room (#757).
  * Fixed a Little Horn room (#1095) where there was only a narrow entrance to the top and bottom doors.
  * Deleted the 2x2 Depths/Necropolis with 2 Begottens (#422), since they automatically despawn due to a bug.
  * Fixed the bug where the damage cache was not properly updated after having Polyphemus and then picking up The Inner Eye or Mutant Spider.
  * Fixed an asymmetric Scarred Guts on a Womb/Utero L room (#757).
  * Fixed a Little Horn room (#1095) where there was only a narrow entrance to the top and bottom doors.
  * Pressing the reset button on Eden now instantly kills her. (It is not possible to fix the resetting bug in a proper way.)
* *0.2.29* - February 12th
  * Changed the double Forsaken room to have two Dark Uriels.
  * All Globins will permanently die upon the 5th regeneration to prevent Epic Fetus softlocks.
  * Knights, Selfless Knights, Floating Knights, Bone Knights, Eyes, Bloodshot Eyes, Wizoobs, and Red Ghosts no longer have invulernability frames after spawning.
* *0.2.27* - February 11th
  * Fixed a room with boils that can cause a softlock with no bombs or keys.
  * Fixed the double trouble room that softlocks if you have no bombs.
  * Added a bunch of splitting enemies to the fast-clear exception list.
  * Pedestal replacement no longer applies to shops. (It causes some weird behavior.)
  * If you arrive at the Void floor for any reason, you will be automatically given the Polaroid and sent to Womb 1.
* *0.2.20* - February 8th
  * Renamed the Jud6s mod to the Racing+ mod. This should still be considered alpha software. It contains all of the room changes from the Afterbirth version of the Jud6s mod, as well as things that were not in the Afterbirth version, like Wrath of the Lamb style room clear. The full list of changes are listed on [the main changes page](https://github.com/Zamiell/isaac-racing-mod/blob/master/CHANGES.md).
