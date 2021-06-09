# Racing+ Version History and News

### *v0.56.0* - Unreleased, 2021

* Fixed the bug where the Lamb was not correctly removed during Victory Laps in the Dark Room. (Thanks antizoubilamakA)
* Fixed the bug where Dead Sea Scrolls would incorrectly give you the Lemon Party pill effect or the Explosive Diarrhea pill effect. (Thanks sisuka)

### *v0.55.17* - October 22nd, 2020

* In season 9, it is no longer possible to start with Godhead as Azazel. (Thanks Adrayon)
* Fixed the bug where the damage penalty from the Technology Zero build would apply when you were dead. (Thanks Po4ti)

### *v0.55.15* - October 21st, 2020

* [R+7 Season 9](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md#r7-season-8-the-shared-item-pool-season) is now released for beta testing.
  * This season will require more feedback than most other seasons, because I want everything to be relatively balanced, and this is a very difficult thing to do. Please report feedback in the Discord server.
* Fixed some miscellaneous bugs with the Season 9 alpha.

### *v0.55.11* - October 8th, 2020

* Fixed the bug where Jr. Fetus was not working correctly. (Thanks LbrtN)

### *v0.55.10* - October 8th, 2020

* Fixed the bug where you would die in a seeded race if you had a half soul heart and an eternal heart. (Thanks mgln)

### *v0.55.7* - October 4th, 2020

* Fixed the bug where clearing a Challenge Room would also open any attached Secret Rooms.

### *v0.55.6* - October 2nd, 2020

* Fixed the bug where Dad's Lost Coin was not correctly granting a luck up. (Thanks sisuka)

### *v0.55.5* - October 2nd, 2020

* Fixed the bug where the vanilla version of Dad's Lost Coin was still in some item pools. (Thanks sisuka)

### *v0.55.0* - October 1st, 2020

* A new seeded build has arrived: Distant Admiration + Friend Zone + Forever Alone + BFFS! (Thanks antizoubilamakA)
* The Pointy Rib + Eve's Mascara build has been replaced with 2 Pointy Ribs. (Thanks toooschi)
* The mod will now remove some unnecessary effects in order to prevent lag. (This will be most noticeable after the Mom fight and the It Lives! fight.)
* The mod now has the option to set an auto-fire keybinding for Anti-Gravity or No. 2 builds. Using this can help prevent RSI/CTS.
* The "shadow" command will now permanently remember whether or not you have it enabled or not. (This requires the "Racing+ Data" mod in order to work properly.)
* Added the "ghost", "ghosts", and "shadows" commands as alternates for the "shadow" command.
* Added the "shadowstatus" command.
* Fixed the (vanilla) bug where Fire Mind spawned from Angelic Prism tears would damage the player.
* Fixed the bug where teleporting to an Angel Room from a Sacrifice Room would not work if you had Cursed Eye. (Thanks Dea1h)
* Fixed the bug where the 2nd Dad's Lost Coin and beyond would not affect the stats of the player. (Thanks sisuka)
* Fixed the bug where a Lucky Penny would spawn if you left the room during the pickup animation of Dad's Lost Coin. (Thanks sisuka)
* Fixed the bug where the charge bar for the Lead Pencil would be misaligned when the player had flying and another charge item. (Thanks KGHB41)
* Fixed the bug where the Victory Lap button would spawn in the wrong place in Mega Satan's room. (Thanks edy47)
* Updated the "--luadebug" Pastebin as it had some incorrect information.

### *v0.54.2* - June 16th, 2020

* Fixed the bug where seeded death would not work properly if you died as The Soul. (Thanks Gamonymous)
* Fixed the bug where reviving from seeded death would not update the cache in certain situations. (Thanks Hispa)

### *v0.54.0* - June 16th, 2020

* A new seeded build has arrived: Pointy Rib + Eve's Mascara. (Thanks Gamonymous)
* In most 2x2 and L rooms, Lumps have been replaced with Mr. Red Maws, Tumors, and Guts.
* Fixed the bug where in seeded races, 3 Dollar Bill would not grant an effect until you entered a new room. (Thanks mgln)
* Fixed the bug where the place text would not show when the room frame count was equal to 0. (Thanks ez_duke)
* Fixed the bug where race placings would be inaccurate under certain conditions. (Thanks mgln)
* Fixed the bug where the seeded death mechanic would not trigger if you died within the first 5 seconds of the run. (Thanks Gamonymous)

### *v0.53.4* - June 9th, 2020

* In seeded races, the Technology Zero + Pop! + Cupid's Arrow damage penalty will no longer apply if you have Mom's Knife, Tech X, Epic Fetus, Ipecac, or Dr. Fetus. (Thanks antizoubilamakA)
* Fixed the bug where completing a Challenge Room could open the way to a Secret Room.
* Fixed the bug in season 8 where Divorce Papers would give you Mysterious Paper when it was already removed from the trinket pool. (Thanks mgln & Gamonymous)
* Fixed the bug where touching a loading zone would cancel the seeded death animation. (Thanks Gamonymous)
* Fixed the bug where in season 6, the builds would not be reset if you finished all 7 characters. (Thanks Gamonymous)
* Fixed the bug where the Fire Mind + 13 luck build would not set the luck to 13 in certain circumstances. (Thanks Gamonymous)
* Fixed the bug where you could not do more than one Victory Lap. (Thanks caesar)

### *v0.53.0* - June 7th, 2020

* In seeded races, you now have the ability to see your opponent inside your own game as a shadow. Thanks to imps for coding this, which was difficult to do. For more instructions, see this Pastebin: https://pastebin.com/2ZnRxDba
* The Technology Zero + Pop! + Cupid's Arrow build now grants a -50% damage multiplier.
* If you are currently jumping into a trapdoor, you can now save & quit in order to cancel travelling to the next floor. (Thanks Dea1h)
* The mod will now display your starting items in the starting room when you are playing as Eden.
* The mod will now display how many sacrifices you have performed when you are in a Sacrifice Room.
* Entering a room with Pin, Frail, or Scolex will now cause the screen to shake for 20 frames as an indication that there are enemies hidden under the ground. (Thanks Dea1h)
* The seeded death mechanic will now always count as causing red heart damage for the purposes of getting a devil deal. (Thanks ez_duke)
* In seeded races, 3 Dollar Bill will now grant one item effect per room, similar to how it worked in Rebirth. The effect is seeded per room. If the player already has the randomly chosen item, another random item effect will be chosen.
* The "+13 Luck" item no longer gives +13 luck. Instead, it will set your luck value to 13. (Thanks antizoubilamakA)
* The "Finished" custom item will no longer spawn after completing a race.
* A button to spawn a DPS-measuring potato will now spawn after completing a race. Thanks to Sinsthar for creating this.
* The "Victory Lap" custom item has been replaced by a button.
* Removed some rocks from Basement/Cellar/Burning room #301 to mitigate a pseudo-softlock with Round Worms.
* Fixed the (vanilla) bug where Guppy's Head was not seeded. (Thanks antizoubilamakA)
* Fixed the (vanilla) bug where The Ludovico Technique, Brimstone, and Dr. Fetus cause a stationary Brimstone ring to remain around the player, potentially softlocking them. When this occurs, Dr. Fetus will be removed to fix the softlock.
* Fixed the (vanilla) bug where The Ludovico Technique, Technology, and Mom's Knife cause a stationary laser ring to remain around the player, potentially softlocking them. When this occurs, Mom's Knife will be removed to fix the softlock.
* Fixed the bug where Larry Jr. and The Hollow were not spawning properly in the Challenge and the Boss Rush.
* Fixed the bug where Grub was not spawning properly in the Challenge Room.
* Fixed the bug where teleporting from a Challenge Room to a Challenge Room would not count as completing it. (Thanks ez_duke)
* Fixed the bug where taking certain pickups in a Challenge Room or the Boss Rush would count as starting it. (Thanks thereisnofuture)
* Fixed the bug where a chest opening into a pedestal item would not start a Challenge Room the Boss Rush. (Thanks ez_duke)
* Fixed the bug where Pitfalls were not working properly in the Big Horn fight. (Thanks thereisnofuture)
* Fixed the bug where Mystery Sack did not include Bone Hearts in the random heart options.
* Fixed the bug where Mystery Sack included Mega Troll Bomb in the random bomb options.
* Fixed the bug with the seeded death mechanic where you would retain the Succubus damage aura bonus after dying. (Thanks Gamonymous)
* Fixed the bug where Judas would not touch his Book of Belial when he started a run with it in the Schoolbag. (Thanks ez_duke)
* Fixed the bug where items dropped from the Schoolbag would not have their charge set properly. (Thanks Gamonymous)
* Fixed the bug where putting an item into a Schoolbag in a Devil Room would delete the empty pedestal under certain circumstances.
* Fixed the bug where the Blue Womb door would not spawn correctly if your race goal was Delirium. (Thanks Po4ti)
* Fixed the bug where Dead Sea Scrolls would not properly be depleted of a charge under certain circumstances. (Thanks ez_duke)
* Fixed the bug where familiars would not be teleported to the center of the room when entering a new floor.
* Fixed the bug where Curse of the Unknown was incorrectly applied to new runs under certain circumstances. (Thanks mgln)
* Fixed the bug where music was not playing correctly in Challenge Rooms and the Boss Rush. (Thanks Sisuka)
* Fixed the bug in season 8 where resetting to the same character would not remember any pills identified on that character. (Thanks mgln)

### *v0.52.2* - May 6th, 2020

* The "Disappear" animation for Pitfalls has been sped up by a factor of 2.
* Fixed the bug where picking up a dropped trinket would start a Challenge Room or the Boss Rush. (Thanks ez_duke)
* Fixed the bug where Suction Pitfalls would persist after the room was cleared under certain circumstances. (Thanks ez_duke)

### *v0.52.0* - May 3rd, 2020

* Season 7 is finished!
  * Congratulations to Dea1h for the best time of 49:34, thereisnofuture for the second best time of 49:41, and mgln for the third best time of 49:45.
  * The top 10 times will be stored in the [Hall of Fame page](https://isaacracing.net/halloffame).
  * If you want to beat these times, the R+7 (S7) category will continue to be tracked on speedrun.com, but the official competition will move on to season 8.
* [Season 8](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md#r7-season-8-the-shared-item-pool-season) has officially begun!
* The R+ sprite will now always show, which fixes the bug where the place sprite would overlap with the stats. (Thanks Gamonymous)
* Added an error message for when you try to continue a run that was played prior to opening the game. (Thanks mgln)
* Fixed the bug where using Void or a Black Rune on a pedestal item in a Challenge Room or the Boss Rush would not start the event. (Thanks Hispa)
* Fixed the bug where races to Mega Satan would not register a finish when you touched the trophy. (Thanks Gamonymous)
* Fixed the bug where if you were using the MinimapAPI, you could see the minimap on certain frames of fast-travel when you were not supposed to. (Thanks Pingouin23)
* Fixed the bug where you could kill the "Room Clear Delay NPC".

### *v0.51.1* - April 29th, 2020

* Fixed the bug where the beginning of the pill sound effect would sometimes play when resetting the game as Magdalene. (Thanks mgln)
* Fixed the bug where the boss HP UI would remain on the screen after completing a Boss Challenge Room or the Boss Rush.
* Fixed the bug where a Challenge Room and the Boss Rush would start when they were not supposed to under certain conditions.

### *v0.51.0* - April 28th, 2020

* The waves in Challenge Rooms are now generated in a custom way that roughly matches vanilla. This means that the long delay between waves has been removed. This also fixes the bug where items in the Schoolbag would not be charged when clearing Challenge Room waves.
* All Boss Challenge Rooms will now spawn two random bosses instead of two set bosses.
* Normal Challenge Rooms on floor 7 and beyond will now correctly use Womb enemies.
* Boss Challenge Rooms on floor 7 and beyond will now correctly use Womb bosses.
* Removed the "R+" icon during unseeded runs. (Curses are now removed via a callback instead of via the "BLCK CNDL" seed.)
* Fixed the bug where using a Strength card could give an additional heart container on seeded runs under certain conditions. (Thanks Dea1h)
* Fixed the bug where you could take both boss items after the Mom fight. (Thanks Hispa)
* Fixed the bug where in season 8, the beginning of "hurt" sound effect would sometimes play when resetting the game as Eve.

### *v0.50.8* - April 27th, 2020

* If you only have Key Piece 1 or only have Key Piece 2, Uriel and Gabriel will now always drop the other key piece. (This is different than the vanilla behavior.)
* In season 8, when resetting on Eve, she should now be a little less noisy.
* Mod Config Menu will now always open, even if there are enemies in the room.
* Fixed the bug where There's Options would not work if Mom spawned a boss item. (Thanks Hispa)
* Fixed the bug where familiars would be placed at an invalid entrance after a teleport under certain conditions.

### *v0.50.7* - April 21st, 2020

* Items will no longer be automatically inserted into your inventory if you are holding down any of the "fast-drop" buttons. (Thanks Moucheron Quipet)
* Fixed the bug where the MinimapAPI icon for the Black Rune was wrong. (Thanks Gamonymous)
* Fixed the bug in season 8 where the "Cards used" would start at 1 instead of 0.
* Fixed the bug in season 8 where it would show 128 trinkets instead of 127. (Thanks Gamonymous)

### *v0.50.6* - April 20th, 2020

* Items will no longer be automatically inserted into your inventory if you are holding down the "drop" button.
* Fixed the bug where an eternal chest would show instead of a broken dressing machine when a dressing machine dropped an item. (Thanks Hispa)

### *v0.50.5* - April 19th, 2020

* The "TeleportUp" animation has been restored. Both "TeleportUp" and "TeleportDown" are now sped up by a factor of 2.
* Blank Runes will no longer spawn in season 8. (Thanks Hispa)
* Fart-rerolls will no longer have a special color.
* Fixed the bug where PHD would not work properly in season 8. (Thanks Dea1h)
* Fixed the bug where active items in season 8 would have no charges if they were a repeat-item replacement. (Thanks Pingouin23)
* Fixed the bug where replaced cards in season 8 would be automatically purchased. (Thanks ez_duke)
* Fixed the bug where backtracking could reroll cards in season 8 in specific circumstances.
* Fixed the bug where cards would despawn in all non-season 8 runs. (Thanks Carter)

### *v0.50.3* - April 18th, 2020

* Fixed the bug in season 8 where you could get black runes and ? cards from Devil Rooms when you had already used them. (Thanks Gamonymous)

### *v0.50.1* - April 17th, 2020

* [R+7 Season 8](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md#r7-season-8-the-shared-item-pool-season) is now released for beta testing.
* Mom's Hands and Mom's Dead Hands now have an "Appear" animation. This is helpful for players who are deaf and/or play with the sound turned off. (Thanks Satanas)
* Deleted Sheol room #33. (Thanks Shigan)
* Added Basement/Cellar/Burning room #721 to the list of rooms for Spiked Chest replacement. (Thanks Dea1h)
* The mod will no longer fix an invalid entrance after a teleport if it is a big room. (Thanks mgln)
* Fixed the bug where the mod would not fix an invalid entrance after using a teleportation card.
* Fixed the bug where fast clear would not work with Dark Red champions under certain conditions. (Thanks thereisnofuture & mgln)
* Fixed the bug where the extra tears from a Monstro's Lung synergy would only fire at half the velocity. (Thanks Gamonymous)
* Fixed the bug where the "S5" sprite was not showing in season 5. (Thanks mgln)

### *v0.49.4* - March 28th, 2020

* Removed Depths/Necropolis/Dank room #709. (Thanks Gamonymous)
* The pills UI will no longer cut off identified pills over 7.
* Fixed the (vanilla) bug where you would not always appear at a valid entrance when teleporting to a new room.
* Fixed the (vanilla) bug where Ticking Spiders would not display the correct frame during their "Appear" animation. (Thanks bobita60)
* Fixed the bug where you could finish a race while dead. (Thanks Pingouin23)
* Fixed the bug in season 7 where the correct photo would not spawn if you started with either The Polaroid or The Negative. (Thanks Gamonymous)
* Fixed the bug where custom races would force you to play as the chosen character under certain conditions.

### *v0.49.2* - March 14th, 2020

* Magdalene will now automatically use her Speed Up pill at the beginning of a run.
* There is now custom streak text to display the floor name when you hold tab.
* Fixed the bug in the seeded death mechanic where you would incorrectly die with two bone hearts. (Thanks CrafterLynx & ReidMercury)
* Fixed the bug where fast-drop would cancel the item pickup animation. (Thanks Pingouin23)
* Fixed the bug in season 7 where icons to boss rooms other than Ultra Greed would show up on the minimap under certain conditions.
* Fixed the bug in season 7 where doors to boss rooms other than Ultra Greed would be accessible.
* Fixed the bug in season 7 where a Greed Door would overlap with an open door. (Thanks mgln)
* Fixed the bug where items dropped from angels could overlap with other entities under certain conditions. (Thanks Toooschi)
* Fixed the bug where Angels would drop key pieces after you already had them.
* Fixed the (vanilla) bug where Forever Alone was inproperly stylized.

### *v0.49.1* - February 23rd, 2020

* Fixed the bug where client race placings were wrong under certain conditions. (Thanks mgln)
* Fixed the bug where switching Schoolbag items would not work when the Racing+ Data mod was disabled. (Thanks Cyber_1)

### *v0.49.0* - February 22nd, 2020

* If you play custom challenges, you must now subscribe to the [Racing+ Data mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2004774809) on the Steam Workshop. Your character order will no longer reset after every patch. Furthermore, you are no longer limited to having one character order stored at a time, meaning that you can store orders for each season.
* If you use the extra keybindings provided by Racing+, you must now subscribe to the [Racing+ Data mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2004774809) on the Steam Workshop. Your settings will no longer reset after every patch.
* Samael now gains double damage with 20/20, triple damage with The Inner Eye, and quadrule damage when picking up Mutant Spider. (This only applies to melee attacks. These effects can stack.)
* In unseeded races and season 5, Mom's Knife now fart-rerolls into Mutant Spider's Inner Eye and Ipecac now fart-rerolls into Incubus. (Thanks antizoubilamakA)
* Fixed the bug where an item would not drop from an angel if you had the Filigree Feather under certain conditions. (Thanks mgln)
* Fixed the bug where the Schoolbag would incorrectly remove some costumes/shields when swapping an item under certain conditions. (Thanks mgln)
* Fixed the bug where Maggy's Faith would give you an extra heart container if the floor was reseeded. (Thanks Gamonymous)
* Fixed the bug where Blank Card + Perthro rune + Tarot Cloth would give you unlimited rolls. (Thanks Mr. Oca)
* Fixed the bug where touching items would cause them to reroll into something else under certain conditions. (Thanks mgln)
* Fixed the bug where the NO! trinket would cause players to get different items in seeded races under certain conditions. (Thanks mgln)
* Fixed the bug where you would not permanently die after taking a devil deal in a seeded race under certain conditions. (Thanks mgln)
* Fixed the bug where places would not show correctly in Everything races under certain conditions.
* Fixed the bug where you would not consistently appear at the center of the screen after a floor transition during Everything races and after taking a Victory Lap.
* Fixed the bug where you could skip a floor through the Black Market in an Everything race. (Thanks thereisnofuture)
* Fixed the bug where using the Void could prevent items from being rolled under certain conditions. (Thanks Hispa)

### *v0.48.0* - January 23rd, 2020

* The client will now show your row in blue so that you can easily distinguish it from the other racers. Thanks to InvaderTim for programming this.
* The client will now sort the racers based on their current place. Thanks to InvaderTim for programming this.
* You can now use the console in a race with a custom format.
* Fixed the bug where There's Options would cause a crash after killing Ultra Greed in season 7. (Thanks mgln)

### *v0.47.15* - January 20th, 2020

* Fixed the bug where the Schoolbag item would drop on the ground after a seeded death. (Thanks Darkdragon)
* Fixed the bug where the "Veto" text would be drawn when there was not a valid character order.

### *v0.47.14* - January 11th, 2020

* A new custom mechanic is added where freshly made trapdoors and crawlspaces are always open, regardless of whether the room is clear or not. (This effectively makes the shovel as powerful as it was before.) This mechanic will be reverted upon the release of Repentance. (Thanks mgln)

### *v0.47.13* - January 9th, 2020

* The Boss Rush will now display the current wave as streak text.
* Trapdoors and crawlspaces will now be closed if the current room is not cleared. (This is how it works in Greed Mode. The old behavior is considered a bug in vanilla and is fixed in Repentance. Racing+ will now match the behavior of Greed Mode and Repentance.)
* Fixed the bug where having the Lost Cork would make the "controls" graphic appear incorrectly. (Thanks Gamonymous)
* Fixed the bug where losing the Schoolbag with an active item inside the Schoolbag would make it disappear instead of dropping on the ground.

### *v0.47.11* - December 28th, 2019

News:

* StoneAgeMarcus will be performing a R+7 Season 6 run live at Awesome Games Done Quick 2020 on Sunday, January 5th.

Mod changes:

* Isaac is now feeling festive. Happy New Years!
* The "controls" starting room graphic will no longer show in seeded or diversity races.
* Fixed the (vanilla) bug where the trapdoor/ beam of light was accessible in I AM ERROR rooms before the room was cleared.
* Fixed the bug where going to the next floor on Greed Mode would automatically start the next wave.
* Fixed the bug where the Butter Bean "morph" mechanic was not working properly. (It is supposed to be a 10% chance per swap.) (Thanks Greg)
* Fixed the bug where Blank Card + ? Card would not work correctly if you had Cursed Eye. (Thanks Greg)
* Fixed the bug where the Glowing Hour Glass would not work correctly if you had Cursed Eye. (Thanks mgln)
* Fixed the bug where brown creep would not be cleared immediately when the room was cleared.
* Fixed the bug where pedestal items could go into an empty Schoolbag upon entering a room under certain conditions. (Thanks Gamonymous)

### *v0.47.10* - December 19th, 2019

* Isaac is now feeling festive. Merry Christmas!
* Fixed the (vanilla) bug where multi-segment bosses would drop more than one black heart when killed with Maw of the Void or Athame.
* The end of run text now says "Rooms entered" instead of "Total rooms" so that it is more clear what the number means.

### *v0.47.9* - December 14th, 2019

* In seeded races, room drops for Devil Rooms and Angel Rooms will now use a separate seed counter than the one used for normal room drops. (Thanks mgln)
* Fixed the bug where beating Delirium would count as beating Ultra Green in season 7. (Thanks olo70009)
* Fixed the bug where using Void with the Schoolbag would not cause it to get properly seeded. (Thanks mgln)

### *v0.47.7* - November 30th, 2019

* Deleted Ultra Greed's "Appear" animation.
* The Lead Pencil charge bar no longer appears if you are Azazel. (Thanks NorBro86)
* Fixed the (vanilla) bug where angels would not drop key pieces if another angel was alive.
* Fixed the bug where the Glowing Hour Glass would not work correctly with the Schoolbag if you had the Butter! trinket. (Thanks mgln)
* Fixed the bug where Teleport 2.0 would not work correctly if you had Cursed Eye. (Thanks Greg)
* Fixed the bug where the Big Chest would spawn out of bounds after killing The Lamb.
* Fixed the bug where the Big Chest would spawn out of bounds after killing Mega Satan.

### *v0.47.6* - November 28th, 2019

* Isaac is now feeling festive. Happy Thanksgiving!
* Fixed the bug where the end-of-speedrun trophies would spawn under certain conditions. (Thanks NorBro86)
* Fixed the bug where extra invisible NPCs would be spawned upon clearing the Boss Rush.

### *v0.47.5* - November 27th, 2019

* The end-of-run text has been reorganized.
* Fixed the bug where the average time per character was incorrect under certain circumstances. (Thanks 910dan)
* Fixed the bug where items would not go into the Schoolbag under certain conditions. (Thanks Dea1h)
* Fixed the bug where the speedrun trophy would get deleted if you leave the room under certain conditions. (Thanks juan3299)

### *v0.47.4* - November 27th, 2019

* Fixed the bug where the Checkpoint was not working properly. (Thanks Pingouin23)
* Fixed the bug where a Lump of Coal would get deleted under certain circumstances. (Thanks Anidalife)

### *v0.47.3* - November 26th, 2019

* The Lead Pencil charge bar will no longer show up on Lilith and Forgotten. (Thanks Pingouin23 & Fawkeyes)
* The devil statue will be faded if there is an item pedestal hiding behind it. (Thanks mgln)
* Fixed the bug where the boss item after Ultra Greed would show up for a frame. (Thanks NorBro86)
* Fixed the bug where the Lead Pencil charge bar would be wrong if you picked it up in the middle of a run. (Thanks Pingouin23)

### *v0.47.0* - November 24th, 2019

* Lead Pencil now grants a charge bar similar to Maw of the Void.
* Reduced the delay when jumping out of a hole on a new floor by 7 frames.
* It is no longer possible to get Mega Maw or the Gate in the Boss Rush room that has rocks along the top wall. (Thanks NorBro86)
* Added Caves / Catacombs / Flooded Caves room #90 to the list of rooms for Spiked Chest replacement. (Thanks SlashSP)
* Fixed the bug where you could push pedestals by swapping an active item over and over.
* Fixed the bug where extra items spawned from a Diplopia were not properly seeded.
* Fixed the bug where heaven doors would not appear in a Black Market. (Thanks Cyber_1)
* Fixed the bug where killing a splitting enemy as the last boss in the Boss Rush would cause it to end early. (Thanks NorBro86)
* Fixed the bug where Victory Laps were not working properly. (Thanks Gamonymous)

### *v0.46.2* - November 9th, 2019

* Hush's appear animation has been removed.
* Scolex will no longer appear in the Boss Rush. (Thanks SlashSP)
* It is no longer possible to get The Haunt or Mama Gurdy in the Boss Rush room that has rocks along the top wall. (Thanks SlashSP)
* Fixed the bug where using a black rune would kill you under specific circumstances. (Thanks CrafterLynx)

### *v0.46.1* - November 7th, 2019

* The pause and unpause animations have been removed.
* Fixed the bug where you could not pause the game while jumping into a trapdoor. (Thanks Dea1h)
* Fixed the bug where the Boss Rush would spawn extra bosses under certain conditions. (Thanks Gamonymous)
* You will now be killed if you try to get extra stats by using a black rune on a Checkpoint in season 7. (Thanks Pingouin23)

### *v0.46.0* - November 2nd, 2019

* Season 6 is finished!
  * Congratulations to Shigan_ for the best time of 44:04, thereisnofuture for the second best time of 45:54, and Greg570 for the third best time of 46:30.
  * The top 10 times will be stored in the [Hall of Fame page](https://isaacracing.net/halloffame).
  * If you want to beat these times, the R+7 (S6) category will continue to be tracked on speedrun.com, but the official competition will move on to season 7.
* [Season 7](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md#r7-season-7-the-diversity-season) has officially begun!

### *v0.45.11* - October 31st, 2019

* Fixed the bug where the Boss Rush would complete upon killing all the bosses instead of all the enemies. (Thanks mgln)
* Fixed the bug where the Chub from the Matriarch was not slowed down in the Boss Rush. (Thanks NorBro86)

### *v0.45.10* - October 26th, 2019

* It is no longer possible to teleport to the I AM ERROR room using Undefined on The Void. (Thanks Pingouin23 & Karolmo)
* Removed Ultra Greed's death animation. (This prevents the bug where the Checkpoint is inaccessible behind the body.) (Thanks thereisnofuture)
* Fixed the bug where the trapdoor on basement 1 did not appear on season 7 under certain conditions. (Thanks Shigan)
* Fixed the bug where the Sacrifice Room would not take you to the next floor under certain conditions. (Thanks Dea1h)

### *v0.45.9* - October 24th, 2019

* Fixed the bug where bone hearts would not be deleted during seeded revival.
* Fixed the bug where the Void door would be open if you exited and re-entered the Hush room after defeating Hush in the season 7 custom challenge. (Thanks mgln)
* Fixed the bug where Mysterious Paper would cause the seeded death mechanic to fail under certain conditions. (Thanks mgln)

### *v0.45.8* - October 22nd, 2019

* In season 7, the Checkpoint item that spawns after It Lives! will no longer have its pedestal delay manually removed. (Thanks Dea1h)
* In season 7, the goals will no longer stick to the screen for 2 seconds when you press tab. (Thanks Dea1h)
* In season 7, the Womb trapdoor will no longer spawn if your only goal left is the Boss Rush.
* The Womb trapdoor will no longer spawn in races to the Boss Rush.
* Fixed the bug where the Checkpoint item would not spawn in the center of the room under certain conditions. (Thanks thereisnofuture)
* Fixed the bug where the seeded death mechanic would erroneously activate if the player had an eternal heart. (Thanks mgln)
* Fixed the bug where the trophy would not spawn after defeating Delirium on races to Delirium.
* The Finish item, the Victory Lap item, the beam of light, and the trapdoor will no longer spawn after defeating Hush on races to Hush.
* The Finish item, the Victory Lap item, the beam of light, and the trapdoor will no longer spawn after defeating Delirium on races to Delirium.
* Fixed the bug where the client could not find the "00.special rooms.xml" file. (Thanks T1biriy)

### *v0.45.6* - October 19th, 2019

* Fixed the bug where the seeded death mechanic would occasionally cause the game to crash. (Thanks Greg)
* Fixed the bug where the seeded death mechanic would erroneously activate if the player had two different kinds of hearts. (Thanks mgln)

### *v0.45.5* - October 18th, 2019

* Reduced the HP of Ultra Greed Coin (Bomb) from 50 to 25. (Thanks Gamonymous)
* Fixed the bug where it was possible for the Boss Rush checkpoint to spawn in an inaccessible location. (Thanks CrafterLynx)
* Fixed the bug where the trigger for beams of light was delayed slightly in certain circumstances. (Thanks mgln)

### *v0.45.4* - October 17th, 2019

* Bosses in the Boss Rush will now always spawn at least 120 units away from the player. (Thanks Dea1h)
* Boss Rush waves will now spawn after a 20 frame delay. (Thanks Cyber_1)
* In season 7, Mahalath has been replaced with Ultra Greed. (His damage scaling has been removed.)
* In season 7, the Broken Remote is now banned from the pool of random starting trinkets. (Thanks CrafterLynx)
* In season 7, if you have completed the speedrun, the goals will no longer show if you press tab.
* Fixed the bug where the trapdoor in the I AM ERROR room on The Void would take you to the 13th floor. (Thanks Gamonymous)

### *v0.45.3* - October 16th, 2019

* The diversity graphics have been rearranged so that they no longer overlap with the player's starting position. (Thanks PassionDrama)
* In season 7, it is no longer possible to get Isaac's Heart + Blood Rights from the random starting items. (Thanks thereisnofuture)
* In season 7, it is no longer possible to get Soy Milk + Libra from the random starting items.
* In season 7, while on the Void, all bosses except for Mahalath are now removed from the minimap upon entering a new room. This means that you can use mapping items more safely.
* In season 7, the remaining goals will now display on the screen after you take a Checkpoint. (Thanks Krakenos)

### *v0.45.2* - October 16th, 2019

* The door to Hush will now automatically open when you arrive on the Blue Womb.
* In season 7, graphics for the random starting items will now show in the first room of the run.
* In season 7, Mahalath has been replaced with Ruthless Mahalath. (Ruthless Mahalath has a new sprite, twice the HP, and faster attack sequences.)
* In season 7, Hush's HP has been doubled.
* In season 7, the goals will now persist on the screen for 2 seconds after you press tab. (Thanks Thoday)

### *v0.45.1* - October 16th, 2019

* The follow pills now have animations and can be used to cancel pedestal pickup animations:
  * One makes you larger (32)
  * One makes you small (33)
  * Infested! (34)
  * Infested? (35)
  * Power Pill (36)
  * Retro Vision (37)
  * Horf (44)
* Gurglings and Turdlings in the Boss Rush will now spawn in triplets (which matches the vanilla behavior).
* In Season 7, if your only goal remaining is Blue Baby, then only The Polaroid will spawn. (Thanks Dea1h)
* In Season 7, if your only goal remaining is The Lamb, then only The Negative will spawn. (Thanks Dea1h)
* Fixed the bug where using the Glowing Hour Glass would cause a Cursed Eye teleport if you had Cursed Eye.
* Fixed the bug where the "Remaining Goals" text would appear on runs outside of the Season 7 custom challenge.

### *v0.45.0* - October 15th, 2019

* [R+7 Season 7](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md#r7-season-7-the-diversity-season) is now released for beta testing.
* The bosses in the Boss Rush are now generated in a custom way:
  * Fast-clear now applies to the Boss Rush.
  * Schoolbag charges will now work correctly with the Boss Rush.
  * The Afterbirth+ bosses are added to the boss pool.
  * All Chapter 4 bosses are added to the boss pool.
* Fixed the (vanilla) bug where Monstro's Lung does not properly synergize with multi-shot items. 20/20 now grants 2x tears, Inner Eye now grants 3x tears, and Mutant Spider now grants 4x tears (in addition to their normal effects). (This bug will also be fixed in the next vanilla version of the game.)
* The seeded death mechanic has been rewritten so that it does not actually kill you and just mimics it instead. This fixes the bug where Guppy's Collar would not work properly and the bug where revival would cause you to not be able to save and quit for the remainder of the run. (Thanks StoneAgeMarcus & CrafterLynx)
* Fixed the bug where a key piece would disappear if you left the room and re-entered it. (Thanks thereisnofuture)
* Fixed the bug where custom inventory management would still occur even if you changed rooms during the pickup animation. (Thanks Gamonymous)
* Fixed the bug where the beam of light would not spawn after killing It Lives! / Hush under certain conditions in the R+15 (Vanilla) custom challenge. (Thanks Dea1h)
* Fixed the bug where Lil Spewer's green creep attack would not work correctly. (Thanks sisuka)
* Fixed the bug where the camera would glitch out when entering the Blue Womb.
* Fixed the bug where if you had Halo of Flies and revived with the seeded death mechanic, you would get an additional Pretty Fly. (Thanks Gamonymous)
* Fixed the bug where if you had A Dollar and revived with the seeded death mechanic, you would get 99 cents.
* Fixed the bug where an empty pedestal was created after taking an active item from a devil deal that went into a Schoolbag.
* Added The Matriarch to the Victory Lap boss pool.

### *v0.44.2* - July 3rd, 2019

* The seeded Devil Rooms and Angel Rooms has been rewritten to be more consistent. (Thanks Gamonymous)
* Fixed the bug where fighting Mom's Heart or It Lives! on The Void would cause extra paths to appear. (Thanks AshDown)

### *v0.44.1* - June 28th, 2019

* Scared Hearts and Sticky Nickels now have unique graphics. Thanks goes to [piber20](https://steamcommunity.com/id/piber20) for creating the graphics for this.
* Fixed the bug where stone entities could cause duplicate pickups to spawn. (Thanks Gamonymous)
* Fixed the bug where having Tarot Cloth would cause the D6 to recharge when using a ? Card under certain conditions. (Thanks Gamonymous)

### *v0.43.5* - June 25th, 2019

* Fixed the bug where Angels in Sacrifice Rooms would not drop key pieces. (Thanks mgln)

### *v0.43.4* - June 23rd, 2019

* Babies in the Isaac fight will now randomly spawn on the edge of a circle 100 units away from him instead of randomly throughout the room, which mimics the intended behavior. (Thanks Krakenos)
* The Devil Room with 10 Red Chests will no longer appear on seeded races to prevent seeding bugs. (Thanks antizoubilamakA)
* Added Caves / Catacombs / Flooded Caves room #119 to the list of rooms for Spiked Chest replacement.
* Fixed the bug where the player would spawn in the wrong position in Greed Mode. (Thanks Dea1h)
* Fixed the bug where Lilith's familiar's poof effects appeared at the bottom of the screen at the beginning of a run.

### *v0.43.3* - June 20th, 2019

* Updated the main menu with some sketches / graphic changes from Rebirth.
* Fixed the (vanilla) bug where Divorce Papers would not cause Mysterious Paper to be removed from the trinket pool. (Thanks Gamonymous)
* Fixed the bug where Lil' Haunts would not be frozen in place during their "Appear" animation. (Thanks thereisnofuture)
* Fixed the bug where the Holy Mantle indicator would not show correctly on Blue Baby when he had one or more bone hearts.
* Fixed the bug where a multi-character run would return to the first character if Eden started with the vanilla schoolbag. (Thanks leo_ze_tron)
* Fixed the bug where the client would not properly track who is in first place in a multi-character speedrun. (Thanks Krakenos)

### *v0.43.2* - June 18th, 2019

* Fixed the bug where Samael's attack caused a Sacrifical Dagger to appear for a frame. (Thanks Pingouin23)

### *v0.43.1* - June 17th, 2019

* Increased the warmup frames on the beam of light attack from 18 to 20.
* Fixed the bug where heaven doors would not spawn in I AM ERROR rooms. (Thanks thereisnofuture)
* Fixed the bug where Book of Sin would give duplicate pickups. (Thanks caesar)
* Fixed the bug where ranked unseeded solo races were giving the Soul Jar instead of the Schoolbag. (Thanks caesar)

### *v0.43.0* - June 15th, 2019

* Various parts of the Racing+ and Babies Mod are now more optimized, which means the mod should work slightly better on slower computers.
* Angels on the Isaac fight are now guaranteed to spawn 60 units away (instead of 40).
* Reverted the custom sound effect when you try to plant a bomb while at 0 bombs.
* Fixed the (vanilla) bug where beams of light from Conquest and the second phase of Isaac would never actually hit the player. The attack has been recoded and has a new animation. Thanks to [piber20](https://steamcommunity.com/id/piber20) for programming this.
* Fixed the bug where Book of Sin and Dead Sea Scrolls would not work correctly with the Schoolbag and the Butter! trinket.
* Fixed the bug where Mushrooms would not deal damage on floors other than Caves.
* Fixed the bug where seeded floors were disabled.

### *v0.42.1* - June 10th, 2019

* The client will now properly track who is in first place in a multi-character speedrun.
* The client now has an option for races to be started in hard mode.
* Removed the "Seeded (Hard)" and the "Unseeded (Lite)" rulesets.
* Little Steven will now always drop from Steven if the player already has the Steven item. (Thanks Gamonymous)
* Fixed the bug where automatic inventory management would not insert bombs or coins into your inventory under certain circumstances. (Thanks thereisnofuture)
* Fixed the bug where the place icon would overlap with the "S#" icon.
* Fixed the bug where the client displayed the wrong color for Mysterious Liquid.

### *v0.41.0* - June 9th, 2019

* Reverted the custom sound effect when you try to open a locked door while at 0 keys.
* Fixed the (vanilla) bug where the babies on the Isaac fight could spawn inside the hitbox of the player.
* Fixed the (vanilla) bug where the babies on the Isaac fight would spawn in a specific location instead of randomly throughout the room.

### *v0.40.1* - June 8th, 2019

* Pin, Frail, and Scolex are now only sped up if there is only one of them in the room. (Thanks Dea1h)
* Reverted the Mini-Boss room nerf in Season 6. (Thanks Dea1h)
* Fixed the bug where the Forgotten softlock check was not running properly under certain circumstances.
* Fixed the bug where the sad sound effect would play when typing into the console.

### *v0.40.0* - June 7th, 2019

* In Season 6, Judas Shadow is now banned on Judas. (Thanks Gamonymous)
* There is now a custom sound effect when a Wishbone or a Walnut breaks.
* There is now a custom sound effect when you try to open a locked door while at 0 keys.
* There is now a custom sound effect when you try to plant a bomb while at 0 bombs.

### *v0.39.0* - June 4th, 2019

* Green player creep is now changed to blue (instead of red). (Thanks Moucheron Quipet)
* The sprite for Mysterious Liquid has been changed to blue (instead of red). Thanks to Thoday for making the graphics for this.
* The Lost now shows his health in the UI. Thanks goes to [piber20](https://steamcommunity.com/id/piber20) for creating the graphics for this.
* Holy Mantle now shows the effect in the UI. Thanks goes to [piber20](https://steamcommunity.com/id/piber20) for creating the graphics for this.
* Fixed the (vanilla) bug where D Infinity was incorrectly stylized.

### *v0.38.0* - June 2nd, 2019

* In seeded races, the Chocolate Milk start is now coupled with Steven. (Thanks Shigan)
* In seeded races, the Jacob's Ladder start is now coupled with There's Options. (Thanks Gamonymous)
* In seeded races, Mysterious Liquid is now added to the Fire Mind build.
* Fixed the bug where the "You are not on Hard Mode" text would not appear. (Thanks AshDown)
* Fixed the bug where the sprite for Mysterious Liquid was green in the "Choose Char Order" custom challenge.

### *v0.37.14* - May 31st, 2019

* Changed the Mysterious Liquid costume and tears effect from green to red in order to match the new creep color. Thanks to Thoday for creating the graphics for this.
* Added Caves / Catacombs / Flooded Caves room #488 to the Forgotten softlock list. (Thanks AshDown)
* Fixed the bug where the Basement 1 Treasure Room icon would appear on the map when it was banned and attached to the starting room.
* Fixed the bug where replaced pedestal sprites would not match the original sprite.
* Fixed the bug where an empty pedestal was not generated when you put an item in the Schoolbag.
* Fixed the bug where a trapdoor would close when entering it as The Soul.

### *v0.37.11* - May 30th, 2019

* Updated the sprite for Mysterious Liquid (from green to red).
* Fixed the bug where the Blue Map would show on floors where the Treasure Room was banned. (Thanks mgln)

### *v0.37.10* - May 29th, 2019

* In formats where the Treasure Room is banned on Basement 1, the room will no longer appear on the minimap and the doors will be deleted.
* In Season 6, Mini-Boss rooms are now emptied on the first character and on the first floor in the same manner as Curse Rooms and Sacrifice Rooms.
* In Season 6, Forgotten will no longer be randomly given Incubus. (Thanks Gamonymous)
* Trapdoors will now be automatically close if you are near one when you switch from The Forgotten to The Soul (or vice versa). (Thanks Xelnas)
* Marbles will no longer put a trinket into your inventory.
* Blank runes will now show the effect if you use the Vanilla Streak Text mod. (Thanks Gamonymous)
* Added Depths / Necropolis / Dank Depths room #227 to the Forgotten softlock list. (Thanks Gamonymous)
* Fixed the bug where you could take a Checkpoint when in ghost form. (Thanks NorBro86)
* Fixed the bug where Troll Bombs, Mega Troll Bombs, and Sticky Nickels would get deleted in automatic inventory management. (Thanks Dea1h)

### *v0.37.9* - May 19th, 2019

* Blastocyst is now immune to freeze. (Thanks Xelnas)
* Getting Spun will now automatically put the pill into your inventory.
* Taking a Checkpoint while in ghost form will no longer send you to the next character. (Thanks mgln)
* Fixed the bug where the sprite was wrong for the all-red pill in the effect list HUD. (Thanks mgln)
* Fixed the bug where it was possible for Eden to naturally start with the selected starting item. (Thanks Gamonymous)
* Fixed the bug where the character number would not be reset if you entered the "Change Char Order" challenge. (Thanks Gamonymous)

### *v0.37.7* - May 16th, 2019

* Fixed the bug where resetting as Eden could cause the mod to go back to the first character under certain conditions. (Thanks Krakenos)

### *v0.37.5* - May 16th, 2019

* Added Depths / Necropolis / Dank Depths room #492 to the Forgotten softlock list. (Thanks Gamonymous)

### *v0.37.4* - May 15th, 2019

* Fixed the bug where fast-travel would cause Forgotten to die after using a Strength card under certain conditions. (Thanks NorBro86)

### *v0.37.3* - May 15th, 2019

* Fixed the bug in season 6 where the veto button would veto the wrong item under certain conditions. (Thanks thereisnofuture)

### *v0.37.2* - May 15th, 2019

* Re-enabled fast-reset with double tapping R. (The first floor check is replaced by a three room check.) (Thanks thereisnofuture)

### *v0.37.1* - May 15th, 2019

* Fixed the bug where Eden was given no items in Season 6. (Thanks thereisnofuture)

### *v0.37.0* - May 14th, 2019

* The Racing+ client now supports races to Hush, Delirium, and the Boss Rush. (Thanks Dea1h)
* All friendly green creep is now changed to red so that it is easier to tell from enemy creep. (Along with the previous change to enemy creep, this should make creep across the entire game completely consistent.)
* Season 6 item selection is changed to have a 1/6 chance to grant a big 4 item. (Thanks Krakenos)
* Azazel will no longer randomly start Ipecac in Season 6. (Thanks mgln)
* Integrated the sprites from the [Consistent Pills](https://steamcommunity.com/sharedfiles/filedetails/?id=1418510121) mod so that pills are easier to identify at a glance.
* Changed the sprite for spotted red pills to all red so that they are easier to distinguish from other pills.
* Fast-reset is now disabled if you have entered 3 or more rooms.
* Enabled both doors in Curse Rooms #10, #18, and #19.
* Addded Caves / Catacombs / Flooded Caves room #754 to the Forgotten softlock list. (Thanks Gamonymous)
* Addded Catacombs room #224 to the Forgotten softlock list.
* Fixed the bug where Sacred Heart would cause bombs to lose special abilities in season 6. (Thanks NorBro86)
* Fixed the bug where Forgotten would not get soul hearts and black hearts upon seeded revival. (Thanks InvaderTim)
* Fixed the bug where enemy creep would show as red creep on the first frame after spawning under certain circumstances.
* Fixed the vanilla spelling of Maw of the Void, Spear of Destiny, and Crown of Light.
* Fixed the bug where Eden could start with Broken Ankh and Cain's Eye in season 6. (Thanks Moucheron Quipet)

### *v0.36.0* - May 12th, 2019

* Season 5 has been added to the Hall of Fame.
* The Justice card will now automatically insert the coin, bomb, and key into your inventory. (Thanks BMZ_Loop)
* Blank Runes will now display the streak text of the randomly chosen effect. (Thanks Dea1h)
* Dead Sea Scrolls will now display the streak text of the randomly chosen effect.
* The streak text will now always appear when you use a card.
* Redesigned Gurglings room #5144 to workaround a bug with There's Options. (Thanks NorBro86)
* Fixed the bug where the automatic inventory insertion feature would not work correctly if you opened a chest at the same time as getting an item. (Thanks PassionDrama)
* Fixed the bug where the automatic inventory insertion feature would not work correctly if you were in a shop.
* Fixed the bug where the Quarter would not work properly with seeded revival. (Thanks InvaderTim)
* Fixed the bug where the Stompy transformation streak text would not show under certain circumstances.
* Fixed the bug where Dead Sea Scrolls would not play a use animation.
* Fixed the bug where the fully unlocked save file check was not working properly.

### *v0.35.2* - May 11th, 2019

* Necronomicon, Monster Manual, Whore of Babylon, Dead Sea Scrolls, Mom's Bra, Mom's Pad, Anarchist Cookbook, The Bible, The Hourglass, D4, D10, Flush!, D100, A Missing Page, Missing Page 2, Spider Butt, Book of Belial, D8, D12, Clicker, Mama Mega!, and Dry Baby no longer have "giantbook" animations. (The animations are deliberately kept for Book of Revelations and Satanic Bible.)
* Sun cards, Death cards, and runes no longer have "giantbook" animations. (The animations are deliberately kept for eternal hearts, black hearts, rainbow poops, sleeping in a bed, and Super Bum.)
* Added Cursed Eye to the Forgotten softlock prevention check. (Thanks Gamonymous)

### *v0.35.1* - May 10th, 2019

* Floors with specific island rooms will now be automatically reseeded if you are playing as The Forgotten, have no soul hearts, and have Chocolate Milk or Brimstone. (This prevents softlocks where you cannot reach enemies on an island.) There are likely some island rooms that I missed, so if you report them I can add them to the list. (Thanks Thoday)
* Fixed the bug where the seeded death mechanic would not work if you died to a Mom's Hand. (Thanks thereisnofuture & Gamonymous)

### *v0.35.0* - May 9th, 2019

* Caffeine Pill will now drop the pill on the ground (instead of directly inserting it into your inventory) if your inventory is already filled.
* Items that drop pickups on the ground will now automatically insert them into your inventory instead, if there is room. (However, Purple Heart, Mom's Toenail, The Tick, Faded Polaroid, and Ouroboros Worm are never inserted automatically.)
* Removed Necropolis room #966 (narrow room with triple Gaping Maws). (Thanks Dea1h)
* Both photos will no longer spawn (after Mom) if you have Mysterious Paper. (Thanks Moucheron Quipet)
* Both paths will no longer spawn (after It Lives!) if you have Mysterious Paper. (Thanks Moucheron Quipet)

### *v0.34.7* - May 7th, 2019

* Racing+ will now report the version when you press the "v" key.
* A clarification on the Guppy's Collar change in the previous patch: it is still possible for Guppy's Collar to revive the player if they currently have any other revival items. (Thanks Gamonymous)
* Removed Womb / Scarred Womb room #865 (narrow room with triple Gaping Maws). (Thanks Dea1h)
* The mod will now automatically reset the run if you are playing as Eden and happen to start with the vanilla Schoolbag (unless it is a seeded run).
* In season 6, vetos will now be automatically reset if you enter the "Change Char Order" custom challenge. (Thanks NorBro86)
* In season 6, the mod will now automatically reset the run if you are playing as Eden and happen to start with The Compass. (Thanks thereisnofuture)
* Fixed the bug where vanilla races and custom races could not be finished.

### *v0.34.6* - May 5th, 2019

* Removed Sheol narrow rooms #257, #275, and #308 (with Mom's Dead Hand). (Thanks Dea1h)
* Added the season 3 Sacrifice Room mechanic to season 6. (Thanks thereisnofuture)
* Fixed the bug where you could manually change from The Forgotten / The Soul when travelling between floors.

### *v0.34.5* - May 3rd, 2019

* The streak text will now always appear when you use a pill.
* In a seeded race or a season 6 speedrun, it is no longer possible to become revived from Guppy's Collar if the player has no other revival items (to prevent the vanilla permadeath bug).
* Removed Broken Ankh from the trinket pool for seeded races and season 6. (Thanks mgln)
* If The Soul enters a trapdoor or beam of light, the game will now automatically switch to The Forgotten (to prevent bugs with teleporting the body).
* If The Soul enters a room with Mom, Gurdy, or It Lives!, the game will now automatically switch to The Forgotten (to prevent bugs with teleporting the body).
* Fixed the bug where The Soul would not switch back to the Forgotten if they died in a seeded race / season 6 speedrun. (Thanks NorBro86)
* Fixed the bug where some rooms were incorrectly flipped. (Thanks thereisnofuture)
* Fixed the bug where duplicate items could be started in season 6. (Thanks NorBro86)
* Fixed the bug where the death timer was overlapping with the "S6" icon in season 6.

### *v0.34.4* - May 3rd, 2019

* The logo for season 6 is improved. Thanks to BMZ_Loop for working on this.
* When performing a multi-character speedrun, there is now a graphic that shows which season you are playing. Thanks to BMZ_Loop for working on this.
* It is no longer possible to roll or destroy a Checkpoint with the D6, D100, D Infinity, Dice Shard, Void, Black Rune, Crooked Penny, or Moving Box.
* In season 6, you are now guaranteed to start a new item on your first character (even if you made it to the second character or beyond).
* Fixed the bug where two heart containers would be removed if you used a Strength card on The Forgotten, swapped forms, and went to the next floor. (Thanks Dea1h)
* Fixed the bug where familiars, knives, clubs, and scythes would appear in the center of the room during the 19th frame of the Mom fight.

### *v0.34.2* - May 2nd, 2019

* Fixed some crashing issues.
* Fixed the bug where all doors would be enabled in a flipped L room. (Thanks mgln)

### *v0.34.0* - May 2nd, 2019

* Season 5 is finished!
  * Congratulations to Dea1h for the best time of 1:02:53, Cyber_1 for the second best time of 1:03:26, and CrafterLynx for the third best time of 1:04:17.
  * The top 10 times will be stored in the [Hall of Fame page](https://isaacracing.net/halloffame).
  * If you want to beat these times, the R+7 (S5) category will continue to be tracked on speedrun.com, but the official competition will move on to season 6.
* [Season 6](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md#r7-season-6) has officially begun! The new season will be considered beta for the first 2-3 weeks.
* Hundreds of API calls have been cached, so the mod should run better on slow computers.
* Mom will now always immediately stomp upon starting the fight, similar to how it works in vanilla.
* The Forsaken is now immune to fear. (This prevents the bug where it will not attack for an extended period of time.)
* Removed some more empty rooms.

### *v0.33.1* - April 27th, 2019

* Increased the delay on Pin/Frail/Scolex from 16 frames to 31 frames. (Thanks mgln)
* Fixed the bug where Pin/Frail/Scolex would gain a lot of velocity in certain circumstances. (Thanks Gamonymous)

### *v0.33.0* - April 27th, 2019

* Pin/Frail/Scolex will now attack you on the 16th frame instead of the 77th frame.
* Replaced the dirty bedroom icon with a new icon that represents a cobweb. Thanks to BMZ_Loop for creating this.
* There are now two additional key bindings available in the "Change Keybindings" custom challenge for dropping only trinkets and for dropping only pocket items.
* Removed the "Jr. Fetus Practice" and "Mahalath Practice" custom challenges.
* The 50% chance for a big 4 fart-reroll now applies to unseeded solo races.
* Fixed the bug where the Lil Haunts attached to a Haunt would not detach under certain circumstances.
* Fixed the bug where familiars would not start in the middle of the room.

### *v0.32.1* - April 24th, 2019

* The color for Cage's gray creep is now also turned to green.
* Fixed the bug where some specific kinds of creep would not turn to red. (Thanks NorBro86)
* Fixed the bug where if Lilith was given Incubus in a seeded revival, she would get an additional Incubus. (Thanks Gamonymous)

### *v0.32.0* - April 22nd, 2019

* The color for detrimental fires is now red (instead of yellow) so that players can easily distinguish them from friendly fires.
* The color for red creep has been changed to green (so that it is easier to see in various situations). (Thanks Nariom)
* Fixed the bug where Eden would get messed up if they started with Betrayal. (Thanks mgln)
* Fixed the bug where The Fallen and the Kamikaze Leeches on the Satan fight would always drop black hearts when killed with Maw of the Void. (Thanks mgln)

### *v0.31.4* - April 19th, 2019

* The animations for charge keys have been changed so that it is easier to tell them apart from normal keys. (Thanks Gamonymous)

### *v0.31.3* - April 13th, 2019

* The player will now start at the center of the starting room instead of next to the bottom door.
* Players who do not like the way that the new streak text looks have the option to revert to the vanilla graphics by using the following mod: https://steamcommunity.com/sharedfiles/filedetails/?id=1714310911

### *v0.31.2* - April 13th, 2019

* Slightly changed the streak animation.
* Fixed the bug where there would be no streak text for transformations. (Thanks AshDown)
* Fixed the bug where you could not select text on the client. (Thanks antizoubilamakA)

### *v0.31.1* - April 13th, 2019

* Fixed the bug where there would be no streak text for unidentified pills. (Thanks mgln)

### *v0.31.0* - April 12th, 2019

* Changed the "streak" text to be more minimalistic.
* Changed the vanilla level text that appears when you hold tab.
* Fixed the bug where The Void portal room would not open after defeating Hush. (Thanks thereisnofuture)
* Fixed the bug where The Void portal would get replaced by a trapdoor.  (Thanks thereisnofuture)
* Fixed the bug where the trapdoor would not spawn after Satan under certain conditions.

### *v0.30.2* - April 7th, 2019

* Fixed the (vanilla) bug where an attack fly would rarely spawn at an invalid position. (Thanks ceehe)

### *v0.30.0* - April 6th, 2019

* As a quality of life change, Death will no longer perform his slow attack.
* As a quality of life change, Cod Worms will now be replaced with Para-Bites.
* Added an error message if you try to play a custom challenge other than Season 5 with the Babies Mod enabled. (Thanks sisuka)
* Fixed the bug where the Soul Jar would not show the correct Devil Room percentages in the Found HUD. (Thanks Gamonymous)

### *v0.29.8* - March 11th, 2019

* Fixed the bug where Daddy Longlegs had the incorrect name in the client. (Thanks Gamonymous)
* Fixed the bug where the seeded death mechanic would get messed up if the player had the game paused. (Thanks Gamonymous & ReidMercury)
* Fixed the bug where having Restock could spawn Restock Machines under certain conditions. (Thanks thereisnofuture & Dea1h)
* Fixed the bug where Diplopia would not work on the photos after the Mom fight.
* Fixed the bug where the photos after the Mom fight would spawn erroneously if The Bible was used with Broken Remote. (Thanks NorBro86)

### *v0.29.6* - December 29th, 2018

* Reduced the delay on a Matriarch Chub to 3 frames (from 15 frames).
* Fixed the bug where Donation Machines could appear from Greed Plates. (Thanks mgln)

### *v0.29.3* - December 10th, 2018

* Fixed the bug where Golden Bombs and Golden Keys would be awarded upon a seeded revival even if the player changed floors. (Thanks mgln)

### *v0.29.2* - November 30th, 2018

* Reduced the diagonal knife window to 2 frames (from 3 frames).

### *v0.29.0* - November 19th, 2018

* Season 4 is finished!
  * Congratulations to antizoubilamakA for the best time of 56:46, Cyber_1 for the second best time of 57:55, and leo_ze_tron for the third best time of 58:42.
  * The top 10 times will be stored in the [Hall of Fame page](https://isaacracing.net/halloffame).
  * If you want to beat these times, the R+7 (S4) category will continue to be tracked on speedrun.com, but the official competition will move on to season 5.
* [Season 5](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md#r7-season-5) has officially begun!
* Diagonal knife throws will now have a 3-frame window instead of a 1-frame window.
* Fixed the bug where Contract From Below would result in errors when clearing a room on a set seed. (Thanks mgln)

### *v0.28.3* - November 19th, 2018

* Isaac is feeling festive. Happy Thanksgiving.
* Fixed the bug where deaths from pitfalls would not revive the player in seeded races. (Thanks Moucheron Quipet)
* Fixed the bug where the Matriarch nerf would only apply once per run. (Thanks Gamonymous)

### *v0.28.2* - November 19th, 2018

* Fixed the bug where Donation Machines could appear in custom challenges if you were on the first run after you opened the game. (Thanks leo_ze_tron)
* Fixed the bug where The Ludovico Technique was not working properly with Samael. (Thanks Gamonymous)

### *v0.28.1* - November 19th, 2018

* Fixed the bug where The Babies Mod would cause the fully unlocked save file check to fail. (Thanks thereisnofuture)
* Fixed the bug where speedrun initialization was not working. (Thanks mgln)
* Fixed the bug where the "Change Char Order" custom challenge was not working correctly. (Thanks thereisnofuture)
* Fixed the bug where the golden heart breaking sound would play when the seeded floor mechanic adjusted your health on The Forgotten specifically. (Thanks Gamonymous)
* Fixed the bug where the "next" and "previous" console commands were not working correctly.

### *v0.28.0* - November 18th, 2018

* The mod will now attempt to check to see if you are on a fully unlocked save file by starting on a specific seed with Eden and looking for certain items. (It will do this once every time the game is opened.) (Thanks AshDown)
* Keeper will now be given the Wooden Cross effect upon revival in a seeded race. (The effect will be removed upon reaching a new floor.) (Thanks mgln)
* Fixed the bug where the trophy would not fall at the end of the R+7 seeded challenge. (Thanks thereisnofuture)
* Fixed the bug where the golden heart breaking sound would play when the seeded floor mechanic adjusted your health. (Thanks Gamonymous)
* Fixed the bug where it showed that 0 frames passed when finishing a race.
* Fixed the bug where Contract From Below would result in errors when clearing a room on a set seed. (Thanks mgln)
* Fixed the bug where Caffeine Pill would give an extra pill during a revival in a seeded race. (Thanks Gamonymous)

### *v0.27.2* - November 17th, 2018

* You can now use the "next" and "previous" console commands to manually move forward and back through characters in a multi-character speedrun. (Thanks thereisnofuture)
* Fixed the bug where Forget Me Now and 5-pip Dice Rooms did not trigger the seeded floor system when playing on a set seed. (Thanks Moucheron Quipet)
* Fixed the bug where going into a new challenge would not exit the R+7 seeded challenge.

### *v0.27.1* - November 16th, 2018

* Fixed the bug where the "level" command would not work properly. (Thanks thereisnofuture)
* Fixed the bug where all of the drops in the seeded drop system were off by 10%. (Thanks blcd)
* Fixed the bug where bombs and chests were swapped in the new seeded drop system. (Thanks blcd)

### *v0.27.0* - November 16th, 2018

* Note that this patch contains some changes for the R+7 Seeded custom challenge. You may have to redo research that was previously done.
* There is a new custom system for awarding room clear awards when playing on a set seed. This will prevent situations where one player goes the wrong way and gets an Emperor card in a seeded race, for example. It is exactly the same as the vanilla system except for the following changes:
  * Instead of being based on the room seed, room drops are based on the starting seed of the run and are awarded in order.
  * A value of 0 luck is always used to calculate room drops, even if the player does not have 0 luck.
  * Rib of Greed no longer has a chance to increase coin drops.
  * Smelter no longer has a chance to increase trinket drops.
  * Guppy's Tail no longer has a chance to increase chest drops.
* Lucky Foot is now removed from all pools when playing on a set seed.
* Lucky Toe, Ace of Spades, Safety Cap, Match Stick, Child's Heart, Rusted Key, Daemon's Tail, and Watch Battery are now removed from the trinket pool when playing on a set seed.
* Seeded swapping will now always occur when playing on a set seed. (Thanks Fawkeyes)
* Silver Dollar and Bloody Crown will now always be removed when playing on a set seed. (Thanks Fawkeyes)
* Fixed the bug where bone hearts would be rearranged upon reaching a new floor when playing on a set seed.
* Fixed the bug where bone hearts would not be filled upon reaching a new floor when playing on a set seed. (Thanks Moucheron Quipet)
* Fixed the bug where the seeded swapping would use the seed from the origin floor instead of the destination floor.
* Fixed the bug where items would disappear from multiple Spiked / Mimic Chests on The Chest / Dark Room. (Thanks NorBro86)
* Deleted the code that prevents unavoidable damage from Spiked / Mimic Chests during the appearing animation, as the bug was fixed in the vanilla game.

### *v0.26.2* - November 15th, 2018

* The "level" console command will now always assume that you are in a seeded race. (Thanks thereisnofuture)

### *v0.26.0* - November 14th, 2018

* Note that this patch contains some changes for the R+7 Seeded custom challenge. You may have to redo research that was previously done.
* Normally, special room placement is affected by coin count, key count, health amount, and more. This can be a problem for seeded races, as two players can get slightly different floors. This patch contains a new custom system that is turned on in seeded races and the R+7 Seeded custom challenge to provide consistent level generation. Right before you reach the next floor, the custom system will now manually set all of the things that affect level generation in a seeded way, and then swap them back after the floor is generated. The percentages of getting the outcomes are as follows:
  * Devil Room visited: 0% on B2, 100% otherwise
  * Book touched: 50% for 0 touched, 50% for 1 touched
  * Coins: 50% for 0 coins, 50% for 20 coins
  * Keys: 50% for 0 keys, 50% for 2 keys
  * Full health: 66% for full health, 33% for damaged health
  * Critical health: 75% for non-critical health, 25% for critical health
* Because of the above system, Boss Rushes are no longer manually created in seeded races.
* Previously, rerolled items from player-created pedetals would be seeded based on the particular room. Now, they are seeded based on the start seed.
* The "level #" custom command has been added to the console. This command will take you to the particular stage and stage type for the particular seed. If you are in a seeded race or the R+7 Seeded custom challenge, it will also perform the necessary seeded swapping beforehand. Example usage: "level 5"
* Rooms will no longer be reseeded in the R+7 Seeded custom challenge (for Duality, duplicate rooms, etc.).
* Silver Dollar and Bloody Crown are now removed from seeded races and the R+7 Seeded custom challenge.
* Fixed the (vanilla) bug where Dead Sea Scrolls was not seeded.
* Fixed the bug where Teleports were not being seeded correctly under certain circumstances.
* Fixed the bug where drops from Bag-style familiars were not being seeded correctly under certain circumstances.

### *v0.25.11* - November 12th, 2018

* Fixed the bug where Samael would get softlocked after killing the first phase of the Matriarch. (Thanks Greninja_San)
* Fixed the bug where both photos would spawn in the R+7 Seeded custom challenge.
* Fixed the bug where both paths would appear after It Lives! in the R+7 Seeded custom challenge under certain conditions.

### *v0.25.10* - November 11th, 2018

* Fixed the bug where the client would not wait long enough for an automatic update when logging in.
* Fixed the bug where a random item would spawn upon revival in a seeded race under certain conditions. (Thanks PassionDrama)

### *v0.25.9* - November 11th, 2018

* Fixed the bug where the starting item would not get properly recorded in the R+7 Season 5 custom challenge.

### *v0.25.8* - November 10th, 2018

* Fixed the bug where active items taken as a ghost would be eaten upon revival in seeded races. (Thanks Gamonymous)
* Fixed the bug where passive items could go inside the Schoolbag when using the Moving Box. (Thanks Shigan)

### *v0.25.7* - November 9th, 2018

* Fixed the bug where the trophy would not appear at the end of a R+7 Seeded custom challenge. (Thanks Moucheron Quipet)

### *v0.25.6* - November 8th, 2018

* Frame counts will now show again, since Will pointed out that sliding animations do count towards frames seen.
* Fixed the bug where the first character started with More Options in the R+7 Seeded custom challenge.

### *v0.25.5* - November 7th, 2018

* Frame counts will no longer show, since sliding animations will not count towards frames seen. (Thanks thereisnofuture)
* Fixed the bug where the Checkpoint would not appear in the R+7 Seeded custom challenge. (Thanks AshDown)

### *v0.25.4* - November 6th, 2018

* Unlike the other challenges, exiting and going into a normal run will not cancel a R+7 Seeded speedrun (due to technical reasons). To set the game back to normal, use the "Finished" item that spawns in the starting room of the first character.
* Fixed the bugs where dropped trinkets would morph into something else in the R+7 Seeded custom challenge. (Thanks Gamonymous)
* Fixed the bug where certain things were not seeded in the R+7 Seeded custom challenge. (Thanks Moucheron Quipet)

### *v0.25.2* - November 5th, 2018

* In the R+7 Seeded custom challenge, Eden has been swapped with Azazel. (Thanks Moucheron Quipet)
* Fixed the bug where the trinkets were not seeded in the R+7 Seeded custom challenge. (Thanks Moucheron Quipet)

### *v0.25.0* - November 4th, 2018

* Introducing a new custom challenge and a new way to compete with your fellow speedrunners: R+7 Seeded (Q4 2018)
  * Unlike the other challenges, this challenge will only be available for a limited time.
  * More information can be found here: https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md#r7-seeded
* Races can now be started with Random Baby as the character. If using this, make sure that everyone in the race knows to have The Babies Mod downloaded and enabled.
* When a Chub emerges from The Matriarch, all enemies in the room will now be killed (which is similar to the mechanic when Mom / It Lives! is killed).
* When completing a race or speedrun, Racing+ will now show you the number of frames that passed. This will let you know how much time you lose to lag. In tournaments, the winner of very close races should be decided by frame count.
* Fixed the bug where Epic Fetus would not work properly on Samael. (Thanks Shigan)
* Fixed the bug where the artificial Matriarch Chub stun was not working properly.

### *v0.24.7* - October 26th, 2018

* Fixed the bug where you could get an item from a Treasure Room in Basement 1 on the second character and beyond in the R+7 Season 5 custom challenge. (Thanks Dea1h)
* Fixed the bug where the Lil Delirium sprite was not updated in the starting room of diversity races. (Thanks AshDown)
* Fixed the bug where Mutant Spider's Inner Eye should not show correctly in the Racing+ client if it was a starting item. (Thanks mgln)
* Fixed the bug where you could reroll your instant-start item in the the R+7 Season 5 custom challenge under certain circumstances. (Thanks SlashSP)

### *v0.24.3* - October 22nd, 2018

* The Babies Mod is now uploaded to the Steam Workshop.
* R+7 Season 5 is now released for beta testing. You can provide general feedback in the "#b-general" channel. Bug reports should go in the "#bugs" channel.
* Duplicate room checking is now disabled on runs with the "Infinite Basements" Easter Egg. (Thanks Gamonymous)
* Looping floor checking is temporarily disabled until it can be rewritten to account for "bunched" floors that are non-looping.

### *v0.24.2* - October 21st, 2018

* Duplicate room checking no longer occurs on The Chest.
* Floors will no longer be reseeded in seeded races. (This is to troubleshooting seeded floor discrepancies.)
* Fast-travel is now disabled if you have the Infinite Basement Easter Egg enabled.
* Crown of Light will no longer grant two soul hearts when taken as a fart-reroll on Basement 1.

### *v0.24.1* - October 20th, 2018

* Racing+ will no longer automatically remove applied easter eggs.
* Fixed the big-tear softlock in Necropolis room #936 by deleting a fire.
* Added Necropolis room #936 to the Mimic exemption list (a narrow room with two Cross Stone Shooters). (Thanks caesar and PassionDrama)

### *v0.24.0* - October 19th, 2018

* Racing+ will now reseed the floor if it contains a loop.
* Moved the Night Crawler away from the door on Catacombs room #267.

### *v0.23.3* - October 14th, 2018

* Fast-clear is now disabled in Greed Mode. (Thanks BigBess)
* Fixed the bug where the Moving Box would be invisible inside of the Schoolbag if it was currently open. (Thanks Gamonymous)
* Fixed the bug where Samael would not shoot properly if he had Brimstone or Cursed Eye. (Thanks Gamonymous)

### *v0.23.2* - October 13th, 2018

* Removed 4 pits from Polycephalus room #5106 to fix the bug where There's Options would cause pedestal items to block the bottom door.
* Changed Flooded Caves rooms #993, #998, #999, #1003, #1004, #1008, #1010, #1013, #1014, #1015, #1017, #1020, #1027, #1028, #1044, and #1049 to ensure that Mr. Mines never spawn too close to a doorway.
* Fixed the bug where a pedestal item could rarely overlap with a trapdoor or crawlspace.

### *v0.23.0* - October 12th, 2018

* Tarot cards, playing cards, and runes are no longer face up. (The other cards remain face up.)
* The Chub that spawns after The Matriarch will now be stunned for the first 0.5 seconds to prevent unavoidable damage. (Thanks StoneAgeMarcus)
* Basement 1 is now exempt from the room duplication check. (Thanks AshDown)
* Replaced the Lil Delirium collectible sprite with one that is easier to distinguish from Delirious. Thanks goes to Gamonymous for making it.
* Changed Hush Flies to Attack Flies in Depths/Necropolis/Dank room #866 and #894.
* Removed the lower door in Flooded Caves room #994.
* Fixed the unavoidable damage caused by champion Gurglings in Scarred Womb room #555. (Thanks CrafterLynx)
* Fixed the bug where Krampus would not grant a charge during a seeded race.
* Fixed the bug where Keeper would erroneously lose a coin container after using a Strength card under certain conditions. (Thanks Gamonymous)
* Fixed the bug where you could touch the trophy while dead in a seeded race. (Thanks Hispa)

### *v0.22.5* - September 29th, 2018

* Fixed the bug where Krampus would not drop the same drop on the same seed consistently.
* Fixed the bug where rolling both photos would give you similar boss items.
* Fixed the bug where double key pieces would drop in seeded races. (Thanks Moucheron Quipet)

### *v0.22.3* - September 27th, 2018

* Fixed the bug where A Lump of Coal, Krampus' Head, Key Piece 1, and Key Piece 2 rerolls were not properly seeded in seeded races. (Thanks AshDown & Moucheron Quipet)

### *v0.22.2* - September 26th, 2018

* Fixed the bug where re-entering a shop would turn a card face-up. (Thanks mgln)

### *v0.22.1* - September 24th, 2018

* Cards in shops will no longer be face up. (Thanks SlashSP)
* In R+7 Season 4, you will no longer be penalized for entering a library on Basement 1.
* Fixed the bug where multiple items could be taken in Angel Rooms and the Boss Rush in seeded races. (Thanks Shigan)
* Fixed the bug where items in Devil Rooms, Angel Rooms, and the Boss Rush were the same on every seed in seeded races. (Thanks Gamonymous)
* Fixed the bug where the sad animation would play if you entered the same Sacrifice Room twice in a R+7 Season 4 on Basement 1 more than one time.

### *v0.22.0* - September 23rd, 2018

* As a quality of life change, cards are runes spawn "face up" to avoid annoying card shuffling. This is experimental and may be reverted in a future patch.
* Holding tab will now show the color of any identified pills on your current run. (If more than 7 pills are identified, only the first 7 will be shown.)
* During seeded races, Devil Rooms are now always room #0 and hard-coded to grant rewards in order. This means it is no longer advantageous to intentionally take red heart damage on Basement 2, for example. (Krampus percentages and room rewards should be the same as other formats.)
* During seeded races, Angel Rooms are now always room #0 and hard-coded to grant rewards in order. (Room rewards should be the same as other formats.)
* During seeded races, the Boss Rush room is now always room #0 and hard-coded to have either 2, 4, or 8 items depending on the seed. (The percentages should be the same as other formats.) (Thanks HauntedQuest)
* Fixed the bug where Keeper would get blue flies under certain conditions when reviving in a seeded race. (Thanks PassionDrama)
* Fixed the bug where the Strength card granted a permanent red heart if you changed floors while it was active. (Thanks thereisnofuture)

### *v0.21.6* - September 21st, 2018

* Similar to dying in a Sacrifice Room, you will now permanently die in a seeded race if you die in the Boss Rush. (Thanks Hispa)

### *v0.21.5* - September 20th, 2018

* Added Catacombs room #285 to the Mimic exemption list (a room with 3 Bonies). (Thanks thereisnofuture)
* Fixed the bug where having Caffeine Pill would mess up a seeded death revival. (Thanks mgln)
* Fixed the bug where dying on seeded revival would sometimes delete pickups. (Thanks caesar)
* Fixed the bug where fast-reset would be messed up on some controllers. (Thanks Lobsterosity and Gamonymous)
* Fixed the bug where the tournament page on the website was not working. (Thanks PassionDrama)
* Fixed the bug where Samael's head would jerk around when you pushed the tear fire buttons.

### *v0.21.4* - September 15th, 2018

* Fast-reset will now be disabled for your current run if you have opened the console at least one time.
* Fixed the bug where you could use a card/pill while transitioning to the next floor.
* Fixed the bug where you could use a card/pill during a room transition (which would delete the card/pill).
* Fixed the bug where Racing+ would not detect that the race was finished after disconnecting and reconnecting. (Thanks Krakenos)
* Fixed the bug where using a Strength card would kill you upon reaching the next floor with no other hearts. (Thanks Thoday)
* Fixed the bug where you could reset the game when the countdown is at 3 seconds or lower.
* Fixed the bug where the forfeit rate on the profile page was 50 instead of 100. (Thanks mgln)
* Fixed the bug where the "no dude" style sound effects would play at the same time as the "1st place" style sound effects.
* Fixed the bug where trapdoors would not work properly with the True Co-op Mod. (Thanks thisguyisbarry)

### *v0.21.3* - September 11th, 2018

* Fixed the bug where Judas was not starting with the Schoolbag in ranked solo unseeded races. (Thanks Cold90a)

### *v0.21.2* - September 10th, 2018

* Fixed the bug where the item tracker would delete all of the items if Racing+ reseeded Basement 1. (Thanks Cyber_1 and Hyphen-ated)

### *v0.21.1* - September 9th, 2018

* Fixed the new unseeded mechanics. (Thanks Greninja_San)
* Fixed the close Drowned Boom Fly in Flooded Caves room #974.
* Fixed the close Guts in Utero room #5.
* Removed Womb/Utero/Scarred narrow room #611 (with Mom's Dead Hand).
* Removed 1 duplicated room from the (vanilla) Cellar.
* Removed 28 duplicated rooms from the (vanilla) Caves/Catacombs/Flooded.
* Removed 36 duplicated rooms from the (vanilla) Depths/Necropolis/Dank.
* Removed 36 duplicated rooms from the (vanilla) Womb/Utero/Scarred.
* Moved the "Avg. time per char" text to the 2nd line so that it is not hidden by the Checkpoint item text.

### *v0.21.0* - September 5th, 2018

* Increased the number of races that count towards the solo ranked unseeded leaderboards from 50 to 100.
* In unseeded races, there are now additional balance changes:
  * Each racer starts with More Options. More Options is removed upon entering the first Treasure Room.
  * The following items have a 50% chance to be rerolled into something else if found in a Basement 1 Treasure Room:
    * Mom's Knife --> Incubus
    * Tech X --> Crown of Light
    * Epic Fetus --> Sacred Heart
    * Ipecac --> Mutant Spider + The Inner Eye
* Added Basement / Cellar / Burning Basement room #716 to the Mimic exemption list (a narrow room with 4 Mulibooms). (Thanks thereisnofuture)
* Added Necropolis room #974 to the Mimic exemption list (a room with 5 Nerve Endings and a Broken Gaping Maw). (Thanks Ibotep and Dea1h)

### *v0.20.4* - September 3rd, 2018

* The race ID will now be displayed in the first room of the race (but only during the first two seconds of the race).
* Fixed the bug where the average time per character was not showing correctly. Thanks to PassionDrama for finding and fixing the bug.
* Fixed the vanilla bug where players did not take any damage from Jr. Fetus troll bombs. (Thanks AshDown)
* Fixed the bug where fart-rerolled items were not removed from item pools on sight.

### *v0.20.3* - August 21st, 2018

* Racing+ will now automatically reseed a floor if it contains a duplicate room. (This also takes into account rooms seen on previous floors.)
* Fixed the bug where golden bombs and keys were not restored upon reviving in a seeded race. (Thanks mgln)
* Fixed the bug where you could see the skipped floor for a single frame during a narrow boss room Duality reseed.
* Fixed the bug where the Spanish language was not working properly. (Thanks Hispa)

### *v0.20.2* - August 21st, 2018

* Racing+ now supports Spanish as a third official language. (Thanks Hispa)
* Removed the sliding part of the text animation and shortened it (for the level name, the item name, etc.).
* Fixed the bug where the "R+15 (Vanilla)" custom challenge would not work. (Thanks CrafterLynx)

### *v0.20.1* - August 18th, 2018

* After finishing a run with a character in a custom challenge, it will now show your average time per character.
* Added a graphic for the "R+15 (V)" button in the "Change Char Order" custom challenge. (Thanks Gromfalloon)
* The new race sound effect will no longer play for password-protected races. (Thanks PassionDrama)
* Fixed the bug where fart-rerolls were broken in diversity races. (Thanks thereisnofuture)

### *v0.20.0* - August 7th, 2018

* Added the "R+15 (Vanilla)" custom challenge. This is not considered an official category.
* Fixed the vanilla bug where Wiggle Worm granted a delayed tears up (instead of a normal tears up). (Thanks thisguyisbarry)
* Sped up the fade-in that occurs at the beginning of a run.
* Changed the color of the Locust of Famine trinket to match the actual color of the flies. (Thanks Hispa)
* Fixed the bug where Incubus would get an extra Incubus familiar after reviving in a seeded race. (Thanks thereisnofuture)

### *v0.19.15* - July 28th, 2018

* Changed the color of the Friend Zone collectible to match the actual color of the familiar.
* Fixed the bug where the game would occasionally crash when using either Telepills or Blank Card. (Thanks Hispa and HauntedQuest)

### *v0.19.14* - July 28th, 2018

* Fixed the bug where the Dead Eye multiplier was not cleared after dying in a seeded race. (Thanks mgln)
* Fixed the bug where Mega Blast would continue to fire after dying in a seeded race. (It will still look like it is firing an invisible laser, but this is a side-effect of the laser removal.) (Thanks mgln)
* Fixed the bug where certain items would not be given back to Samael after dying in a seeded race. (Thanks Greninja_San)
* Fixed the bug where the number shown for the final character was wrong in the "Choose Char Order" custom challenge under certain conditions.
* Fixed various bugs with the True Co-op Mod. (Thanks thisguyisbarry)

### *v0.19.13* - July 26th, 2018

* You can now only store one multi-character speedrun order at a time. (This simplifies the code.)
* When More Options is given for only Basement 1, it will no longer show the costume in order to reduce confusion and clutter.
* Fixed the bug where the mod would infinitately reset if you went into a custom challenge without setting a character order first. (Thanks olo70009)

### *v0.19.12* - July 25th, 2018

* Both photos will now spawn if you are doing a normal (i.e. non-race) run.
* Larry Jr. has been moved away from the doors in rooms #1025 and #1028.
* Fixed the bug where clean bedroom #24 would glitch out if you bombed the center of the room. (Thanks Hispa)
* Fixed the bug where the secondary character would not get a charge on their active item after clearing a room (when using the True Co-op Mod). (Thanks thisguyisbarry)
* Fixed the bug where selecting dark mode would crash the client. (Thanks Gamonymous)

### *v0.19.10* - July 22nd, 2018

* Fixed the bug where both paths would spawn after It Lives! on races to Blue Baby.

### *v0.19.9* - July 22nd, 2018

* The system that handles automatic updates has itself been updated, which should hopefully fix the issues with automatic updating in the last patch.
* Changed the charge bars back to the custom Racing+ minimialistic pre-BP5 version. Note that the Maw of the Void charge bar is placed lower than the other charge bars; this is a vanilla bug that I cannot control.
* Changed the color of the Forever Alone collectible from dark blue to light blue (to match the actual color of the familiar).
* Changed the color of the Distant Admiration collectible from black to red (to match the actual color of the familiar).
* Changed the 20/20 sprite to make it easier to see.
* Replaced the Abaddon sprite with the pre-BP5 version.
* Fixed the bug where The Forgotten would not revive with the correct health in a seeded race. He will now revive with one bone heart that is half filled and 0 soul hearts, meaning that he will be unable to switch to The Soul. (Thanks Moucheron Quipet)
* Fixed the bug where text in the top-left (i.e. the run seed) would be misaligned if you had any bone hearts.
* Fixed the bug where dying and reviving in a seeded race would make you the incorrect size under certain situations. (Thanks StoneAgeMarcus)

### *v0.19.8* - July 16th, 2018

* Fixed the bug where some rooms with Rage Creeps had incorrect door assignment. (Thanks leo_ze_tron)

### *v0.19.7* - July 15th, 2018

Mod changes:

* Diversity races will no longer grant items that characters naturally start with. (Thanks AshDown)
* Dying in a seeded race will now drop your trinkets and pocket items next to where you died.
* Removed the custom handling for The Lamb (since it was fixed in the vanilla game).
* Removed a fire from the narrow Burning Basement room with a Rag Man.
* Fixed the bug where Angel Room #6 had 2 doors instead of 4. (Thanks caesar)
* Fixed the bug where pickups would spawn on the ground when you revived in a seeded race and had Marbles, Marrow, or Divorce Papers.
* Fixed the bug where you would get extra bone hearts if you revived in a seeded race and had Marrow, Divorce Papers, or Brittle Bones. (Thanks Moucheron Quipet and thisguyisbarry)
* Fixed the bug where if you took a pedestal item as a seeded death ghost, you would not get any of your other items back.
* Fixed the bug where Wall Creeps with negative coordinates could lead to unavoidable damage. (Thanks NotAnElk)
* Fixed the bug where if Keeper used a Strength card while at 2 coin containers, he would lose a coin container upon leaving the room. (Thanks NorBro86)
* Fixed the bug where a Host could spawn on top of a trapdoor in Double Trouble room #3762. (Thanks NorBro86)
* Fixed the bug where under certain specific situations, players would not die when they had no hearts remaining. (Thanks ceehe)
* Fixed the bug where the "correct" path would not appear after defeating Hush under certain circumstances. (Thanks PassionDrama)
* Fixed the bug where it was possible to take two "big 4" items in the "Change Char Order" custom challenge. (Thanks olo70009)
* Fixed the bug where the pentagram was cut off on the character select screen (when selecting Judas).
* Fixed the bug where it was possible to duplicate chests by pushing them on top of stationary stone enemies. (Thanks leo_ze_tron)

Client changes:

* Fixed the bug where the "Everything" race goal had no tooltip. (Thanks PassionDrama)
* Fixed the bug where the language would always start in English even if you had set it to French. (Thanks Greninja_San)

### *v0.19.6* - May 14th, 2018

* The next version after this may not automatically update because due to issues with me upgrading to the latest version of Electron.
* Attempted to fix the bug where you could get an empty boss room. (I thought I fixed it in the last patch. I am still unsure as to why it is happening.) (Thanks thisguyisbarry)
* Fixed the client bug where entering the wrong password would prevent you from clicking on anything. (Thanks thereisnofuture and FineWolf)

### *v0.19.5* - May 13th, 2018

* Racing+ will no longer erase your character order and custom hotkeys after every patch.
* Fixed the bug where having the client open would mess up the "Choose Char Order" custom challenge.
* Removed one row of Pitalls on Devil room #2. (Thanks StoneAgeMarcus)
* Fixed the bug where it was possible to get an empty boss room on Basement 1 or Basement 2. (Thanks AshDown)
* Fixed the bug where doors would appear in the Pre-Race Room. (Thanks Greninja_San)

### *v0.19.2* - May 12th, 2018

* The client now has a "dark mode" theme. You can enable it in the settings. Thanks to SapphireHX for coding this.
* Removed heart drop pickups in Angel Rooms #2, #7, #13, and #14. (It is still possible to get soul hearts from fires in Angel Rooms.)
* The Devil Room with 3 items (#2) now has more Pitfalls.
* Added some Blue Fires to Angel Room #3 to make it unique.
* Removed adding Flat Stone to the Treasure Room item pool (since it was fixed in the vanilla game).
* Fixed the bug where flipped rooms were accidently not applied to some floors.
* Fixed the bug where the Angel Room change from the last patch was not applied.

### *v0.19.1* - May 10th, 2018

News:

* While the Devil Room and Angel Room changes introduced last week were seen as an improvement by most of the community, I'm not satisfied until I can make Racing+ the best it can be. Based on community feedback, there is room for some things to be tweaked. Most people were indeed in favor of reducing RNG, but a significant portion liked the "fun" aspect of getting a 4 item devil deal. So, it seems appropriate to strike a compromise between getting fun rooms and getting consistent rewards, so that everyone can get some of what they want.
* Furthermore, a good chunk of people felt like Devil Rooms needed a slight buff, as Afterbirth+ and the Booster Packs have further diluted the pool value. In the previous change, the overall power level of Devil Rooms remained the same. But adhering to this principle is restrictive in that it forces a specific amount of 1 item deals. Adding a few pedestals is a slight buff to Devil Rooms, but it also has the benefit of helping to reduce RNG. In addition to adding pedestals, I've also done some other nerfs for balance reasons.
* Angel Rooms look to be in a good spot, so hardly any changes to them seem necessary.
* The results of the "rock" poll (regarding the Treasure Room change) was 15 to 23 in favor of not changing anything. However, the vast majority of people were for making the change on Basement 1 only, so I've done the work to custom code that, and this should satisfy almost everyone.

Mod Changes:

* Devil Deals have been nerfed:
  * There are no longer any enemies in Devil Rooms, so it is harder to get your D6 up and backtracking is more important.
  * There are no longer black hearts and Red Chests in Devil Rooms.
  * It is no longer possible to get heart drops from fires in Devil Rooms.
  * There are more hazards in various Devil Rooms.
  * The 2 Red Chests in room #16 have been replaced with 4 bombs.
  * The random card in room #15 has been removed.
  * There is a 0.6% chance to get a room with 10 Red Chests. (There is a 10% chance to get an item per Red Chest, so this will yield one or more items 65% of the time.)
* Devil Deals have been buffed:
  * There is a 23.5% chance to get a room with 1 item (decreased from 31.6%).
  * There is a 70.4% chance to get a room with 2 items (increased from 68.4%).
  * There is a 5% chance to get a room with 3 items (increased from 0%).
  * There is a 0.6% chance to get a room with 4 items (increased from 0%).
  * The Red Chest in room #14 has been replaced with a ? card.
* The Angel Room with 2 items behind key blocks (#7) now has 3 items.
* You will now always be able to take an item in the Basement 1 Treasure Room without spending a bomb or being forced to walk on spikes. (Thanks Cyber_1)
* Removed the custom handling for Mushrooms, since the unavoidable damage from skulls was fixed in the vanilla game, and Edmund personally confirmed that he intended for Mushrooms to appear in floors other than 3 and 4.

### *v0.19.0* - May 8th, 2018

* The client now has the option to password protect a race. Thanks to FineWolf for coding this.
* All of the room fixes are now in the game again. (Duality, unavoidable damage, etc.)
* Rooms now have a chance to be flipped.
* Both narrow Pride rooms are removed.
* Fixed the bug where Book of Sin would spawn a pickup on top of you. (Thanks thisguyisbarry)

### *v0.18.12* - May 4th, 2018

* Removed the custom handling for Eyes and Bloodshot Eyes (since it was fixed in the vanilla game).
* Fixed the bug where using the Sacrifice Room teleport to the Dark Room would crash the game. (Thanks StoneAgeMarcus)
* Fixed the bug where the player would become invisible in the Mom or It Lives! fight under conditions. (Thanks Blumpkin Idaho)

### *v0.18.11* - May 4th, 2018

* Fixed the bug where sometimes bombs would be invisible. (Thanks Moucheron Quipet and thisguyisbarry)

### *v0.18.10* - May 3rd, 2018

* Fixed the (vanilla) bug where Flat Stone was not in the Treasure Room item pool. (Thanks StoneAgeMarcus)
* Fixed the bug where Samael would spawn as the Forgotten in R+7 season 2. (Thanks Cyber_1)
* Fixed the bug where the Strength card would not work properly with fast-travel. (Thanks Blumpkin Idaho)
* Fixed the bug where familiars and flies are teleported under Gurdy and It Lives! (Thanks Moucheron Quipet)

### *v0.18.9* - May 2nd, 2018

* The Dark Room will now have 4 Golden Chests instead of 4 Red Chests. Note that the rest of the rooms are still vanilla, as it will take several days to integrate all of the changes. (Thanks Cyber_1)
* Fixed some Devil and Angel rooms incorrectly having vanilla weight values instead of 1.0. (Thanks CrafterLynx)

### *v0.18.8* - May 2nd, 2018

* More Devil Room balance changes:
  * Moved a pedestal from the Red Chest room (#4) to another 1 item room.
  * Moved a pedestal from the the Devil Beggar room (#10) to another 1 item room.
  * Added a Black Rune to a 1 item room (#7).
  * Added a random card to a 1 item room (#15).
  * Added 2x Red Chest to a 1 item room (#16).
* More Angel Room balance changes:
  * Added an extra statue to a 1 item room (#2).
* Devil Room and Angel Room changes are reflected in the spreadsheet: https://docs.google.com/spreadsheets/d/1f47LetK5U9g4uX6UuBPiwciKzFqrTOSwozk0VEC0B4k/edit#gid=1040362406
* Added 3x Red Poops to Devil Room #18 (as a small reference to the Jud6s mod).
* Fixed the bug where diversity races with the Booster Pack #5 trinkets would crash the client. (Thanks Gamonymous)
* Fixed the bug in the client where the Forgotten graphic was not showing up properly.

### *v0.18.5* - May 1st, 2018

* Devil Rooms and Angel Rooms are now rebalanced. See the following spreadsheet for more information: https://docs.google.com/spreadsheets/d/1f47LetK5U9g4uX6UuBPiwciKzFqrTOSwozk0VEC0B4k/edit#gid=1040362406
* Note that the rest of the rooms are still vanilla, as it will take several days to integrate all of the room changes.
* In R+7 S4, on the Kamikaze build, Kamikaze will now start in the first slot instead of the D6. (Thanks thisguyisbarry)
* Fixed the bug where Isaac would start with the Sacrificial Alter instead of the D6 in ranked solo races. Please contact Zamiel if you want a bugged race deleted from the database. (Thanks elgirs)

### *v0.18.4* - April 30th, 2018

* Fixed the bug where diversity races with the new item would crash the client. (Thanks Gamonymous)
* Fixed the bug where the Black Rune was not center-leaning after you picked it up. (Thanks Thoday)

### *v0.18.2* - April 30th, 2018

* You can now choose the new character for races in the client.
* Fixed the bug where the "Change Char Order" custom challenge was not working. (The__J0ker)

### *v0.18.0* - April 30th, 2018

* Racing+ will now work with Booster Pack #5. All of the new items are now included in diversity races.
* Since Booster Pack #5 includes new achievements, all save files will no longer be 100%. The Racing+ client should automatially help you install a new one upon connecting to the server, if you wish. You should know that some of the new content will not work with Racing+ enabled.
* All room changes are reverted to vanilla (for the time being).
* Removed the custom handling for co-op babies (since "stealing" Devil Room items was fixed in the vanilla game).
* Removed the custom handling for Knights, Selfless Knights, Floating Knights, and Bone Knights (since it was fixed in the vanilla game).
* Removed the custom handling for Eden's Soul (since it was fixed in the vanilla game).
* Removed the custom handling for heart drops from bosses (since it was fixed in the vanilla game).
* Removed the custom trinket sprites for the Karma and NO! trinkets (since the sprites were updated in the vanilla game).
* Changed the custom sprite for the Daemon's Tail trinket to have a 1 pixel border instead of a 2 pixel border.
* Removed the custom sprites for the Chaos card, the Huge Growth card, the Ancient Recall card, the Era Walk card, the Credit Card, the Cards Against Humanity Card, the Get Out of Jail Free card, and the Holy Card (since the sprites were updated in the vanilla game).
* The Rules card now uses the old Cards Against Humanity sprite.
* The ? card sprite is updated to the new version from the Unique Card Backs mod by [piber20](https://steamcommunity.com/id/piber20).
* Reverted the new "LightTravel" animation back to the pre-Booster Pack 5 one, since it is unnecessarily slow.

### *v0.17.4* - April 28th, 2018

* The spikes will now despawn in a Sacrifice Room if you enter as a seeded death ghost. (Thanks AshDown)

### *v0.17.3* - April 27th, 2018

* Dying in a Sacrifice Room will no longer trigger the seeded death mechanic. (Thanks AshDown)

### *v0.17.2* - April 25th, 2018

* In R+7 Season 4, the spikes will now always despawn on Basement 1 instead of only despawning if you have Judas' Shadow. (Thanks thisguyisbarry)
* Fixed the bug where the R+7 Season 4 Library code was not working properly.

### *v0.17.1* - April 23rd, 2018

* In R+7 Season 4, going into a Library on Basement 1 will result in bad things happening.
* Fixed the bug where having the client open would prevent setting new custom fast-drop or Schoolbag switch hotkeys.

### *v0.17.0* - April 21st, 2018

* Season 3 is finished!
  * Congratulations to Dea1h for the best time of 1:03:17, ReidMercury for the second best time of 1:04:04, and BMZ_Loop for the third best time of 1:08:11.
  * The top 10 times will be stored in the [Hall of Fame page](https://isaacracing.net/halloffame).
  * If you want to beat these times, the R+7 (S3) category will continue to be tracked on speedrun.com, but the official competition will move on to season 4.
* [Season 4](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/CHANGES-CHALLENGES.md#r7-season-4) has officially begun!
* There is a new death mechanic for seeded races:
  * Upon dying, you will respawn in the previous room with 1.5 soul hearts.
  * You will then have a "debuff" effect that removes all of your items. The debuff will last 45 seconds.
  * This mechanic doesn't apply to deaths from devil deals. (If you die from a devil deal, the normal death screen will appear.)

### *v0.16.33* - April 20th, 2018

* Fixed the bug where duplicate pedestals would appear in Basement 1 on diversity races under certain conditions. (Thanks klover48)

### *v0.16.31* - April 19th, 2018

* Fixed the bug where beggars were not properly being deleted from Curse Rooms in R+7 Season 4. (Thanks Shigan)

### *v0.16.30* - April 17th, 2018

* In R+7 Season 4, the Fire Mind build will now start with Mysterious Liquid instead of The Wafer. It is a lot better now. (Thanks Cyber_1)
* In R+7 Season 4, Basement 1 Curse Rooms and Sacrifice Rooms are now "nerfed" on all characters, not just the first character. (Thanks Dea1h)

### *v0.16.29* - April 16th, 2018

* The Battery will now work properly with The Schoolbag in that it will properly show the orange bar as well as remember the proper charge. This will be most noticable during seeded races that start with the Mega Blast build.
* The run summary will now disappear if you leave the room. (Thanks Cyber_1)
* Deleted Depths/Necropolis/Dank room #639 (a narrow room with Mom's Dead Hand).
* Isaac is now blindfolded in the "Change Char Order" custom challenge.

### *v0.16.28* - April 14th, 2018

* The mod will now show the total number of rooms entered below the seed when a run is completed. (Thanks Ou_J)
* In R+7 Season 4, Chocolate Milk will now also start with Steven.
* In R+7 Season 4, the Fire Mind build will now also start with The Wafer.
* In R+7 Season 4, if you start with Judas' Shadow or The Wafer on the first character and enter a Sacrifice Room on Basement 1, the spikes will despawn. (Thanks Greg and NorBro86)
* In R+7 Season 4, if you enter a Curse Room on the first character, Demon Beggars will now be despawn in addition to pickups. (Thanks Dea1h)

### *v0.16.26* - April 8th, 2018

* In R+7 Season 4, Kamikaze is now properly removed from the pools if you start with the Kamikaze build.
* In R+7 Season 4, Krampus will now always drop Krampus' Head if you start with the Technology build. (Thanks BMZ_Loop)

### *v0.16.24* - April 7th, 2018

* In the "Change Char Order" custom challenge, there are now icons that show what all of the builds are. Thanks to sillypears for this.
* In R+7 Season 4, Lilith is no longer granted an Incubus and is instead granted an extra familiar. Much like her original familiar, the second one is also tied to her character.

### *v0.16.23* - April 7th, 2018

* The rules for R+7 Season 4 are now documented on the website/readme.
* In R+7 Season 4, the Jacob's Ladder start will now also grant There's Options.
* In R+7 Season 4, Lazarus no longer starts with a pill.
* In R+7 Season 4, the "sad" animation that signifies a Curse Room deletion will only play once per run.
* In R+7 Season 4, the "sad" animation that signifies a Curse Room deletion will only play if there are any pickups in the room.
* In R+7 Season 4, the first character will no longer start with More Options.

### *v0.16.22* - April 6th, 2018

* R+7 Season 4 is now released for beta testing. Please provide feedback on what you think should be changed or improved upon.
* Fixed a Technology softlock in Depths room #226.

### *v0.16.18* - April 1st, 2018

* Fixed the bug where multiplayer races would show as unranked in the client. (Thanks thereisnofuture)
* Fixed the bug where the new custom sound effects were playing when they shouldn't. (Thanks caesar)

### *v0.16.17* - March 31st, 2018

* Something special will now happen if you lose to someone by 3 seconds or less.
* Fixed the bug where the starting item would be wrong if you saved and continued. (Thanks AshDown, PassionDrama, and StoneAgeMarcus)
* Fixed the bug where the automatic update feature was not working properly.
* Fixed the bug where Blank Card + Joker would play the vanilla use animation. (Thanks Gamonymous)

### *v0.16.2* - March 30th, 2018

* The client will now work on macOS again. (Thanks glyndsuresight)
* Fixed the bug where Door Stop and Extension Cord were never selected for diversity races.
* In diversity races, Blood Rights is now removed from the Treasure Room pool if you start with Isaac's Heart.
* In diversity races, Isaac's Heart is now removed from the Treasure Room pool if you start with Blood Rights.

### *v0.16.1* - March 28th, 2018

Mod:

* Fixed the bug where controller players could not use the new custom hotkeys. Depending on your controller, you may now be able to directly define hotkeys in the custom challenge without using external software. However, if you have any problems or weird behavior, try binding keyboard hotkeys and then using a program like Joy2Key or DS4Windows. (Thanks AshDown and Lobsterosity)
* Fixed the bug where Dangles spawned from Brownies would be faded. (Thanks Greninja_San)
* Fixed the bug where the Schoolbag was not removed from item pools in the solo ranked unseeded race format. (Thanks BMZ_Loop)
* Fixed the bug where the special characters in the French and Spanish fortunes would not appear. (Thanks AshDown)
* Fixed the bug where two trinkets would appear on the item tracker after using a Gulp! pill.
* Fixed the bug where Karma was not properly removed from the trinket pool. (Thanks Moucheron Quipet)
* Caves/Flooded room #55 is now symmetrical.

Client:

* Fixed the bug where the window could get stuck offscreen under certain conditions. (Thanks KingGed)

### *v0.16.0* - March 18th, 2018

* The Unseeded Ranked Solo Season 1 has concluded. Congratulations to BMZ_Loop on 1st place with an average time of 12:41, CrafterLynx on 2nd place with an average time of 12:51, and Dea1h with 3rd place with an average time of 13:12. Note that these times should be taken with a grain of salt, since the timing of the client was a little wonky until v0.15.0 (February 11th).
* Season 2 has now started! The leaderboard has been completely reset. In Season 2, Judas will now start with the Schoolbag, but the category is otherwise the same.
* You can now use the "Change Keybindings" custom challenge to set a unique key for fast-drop and a Schoolbag-switch.
  * If you do not have a binding set for fast-drop, the fast-drop feature will not function at all.
  * If you do not have a binding set for the Schoolbag-switch, the game will look for the normal "drop" input (like in vanilla).

### *v0.15.6* - March 18th, 2018

* Fixed the "Cannot read property 'replace' of undefined" bug. (Thanks AshDown and Greninja_San)
* Fixed another bug that was causing the client to complain that the mod was corrupt when it really was not. (Thanks Gamonymous and Shigan)

### *v0.15.5* - March 17th, 2018

* Fixed the bug where the client would complain that the mod was corrupt under certain conditions when it really was not. (Thanks Gamonymous)

### *v0.15.4* - March 11th, 2018

* Eden will now be given the Sad Onion if they happen to start with the vanilla Schoolbag as the random passive item.
* 5 Monstros will no longer spawn if you use We Need to Go Deeper! or Ehawaz on Womb 2 during races with a goal of "Everything". (Thanks Gamonymous)
* Fixed the bug where if Eden starts with the Schoolbag, a pedestal will be created on the ground. (Thanks NorBro86)

### *v0.15.3* - February 15th, 2018

* Creep will now instantly fade as soon as the room is cleared. (Thanks thisguyisbarry)

### *v0.15.2* - February 14th, 2018

* If it is not already, the game will now automatically be focused during the countdown at 1 second left. (Thanks The_Moep)
* Fixed the bug where the starting item was not being reported correctly. (Thanks PassionDrama and meepmeep13)
* Fixed the bug where killing a Heart of Infamy caused the Mask of Infamy to fade. (Thanks Blumpkin Idaho and BMZ_Loop)
* Changed the ordering of the starting room graphic. (Thanks 910dan)

### *v0.15.1* - February 13th, 2018

* All bosses are now faded upon playing their death animation. (This is more consistent than the previous implementation.)
* The Racing+ timing system now uses in-game time. (Server time, client time, and time offsets are no longer used.) This should fix the bug where the time reported by the client was different than the one reported by the mod.

### *v0.15.0* - February 11th, 2018

* The website now has a "Tournaments" section, where you can see the currently scheduled matches for the week in the current Binding of Isaac: Afterbirth+ league, [Isaacs of the Round](http://isaacsoftheround.weebly.com/). In the future, it will show past tournaments. Thanks to sillypears for coding this.
* Sometimes, a dying boss will cover up an item pedestal, forcing the player to wait until the death animation is over to see what the item is. Any bosses that have the possibility to interfere with seeing what an item pedestal in this way are now faded during their death animation.
* Fixed the Mimic exception code, as it wasn't working on the latest patch. (Mimics should not be able to spawn in certain rooms with narrow paths, as it causes unavoidable damage.)
* Added Caves room #125 to the Mimic exemption list.
* Added flipped rooms to the Mimic exemption code.
* Fixed the bug where Blisters were not killed properly after defeating Mom.
* Added some more French translations. (Thanks Greninja_San)

### *v0.14.27* - December 29th, 2017

* The mod will now work with the True Co-op Mod. (Thanks BMZ_Loop)

### *v0.14.26* - December 27th, 2017

* Isaac is now feeling festive. Happy New Years! (Thanks to Gromfalloon for this)
* Now that the Rage Creep bug has been fixed in the vanilla game, the pot has been restored to Womb/Utero/Scarred room #202.
* Fixed a (vanilla) softlock in Womb room #847 by removing the red poop.
* Fixed the bug where the client would fail to heal a corrupt mod on macOS. (Thanks liam13661)

### *v0.14.25* - December 19th, 2017

* You will now always get a Treasure Room with two items on the first floor of the first character of a multi-character speedrun custom challenge. (Thanks Cyber_1)
* Fixed the bug where the client would crash on macOS when repairing a corrupted mod. (Thanks TrumpetZorua)

### *v0.14.23* - December 17th, 2017

* Fixed the bug where you would get extra bombs, keys, and pickups when the new death mechanic ended. (Thanks BMZ_Loop)
* Fixed the bug where the trophy would spawn on the 7th character during a season 1 custom challenge. (Thanks Cyber_1)

### *v0.14.22* - December 17th, 2017

* Isaac is now feeling festive. Merry Christmas!
* The website is currently being rewritten to support the new leaderboards. Currently, it is broken, but eventually there will be 6 different leaderboards.
* The new death mechanic has been implemented for seeded races, but only if you have "RPGlobals.debug = true" in the "src/RPGlobals.lua" file. Feel free to test it and provide feedback before it is implemented by default.
* Fixed the bug where the "Items" column in the client would show a number instead of the starting item.
* Fixed the bug where having the client open would mess up the "Change Char Order" custom challenge. (Thanks molfried)
* Fixed the bug where the client would close your game in the middle of a run on potato computers. (Thanks Krakenos)
* Fixed the bug where the client would fail to fix a corrupted mod when the directory did not exist. (Thanks Astraii)
* Fixed the bug where the ranked/unranked icon would show up in the lobby for multiplayer races.
* Fixed the bug on the french version of the client where "En Course" would wrap to a second line.

### *v0.14.21* - December 16th, 2017

* You can now perform a Schoolbag switch during an item pickup animation, as long as the item that you are holding above your head is not an active item.
* Fixed the bug where you could go the wrong way and still complete a multi-character speedrun custom challenge.
* Fixed the bug where the automatic update was not working properly. You may need to manually download and install this version.

### *v0.14.14* - December 14th, 2017

* The macOS version should actually work now.
* All multiplayer races (past and present) are now considered ranked for the purposes of calculating a leaderboard. There are now 3 multiplayer leaderboards for seeded, unseeded, and diversity. (Thanks SlashSP)
* The mod will now automatically detect and kill and Flaming Hoppers that are softlocking the game. (Thanks SlashSP)
* Fixed the bug where the diversity leaderboard was not displaying the correct TrueSkill values. The rankings now take into account the Mu and Sigma values correctly, meaning that players who have only played a small number of races will no longer be as high on the leaderboard as they were before. (Thanks Krakenos)
* Fixed the bug where Jr. Fetus could spawn a bunch of extra bombs under certain conditions. (Thanks CrafterLynx)
* Fixed the bug where Teratoma and Fistula were not properly killed after It Lives! (Thanks Dea1h)
* Fixed the bug where the trapdoor would not appear in the Womb 2 I AM ERROR room under certain conditions. (Thanks SapphireHX and BMZ_Loop)

### *v0.14.11* - December 5th, 2017

* Fixed the bug where a bunch of numbers would show as the status for a race in the lobby under certain conditions. (Thanks PassionDrama)

### *v0.14.9* - December 3rd, 2017

* The client should now work on macOS.
* Using the "~" button to open the console will no longer work when you are currently in a race.

### *v0.14.8* - November 28th, 2017

* The Checkpoint item will no longer have any pedestal delay.
* Fixed the bug where the run timer would be misaligned if you did not have the Schoolbag.

### *v0.14.7* - November 24th, 2017

* Adjusted Big Horn's "BigHoleOpen" animation length from 24 frames to 32 frames. (Thanks Krakenos)
* Fixed the bug where having Dead Cat and Greed's Gullet on Keeper would result in an incorrect amount of coin containers under certain conditions. (Thanks NorBro86)

### *v0.14.6* - November 21st, 2017

Mod:

* Certain parts of the Big Horn fight have been sped up in order to remove pointless downtime where there are no entities are on the screen.
* Mahalath will no longer play a death animation (as it was not affected by fast-clear). (Thanks Dea1h)
* Fixed the bug where the Schoolbag was not being properly removed from pools. (Thanks Krakenos)

Client:

* Removed the setting in the options to enable boss cutscenes.

Website (coded by sillypears):

* Player's profiles now show more information.

### *v0.14.0* - November 18th, 2017

News:

* Isaac is now feeling festive. Happy Thanksgiving! (Thanks to Gromfalloon for this)
* Season 2 is finished!
  * Congratulations to Dea1h for the best time of 1:01:13, Shigan for the second best time of 1:07:13, and ceehe for the third best time of 1:09:18.
  * The top 10 times will be stored in a hall of fame page on the website in the future.
  * If you want to beat these times, the R+7 (S2) category will continue to be tracked on speedrun.com, but the official competition will move on to season 3.
  * If you tried out Season 2 and did not like it, Samael is being heavily buffed in this patch with the goal of making him more fun to play (see below).
* Season 3 has officially begun!
* Thanks goes to [DeadInfinity / Meowlala](http://steamcommunity.com/profiles/76561198172774482/myworkshopfiles/?appid=250900), who created the [Jr. Fetus](http://steamcommunity.com/sharedfiles/filedetails/?id=1145038762) boss, who is featured in season 3 at the end of Cathedral / Sheol.
* Thanks goes to [melon goodposter](http://steamcommunity.com/id/pleasebecareful), who created the [Mahalath](http://steamcommunity.com/sharedfiles/filedetails/?id=1145038762) boss, who is featured in season 3 at the end of The Chest / Dark Room.
* If you have ideas for season 4, send them to me on Discord, which is planned for May 2018.
* Thanks goes to Krakenos for taking some screenshots that showcase Racing+ on the [Steam Workshop page](http://steamcommunity.com/sharedfiles/filedetails/?id=857628390).

Mod changes:

* You can now hold down tab (map) to see the time spent on the current run. (Thanks Ou_J)
* Samael's starting speed has been increased from 0.85 to 1.15.
* Samael's starting health has been changed to 1 red heart, 1 soul heart, and 1 black heart.
* The Haunt's "Peel" and "AngrySkin" animations are now sped up.
* Fixed the bug where We Need to Go Deeper! would not work on Womb 2 in the season 3 custom challenge. (Thanks sillypears)
* Fixed the bug where on the season 3 custom challenge, certain entities would occasionally despawn (trapdoors, devil statues, angel statues, and Epic Fetus targets). DeadInfinity / Meowlala deserves credit for finding and fixing this bug in the base Mahalath mod. (Thanks to Moucheron Quipet, Gamonymous, Dea1h, and Krakenos for reporting.)
* Fixed the bug where you could take the wrong path on the season 3 custom challenge and still progress to the next character.
* Fixed the bug where dying with Guppy's Collar in custom challenges would send you back to the first character. (Thanks Gamonymous)
* Fixed the bug where the place graphic next to the R+ icon would overlap with the character progress graphic in races. (Thanks molfried)
* Fixed the bug where the I AM ERROR room on Womb 2 would always give you the "correct" direction during a custom challenge. (Thanks ceehe)

Client/server changes:

* It is now impossible to get Abaddon when playing a diversity race as Keeper. (Thanks leo_ze_tron)
* Removed the "Ongoing" label from races in the lobby. (Thanks Cyber_1)
* Added some random buttons to the new race tooltip. (Thanks HauntedQuest)
* Added a new icon for seeded hard mode races.
* Fixed the bug where the icon would not show for seeded hard mode races.

### *v0.13.8* - November 13th, 2017

Mod:

* Fixed the bug where Krampus items and key pieces could potentially spawn on top of grid entities. (Thanks Dea1h)

Client:

* If the ready button is greyed out, the tooltip will now always appear.
* The new race tooltip has been slightly reorganized; there are now radio buttons to represent size and ranked.
* The lobby has been slightly reorganized; there are now 3 icons to represent size, ranked, and format. A tooltip will show everything about the race.
* You can now see how much time has passed in a race from the lobby.

### *v0.13.7* - November 10th, 2017

* Fixed the bug where the place graphic would overlap with the R+ graphic in hard mode.
* Fixed the bug where no hearts would spawn from bosses appear on hard mode.
* Fixed the bug where Chubber Projectiles (what Fistuloids spawn on death) prevented fast-clear from functioning.
* Fixed the bug where the Mom teleport subversion wasn't working properly if you entered from certain 2x2 or L rooms.

### *v0.13.6* - November 9th, 2017

* Added the "Seeded (Hard)" ruleset to the client to faciliate the Lynx Trials tournament. This will only exist for the duration of the tournament.
* Fixed the bug where angel statues would drop a key piece even if another angel was still alive. (Thanks StoneAgeMarcus)

### *v0.13.5* - November 5th, 2017

* Maggy now starts with her speed-up pill in the season 3 custom challenge. (Thanks Cyber_1)
* Fixed the bug where an Attack Fly would spawn every time you re-entered a room with a trapdoor or crawlspace that happened to originally be on top of a Corny Poop. (Thanks Nanahachiyasu)

### *v0.13.2* - November 4th, 2017

* If you live in China, the client will now automatically use a proxy in Singapore to access the racing server.
* You can no longer enter a trapdoor or crawlspace when the jump animation is playing. (Thanks NorBro86)
* Fixed the bug where the Mom teleportation subversion did not work or teleported you to the wrong spot. (Thanks 910dan)

### *v0.13.1* - November 4th, 2017

* Fixed the bug where Jr. Fetus and Mahalath would spawn if you re-entered a cleared room. (Thanks Dea1h and thereisnofuture)

### *v0.13.0* - November 3rd, 2017

News:

* Lobsterosity has officially joined the staff, charged with Community Relations.

Mod:

* The "R+7 (Season 3)" custom challenge is now available for beta testing. All of the changes are documented on the website. It will be in beta testing for 2 weeks. Note that if anything changes during the beta, any runs you submit to the leaderboards will become invalid. Season 2 will also end in 2 weeks.
* Samson no longer starts with the Child's Heart. (This is a quality of life change, since the "correct" strategy is to instantly drop it.)
* Mom will no longer subversively teleport you.
* Fixed the bug where Filigree Feather would cause Angels to drop an extra key piece. (Thanks HauntedQuest)
* Fixed the bug where Eden could start with both the vanilla Schoolbag and the Racing+ Schoolbag. (Thanks ceehe)
* Fixed the bug where Peep Eyes and Bloat Eyes would prevent fast-clear from working properly in certain situations.

Client:

* Fixed the bug where it would complain about the Windows registry on macOS and Linux. (Thanks kwidz)

Website:

* On your profile page, you can now see the last 50 ranked unseeded races. This allows you to determine which races will next be cut off.
* There is now a diversity leaderboard, based on TrueSkill. (Solo diversity races will not affect your ranking.)
* You now need at least 20 races to appear on the unseeded leaderboard.
* The columns on the leaderboard are now sortable if you click on them. (Thanks SlashSP)
* On the leaderboards, next to the verified checkmark or X, there is now a link to the racer's Twitch stream.
* The races page now shows the starting item.

All website work was performed by sillypears, so thanks goes to him.

### *v0.12.9* - October 27th, 2017

* Isaac is now feeling festive. Happy Halloween! (Thanks to Gromfalloon for this)
* Custom races now have a time limit of 4 hours. (Normal races still have a 30 minute time limit.) (Thanks Molfried)
* You can now easily do DPS tests by entering a "spawn test" at the Isaac console, which will spawn a Nerve Ending with 1000 HP. (Thanks Krakenos)
* Fixed the bug where the vanilla Schoolbag was not being removed during seeded races. (Thanks thisguyisbarry)
* Fixed the bug where Apollyon was not starting with Void inside the Schoolbag during seeded races. (Thanks 910dan)

### *v0.12.8* - October 19th, 2017

Mod:

* Fixed the bug where key pieces would drop from angels on the Mega Satan fight, Boss Rush, and The Chest. Note that key pieces are intended to drop from super secret rooms, as that is a new feature of the vanilla game. (Thanks Cyber_1)
* Fixed the bug where the D6 would have infinite charges if you had Car Battery. (Thanks At3ch)
* Fixed the bug where The Book of Sin did not have an animation. (Thanks thereisnofuture)
* Fixed the bug where the player was able to enter a trapdoor or crawlspace while performing the Happy animation. (Thanks Krakenos)
* Fixed the bug where the player was able to enter a crawlspace while in a item pickup animation. (Thanks Krakenos)

Client:

* Fixed the bug where the client would not communicate to the mod under certain conditions. (Thanks Lobsterosity, Shigan, and Nanahachiyasu)
* Fixed the bug where the Technology Zero build was not being included in the "Random (all)" build selection. (Thanks Shigan)

Website:

* You now need at least 5 races played to show up on leaderboards.
* The leaderboards will now link to the profile pages of the racers. (Thanks SlashSP)
* Fixed the bug where some player profiles were not working. (Thanks Lobsterosity)
* Fixed the bug where the races listing would show blank pages. (Thanks Lobsterosity)

Item tracker:

* Fixed the bug where the Schoolbag would show as a "?" on the item tracker.

### *v0.12.7* - October 17th, 2017

* The [unseeded leaderboards](https://isaacracing.net/leaderboards) have been officially released.
* The vanilla Schoolbag will not work properly with fast-clear, so it has been replaced with the Racing+ version.
* Fixed the bug where the angel key pieces were not being spawned at the correct time.
* Fixed the bug where the D6, D100, Diplopia, Void, Crooked Penny, D Infinity, and Moving Box would have buggy behavior if they were used on the same frame as a pedestal item spawned. (Thanks thereisnofuture)

### *v0.12.6* - October 16th, 2017

* The list of races on the website will now only show multiplayer races. (Thanks thisguyisbarry)
* Fixed the bug where The Book of Sin and Smelter were mistakenly removed from all pools on all runs. (Thanks 910dan)
* Fixed the bug where Keeper did not start with the intended items on the R+14 custom challenge. (Thanks ceehe)
* Fixed the bug where trying to create a ranked race would result in an unranked race being created.
* Fixed the bug that prevented you from clicking ready under certain circumstances. (Thanks Shigan and Ivana)

### *v0.12.5* - October 15th, 2017

* The LiveSplit AutoSplitter should now work with the latest patch. (Thanks blcd, Sillypears, NorBro86, and Hyphenated)
* Fixed the bug where the mod would not work on the first race if you used save slot 2 or save slot 3. (Thanks 910dan)
* Fixed the bug where the tenths digit of the timer was inaccurate under certain conditions. (Thanks TheMoonSage and PassionDrama)
* Fixed the bug where you could not do R+9 / R+14 / R+7 races using the client. (Thanks Yama)

### *v0.12.3* - October 15th, 2017

* Fixed the Schoolbag not working.
* Fixed the vanilla bug where a Flooded Caves room with a Slot Machine (#976) was incorrectly given 1000 weight. (Thanks Lobsterosity)

### *v0.12.2* - October 14th, 2017

* The Booster Pack #4 rooms have now been integrated into Racing+ (and flipped).
* The Booster Pack #4 items will now be included in diversity races.
* The vanilla Schoolbag will now be removed from all pools when you have the Racing+ version of the Schoolbag. Until The Battery synergy is fixed in vanilla, it is better to use the Racing+ version.
* Fixed the bug where you could not play hard mode runs in races with a custom format. (Thanks CrafterLynx)
* Fixed the bug where extra enemies were not being killed upon killing Mom, Mom's Heart, or It Lives! (Thanks ReidMercury and NorBro86)
* Fixed the bug where the Gurdy teleport was not being subverted in three flipped rooms in The Chest. (Thanks Cyber_1)
* Fixed the bug where you would prematurely finish a race if your internet disconnected and you reconnected under certain conditions. (Thanks Molfried)

### *v0.12.0* - October 10th, 2017

* Racing+ will now work with the latest patch (Booster Pack #4). The new Booster Pack rooms are not yet integrated. Diversity races won't have the new items yet.
* The mod no longer fixes the champion Scolex, since the bug was fixed in the vanilla game.
* The mod no longer has a custom Broken Modem sprite, since they added a good one to the vanilla game.
* Fixed the bug where holding R to go back to the first character on a custom speedun challenge would not reset LiveSplit.
* You will now get a warning if you try to perform an inproperly formatted command on the client.
* The valid client commands are now listed on the website.

### *v0.11.11* - October 1st, 2017

* Fixed the bug where the doors would open prematurely with Rag Man's Raglings under certain conditions. (Thanks thereisnofuture and FezzesOrBowties)
* Fixed the bug where the client told you that the mod was corrupt under certain conditions. (Thanks thereisnofuture)

### *v0.11.10* - September 30th, 2017

* Integrated the [Trinket Outlines](http://steamcommunity.com/sharedfiles/filedetails/?id=1138554495) mod by [O_o](http://steamcommunity.com/profiles/76561197993627005/myworkshopfiles/?appid=250900) into Racing+, which is a sprite improvement mod.
* Fixed the bug where the Lil' Haunt delay reduction wouldn't work if there was more than one Haunt in the room. (Thanks Gamonymous and NorBro86)
* Fixed the bug where the game would lock up if you joined a race while in a custom challenge. (Thanks Thoday)
* Fixed the bug where the game would softlock if you had Mom's Knife and died on Samael and respawned as another character. (Thanks Zazima)

### *v0.11.9* - September 27th, 2017

* The annoying vanilla in-game timer and score text will no longer appear.
* Fixed the (vanilla) unavoidable damage in Caves/Catacombs room with 2 Mushrooms and 8 Maggots. (Thanks Dea1h and NorBro86)
* Fixed the bug on "Everything" races where a trapdoor would appear about It Lives! under certain conditions. (Thanks Moucheron Quipet)
* Fixed the bug on "Everything" races where the trophy would spawn prematurely on The Chest if you exited and entered the boss room. (Thanks gorthol and Molfried)

### *v0.11.6* - September 24th, 2017

Gameplay:

* Fixed the bug where the Gulp! pill wouldn't do anything. (Thanks thereisnofuture)
* Fixed the bug where races to The Lamb wouldn't work properly. (Thanks Gamonymous)

Client:

* The client now uses a much faster auto update system; instead of having to download everything, you will only have to download the changed files.
* Fixed the bug where the client would think your mod was corrupted if it was disabled. (Thanks thereisnofuture)
* Fixed the bug where the client would restart the run if your internet died in the middle of a race.

### *v0.11.4* - September 23rd, 2017

Gameplay:

* Samael's scythe charge will now be deleted instead of automatically released if you pick up an item. This should help prevent damaging yourself with Ipecac. (Thanks missingyes)
* Fixed the bug where Samael would lose the Dead Eye multiplier if you hit a tear shoot button in between swings. (Thanks Krakenos)
* Fixed the bug where Sacks spawned from killed Blisters would stay alive after killing Mom under certain conditions. (Thanks Krakenos)

Client:

* The client will now check to see if you have a fully unlocked save file upon logging in. If none is found, it will ask you if you want it to automatically install one for you. This save file is actually fully unlocked in the sense that it has every completion mark on the post-it notes, 999 coins in the donation machine, 9,999,999 Eden tokens, and every easter egg unlocked.
* The client will now show you a message if it is restarting your Isaac for you. (It won't do this unless it detects a corrupted mod.)
* The client will no longer let you ready up if you are playing a non-custom race without the Racing+ mod enabled.
* Previously in v.10.0, the automatic corrupted mod repair was disabled. This is now re-enabled and more robust in that it will check for extraneous files in your mod directory.

### *v0.11.2* - September 20th, 2017

* Fixed the bug where Lil' Haunt delay canceling wouldn't work under certain conditions. (Thanks Gamonymous)
* Fixed the bug where non-boss Lil' Haunts had boss health bars. (Thanks Krakenos)
* Fixed the bug where fast-clear would not work properly with Stoneys that morph from Fatties.
* Fixed the (vanilla) bug where Globins are not properly killed after defeating Mom, Mom's Heart, or It Lives! (Thanks Gamonymous)
* Added the TehePelo emote. (Requested by Lobsterosity)

### *v0.11.0* - September 16th, 2017

* Integrated the [Unique Card Backs](https://steamcommunity.com/sharedfiles/filedetails/?id=1120999933) mod by [piber20](https://steamcommunity.com/id/piber20) into Racing+, which is a quality of life / sprite improvement mod.
* Since the game's mod support is very buggy, Racing+ has always had an issue where when you enable Racing+ for the first time from the mod menu and then immediately go into a game, certain things will not be initialized properly. (For example, boss cutscenes will play during this state.) Racing+ will now detect this corrupted state and show an error message advising you to close and reopen the game.
* There will no longer be a delay before The Haunt sends out his first Lil' Haunt to attack you.
* The spawning of Key Piece 1 and Key Piece 2 are now sped up in the same way that Krampus items are.
* Fixed the bug where both photos would spawn on the season 1 speedrun challenges if you had Mysterious Paper.
* Fixed the bug where the wrong direction would appear after It Lives! or Hush if you had Mysterious Paper under certain conditions.
* Fixed the bug where the Sloth, Super Sloth, Pride, and Super Pride card seeding wasn't being applied to flipped rooms.

### *v0.10.7* - September 14th, 2017

* Fixed the bug where the client would not remember that you selected a random character. (Thanks Shigan)
* Fixed the bug where the mod was inproperly deleting A Lump of Coal from Mystery Gift. (Thanks Thalen22)

### *v0.10.3* - September 13th, 2017

* Fixed the bug where Krampus' Head would get deleted under certain conditions. (Thanks leo_ze_tron)
* Fixed the bug where the new race tooltip would not show some sections on startup under certain conditions. (Thanks Shigan and Blumpkin Idaho)
* Fixed the bug where you could fight Mega Satan twice if you teleported out of the fight after killing him. (Thanks Gamonymous)

### *v0.10.0* - September 10th, 2017

Gameplay:

* Shops are no longer flipped.
* The Y-flipped double Gate rooms and double Mega Maw rooms have been unflipped due to how the patterns from their respective champion versions are much harder to dodge from behind. (Thanks Shigan)
* Krampus' item will now spawn at the beginning of the death animation rather than midway through. This prevents the Krampus item getting deleted if you accidently leave the Devil Room as soon as the doors open. Furthermore, this means that it is now possible to do the "Anti Quick Roll" strategy in Racing+, where you can roll the item before the room is cleared to get an extra charge on the D6. (Note that unlike before, this is now a frame perfect trick.) (Thanks Thoday)
* Unfair Dople / Evil Twin tears that fire on the first frame were previously "fixed" by adjusting the Dople / Evil Twin placement in the room. However, this method did not reliably stop Evil Twin triple shots from hitting the player, so Dople / Evil Twin placement has been reverted to vanilla in all rooms and new Lua code will automatically delete any projectiles fired on the first frame.
* If you enter the Mega Satan room without defeating the Lamb first on the "Everything" race goal, something very bad will happen. (Thanks Shigan and BMZ_Loop)
* You can no longer use the Glowing Hour Glass in the pre-race room. (Thanks Gamonymous)
* If you have the Mysterious Paper trinket, you will now always have a choice between the two photos after defeating Mom. (It is impossible to tell if the player has the real Polaroid or Negative when this trinket is equipped.) (Thanks Molfried and Smoom)
* Fixed the bug where friendly enemies would prevent fast-clear from functioning. (Thanks thereisnofuture)
* Fixed the bug where The Compass was not being removed from all pools in seeded races.
* Fixed the bug where Rag Man Raglings would not work with fast-clear under certain conditions. (Thanks 910dan)
* Fixed the bug where the spike deleting code for the Depths/Necropolis bomb puzzle room was not being applied to the flipped versions of those rooms. (Thanks SlashSP)
* Fixed the bug where you could hear the beginning of the recharge sound every time you reset on Eden.
* Fixed the bug where the number of people ready was not properly updated in the pre-race room if someone left the race. (Thanks Nariom)

Client/Server:

* The server once again shows the [race listing](https://isaacracing.net/races). The page has been updated and looks much better than before. Sillypears programmed this, so a big thanks goes to him.
* The server once again shows [player profiles](https://isaacracing.net/profiles). This was also programmed by Sillypears.
* The server now requires that you have the latest version of the client before letting you connect.
* The client will now automatically logout if you logout of Steam in order to curb unscrupulous behavior.
* The client no longer checks to see if you have the Racing+ mod installed when you launch it. (Thanks Hyphen-ated)
* When creating a new race, the client now remembers all of the values that you entered in the last time the client was open. (Thanks Hyphen-ated)
* The client will now perform a more robust check to see if your mod is corrupted. If it detects your mod is corrupted, it will restart your game.
* Fixed the bug where the Chinese racer named "box" would mess up the lobby users list. (It wasn't his fault.)
* Fixed the bug where selecting a random character in the new race tooltip would not include Samael. (Thanks Shigan)
* Removed the "Ctrl+C" and "Ctrl+V" hotkeys since they are not needed anymore.
* Removed the double negative in the "Enable boss cutscenes" checkbox. (Thanks tyrannasauruslex)
* The client will now automatically remove all trailing slashes in your Twitch URL. (Thanks Thoday)
* The server now keeps track of when you enter all rooms and when you pick up all items.
* The server now keeps track of what item you started (in non-seeded races).

### *v0.9.5* - August 14th, 2017

* Mid-race placements will now work in races with over 10 people in them. (This was previously disabled to stop the server from crashing.)
* Fixed some placements of Mega Maws and Gates in flipped rooms on The Chest and The Dark Room. (Thanks Thalen22 and thereisnofuture)
* Fixed some miscellaneous bugs with the server. (Thanks PassionDrama and Molfried)

### *v0.9.0* - August 13th, 2017

* The server has been rewritten mostly from scratch in an attempt to fix the deadlocking issue that was causing it to crash every once in a while. This process took around 60 hours over the past week, with around 7500 new lines of code.
  * The new server should be an order of magnitude faster and will be able to support race ghosts in the same vein that Mario Kart has.
  * The [SQLite](https://www.sqlite.org/about.html) database was replaced with [MariaDB](https://mariadb.org/about/). This was the thing holding leaderboards back. Now it should be pretty easy to make them.
  * The Golem WebSocket framework was replaced with the Melody WebSocket framework. Golem's handling of WebSockets was causing the deadlock during times of mass sending.
* Are you ready to get flipped? In order to promote run diveristy, all rooms now have the possibility to be flipped on the X axis, the Y axis, or both axises.
  * This is probably something that should have been in the original game, but I can only guess that no-one thought of it (or Nicalis was too lazy).
  * This will only be noticable in non-symmetrical rooms.
  * All room shapes are preserved with the exception of L rooms, which are flipped accordingly.
  * Since the probabilities of getting each individual room are the same (discounting entrances), there are no general strategical implications of this change.
    * One small exception is that instead of there being only 3 types of top-left L-rooms in The Chest, there are now 12.
    * Another small exception is that the trapdoor room on the Caves/Catacombs/Depths/Necropolis is flipped, so you can get it from the bottom now instead of only from the top.
  * An enormous thanks goes to Chronometrics for this, as he designed the custom code that allowed this to be programatically done.
* The server will no longer send messages to your Twitch chat if your client is closed.
* In the client, the "Custom" character is now replaced with "Samael" and shows a graphic for him.
* Fixed the bug where mid-race placements were messed up on non-seeded races. (Thanks Shigan and BMZ_Loop)

### *v0.8.20* - August 3rd, 2017

* Fixed the bug where the Booster Pack #3 items were not in any item pools. (Thanks Flaw98)

### *v0.8.15* - August 3rd, 2017

* The client installer will now work on 32-bit systems. (Thanks missingyes)
* Fixed the bug where you could take both The Polaroid and The Negative if both spawned. (Thanks Krakenos and CrafterLynx)

### *v0.8.14* - August 3rd, 2017

* The seed will now be shown in the upper-left hand corner of the screen after finishing a race or finishing a run on a multi-character speedrun custom challenge. Now, players do not have to use Hyphen-ated's item tracker (or manually pause the game) in order to have their runs be legal on Speedrun.com. (Thanks Krakenos)
* The "Unseeded (Beginner)" format is renamed to "Unseeded (Lite)". (Thanks SlashSP)
* Isaac now starts with 1.6 speed (instead of 1.0 speed) in the "Change Char Order" custom challenge. This should making choosing your order a little less cumbersome. (Thanks Thoday)
* If you start with The Polaroid or The Negative in a diversity race, the opposite photo will now spawn after defeating Mom. If you start with both The Polaroid and The Negative, a random boss item will spawn. (Thanks tODDlife, Krakenos, and BMZ_Loop)
* Fixed the bug where the bomb puzzle room in Dank Depths would have invisible collision on squares where spikes were removed. Spikes will still be removed, but now they won't be replaced with rocks. (Thanks Karolmo)
* Fixed the bug where fast-clear would not work if a black worm was spawned from the My Shadow item. (Thanks BMZ_Loop)
* Fixed the bug where big 4 items could fart-reroll into other big 4 items in the "Unseeded (Lite)" format. (Thanks leo_ze_tron)
* Fixed the bug where fast-clear would not work with Hosts that were spawned as a Mushroom replacement. (Thanks Chronometrics)
* Fixed the bug where fast-clear would not work with Rag Man's Raglings. (Thanks BMZ_Loop)
* Fixed the bug where you could sometimes see The Polaroid or The Negative for a frame before it was moved or deleted.
* Fixed the bug where you could sometimes see the trapdoor on Womb 2 for a frame before it was moved or deleted. (Thanks BMZ_Loop)
* Fixed the bug where the trapdoor would spawn closed after Isaac and Blue Baby in the "Everything" race goal. (It will now spawn open like it does after Satan.)
* Fixed the bug where the beam of light that spawns after It Lives! would take a while to activate when reloading the room.

### *v0.8.13* - July 31st, 2017

* For the "Mega Satan" and "Everything" race goals, going into the Mega Satan room will count as a new floor for the purposes of updating the mid-race place indicator. (It will show as "MS" as your floor inside the client.)
* Fixed the bug where fast-clear would not work with Samael when his special animations were playing. (Thanks Noowoo)
* Fixed the bug where you could use a Sacrifice Room to cheat on the "Everything" race goal. (Thanks thereisnofuture)
* Fixed the bug where the mid-race places were not calculated properly on the later floors of the "Everything" race goal (for real this time). (Thanks Krakenos)
* Fixed the bug where you could ready up while in a hard mode or greed mode run.

### *v0.8.12* - July 30th, 2017

* Fixed the bug where fast-clear was not working with Begottens.

### *v0.8.11* - July 29th, 2017

* Fixed the bug where fast-clear was not working with Satan (for real this time.) (Thanks NorBro86)

### *v0.8.10* - July 29th, 2017

* The LiveSplit autosplitter should now work again. (Thanks NorBro86, Sillypears and Hyphen-ated)
* Fixed the bug where the client was crashing. (Thanks DiaTech, rerol, Shigan, and Drunkenshoe)
* Fixed the bug where fast-clear was not working as Samael. (Thanks NorBro86 and thereisnofuture)

### *v0.8.8* - July 29th, 2017

* Fixed the bug where fast-clear was not working properly with Peep, Bloat, Death, Mama Gurdy, Big Horn, Daddy Long Legs, Triachnid, and Portals.

### *v0.8.6* - July 29th, 2017

* It is no longer possible to skip Cathedral using Undefined on the "Everything" race goal. (Thanks antizoubilamakA)
* Fixed the bug where the doors would prematurely open in puzzle rooms under certain conditions. (Thanks SlashSP)
* Fixed the bug where charmed enemies were stopping fast-clear from happening. (Thanks tODDlife)
* Fixed the bug where fast-clear was not working with Satan.
* Fixed the bug where Frail was making the doors open early. (Thanks tODDlife)
* Fixed the bug where a pickup on top of a trapdoor would play a spawning animation instead of just being moved. (Thanks tODDlife)
* Fixed the bug where the mid-race places were not calculated properly on the later floors of the "Everything" race goal. (Thanks antizoubilamakA)

### *v0.8.5* - July 29th, 2017

* When there is more than one Sloth, Super Sloth, Pride, or Super Pride in a room, they should now always drop the same card no matter which order you kill them in. (Thanks Krakenos)
* The "Victory Lap" text will now appear on the top-left hand corner of the screen instead of the top-right. This should make it display more consistently across different resolutions.
* Fixed the bug where the doors would not stay closed after bombing an angel (again). (Thanks SlashSP)
* Fixed the bug where it was possible to play a race on the wrong character. (Racing+ will always automatically change your character to the correct character for the race.) (Thanks Darkwolf)

### *v0.8.4* - July 28th, 2017

* The "fast-clear" feature was not working properly in the last patch, but it should be better now. (Thanks CrafterLynx, Cyber_1, BMZ_Loop, and 910Dan)

### *v0.8.3* - July 28th, 2017

* Fixed the bug in the "Everything" race goal where Sheol and the Dark Room had the same layouts as Cathedral and The Chest.

### *v0.8.0* - July 27th, 2017

* Added a new seeded build: Technology Zero + Pop! + Cupid's Arrow
* Added a new race goal of "Everything", which takes you on an epic journey to kill Blue Baby, The Lamb, and Mega Satan. (This is the mode that will be used for the Papaya Party tournament.)
* The Lamb can no longer move while he is doing a brimstone attack. (This can cause unavoidable damage in certain situations.) (Thanks ceehe)
* Fixed the (vanilla) unavoidable damage on the Dank Depths bomb puzzle room where a spike could sometimes overwrite a rock. (Thanks Nariom)
* Fast-clear will now work properly with Dark Red champions.
* Added functionality to hide the in-game timer. Just add "timer":false to your "save#.dat" file. (Thanks Gustavo Hernandez Pachito)
* Fixed the bug where sometimes pickups spawn on (or get pushed on to) trapdoors.

### *v0.7.14* - July 12th, 2017

* Fixed the bug where diversity races would crash when starting with certain trinkets. (Thanks BMZ_Loop)
* Fixed the bug where using Clicker on Samael would cause the scythe to float in the air.

### *v0.7.13* - July 7th, 2017

* Reduced the damage penalty on Samael for Mom's Knife from 1.5 to 1.25.
* Fixed the bug where the black champion Widow would open the doors prematurely under certain circumstances.
* Fixed the bug where pickups could sometimes spawn on top of trapdoors and crawlspaces. (Thanks Cyber_1)
* Fixed the bug where killing a Dukie would open the doors prematurely under certain conditions. (Thanks NorBro86)
* Fixed the bug where if Eden started with Eden's Soul, it would incorrectly show as fully charged inside of the Schoolbag. (Thanks Birdie0)
* Fixed the bug where the game softlocks if you enter a crawlspace inside of an Angel Room. (Thanks TheMoonSage)
* Fixed the bug where the races with the "Unseeded (Beginner)" format would not show up correctly in the lobby.

### *v0.7.12* - July 5th, 2017

* Added a new race format called "Unseeded (Beginner)". This is similar to the Racing+ Light mod. More details can be found on the website.
* Removed the knife accuracy feature, since it was not displaying properly on for some people; there seems to be no way to display text in a standardized location.
* Fixed the bug where you could faintly hear the recharge sound when resetting as Keeper and Eve.
* Fixed the bug where killing Dark Red champions, Rag Man's Head, the green champion Hollow, the black champion Hollow would open the doors prematurely if you killed them last. (Thanks BMZ_Loop)

### *v0.7.10* - July 3rd, 2017

* When you have the Schoolbag but no 2nd active item, there will now be a faded placeholder graphic of a Schoolbag to indicate this. (Thanks thisguyisbarry)
* Mid-race floor updates are turned off for races over 10 people in order to prevent server crashes. This means that you won't know what place you are in until you actually finish the race. Fixing this in the long term is somewhat complicated.
* Fixed the bug where fireworks would play on the next run after a completed speedrun during certain conditions. (Thanks Thoday)
* Fixed the bug where Lilith was not starting with the Box of Friends inside the Schoolbag in seeded races. (Thanks thisguyisbarry)
* Fixed the bug where Keeper was not starting with the Wooden Nickel inside the Schoolbag in seeded races. (Thanks thisguyisbarry)

### *v0.7.9* - June 30th, 2017

* The Schoolbag now works with the Booster Pack #3 items.
* Diversity races now include the Booster Pack #3 items.
* Fixed the bug where fireworks would play on the next run after a completed speedrun. (Thanks Molfried)
* Fixed the bug where the HP up pill would not work on Keeper if he has Greed's Gullet. (Thanks Dea1h)

### *v0.7.8* - June 30th, 2017

* Racing+ will now work with the latest patch (Booster Pack #3).
* Fixed the bug where the doors would open prematurely when fighting an angel. (Thanks ReidMercury)

### *v0.7.6* - June 26th, 2017

* Knife accuracy statistics will no longer show if you have Tech X.
* Fixed a bug with the "Checkpoint" custom item not showing up under certain conditions. (Thanks Jerseyrebox)
* The server should no longer crash during big races. (Thanks Molfried)

### *v0.7.4* - June 23rd, 2017

* Moving Box will now appear properly in the Schoolbag if it is an open state.
* Knife accuracy statistics will no longer show if you have the Mom transformation. (Thanks Shigan)
* Fixed some crashes on Linux. (Thanks Dion)

### *v0.7.3* - June 20th, 2017

* Fast-clear should work now in the special situation where you kill an enemy with a long death animation and then kill a splitting enemy afterward. (Thanks BMZ_Loop)
* Fixed an unavoidable damage room with two Sister Vis in the Dark Room (#104). (Thanks Blumpkin Idaho)
* Knife accuracy statistics will no longer show if you have 3 Dollar Bill, Mom's Eye, Loki's Horns, Monstro's Lung, Conjoined, or Book Worm. (Thanks BMZ_Loop and Blumpkin Idaho)

### *v0.7.2* - June 19th, 2017

* Knife accuracy statistics will no longer show for Samael. (Thanks TaKer093)
* Fixed the bug where the starting item graphic (in the starting room) was not being shown correctly in seeded races.
* Fixed some bugs with the new fast-clear. (Thanks Thoday and 910Dan)
* Fixed the bug where Mushroom replacement did not work properly. (Thanks BMZ_Loop)

### *v0.7.1* - June 14th, 2017

* For R+9, R+14, and R+7 custom challenges, the LiveSplit AutoSplitter will now automatically detect a reset when you hold R to go back to the first character. (Thanks Hyphen-ated)
* Knife accuracy statistics will no longer show for Keeper. (Thanks TaKer093)

### *v0.7.0* - June 12th, 2017

News:

* Season 1 is finished!
  * Congratulations to Cyber_1 for the best R+9 time of 1:31:02 and Dea1h on the second best time of 1:33:27. I was luckily able to nab third place with 1:33:49.
  * Congratulations to Dea1h for the best R+14 time of 2:41:37, Shigan for the second best time of 2:49:48, and CrafterLynx for the third best time of 2:54:08.
  * The top 10 times will be stored in a hall of fame page on the website in the future.
  * If you want to beat these times, the R+9 and R+14 categories will continue to be tracked on speedrun.com, but the official competition will move on to season 2.
* Season 2 has officially begun!
* If you have ideas for season 3, send them to me on Discord, which is planned for November 2017.

Changes:

* Azazel's starting health has been changed to be 3 black hearts and 1 half soul heart. This makes him more powerful, but is closer to vanilla. (Thanks Lobsterosity and Krakenos)
* When you have Mom's Knife, extra stats will now appear in the bottom-right hand corner of your screen to show your accuracy.
  * Shots fired when the room is clear of enemies won't count towards the stats.
  * The stats won't show if you have more than one knife, Epic Fetus, or Brimstone.
* In the R+7 custom challenge, both The Polaroid and The Negative will now spawn after defeating Mom (instead of just The Polaroid). Neither are required for the trapdoor to appear after Satan. (Thanks SlashSP)
* If there are multiple Mom's Hands or Mom's Dead Hands in a room, they will now fall in 3 frame intervals instead of 1 frame intervals, which will make them look less buggy.
* If you are on a victory lap, the amount of victory laps will now show in the bottom-right hand corner of the screen.
* Fixed the bug where Samael could get a double charge out of a Lil' Battery or Charged Key if he swapped Schoolbag items immediately after touching it. (Thanks Blumpkin Idaho)
* Fixed the invisible hitbox on the double Frail fight on seeded races. (Thanks thereisnofuture)
* The entity checking and fast-clear code has been rewritten so that the game should run faster on potato computers.

### *v0.6.18* - June 7th, 2017

* Charge accumulation on the Wraith Skull will work more normally now at high levels of damage.
* Reduced the Samael Mom's Knife damage nerf from 1.75 to 1.5. (Thanks Krakenos)
* Added the "R+7 (S2)" graphic to the "Choose Char Order" custom challenge. Thanks to Gromfalloon for doing the artwork.
* Reverted the "jumping into the chest" animation to vanilla.
* Fixed the bug where Samael would start with extra damage after having certain items on the previous run.
* Fixed the bug where the statue would take a while to wake up on the Satan fight if you killed the Fallen super quickly. (Thanks SlashSP)
* Fixed the bug where Flesh Death's Heads would not spit out tears when they died. (Thanks SlashSP)
* Fixed the bug where the D6 was not getting removed from item pools properly when playing as Isaac on custom challenges. (Thanks CrafterLynx)

### *v0.6.17* - June 6th, 2017

* Putting the Wraith Skull in the Schoolbag will now immediately end the item's invulernability, similar to how My Little Pony and Unicorn Stump work.
* Fixed the bug with Samael where A Pony and White Pony did not grant the correct amount of speed. (Thanks Krakenos)
* Fixed the bug where canceling the pickup animation of Sacrificial Dagger would give you two Sacrificial Daggers. (Thanks SlashSP and Lobsterosity)
* Fixed the bug with Samael where swapping from the Wraith Skull with the invulernability activated incorrectly lowered your speed permanently (until you swapped back to the Wraith Skull). (Thanks ceehe)

### *v0.6.16* - June 5th, 2017

* The hitbox size and damage of Samael's Mom's Knife scythe has been reduced.
* Fortune Teller Machine now have custom fortunes. If you have ideas for more funny fortunes, please message me on Discord.
* Keeper will now only start with his extra items if he is played in a R+9 or R+9/14 custom challenge.
* Fixed the bug where Lil' Batteries, Charged Keys, and the Hairpin trinket would not charge the Wraith Skull.
* Fixed the bug where saving and quitting with the Wraith Skull granted permanent invincibility on other characters. (Thanks TaKer093)
* Fixed the bug where Mom's Knife and Dead Eye will softlock Samael. (Dead Eye is now automatically removed if you have Mom's Knife.)
* Fixed the bug where Death's Heads and Flesh Death's Heads died at the end of other enemies death animations instead of when the doors opened.
* Fixed a bug where trapdoors were always centered in the room in a R+7 custom challenge. (Thanks CrafterLynx and Karolmo)

### *v0.6.13* - June 4th, 2017

* Fixed a bug where the Womb 2 trapdoor was not correctly centered in R+7 if you skipped taking The Polaroid.

### *v0.6.12* - June 3rd, 2017

* The trapdoor now spawns in an open state after defeating Satan. (Thanks Krakenos)
* Added the BozoT emote. (Requested by LogBasePotato)

### *v0.6.11* - June 1st, 2017

* The Satan fight is faster now.
* Fixed a bug with the "Change Char Order" room. (Thanks leo_ze_tron)
* Fixed a bug where the Checkpoint custom item did not spawn properly under certain conditions. (Thanks CrafterLynx)

### *v0.6.9* - May 31st, 2017

* Fixed a bug with the Butter! trinket where it could give unlimited charges to an active item under certain conditions. (Thanks blcd)
* Fixed 4 Sheol rooms with Begotten Chains (#255, #269, #334, and #341) to have Begottens instead.
* Fixed the bug where you saw the old character briefly after grabbing the Checkpoint custom item.
* Added the Samael custom character for the purposes of testing him out as a potential canditate for season 2. This is a character made by Ghostbroster: http://steamcommunity.com/sharedfiles/filedetails/?id=897795840
* Samael now starts with the D6, the Schoolbag, and 1 bomb.
* Removed Samael's innate ability; he now starts with the Wraith Skull inside the Schoolbag.
* Removed Samael's custom Isaac decapitation animation. (It's pretty satisfying to see, but it gets old after a while.)
* Fixed various bugs relating to Samael. (Sacrificial Dagger now works.)
* Added a new custom challenge for season 2.
  * It has 7 characters: Isaac, Cain, Judas, Azazel, Eden, Apollyon, and Samael.
  * It goes to the Dark Room, but you still get the Polaroid.
  * It is still in the testing phases.

### *v0.6.7* - May 28th, 2017

* Added support for racing custom characters to the client.
* Added Globins to the fast-clear exception list. (Thanks Thoday)
* Added Dark Red champions to the fast-clear exception list. (Thanks ReidMercury)

### *v0.6.6* - May 22nd, 2017

* Some of the fixes from the last patch are now integrated into Racing+.
* Basement/Cellar room #811 is deleted.

### *v0.6.6* - May 22nd, 2017

* The Sacrifice Room teleport will now only go to the next floor if your race goal is to The Lamb or to Mega Satan. (Thanks Cyber_1 and Dea1h)
* Fixed the bug where you could swap the Schoolbag item over and over to get infinite invincibility from My Little Unicorn and Unicorn Stump. (Thanks aferalsheep)

### *v0.6.5* - May 18th, 2017

* The Maw of the Void and Athame room extension has been reverted to vanilla. (The result of the poll was 22 to 14.)
* The spelling of Humbleing Bundle has been reverted to vanilla.
* Fixed the bug where you wouldn't get a charge for clearing Mega Satan. (Thanks LogBasePotato)
* Fixed the bug where you could find Incubus, Sacred Heart, and Crown of Light on basement 1 if you started with those items in a diversity race. (Thanks Thoday)

### *v0.6.3* - May 17th, 2017

* Portals are now on the fast-clear exception list. (Thanks 910dan)

### *v0.6.2* - May 16th, 2017

* It is no longer possible to kill both phases of Mega Satan with one Chaos Card. (Thanks tODDlife)
* The Moving Box is now removed from all pools in the Pageant Boy ruleset. (Thanks StoneAgeMarcus)
* Fixed the bug with the Victory Lap and Finish custom items where they would still take effect even if they were rerolled. (Thanks 910dan)
* Fixed the bug with the Victory Lap custom item where it would sometimes not work. (Thanks thisguyisbarry)
* Fixed the bug where going into a crawlspace from a Devil Room would softlock the game. (Thanks ReidMercury and SapphireHX)

### *v0.6.0* - May 15th, 2017

* Fixed the bug where the client would crash when getting a Booster Pack #2 item in a diversity race. (Thanks leo_ze_tron)
* Fixed the bug where active items could be recharged by dropping them and picking them up again. (Thanks nicoluwu and ReidMercury)

### *v0.5.25* - May 14th, 2017

* The new Angel Room changes from vanilla are now itegrated into the mod.
* The fart-reroll system has been deleted; items will now automatically be removed from pools thanks to new API stuff in the last patch. (In diversity races, Incubus, Crown of Light, and Sacred Heart will still have the special fart-reroll.)
* You can now pick up items immediately after performing a Schoolbag switch thanks to new API stuff in the last patch.
* Diversity races will now include Booster Pack #2 items.
* The mod no longer has a custom Crystal Ball since it is now seeded in the base game.
* The mod no longer modifies Portals since they are now seeded in the base game.
* Champions other than Pulsing Green and Light White are no longer on the fast-clear exception list thanks to new API stuff in the last patch.
* The Schoolbag will now function properly with the Booster Pack #2 items.
* The 2nd D6 has been replaced with the Moving Box in the Pageant Boy ruleset.
* Fixed the bug where if you started with Krampus' Head in a diversity race, it would turn into A Lump of Coal if you dropped it. (Thanks Dune1008)
* Fixed the bug where the race start room was not properly set up if you reset during the countdown. (Thanks thisguyisbarry)

### *v0.5.23* - May 13th, 2017

* Racing+ now works with the latest patch. Diversity races and the Schoolbag will still be messed up.

### *v0.5.22* - May 12th, 2017

* Diversity special rerolls will now have a bright red fart. (Thanks Krakenos)
* If a Lump of Coal is banned, then Krampus' Head will always drop. If Krampus' Head is banned, then a Lump of Coal will always drop. If both are banned, then a random item will drop. (Thanks thisguyisbarry)
* Added the VoHiT emote. (Requested by LogBasePotato)

### *v0.5.21* - May 11th, 2017

* After you have opened the console, you can now double tap R to fast-reset.
* The delay on Mom's Hands and Mom's Dead Hands will now rotate over a 10 frame interval over the course of a run instead of being random. This prevents the small chance where two hands can drop on the same frame. (Thanks Dea1h)
* Fixed the old Butter! bug that resurfaced. (Thanks SlashSP)

### *v0.5.20* - April 27th, 2017

* Fixed the (vanilla) bug where the black Scolex champion had the wrong graphics. (Thanks NorBro86)
* Fixed the bug where pickups would be duplicated if they appeared over trapdoors under certain conditions. (Thanks Cyber_1)
* Fixed the bug where the Soul Jar was not working properly with Abaddon. (Thanks Cyber_1)
* Fixed the bug with Book of Sin where it wouldn't work under certain conditions. (Thanks Thalen22)
* Fixed the bug where Ball of Bandages was getting fart-rerolled in diversity races when it shouldn't. (Thanks BMZ_Loop)
* Fixed the bug where Krampus' Head and A Lump of Coal were not being fart-rolled under certain conditions. (Thanks PassionDrama)
* Fixed the bug where the Schoolbag + Glowing Hour Glass + Broken Remote synergy was not working properly. (Thanks Ou_J)
* Added the KonCha emote. (Requested by Ou_J)

### *v0.5.19* - April 21st, 2017

* Fixed the bug where The Relic would not spawn any soul hearts if it came from an Immaculate Conception. (Thanks blcd)
* The mod will no longer show the challenge warning when you are in a challenge. (This allows R+9 custom races.) (Thanks BMZ_Loop and SedNegi)

### *v0.5.18* - April 20th, 2017

* Made it so that all of the bag familiars work based on individual room clear counters, instead of a global room clear counter. This means that they should act more fairly now in a seeded race. (Thanks Cyber_1 and blcd)
* Fixed the bug where level 2 Bumbo would not drop random pickups after clearing a room. (Thanks blcd)
* Fixed the bug where Spider Mod would not drop random blue spiders or batteries after clearing a room. (Thanks blcd)
* Fixed the bug where Mystery Sack drops did not have an equal chance to be each pickup subtype. (Thanks blcd)
* Fixed the bug where the "13 Luck" custom item was not being given correctly in seeded races with the Fire Mind start. (Thanks Dea1h)

### *v0.5.17* - April 19th, 2017

* Added the "beginner" format for the Pandora's Box tournament. In this format, Judas starts with the Schoolbag, a full red heart container, and a full soul heart. You can activate this by changing the "rFormat" field to "beginner" in the "save#.dat" file corresponding to your save slot.
* Fixed the unavoidable damage when a Spiked or Mimic chest spawns in Womb/Utero room #458. (Thanks Dea1h)
* Pickups will now bounce off of trapdoors, crawlspaces, and beams of light. (Thanks Cyber_1)
* Fixed the bug where the countdown graphic would overlap with the final place graphic. (Thanks PassionDrama)
* Added the PunOko emote. (Requested by thisguyisbarry)
* Added the PagChomp emote. (Requested by LogBasePotato)

### *v0.5.13* - April 17th, 2017

* Fixed the bug where finishing the Mega Satan fight would trigger the natural finish code instead of the custom Racing+ finish code. (Thanks Lobsterosity)
* Fixed the bug where the Butter! trinket would make the Schoolbag item not work properly. (Thanks blcd and Lobsterosity)

### *v0.5.12* - April 17th, 2017

* Fixed the bug where the opening the client would make it complain about the "save.dat" file.

### *v0.5.10* - April 17th, 2017

* It is now impossible to get a narrow boss room on floors 2 through 7 when having Duality. (Thanks Dea1h)

### *v0.5.9* - April 15th, 2017

* Fixed the bug where a race trophy would erroneously appear in a R+9/14 speedrun under certain conditions. (Thanks Dea1h)
* Fixed the bug where the player could erroneously teleport in a Gurdy, Mom's Heart, or It Lives! room when coming out of a Devil Room.

### *v0.5.7* - April 15th, 2017

* When you finish a race, there will now be an in-game custom graphic that shows what place you finished in.
* The "Would you like to do a Victory Lap!?" popup will no longer appear after defeating The Lamb. (Thanks Cyber_1)
* The disruptive teleport that occurs when entering a room with Gurdy, Mom's Heart, or It Lives! will no longer occur.
* Mushrooms can no longer spawn outside of floors 3 and 4. (They will spawn as Hosts instead.) (Thanks Krakenos)
* Fixed the bug where quitting and continuing in the "Race Room" would delete the two Gaping Maws.
* Fixed the bug where the mod would incorrectly spawn you as the wrong character under certain conditions. (Thanks PassionDrama)
* Fixed the bug where the mod would incorrectly spawn fireworks under certain conditions. (Thanks Cyber_1)
* Fixed the bug where invulernability frames were not being removed properly.

### *v0.5.6* - April 14th, 2017

* Changed the behavior of the fast-restart feature such that on floors 2 and beyond, you need to double tap R to trigger it. This should prevent accidental restarts. (Thanks Hyphen-ated, Nariom, and tyrannasauruslex)
* Changed the behavior of the fast-drop feature such that if you drop more than one item, they will no longer be stacked on top of each other.
* Slightly increased the hitbox on trapdoors and crawlspaces (from 16 to 16.5).
* Moved all NPC checks to the NPCUpdate callback, which will make the game run faster on potato computers.
* Fixed an unavoidable damage room with a Charger near the top entrance (#1033). (Thanks starg09 and CrafterLynx)
* Mushrooms can no longer be spawned from breaking skulls. (It spawns a Host instead.) This fixes the unavoidable damage when you walk over a skull with Leo / Thunder Thighs. (Thanks thisguyisbarry)
* Fixed the bug where using a Forget Me Now or Victory Lap on the Dark Room would cause the game to lag under certain conditions.
* The two Frails that replace Scolex in seeded races will no longer spawn on top of each other, which makes it much easier to distinguish between the two of them.
* Cube of Meat and Ball of Bandages will no longer be fart-rerolled in diversity races. (Thanks PassionDrama)
* The "Finish" custom item will now take you to the menu immediately. (Before, you had to wait for the entire item pickup animation to complete.)
* The "Victory Lap" custom item has been recoded to use the fast-travel feature instead of the Forget Me Now effect.
* Fixed the bug where the place graphic would not show the correct place after you finished the race under certain conditions.
* Reorganized the way items show up on the item tracker in seeded races.

### *v0.5.4* - April 13th, 2017

* You no longer have to switch characters before a race. When the race starts, you character will automatically change to the correct one.
* Removed all of the useless animations in the Mega Satan fight. The fight is incredibly smooth now.
* Finishing the Mega Satan fight no longer has a random chance to send you back to the menu.
* Eden now has better hair in the "Change Char Order" custom challenge. (Thanks Krakenos)
* All of the character graphics are less faded in the "Change Char Order" custom challenge.
* Fixed the bug in the speedrun custom challenges where you could touch an item pedestal to advance to the next character under certain conditions. (Thanks ceehe)
* Fixed the bug where some of the save file graphics had the wrong text color.
* Fixed the bug where hearts could disappear if they travelled over trapdoors under certain conditions.
* Fixed the bug in custom challenge speedruns where restarting as The Lost after a death would go back to the first character. (Thanks Dea1h)

### *v0.5.3* - April 12th, 2017

* After each patch, your R+9 and R+14 character orders will be deleted. Backup your "save#.dat" file and copy it back after a patch if you want to quickly restore your character order without having to go through the custom challenge again.
* Added a new warning message if you attempt to perform a R+9 or R+14 speedrun without having set your character order.
* Fixed the bug where the "R+9" and "R+14" labels weren't showing on the "Change Char Order" custom challenge.
* Fixed the bug where the game would ocassionally crash if you restarted the game while playing as Lilith. (Thanks Cyber_1)
* Fixed the bug where Keeper would not heal properly in certain specific conditions. (Thanks Cyber_1)
* Fixed the bug where pickups could ocassionally glitch out over trapdoors. (Thanks PassionDrama)

### *v0.5.0* - April 10th, 2017

* Introducing a brand new custom challenge for R+9 and R+14 speedruns!
  * This mode will automatically take you from character to character upon run completion. No more going back to the menu!
  * This mode will show a timer on screen, similar to how races work.
  * If you are in the middle of a run and you want to start over, you can hold R to go back to the first character.
  * You can set your character order by using the custom "Change Char Order" challenge.
  * In order for it to work with the LiveSplit auto-splitter, you have to check the box that says "Racing+ speedrun" in the auto-splitter options.
  * The "S1" stands for season 1. In the future, we can easily make new speedrun categories.
* Isaac, Magdalene, Lilith, and Apollyon are set back to their old starting items. (They just get the D6 now and nothing else special. They will still get their additional starting items in the R+9/14 custom challenge.)
* Added sparklies and fireworks if you complete a race with 3 or more people or finish a R+9/14 speedrun. (Thanks to Chronometrics for helping to code this.)
* Mimics now have vanilla graphics instead of the special Racing+ graphic. (The final tally on the vote was 19 to 18.)
* The beam of light on Womb 2 will no longer have the extra delay if the room is already cleared.
* The colors of some Purity auras have been changed to make them easier to see; speed is now green (think "Roid Rage") and range is now yellow. (Thanks to Inschato for helping with this and BMZ_Loop for the graphics and Ou_J for the idea.)
* Fixed the bug where the beam of light would be incorrectly placed in Black Markets and I AM ERROR rooms. (Thanks blcd and Lobsterosity)
* Fixed the bug where Eden's Soul would always be fully charged if you had the Schoolbag. (Thanks Lobsterosity)
* Fixed the bug where the recharge sound would play during a reset on potato computers.
* Fixed the bug where trapdoors would appear for a frame before being removed.
* Fixed the bug where Krampus' Head could start with 0 charges under certain conditions. (Thanks Cyber_1)
* Fixed the bug where the Butter! trinket would make the Schoolbag stop working. (Thanks SlashSP)
* Fixed the bug where a trophy would spawn if you were not in a race and reloaded the room with the big chest in it. (Thanks Nariom)
* Fixed the bug where the stage graphic would stay on the screen forever if you reset under certain conditions.
* Fixed the bug where the trapdoor would not respawn in a run where you resumed a save after completely quitting the game.
* Made Cathedral room #11 and #12 symmetrical.
* Fixed the bug with the client where it would give an error if there were no "save.dat" files in your mod folder.
* Added the VapeNation emote. (Requested by LogBasePotato)

### *v0.4.20* - April 7th, 2017

* Increased the pedestal pickup delay on freshly spawned items from 15 to 20. (It is 20 in vanilla.) (Thanks Lobsterosity)
* Fixed the bug where Big Horn would drop an extra heart under certain conditions.
* Fixed the bug where the Mega Satan fight could end early under certain conditions. (Thanks PassionDrama and ReidMercury)
* Fixed the bug where the timer would get messed up under certain conditions. (Thanks PassionDrama)
* Fixed the bug where the trapdoor would troll you after coming out of a Devil Room.
* Fixed the bug where it would not show the correct "pre-race" graphic under certain conditions. (Thanks blcd)
* Added the SexyDaddy emote.

### *v0.4.19* - April 5th, 2017

* There will now be an x or a checkmark next to the "pre-race" graphic to indicate whether you are ready or not.
* Replaced the "Unranked" and "Mega Satan" in-game icons with better ones. (Thanks to SnugBoat for drawing the cake.)
* Added the deIlluminati emote.

### *v0.4.18* - April 4th, 2017

* Trapdoors should be behave more similarly to vanilla now in that they won't open right away if the player is standing relatively close. If you continue to accidently fall into trapdoors, please let me know.
* Fixed the bug where using a Glowing Hour Glass on the first room of a floor would make your character permanently invisible. (Thanks Fyon and CrafterLynx)

### *v0.4.16* - April 3rd, 2017

* Removed the April Fool's joke where [Big Horn and Little Horn had clown suits](http://steamcommunity.com/sharedfiles/filedetails/?id=850578581), which is a mod from [Mr. Metal Alex](http://steamcommunity.com/id/MetalAlex/myworkshopfiles/?appid=250900).
* Added a "last person left" graphic when you are the last person left. (It will only show in races with 3 people or more.)
* Added the fast-travel feature to the Blue Womb.
* Fixed the bug where if you left a room with a trophy, it would disappear forver. (Thanks Cyber_1)
* Fixed the bug where the run would be reset if your internet hiccuped during a race. (Thanks thisguyisbarry)
* Fixed the bug where the beam of light would not spawn if you had both The Polaroid and The Negative. (Thanks nicoluwu and tyrannasauruslex)
* Fixed the bug where the timer would show before a race started.
* Slightly increased the hitbox on trapdoors and crawlspaces (from 15.5 to 16).
* The "News" link on the website will now go to [this page](https://github.com/Zamiell/isaac-racing-client/blob/master/HISTORY.md).
* There is now an alpha version of both [profiles](https://isaacracing.net/profiles) and [races](https://isaacracing.net/races) on the website. This was coded by sillypears, so thanks to him for that.
* The separate "mod-only" change-log will no longer be maintained.

### *v0.4.15* - April 2nd, 2017

* Fixed the bug where the beam of light would not work after Hush. (Thanks StoneAgeMarcus)
* Fixed the bug that caused unseeded weirdness on seeded races. (Thanks blcd for discovering why this happened)
* The Polaroid (and The Negative) will no longer spawn in an off-center position.
* The beam of light (and trapdoor) after It Lives! and Hush will no longer spawn in an off-center position.
* The beam of light and trapdoor will now despawn based on whether you have The Polaroid or The Negative instead of the race goal.
* Made the custom stage text disappear quicker. (Thanks LogBasePotato)
* Changed "???" to "Blue Baby" on the character select screen. (Thanks to nicoluwu for the artwork.)

### *v0.4.12* - April 1st, 2017

* Added custom floor notification graphics for every floor in the game. (Fast-travel doesn't trigger the vanilla notifications.)
* You are no longer automatically sent to the "Race Room" if you join a race. (You will only be sent there if you start a new run.) Going to the "Race Room" in between races is entirely optional, since all races start with a reset. (Thanks tyrannasauruslex)
* Trapdoors will now properly show as Womb Holes on floors 6 and 7. (Thanks tyrannasauruslex)
* Fixed the bug where using a Strength or Huge Growth card before entering a trapdoor would make you keep the increased size forever. (Thanks blcd and tyrannasauruslex)
* Fixed the bug where pickups would sometimes spawn inside Stone Grimaces and the like. (Thanks CrafterLynx)
* Fixed the bug where you could use a card or a pill before jumping out of the hole when coming from another floor.

### *v0.4.9* - March 31st, 2017

* It is pretty unfair when a Mimic chest spawns behind you and your body is blocking the two spike tells. (Or, alternatively, if the Mimic is behind a dying enemy.) To rectify this problem, Mimic chests now have a custom "Appear" animation if they spawn within a certain distance of the player. If you want to see this in action, use the "spawn mimic" console command. If you get hit by a mimic chest and you feel that it wasn't your fault or that it was unfair, show me the clip and we can continue to work on it.  (Thanks Dea1h and tyrannasauruslex)
* Fixed the bug where the Butter! trinket wouldn't work properly with the Schoolbag. (Thanks MrNeedForSpeed96)
* Fixed the bug where trapdoors would be duplicated in rooms that weren't connected to the level grid under certain circumstances. (Thanks thereisnofuture)
* Reduced the delay on the Womb 2 beam of light from 60 frames to 40. This is just short enough that you will be hit by the wave of tears before going up. (Thanks Krakenos)
* Fixed the bug where Conjoined Fatties would make the doors open early in certain circumstances. (Thanks PassionDrama)
* Fixed the bug where the unavoidable damage prevention code for Mimics was not firing properly. (Thanks tyrannasauruslex)
* Fixed the unavoidable damage room in the Caves/Catacombs with 5 Crazy Long Legs by removing 1 Crazy Long Legs to make it a bit easier (#862). (Thanks Cyber_1)
* The on-screen timer now uses custom sprites and looks a lot better.
* Replaced all of the Rules card text snippets with educational history.

### *v0.4.7* - March 30th, 2017

* You can now do a Schoolbag switch during the "use item" animation. This is a big buff to the item. PogCena
* Chargebars are now minimialistic and actually good.
* Changed the Broken Modem sprite to one that isn't complete garbage. (I got it from freeze, the original author of the item.)
* Trapdoors will now be shut if you enter a room and are standing near to them. (This is also how it works in vanilla. Thanks Cyber_1)
* Fixed the bug where trapdoors would disappear in certain circumstances.
* Fixed the bug where a rock could occupy the same square as a trapdoor or crawlspace under certain conditions. (Thanks CrafterLynx)
* Fixed the bug where the starting items for seeded and diversity races would not show up. (Thanks PassionDrama)
* Fixed the client bug where the question mark icon would not show up next to the build on the new race tooltip.
* Fixed the client bug where the build column would not show in seeded races. (Thanks vertopolkaLF)

### *v0.4.5* - March 29th, 2017

* For races to Mega Satan and races that are already completed, the Mega Satan door will be automatically opened. (This is simpler than placing a Get Ouf of Jail Free Card next to the door.)
* Fast-travel no longer applies to the portal to the Blue Womb. This fixes the bug where the Blue Womb trapdoor would take you to Sheol instead of the Blue Womb. (Thanks Dea1h)
* Fixed the bug where Dr. Fetus bombs could be shot while jumping through the new trapdoors. (Thanks PassionDrama and tyrannasauruslex)
* The 13 luck for the Fire Mind build is now a custom item called "13 Luck". It should now function properly with other items. (Thanks thisguyisbarry)
* Reduced the delay for the beam of light in the Cathedral to 16 frames. (Thanks Dea1h)
* Made the fast-reset feature work for people who have reset bound to shift. (Thanks MasterofPotato)
* Fixed an unavoidable damage room in the Caves (#167). (Thanks Dea1h)

### *v0.4.3* - March 28th, 2017

* The hitbox on trapdoors and crawlspaces was slightly larger than it was on vanilla due to having to override the vanilla entities. Racing+ now uses custom entities for these, which fixes the bug where you would sometimes accidently walk into a trapdoor while entering a Devil Room, for example. This also fixes the bug where you would sometimes skip a floor when going in a trapdoor.
* Fixed the bug where your blue flies / spiders would kill themselves on the custom floor transition hole. (Thanks CrafterLynx)
* Fixed the crash when a diversity race started with Booster Pack #1 items. (Thanks stoogebag)
* Fixed the bug where your character would move to the center of the room upon coming back from a crawlspace.
* Fixed the bug where you would be in a weird spot after returning to the Boss Room after coming back from a Boss Rush with a crawlspace in it.
* Fixed the bug where people with controllers would not be able to use the fast-reset feature in some circumstances. (Thanks Krakenos)
* Fixed the bug with the Pageant Boy ruleset where the trinket was not getting deleted.
* Fixed the bug with the Pageant Boy ruleset where it was not detecting the ruleset on the first run after opening the game.

### *v0.4.0* - March 27th, 2017

* When starting a new run, Racing+ will now automatically put on the "Total Curse Immunity" Easter Egg for you (the "BLCK CNDL" seed). If Basement 1 happened to have a curse on it, the run will be automatically restarted. [Rejoice, and be merry](https://www.youtube.com/watch?v=tHvnxbtHqsE).
* The racing system was rewritten such that you should never have to go back to the menu in between races anymore (unless you need to change your character). You will now start the race in an isolated room, and all races will start by resetting the game.
* Seeded races will automatically start you on the correct seed; you do not have to type it in anymore.
* Pressing the reset key will now instantly reset the game. (This change is experimental.)
* The client now validates that you are not on a challenge before letting you ready up.
* The mod now has some new pre-race graphics, including showing you the goal. (Thanks stoogebag)
* The long and annoying fade out / fade in animation between floors has been replaced with something better. (Thanks PassionDrama for helping to test.)
* The Schoolbag will now work properly with the new Booster Pack items. (Thanks meepmeep)
* Diversity races that start with the new Booster Pack items will now work properly. (Thanks BMZ_Loop)
* Fixed the unavoidable damage when Spiked Chests or Mimics spawn in Caves/Catacombs room #19. (Thanks PassionDrama)
* In diversity races, when you pick up Crown of Light from a Basement 1 Treasure Room, it will now heal you for half a heart if you are not already at full red hearts. (Thanks Dea1h)
* Fixed the bug where banned items would roll into other banned items under certain conditions. (Thanks Lobsterosity)
* If Eden starts with Book of Sin, Crystal Ball, Betrayal, or Smelter, they will now start with the Racing+ custom version of the item.

### *v0.3.2* - March 23rd, 2017

News:

* Now that the Mom's Hand change has been played for a while, I've asked around for feedback. Almost everyone likes the change, so it will remain in the game permanently.

Changes:

* Made the mod work with the new patch.
* Increased the pedestal pickup delay from 10 to 15.
* Fixed the bug where the Schoolbag item would be overwritten under certain conditions.
* Fixed the (vanilla) bug where stuff on the bottom left hand corner of the title screen was cut off.
* Fixed the bug where banned items could roll into other banned items. (Thanks PassionDrama)

### *v0.3.0* - March 22nd, 2017

* The size of the mod has been reduced by around 12 MB. (Thanks ArseneLapin)
* Fixed a bug that prevents the lobby from being loaded in certain circumstances. (Thanks Gandi)
* Fixed a bug where the "Enable Boss Cutscenes" checkbox was not working in certain circumstances. (Thanks tyrannasauruslex)

### *v0.2.85* - March 21st, 2017

* It seems to be pretty common for the Steam download system to break people's mods whenever I push an update. Now, whenever you log in with the client, if you have a damaged mod, it will automatically be healed.
* Fixed the bug where you could recharge your active item by swapping for another active item. (Thanks dion)
* Fixed the bug where items that were not fully decremented on sight rolled into themselves. This involved rewriting both the item ban system and the RNG that the mod uses. The ban system now seeds items one by one starting with the room seed. The RNG is now based on the game's internal RNG. (Thanks Rex and Krakenos, and thanks blcd for ShiftIdx recommendation)
* Fixed the bug where rerolled items would be swapped if one item was purchased beforehand and the other one wasn't.
* Fixed the bug where Schoolbag items were not added to the ban list on seeded races. (Thanks Cyber_1)
* Fixed the bug where the charge bar for Wait What? would not show up in the Schoolbag. (Thanks Cyber_1)
* Special items are no longer special. This means that you will no longer be screwed by seeing a D100 or The Ludovico Technique, for example.
* Fixed the bug with the Schoolbag where the game would play a sound when you switched to an item that was not fully charged.
* Fixed the bug where teleporting would cause you to lose your Schoolbag item under certain circumstances. (Thanks Dea1h)
* Fixed the bug where the pre-race graphics would stay on the screen for the entire race under certain circumstances. (Thanks Dea1h)
* Touched up the save file graphics.

### *v0.2.77* - March 19th, 2017

* Fixed the bug where in certain circumstances, the client was not able to find the Racing+ mod directory.
* Trinkets consumed with the Gulp! pill will now show up on the item tracker. (This only works if you are using the Racing+ mod.)
* Fixed the bug where some glowing item and trinket images were not showing up properly on the starting room. (Thanks Krakenos)
* Fixed the bug where starting the Boss Rush would not grant a charge to the Schoolbag item. Note that actually clearing the Boss Rush still won't give any charges, due to limiations with the Afterbirth+ API. (Thanks Dea1h, who saw it on tyrannasauruslex's stream)
* Fixed the bug where fart-reroll items would start at 0 charges. (Thanks Munch, who saw it on tyrannasauruslex's stream)
* The Polaroid and The Negative are no longer automatically removed in the Pageant Boy ruleset.
* The beam of light and the trapdoor are no longer automatically removed after It Lives! in the Pageant Boy ruleset.
* The big chests after Blue Baby, The Lamb, and Mega Satan will now be automatically removed in the Pageant Boy ruleset.
* Fixed the Schoolbag sprite bug when starting a new run in the Pageant Boy ruleset.


### *v0.2.74* - March 18th, 2017

* Upon finishing a race, a flag will now spawn in addition to the Victory Lap. You can touch the flag to take you back to the menu. (Thanks Birdie)
* The Pageant Boy ruleset now has item bans for the starting items.
* The Pageant Boy ruleset now starts with +7 luck.
* Before a race, you will now see the race type and the race format next to the Gaping Maws.
* Before a race, you will see an indication of whether you are ready or not.
* Seeded races now show the starting item / starting build in a manner similar to diversity races.
* Items shown on the starting room in seeded and diversity races now have a glow so that it is easier to see them. (The glow images were taken from the item tracker.)
* Fixed the bug where you could see the diversity items early under certain conditions. (Thanks Lobsterosity, Ou_J, and Cyber_1)
* Fixed the bug where enemies spawned after touching the trophy under certain conditions. (Thanks MasterofPotato, Ou_J, and Cyber_1)
* Fixed the bug where on seeded races, the door to the Treasure Room that was inside a Secret Room would behave weirdly on Basement 1.
* Fixed the bug where the depths STB wasn't getting loaded. (Thanks Lobsterosity)

### *v0.2.73* - March 17th, 2017

* The Racing+ versions of The Book of Sin, Crystal Ball, Smelter, and Betrayal now work with the item tracker. If you haven't already, make sure that you download the latest version of the tracker. (The item tracker will now also auto-update if you have v2.0 or higher.) Thanks goes to Hyphen-ated for this.
* The Racing+ custom items Schoolbag, Soul Jar, Victory Lap, Off Limits, and Debug will now work with the item tracker. Thanks also goes to Gromfalloon for the artwork on the Soul Jar icon.
* Smelter will now make consumed trinkets appear on the item tracker. (This will only happen if you use the Racing+ mod.)
* The item tracker will now show the smelted random trinket in diversity races.
* Godhead is removed from the special diversity Basement 1 rerolls.
* If the goal of a race is Mega Satan, the chests will now be deleted after Blue Baby and The Lamb as a reminder. (Thanks Krakenos)
* Fixed the spawning of the key pieces if the race goal is set to Mega Satan. Additionally, a Get out of Jail Free Card will now spawn instead of two key pieces.  (Thanks BMZ_Loop)
* A Get out of Jail Free Card will now spawn next to the Mega Satan door if you visit the starting room after finishing a race.
* The Forget Me Now that spawns after a race has been replaced with a custom item called Victory Lap. Victory Lap is a passive item, so you don't have to give up your active items anymore to reset the floor.
* Added a feature where Blue Baby will be replaced on a Victory Lap with 2+ random bosses. The number of bosses will continue to increase with the amount of total victory laps that you have done.
* Fixed the bug where Keeper would lose a coin container under certain conditions. (Thanks Cyber_1)
* Fixed the bug where Krampus' head would turn into A Lump of Coal under certain conditions. (Thanks Cyber_1)
* Fixed some bugs with the client affecting Linux users. (Thanks mithrandi)

### *v0.2.72* - March 17th, 2017

* Boomerang, Butter Bean, The Candle, Red Candle, Glass Cannon, Brown Nugger, and Sharp Straw all appear properly now in the Schoolbag. (Thanks Birdie)
* The bug where the aformentioned items would not start fully charged is also fixed.
* Fixed a client crash when diversity races started with certain items. (No-one actually reported this out of the 12 people that it happened to. WutFace)
* Fixed the (vanilla) unavoidable damage when a Mimic spawns on top of you. (Thanks henry_92)
* All Spike Chests will now spawn as Mimics instead, since there isn't really a point in having both of them. (Thanks thisguyisbarry)
* Mimics are rediculously trivial to spot, so their graphics have been experimentally reverted back to the pre-nerf graphics. You can tell them apart from normal chests by just looking for the beginnings of the spikes protruding from them. It's fairly easy to see if you just pay attention and look for it. It can be very rewarding when you are paying attention and it pays off: https://clips.twitch.tv/AssiduousSillyLardTwitchRPG
* Fixed the unavoidable damage that occurs when Spiked Chests and Mimics spawn in very specific rooms that only have a narrow path surrounded by walls or pits (Caves #12, Caves #244, Caves/Catacombs #518, Caves #519, Womb/Utero #489). In these rooms, all Spiked Chests / Mimics will be converted to normal chests. If you find more rooms with narrow paths like these ones, let me know.
* Hosts and Mobile Hosts are now immune to fear.
* Maw of the Void and Athame will no longer be canceled upon exiting a room.
* Fixed the (vanilla) bug where having Gimpy causes the Krampus item to be different than it otherwise would have been. (Thanks Dea1h)
* Fixed the seeded boss heart drops to be more accurate to how the vanilla game does it. (Thanks to blcd for providing the reverse engineering research.)
* Added the FeelsAmazingMan emote (requested by MasterofPotato).
* Added the DICKS emote (requested by MasterofPotato).
* Added the YesLikeThis emote (requested by MasterofPotato).
* Fixed a bug with the "/r" command on the client. (Thanks to InvaderTim for coding this.)
* The lobby users list is now properly alphabetized. (Thanks to InvaderTim for coding this.)
* Your "save.dat" file will no longer be overwritten if the client encounters an error and you restart the program. This fixes the error message that tells you to restart in the middle of your run. (Thanks henry_92)
* Fixed the bug where the in-game timer would disappear from the screen once you finished the race.

### *v0.2.71* - March 16th, 2017

* Previously, pickup delay on pedestals was only reduced for freshly spawned pedestals. Pedestal delay is also set to 18 upon entering a new room, so this class of delay is reduced to 10 as well.
* Fixed the bug where Keeper would get stuck on 24, 49, or 74 cents. (Thanks Crafterlynx)
* Fixed the bug with Schoolbag where if you took damage at the same time as picking up a second active item, it would delete it. (Thanks Ou_J)
* Fixed the bug with Mom's Hands and Mom's Dead Hands where they would stack on top of each other when falling at the exact same time. Instead of falling with a 30 frame timer, they will now fall with a random 25 to 35 frame timer. (Thanks ceehe)
* Fixed the bug where the Lil' Haunts on The Haunt fight would be messed up. (Thanks Thoday)

### *v0.2.70* - March 15th, 2017

* Increased the pickup delay on pedestal items from 0 to 10. (On vanilla, it is 20.)
* All boss heart drops are now seeded. This was a nightmare to do.
* Mom's Hands and Mom's Dead Hands will now fall faster even if there is more than 1 in the room.
* It is no longer possible to start with D4, D100, or D Infinity as the random active item in diversity races.
* Fixed a crash that occurred in the client on diversity races that gave Betrayal.
* Cursed Eye no longer overrides Cursed Skull. (Thanks Cyber_1)
* Cursed Eye no longer overrides Devil Room teleports from Red Chests. (Thanks Dea1h and tyrannasauruslex)
* The Schoolbag will now work properly with the Glowing Hour Glass. (Thanks TheMoonSage)
* PMs will no longer give an error message when the recipient is online. (Thanks to InvaderTim for coding this.)
* You can now use the "/r" command to reply to PMs. (Thanks to InvaderTim for coding this.)

### *v0.2.69* - March 14th, 2017

* Fixed the bug where some items would not render properly in the Schoolbag. (Thanks Krakenos)
* Fixed the path to the mods folder on Linux. (Thanks Birdie)
* Changed the caves room with the black heart surrounded by blocks (#267) to the way that Edmund intended it to be.
* Added the OhMyDog emote.
* Added the DatSheffy emote.

### *v0.2.68* - March 13th, 2017

* The Soul Jar effects are now based on whether you hold the item (instead of being tied to the Magdalene character specifically). (Thanks Cyber_1)
* The Schoolbag now works the same way as it does in Antibirth when you only have one active item. (Thanks Cyber_1)
* Fixed the bug where the Schoolbag item would sometimes not appear when first starting a run. (Thanks Cyber_1)
* The mod will now work on Linux. (Thanks mithrandi)
* Fixed the bug where the AAA Battery did not work with the Schoolbag. (Thanks Dea1h)
* Fixed the bug where the race timer would not appear. (Thanks Krakenos)
* Fixed the bug where the format and goal tooltips in the client were wrong. (Thanks vertopolkaLF)
* Fixed the bug where the question mark icon for the random character would not show. (Thanks Birdie)

### *v0.2.67* - March 13th, 2017

* Removed the annoying vanilla delay where you are not able to take a pedestal item immediately after it spawns.
* Fixed the (vanilla) bug where double coins and nickels would not heal Keeper for their proper amount. (Thanks Victor23799)
* Fixed the client crash that occurred whenever The Book of Sin, Crystal Ball, or Betrayal were given in a diversity race.
* Fixed the bug where if the game was paused when the race started, there would be a lot of lag. (Thanks Birdie)
* Fixed the bug where if you were dead when the race started, there would be a lot of lag. (Thanks Dea1h)
* Fixed the bug where the wrong race settings were loaded when entered the game from the menu. (Thanks Lobsterosity)
* Fixed the bug where in-game error messages would not display in big rooms. (Thanks dion)
* Fixed the bug where in-game error messages wouldn't work properly when saving, quitting, and continuing.
* Fixed the bug where closing the game in the middle of a race and coming back would mess some things up.
* All shop items are now seeded.
* On seeded races, The Compass will now be fart-rolled in the shop.
* On seeded and diversity races, active items that you start with will now be properly fart-rolled. (Thanks dion and BMZ_Loop)
* Added a new in-game error message: "Error: Start a new run by holding "R"."
* Reorganized the way Schoolbag items work, which will fix the bug where Judas only needs 2 touches for the Bookworm transformation. (Thanks Cyber_1 and Dea1h)
* Added the Catgasm emote (requested by masterofpotato).

### *v0.2.66* - March 12th, 2017

* Refactored all of the code for the Lua mod. It is now split up across multiple files instead of in one giant file. If there are any new in-game bugs with this new patch, it's probably due to this. (Thanks to sillypears and Chronometrics for the help.)
* Fixed the bug where the game would softlock if you entered a crawlspace from a Bossh Rush. (Thanks Dea1h)
* Fixed the bug where the AAA Battery would not do anything.
* Fixed the (vanilla) bug where the AAA Battery would not synergize with The Battery.
* Fixed the (vanilla) bug where the 9 Volt would not synergize with The Battery.
* Fixed the bug with diversity races where starting with active items that granted consumables would not grant those consumables. (Thanks PassionDrama)
* Fixed the bug where the Gaping Maws would sometimes appear after a race had already started. (Thanks Lobsterosity)
* Changed the build option "Random (D6 builds only, 1-30)" to "Random (single items only, 1-26)", since all the builds include the D6 now.
* Made the lobby race table more compact and neat.
* Added the BibleD emote (requested by Birdie).
* Added the FutureMan emote (requested by Lobsterosity).

### *v0.2.65* - March 11th, 2017

News:

* tODDlife has officially joined the staff, charged with Community Relations.

Changes:

* Updated the FAQ with various things at: https://isaacracing.net/info
* Fixed the bug where the trophy would drop instead of a chest when you were not in a race. (Thanks Krakenos/Dea1h/CrafterLynx/thisguyisbarry/Victor23799)
* Warning messages (like "Error: Turn on the "BLCK CNDL" Easter Egg.") will no longer show in big rooms. (Thanks dion)
* Changed the Alt+C and Alt+V hotkeys to work more reliably.
* Resetting is now disabled when the countdown is between 2 and 0 seconds in order to prevent bugs on potato computers. (Thanks Krakenos)
* Fixed the bug with The Book of Sin taking away charges when the player had The Battery. (Thanks HauntedQuest)
* Finally fixed the annoying bug where in big races you couldn't see all the people in the race properly. (Thanks SedNegi and stoogebag)
* Fixed the bug where if too many races were open, the lobby would mess up and overflow.
* The Kamikaze! and Mega Blast builds will now correctly use the Schoolbag to keep the D6. (Thanks antizoubilamakA)

### *v0.2.64* - March 10th, 2017

* Several characters have been changed to make the R+14 speedrun category more interesting. These changes are experimental, and can be changed back to vanilla if people don't like it:
  * Isaac now starts with The Battery.
  * Maggy now starts with the Soul Jar, a new passive item. (Thanks to Gromfalloon for the custom Soul Jar graphics.)
  * The Soul Jar has the following effects:
    * You no longer gain health from soul/black hearts.
    * You gain an empty red heart container for every 4 soul/black hearts picked up.
    * You always have a 100% Devil Room chance if no damage is taken.
  * Eden now starts with the Schoolbag. They will start with her random active item inside the bag.
  * Lilith now starts with the Schoolbag. She will start with Box of Friends inside the bag.
  * Apollyon now starts with the Schoolbag. He will start with Void inside the bag.
* Fixed the bug where red chest teleports could kill you in certain situations.
* Fixed the bug where Eden would incorrectly retain the stats from their starting active item. (Thanks SlashSP)
* Fixed the bug where the Joker card would not work if you had Cursed Eye. (Thanks thereisnofuture)
* Fixed the bug where the current trinket for the diversity race would not display in the tooltip.
* Replaced the Glowing Hour Glass rewind process of starting a race with a better method. This should help people with potato computers.
* Moved a lot of code to the game physics callback; the game should run much faster now on potato computers.
* Fixed the bug where Cain and Samson's trinkets would incorrectly get smeltered in diversity races.
* Fixed the bug where the active item in a diveristy race would get fart-rolled if you swapped it for something else. Unfortunately, this means your random active item in diversity will not be removed from any pools. (Thanks Thoday)
* Fixed the bug where the item inside the Schoolbag would not appear on the item tracker in certain situations.
* Fixed the bug where trophies would appear for non-race goals. (Thanks PassionDrama)

### *v0.2.62* - March 9th, 2017

* Fixed the crash when you teleported to an L room. (Thanks to SlashSP for reporting and blcd for the code fix)
* Betrayal no longer pauses the game and plays an animation before charming enemies. (Thanks InvaderTim)
* Fixed some miscellaneous bugs with the end of race trophy. (Thanks tyrannasauruslex)
* Added D4 to the Lost's Schoolbag for seeded races. (Thanks Krakenos)
* The Schoolbag is a lot more responsive now and you can switch items much faster. Additionally, if you hold the switch button down, it will only switch the items once. (Thanks Cyber_1)
* Fixed the bug where stat caches were not properly updated after switching an item into a Schoolbag. (Thanks Cyber_1)
* Fixed the bug where costumes were not properly updated after switching an item into a Schoolbag. (Thanks Cyber_1)
* Blood Bag is no longer excluded from diversity starting passive items.
* Lucky Foot is now excluded from diversity starting passive items.
* Diversity races now start with the Schoolbag, a random active item, and a random trinket that is smelted. (Thanks to henry_92 for the idea.)
* Diversity races now show the 5 starting items on the starting screen so that you can easily see what the build is at the start of a run.

### *v0.2.61* - March 8th, 2017

* A trophy will now spawn at the end of races instead of a big chest. Touching the trophy will finish the race, but not end the game. A Forget Me Now will spawn in the corner of the room after touching a trophy, in case you want to keep playing around with your run while you wait for others in the race to finish. (If you defeat the boss again, another Forget Me Now will spawn.)
* Fixed the bug with duplicating trinkets. (Thanks Dea1h)
* Fixed the bug where under certain specific circumstances, players could obtain banned trinkets.
* Fixed the bug where you would die too early after taking a devil deal that killed you. (Thanks ceehe)
* Fixed the bug on the new Maggy where she would stay alive while at 0 red hearts and 0 soul hearts. (The new Maggy is still disabled by default.)
* Fixed the bug with Schoolbag and Crystal Ball / Mega Blast Placeholder. (Thanks Cyber_1)
* Fast-clear now applies to Fallens who have already split.
* Trinkets will now only be deleted from the starting room on the Pageant Boy ruleset. (Thanks Dea1h)
* The following items have been added to the Treasure Room item pool in diversity races, but ONLY on basement 1. They are generated when fart-rolled from a Mom's Knife, Epic Fetus, Tech X, and D4 respectively:
  * Incubus
  * Crown of Light
  * Godhead
  * Sacred Heart

### *v0.2.60* - March 7th, 2017

* Diversity Races now start with More Options. More Options is automatically removed after going into one Treasure Room.
* Summoning a co-op baby will now only delete unpurchased Devil Deal items (instead of all items). This is to prevent using the co-op baby beneficially in certain situations.
* We Need to Go Deeper! is no longer banned in races to The Lamb.

### *v0.2.59* - March 4th, 2017

* Fixed the bug with the Schoolbag where the charge sound would play every time you swapped in a fully charged item. (Thanks Cyber_1)
* Fixed the (vanilla) bug with Eden's Soul where it would not start off at 0 charges. (Thanks Krakenos)
* Crystal Ball is now seeded. (Thanks to Krakenos for reporting and blcd for figuring out the drop chances.)
* Portals are now seeded. (As a side effect of this, Portals will always spawn 5 enemies instead of 1-5 enemies. This means that focusing them down is more important now.)
* Mom's Hand and Mom's Dead hand will now immediately attack you if there is only one of them in the room.
* Removed Mom's Hand from Devil Room #13.
* Kappa will now take tab priority over Kadda. (InvaderTim fixed this, so thanks to him.)
* NotLikeThis will take tab priority over NootLikeThis. (InvaderTim fixed this, so thanks to him.)
* FrankerZ will take tab priority over the other Franker colors. (InvaderTim fixed this, so thanks to him.)
* Added sillyPoo and sillyPooBlack.

### *v0.2.58* - March 3rd, 2017

* Fixed various bugs with the new crawlspace, including getting flies on Keeper and ocassional crashes. (thanks Crafterlynx / Dea1h for reporting, and blcd for the code fix)
* Non-purchasable item pedestals in shops are now seeded.
* On seeded races, Scolex will automatically be replaced with 2 Frails.
* Fixed the bug where some items that were supposed to be banned were not being fart-rolled. (Thanks BMZ_Loop)
* Fixed the bug where the mod tried to load the "save.dat" file on every single frame. Now the mod should run much faster on potato computers.
* Fixed the bug where PMs weren't working. (InvaderTim fixed this, so thanks to him)
* Fixed the bug where emotes from Discord would look weird in the client lobby. (InvaderTim fixed this, so thanks to him)

### *v0.2.57* - March 2nd, 2017

* Made crawlspaces use normal room transition animations instead of the long fade.
* Removed the Blank Card animation when you use it with teleportation cards.
* Centered the Mega Maw in the single Mega Maw room on the Chest (#269). (Thanks REXmoreOP)
* Added a door to the double Mega Maw room on the Chest (#39).
* Fixed the (vanilla) bug where the door opening sound effect would play in crawlspaces.
* Fixed the bug where the Mega Blast placeholder was showing up in item pools instead of The Book of Sin. (Thanks Krakenos)

### *v0.2.55* - February 29th, 2017

* Fixed a client crash when you quit and continued as Lazarus II or Dark Judas.
* The countdown should lag a bit less on potato computers.
* Greatly sped up the attack patterns of Wizoobs and Red Ghosts.
* Removed invulernability frames from Lil' Haunts.
* Cursed Eye is now seeded. (This is now possible due to a change in the last patch.)
* Broken Remote is now seeded. (This is now possible due to a change in the last patch.)
* Broken Remote is no longer removed from seeded races.
* Fixed the bug with Schoolbag where items would have more charges than they were supposed to at the beginning of a race.
* Fixed the bug where The Book of Sin did not show up in the Schoolbag. (Thanks Krakenos)
* Fixed the bug where the Mega Blast placeholder did not show up in the Schoolbag.
* Fixed the bug where The Book of Sin would not count towards the Book Worm transformation. (Thanks Krakenos)
* Fixed the bug where The Polaroid / The Negative would not be removed under certain conditions.
* Fixed the bug where if you consumed a D6 with a Void and then tried to consume another pedestal, it would sometimes duplicate that pedestal. (Thanks henry_92)

### *v0.2.54* - February 28th, 2017

* Fast-clear now works with puzzle rooms.
* The timer that appears during races will now use real time instead of in-game frames, so it will be a lot more accurate. (This is now possible due to a change in the last patch.)
* Fixed a Larry Jr. room that should not have an entrance from the top. (Thanks BMZ_Loop)
* Added better save file graphics, thanks to Gromfalloon.
* Updated [the FAQ](https://isaacracing.net/info).
* Lobby chat is now transfered to the Discord #racing-plus-lobby channel, and vice versa.

### *v0.2.53* - February 27th, 2017

* The "drop" button will now immediately drop cards and trinkets. (This won't happen if you have the Schoolbag, Starter Deck, Little Baggy, Deep Pockets, or Polydactyly.)
* Holding R on Eden no longer kills them (since Nicalis fixed it in the vanilla game).
* Fixed the crash that occurred with Schoolbag when you swapped at the same time as picking up a new item.
* You will no longer recieve the Polaroid and get teleported to Womb 1 if you arrive at the Void floor (since Nicalis fixed the instant Void teleport).
* Removed the use animation from Telepills.
* Fixed a Basement/Cellar room that had a chance to spawn empty because of stacked entities.
* Fixed the Strength card on Keeper. Note that it will only permanently give you a coin container if you are at 0 or less base coin containers. (This is now possible due to a change in the last patch.)
* Added two new graphics for save files (fully unlocked and not fully unlocked).
* The Alt+C and Alt+V hotkeys should work more consistently now.

### *v0.2.49* - February 26th, 2017

* Teleport! is now seeded (per floor). This item is no longer removed in seeded races.
* Undefined is now seeded (per floor). This item is no longer removed in seeded races.
* Telepills is now seeded (per floor, separately from Teleport!).
* Broken Remote is now banned during seeded races.
* Fixed unavoidable damage in an I AM ERROR room where you would teleport on top of a Spiked Chest.
* Cleaned up the door placements on some miscellaneous I AM ERROR rooms to ensure that the player always teleports to an intended location.
* Fixed the I AM ERROR room without any entrances.
* Fixed some more out of bounds entities.
* Deleted the 2x2 Depths/Necropolis with 2 Begottens (#422), since they automatically despawn due to a bug.
* Fixed the bug where the damage cache was not properly updated after having Polyphemus and then picking up The Inner Eye or Mutant Spider.
* The title screen has been updated to a beautiful new one created by Gromfalloon.
* Fixed an asymmetric Scarred Guts on a Womb/Utero L room (#757).
* Fixed a Little Horn room (#1095) where there was only a narrow entrance to the top and bottom doors.

### *v0.2.48* - February 22nd, 2017

* Pressing the reset button on Eden now instantly kills them. (It is not currently possible to fix the resetting bug in a proper way.)
* There will no longer be sound notifications when someone starts a solo races.
* There will no longer be text notifications when someone starts a solo races.
* There will no longer be text notifications when a test account connects or disconnects.
* Fixed the bug where the diversity question marks would stay on the client in future races. (Thanks Birdie0)

### *v0.2.45* - February 21st, 2017

* Co-op baby detection has been rewritten (thanks to Inschato). Now when you spawn a baby, it will:
  1. play AnimateSad
  2. automatically kill the baby
  3. delete all item pedestals in the room
* The new detection also fixes the bug where co-op babies would make the game crash under certain conditions.
* The new detection also fixes the bug where trying to skip cutscenes would damage you and/or kill you.
* Solo races now start in 3 seconds instead of 10. If this seems too fast for you, remember that you can use the Alt+R hotkey to ready up while inside the game.
* Fixed a bug where "Go!" would appear before the numbers in the countdown on potato computers.
* Fixed a bug where race graphics would stay on the screen after you quit the client.

### *v0.2.44* - February 21st, 2017

* Fixed the bug where the "1" graphic would stay on the screen for the whole race under certain conditions.
* The Schoolbag will now only be enabled in seeded races. (Having Schoolbag at all is still experimental.)
* Fixed the bug with Schoolbag where the D6 would not be fully charged when the race started under certain conditions.
* The Schoolbag will no longer allow a swap if you are in the "item pickup" animation. This fixes the bug where it would delete your D6.
  * If you swap at the exact time that you pickup a new active item, the game will crash. Don't do this.
* Finishing or quitting a race will now automatically reset your "save.dat" file to defaults. This will help in cleaning up post-race related artifacts in-game.
* Added [a new file](https://github.com/Zamiell/isaac-racing-client/blob/master/mod/README-DIVERSITY.md) for diversity documentation.
* Fixed the icons for A Dollar, A Quarter, and Money Equals Power in diversity races.
* It is no longer possible to start with Dad's Lost Coin or Moldy Bread in diversity races.

### *v0.2.43* - February 20th, 2017

* All characters now start with the Schoolbag from Antibirth. This is experimental.

### *v0.2.42* - February 19th, 2017
* Keeper now starts with the D6 and 4 coin containers (along with Greed's Gullet and Duality).
* Fixed the bug where the D6 doesn't get removed from the pools on Keeper. (Thanks @HauntedQuest)
* The client window is now resiable from the top. (Thanks @tODDlife)
* Fixed the bug where the doors would open prematurely under certain conditions.

### *v0.2.41* - February 17th, 2017

* The title screen is now better.
* Fixed the bug with seeded races where it would show question marks for the build.
* Fixed the bug with Keeper and Greed's Gullet.
* If you spawn a co-op baby, the mod will automatically kill you.

### *v0.2.40* - February 16th, 2017

* Added the old Afterbirth item bans to diversity races. (The item synergy bans from Afterbirth are not included.)
* Added D Infinity as a new diversity item ban.
* Diversity items are now hidden until the race starts.
* Added the "<3" and ":thinking:" emoticons.
* Fast room-clear now applies to Krampus.

### *v0.2.38* - February 15th, 2017

* If you try to use the Sacrifice Room to teleport to the Dark Room, it will now send you to the next floor instead.
* Fixed the bug where the countdown graphic would stay on the screen for longer than it should.

### *v0.2.36* - February 14th, 2017

* Diversity races have been added to the Racing+ platform as a third race format.

### *v0.2.33* - February 13th, 2017

* Fixed the Mega Blast build for seeded races. If you try to use Mega Blast before The Hourglass, you will get an "error" sound, and it won't work. This is by design, because the game is bugged such that using Glowing Hour Glass while a Mega Blast is underway doesn't actually delete the beam.

### *v0.2.29* - February 12th, 2017

* Added a global Alt+B hotkey to launch the game.
* The "Race completed" sound effect will no longer play for solo races.
* Added "Custom" as a new race format. In this format, you can ready up and finish manually. This means you can now you can race the vanilla game (or custom mods) on the Racing+ platform.
* Added an Alt+F hotkey for finishing. This only works in the new "Custom" format.
* More countdown sounds have been added (from Mario Kart: Double Dash).
* In the client, you can now hover over emotes to see what they are.
