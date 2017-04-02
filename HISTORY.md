# Racing+ Version History


Patch notes for v0.4.15:
* Fixed the bug where the beam of light would not work after Hush. (Thanks StoneAgeMarcus)
* Fixed the bug that caused unseeded weirdness on seeded races. (Thanks blcd for discovering why this happened)
* The Polaroid (and The Negative) will no longer spawn in an off-center position.
* The beam of light (and trapdoor) after It Lives! and Hush will no longer spawn in an off-center position.
* The beam of light and trapdoor will now despawn based on whether you have The Polaroid or The Negative instead of the race goal.
* Made the custom stage text disappear quicker. (Thanks LogBasePotato)
* Changed "???" to "Blue Baby" on the character select screen. (Thanks to nicoluwu for the artwork.)

Patch notes for v0.4.12:
* Added custom floor notification graphics for every floor in the game. (Fast-travel doesn't trigger the vanilla notifications.)
* You are no longer automatically sent to the "Race Room" if you join a race. (You will only be sent there if you start a new run.) Going to the "Race Room" in between races is entirely optional, since all races start with a reset. (Thanks tyrannasauruslex)
* Trapdoors will now properly show as Womb Holes on floors 6 and 7. (Thanks tyrannasauruslex)
* Fixed the bug where using a Strength or Huge Growth card before entering a trapdoor would make you keep the increased size forever. (Thanks blcd and tyrannasauruslex)
* Fixed the bug where pickups would sometimes spawn inside Stone Grimaces and the like. (Thanks CrafterLynx)
* Fixed the bug where you could use a card or a pill before jumping out of the hole when coming from another floor.

Patch notes for v0.4.9:
* It is pretty unfair when a Mimic chest spawns behind you and your body is blocking the two spike tells. (Or, alternatively, if the Mimic is behind a dying enemy.) To rectify this problem, Mimic chests now have a custom "Appear" animation if they spawn within a certain distance of the player. If you want to see this in action, use the "spawn mimic" console command. If you get hit by a mimic chest and you feel that it wasn't your fault or that it was unfair, show me the clip and we can continue to work on it.  (Thanks Dea1h and tyrannasauruslex)
* Fixed the bug where the Butter! trinket wouldn't work properly with the Schoolbag. (Thanks MrNeedForSpeed96)
* Fixed the bug where trapdoors would be duplicated in rooms that weren't connected to the level grid under certain circumstances. (Thanks thereisnofuture)
* Reduced the delay on the Womb 2 beam of light from 60 frames to 40. This is just short enough that you will be hit by the wave of tears before going up. (Thanks Krakenos)
* Fixed the bug where Conjoined Fatties would make the doors open early in certain circumstances. (Thanks PassionDrama)
* Fixed the bug where the unavoidable damage prevention code for Mimics was not firing properly. (Thanks tyrannasauruslex)
* Fixed the unavoidable damage room in the Caves/Catacombs with 5 Crazy Long Legs by removing 1 Crazy Long Legs to make it a bit easier (#862). (Thanks Cyber_1)
* The on-screen timer now uses custom sprites and looks a lot better.
* Replaced all of the Rules card text snippets with educational history.

Patch notes for v0.4.7:
* You can now do a Schoolbag switch during the "use item" animation. This is a big buff to the item. PogCena
* Chargebars are now minimialistic and actually good.
* Changed the Broken Modem sprite to one that isn't complete garbage. (I got it from freeze, the original author of the item.)
* Trapdoors will now be shut if you enter a room and are standing near to them. (This is also how it works in vanilla. Thanks Cyber_1)
* Fixed the bug where trapdoors would disappear in certain circumstances.
* Fixed the bug where a rock could occupy the same square as a trapdoor or crawlspace under certain conditions. (Thanks CrafterLynx)
* Fixed the bug where the starting items for seeded and diversity races would not show up. (Thanks PassionDrama)
* Fixed the client bug where the question mark icon would not show up next to the build on the new race tooltip.
* Fixed the client bug where the build column would not show in seeded races. (Thanks vertopolkaLF)`

Patch notes for v0.4.5:
* For races to Mega Satan and races that are already completed, the Mega Satan door will be automatically opened. (This is simpler than placing a Get Ouf of Jail Free Card next to the door.)
* Fast-travel no longer applies to the portal to the Blue Womb. This fixes the bug where the Blue Womb trapdoor would take you to Sheol instead of the Blue Womb. (Thanks Dea1h)
* Fixed the bug where Dr. Fetus bombs could be shot while jumping through the new trapdoors. (Thanks PassionDrama & tyrannasauruslex)
* The 13 luck for the Fire Mind build is now a custom item called "13 Luck". It should now function properly with other items. (Thanks thisguyisbarry)
* Reduced the delay for the beam of light in the Cathedral to 16 frames. (Thanks Dea1h)
* Made the fast-reset feature work for people who have reset bound to shift. (Thanks MasterofPotato)
* Fixed an unavoidable damage room in the Caves (#167). (Thanks Dea1h)


Patch notes for v0.4.3:
* The hitbox on trapdoors and crawlspaces was slightly larger than it was on vanilla due to having to override the vanilla entities. Racing+ now uses custom entities for these, which fixes the bug where you would sometimes accidently walk into a trapdoor while entering a Devil Room, for example. This also fixes the bug where you would sometimes skip a floor when going in a trapdoor.
* Fixed the bug where your blue flies / spiders would kill themselves on the custom floor transition hole. (Thanks CrafterLynx)
* Fixed the crash when a diversity race started with Booster Pack #1 items. (Thanks stoogebag)
* Fixed the bug where your character would move to the center of the room upon coming back from a crawlspace.
* Fixed the bug where you would be in a weird spot after returning to the Boss Room after coming back from a Boss Rush with a crawlspace in it.
* Fixed the bug where people with controllers would not be able to use the fast-reset feature in some circumstances. (Thanks Krakenos)
* Fixed the bug with the Pageant Boy ruleset where the trinket was not getting deleted.
* Fixed the bug with the Pageant Boy ruleset where it was not detecting the ruleset on the first run after opening the game.

Patch notes for v0.4.0:
* When starting a new run, Racing+ will now automatically put on the "Total Curse Immunity" Easter Egg for you (the "BLCK CNDL" seed). If Basement 1 happened to have a curse on it, the run will be automatically restarted. Rejoice, and be merry. https://www.youtube.com/watch?v=tHvnxbtHqsE
* The racing system was rewritten such that you should never have to go back to the menu in between races anymore (unless you need to change your character). You will now start the race in an isolated room, and all races will start by resetting the game.
* Seeded races will automatically start you on the correct seed; you do not have to type it in anymore.
* Pressing the reset key will now instantly reset the game. (This change is experimental.)
* Racing+ now validates that you are not on a challenge before letting you ready up.
* Racing+ now has some new pre-race graphics, including showing you the goal. (Thanks stoogebag)
* The long and annoying fade out / fade in animation between floors has been replaced with something better. (Thanks PassionDrama for helping test)
* The Schoolbag will now work properly with the new Booster Pack items. (Thanks meepmeep)
* Diversity races that start with the new Booster Pack items will now work properly. (Thanks BMZ_Loop)
* Fixed the unavoidable damage when Spiked Chests or Mimics spawn in Caves/Catacombs room #19. (Thanks PassionDrama)
* In diversity races, when you pick up Crown of Light from a Basement 1 Treasure Room, it will now heal you for half a heart if you are not already at full red hearts. (Thanks Dea1h)
* Fixed the bug where banned items would roll into other banned items under certain conditions. (Thanks Lobsterosity)
* If Eden starts with Book of Sin, Crystal Ball, Betrayal, or Smelter, she will now start with the Racing+ custom version of the item.

News:
* Now that the Mom's Hand change has been played for a while, I've asked around for feedback. Almost everyone likes the change, so it will remain in the game permanently.

Patch notes for v0.3.2:
* Made the mod work with the new patch.
* Increased the pedestal pickup delay from 10 to 15.
* Fixed the bug where the Schoolbag item would be overwritten under certain conditions.
* Fixed the (vanilla) bug where stuff on the bottom left hand corner of the title screen was cut off.
* Fixed the bug where banned items could roll into other banned items. (Thanks PassionDrama)

Patch notes for v0.3.0:
* The size of the mod has been reduced by around 12 MB. (Thanks ArseneLapin)
* Fixed a bug that prevents the lobby from being loaded in certain circumstances. (Thanks Gandi)
* Fixed a bug where the "Enable Boss Cutscenes" checkbox was not working in certain circumstances. (Thanks Lex)

Patch notes for v0.2.85:
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

Patch notes for v0.2.77:
* Fixed the bug where in certain circumstances, the client was not able to find the Racing+ mod directory.
* Trinkets consumed with the Gulp! pill will now show up on the item tracker. (This only works if you are using the Racing+ mod.)
* Fixed the bug where some glowing item & trinket images were not showing up properly on the starting room. (Thanks Krakenos)
* Fixed the bug where starting the Boss Rush would not grant a charge to the Schoolbag item. Note that actually clearing the Boss Rush still won't give any charges, due to limiations with the Afterbirth+ API. (Thanks Dea1h, who saw it on tyrannasauruslex's stream)
* Fixed the bug where fart-reroll items would start at 0 charges. (Thanks Munch, who saw it on tyrannasauruslex's stream)
* The Polaroid and The Negative are no longer automatically removed in the Pageant Boy ruleset.
* The beam of light and the trapdoor are no longer automatically removed after It Lives! in the Pageant Boy ruleset.
* The big chests after Blue Baby, The Lamb, and Mega Satan will now be automatically removed in the Pageant Boy ruleset.
* Fixed the Schoolbag sprite bug when starting a new run in the Pageant Boy ruleset.


Patch notes for v0.2.74:
* Upon finishing a race, a flag will now spawn in addition to the Victory Lap. You can touch the flag to take you back to the menu. (Thanks Birdie)
* The Pageant Boy ruleset now has item bans for the starting items.
* The Pageant Boy ruleset now starts with +7 luck.
* Before a race, you will now see the race type and the race format next to the Gaping Maws.
* Before a race, you will see an indication of whether you are ready or not.
* Seeded races now show the starting item / starting build in a manner similar to diversity races.
* Items shown on the starting room in seeded & diversity races now have a glow so that it is easier to see them. (The glow images were taken from the item tracker.)
* Fixed the bug where you could see the diversity items early under certain conditions. (Thanks Lobsterosity, Ou_J, and Cyber_1)
* Fixed the bug where enemies spawned after touching the trophy under certain conditions. (Thanks MasterofPotato, Ou_J, and Cyber_1)
* Fixed the bug where on seeded races, the door to the Treasure Room that was inside a Secret Room would behave weirdly on Basement 1.
* Fixed the bug where the depths STB wasn't getting loaded. (Thanks Lobsterosity)

Patch notes for v0.2.73:
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

Patch notes for v0.2.72:
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
* Added the FeelsAmazingMan emote. (Requested by MasterofPotato)
* Added the DICKS emote. (Requested by MasterofPotato)
* Added the YesLikeThis emote. (Requested by MasterofPotato)
* Fixed a bug with the "/r" command on the client. (Thanks to InvaderTim for coding this.)
* The lobby users list is now properly alphabetized. (Thanks to InvaderTim for coding this.)
* Your "save.dat" file will no longer be overwritten if the client encounters an error and you restart the program. This fixes the error message that tells you to restart in the middle of your run. (Thanks henry_92)
* Fixed the bug where the in-game timer would disappear from the screen once you finished the race.

Patch notes for v0.2.71:
* Previously, pickup delay on pedestals was only reduced for freshly spawned pedestals. Pedestal delay is also set to 18 upon entering a new room, so this class of delay is reduced to 10 as well.
* Fixed the bug where Keeper would get stuck on 24, 49, or 74 cents. (Thanks Crafterlynx)
* Fixed the bug with Schoolbag where if you took damage at the same time as picking up a second active item, it would delete it. (Thanks Ou_J)
* Fixed the bug with Mom's Hands and Mom's Dead Hands where they would stack on top of each other when falling at the exact same time. Instead of falling with a 30 frame timer, they will now fall with a random 25 to 35 frame timer. (Thanks ceehe)
* Fixed the bug where the Lil' Haunts on The Haunt fight would be messed up. (Thanks Thoday)

Patch notes for v0.2.70:
* Increased the pickup delay on pedestal items from 0 to 10. (On vanilla, it is 20.)
* All boss heart drops are now seeded. This was a nightmare to do.
* Mom's Hands and Mom's Dead Hands will now fall faster even if there is more than 1 in the room.
* It is no longer possible to start with D4, D100, or D Infinity as the random active item in diversity races.
* Fixed a crash that occured in the client on diversity races that gave Betrayal.
* Cursed Eye no longer overrides Cursed Skull. (Thanks Cyber_1)
* Cursed Eye no longer overrides Devil Room teleports from Red Chests. (Thanks Dea1h & Lex)
* The Schoolbag will now work properly with the Glowing Hour Glass. (Thanks TheMoonSage)
* PMs will no longer give an error message when the recipient is online. (Thanks to InvaderTim for coding this.)
* You can now use the "/r" command to reply to PMs. (Thanks to InvaderTim for coding this.)

Patch notes for v0.2.69:
* Fixed the bug where some items would not render properly in the Schoolbag. (Thanks Krakenos)
* Fixed the path to the mods folder on Linux. (Thanks Birdie)
* Changed the caves room with the black heart surrounded by blocks (#267) to the way that Edmund intended it to be.
* Added the OhMyDog emote.
* Added the DatSheffy emote.

Patch notes for v0.2.68:
* The Soul Jar effects are now based on whether you hold the item (instead of being tied to the Magdalene character specifically). (Thanks Cyber_1)
* The Schoolbag now works the same way as it does in Antibirth when you only have one active item. (Thanks Cyber_1)
* Fixed the bug where the Schoolbag item would sometimes not appear when first starting a run. (Thanks Cyber_1)
* The Racing+ mod will now work on Linux. (Thanks mithrandi)
* Fixed the bug where the AAA Battery did not work with the Schoolbag. (Thanks Dea1h)
* Fixed the bug where the race timer would not appear. (Thanks Krakenos)
* Fixed the bug where the format & goal tooltips in the client were wrong. (Thanks vertopolkaLF)
* Fixed the bug where the question mark icon for the random character would not show. (Thanks Birdie)

Patch notes for v0.2.67:
* Removed the annoying vanilla delay where you are not able to take a pedestal item immediately after it spawns. PogCena
* Fixed the (vanilla) bug where double coins and nickels would not heal Keeper for their proper amount. (Thanks Victor23799)
* Fixed the client crash that occured whenever The Book of Sin, Crystal Ball, or Betrayal were given in a diversity race.
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
* Added the Catgasm emote to the client. (Requested by masterofpotato)

Patch notes for v0.2.66:
* Refactored all of the code for the Lua mod. It is now split up across multiple files instead of in one giant file. If there are any new in-game bugs with this new patch, it's probably due to this. (Thanks to sillypears and Chronometrics for the help.)
* Fixed the bug where the game would softlock if you entered a crawlspace from a Bossh Rush. (Thanks Dea1h)
* Fixed the bug where the AAA Battery would not do anything. (I'm suprised nobody noticed this.)
* Fixed the (vanilla) bug where the AAA Battery would not synergize with The Battery.
* Fixed the (vanilla) bug where the 9 Volt would not synergize with The Battery.
* Fixed the bug with diversity races where starting with active items that granted consumables would not grant those consumables. (Thanks PassionDrama)
* Fixed the bug where the Gaping Maws would sometimes appear after a race had already started. (Thanks Lobsterosity)
* Changed the build option "Random (D6 builds only, 1-30)" to "Random (single items only, 1-26)", since all the builds include the D6 now.
* Made the lobby race table more compact and neat.
* Added the BibleD emote (requested by Birdie).
* Added the FutureMan emote (requested by Lobsterosity).

Patch notes for v0.2.65:
* tODDlife has officially joined the staff, charged with Community Relations.
* Updated the FAQ with various things at: https://isaacracing.net/info
* Fixed the bug where the trophy would drop instead of a chest when you were not in a race. (Thanks Krakenos/Dea1h/CrafterLynx/thisguyisbarry/Victor23799)
* Warning messages (like "Error: Turn on the "BLCK CNDL" Easter Egg.") will no longer show in big rooms. (Thanks dion)
* Changed the Alt+C and Alt+V hotkeys to work more reliably.
* Resetting is now disabled when the countdown is between 2 and 0 seconds in order to prevent bugs on potato computers. (Thanks Krakenos)
* Fixed the bug with The Book of Sin taking away charges when the player had The Battery. (Thanks HauntedQuest)
* Finally fixed the annoying bug where in big races you couldn't see all the people in the race properly. (Thanks SedNegi & stoogebag)
* Fixed the bug where if too many races were open, the lobby would mess up and overflow.
* The Kamikaze! and Mega Blast builds will now correctly use the Schoolbag to keep the D6. (Thanks Anti)

Patch notes for v0.2.64:
* Isaac now starts with The Battery. (This is to make the R+14 speedrun category more interesting, but is experimental, and can be changed back to vanilla if people don't like it.)
* Maggy now starts with the Soul Jar, a new passive item. (This is to make the R+14 speedrun category more interesting, but is experimental, and can be changed back to vanilla if people don't like it.)
* The Soul Jar has the following effects:
  * You no longer gain health from soul/black hearts.
  * You gain an empty red heart container for every 4 soul/black hearts picked up.
  * You always have a 100% Devil Room chance if no damage is taken.
  * (The 9% Devil Room chance thing in the old Soul Jar is removed.)
  * (Thanks to Gromfalloon for the custom Soul Jar graphics.)
 * Eden now starts with the Schoolbag. She will start with her random active item inside the bag. (This is to make the R+14 speedrun category more interesting, but is experimental, and can be changed back to vanilla if people don't like it.)
 * Lilith now starts with the Schoolbag. She will start with Box of Friends inside the bag. (This is to make the R+14 speedrun category more interesting, but is experimental, and can be changed back to vanilla if people don't like it.)
 * Apollyon now starts with the Schoolbag. He will start with Void inside the bag. (This is to make the R+14 speedrun category more interesting, but is experimental, and can be changed back to vanilla if people don't like it.)
* Fixed the bug where in certain specific situations red chest teleports could kill you.
* Fixed the bug where Eden would incorrectly retain the stats from her starting active item. (Thanks SlashSP)
* Fixed the bug where the Joker card would not work if you had Cursed Eye. (Thanks thereisnofuture)
* Fixed the bug where the current trinket for the diversity race would not display in the tooltip.
* Replaced the Glowing Hour Glass rewind process of starting a race with a better method. This should help people with potato computers.
* Moved a lot of code to the game physics callback; the game should run much faster now on potato computers.
* Fixed the bug where Cain and Samson's trinkets would incorrectly get smeltered in diversity races.
* Fixed the bug where the active item in a diveristy race would get fart-rolled if you swapped it for something else. Unfortunately, this means your random active item in diversity will not be removed from any pools. (Thanks Thoday)
* Fixed the bug with Schoolbag where the item inside the Schoolbag did not appear on the item tracker in certain situations.
* Fixed the bug where trophies would appear for non-race goals. (Thanks PassionDrama)

Patch notes for v0.2.62:
* Fixed the crash when you teleported to an L room. (Thanks to SlashSP for reporting and Will/blcd for the code fix)
* Betrayal no longer pauses the game and plays an animation before charming enemies. (Thanks InvaderTim)
* Fixed some miscellaneous stuff with the end of race trophy. (Thanks Lex)
* Added D4 to the Lost's Schoolbag for seeded races. (I missed this initially; thanks Krakenos)
* The Schoolbag is a lot more responsive now * you can switch items much faster. Additionally, if you hold the switch button down, it will only switch the items once. (Thanks Cyber_1)
* Fixed the bug where stat caches were not properly updated after switching an item into a Schoolbag. (Thanks Cyber_1)
* Fixed the bug where costumes were not properly updated after switching an item into a Schoolbag. (Thanks Cyber_1)
* Blood Bag is no longer excluded from diversity starting passive items.
* Lucky Foot is now excluded from diversity starting passive items.
* Diversity races now start with the Schoolbag, a random active item, and a random trinket that is smelted. (This is henry's idea.)
* Diversity races now show the 5 starting items on the starting screen so that you can easily see what the build is at the start of a run.

Patch notes for v0.2.61:
* A trophy will now spawn at the end of races instead of a big chest. Touching the trophy will finish the race, but not end the game. A Forget Me Now will spawn in the corner of the room after touching a trophy, in case you want to keep playing around with your run while you wait for others in the race to finish. (If you defeat the boss again, another Forget Me Now will spawn.)
* Fixed the bug with duplicating trinkets. (Thanks Dea1h)
* Fixed the bug where under certain specific circumstances, players could obtain banned trinkets.
* Fixed the bug where you would die too early after taking a devil deal that killed you. (Thanks ceehe)
* Fixed the bug on the new Maggy where she would stay alive while at 0 red hearts and 0 soul hearts. (The new Maggy is still disabled by default.)
* Fixed the bug with Schoolbag and Crystal Ball / Mega Blast Placeholder. (Thanks Cyber_1)
* Fast-clear now applies to Fallens who have already split.
* Trinkets will now only be deleted from the starting room on the Pageant Boy ruleset. (Thanks Dea1h)
* The following items have been added to the Treasure Room item pool in diversity races, but ONLY on basement 1:
  (they are generated when fart-rolled from a Mom's Knife, Epic Fetus, Tech X, and D4 respectively)
    * Incubus
    * Crown of Light
    * Godhead
    * Sacred Heart

Patch notes for v0.2.60:
* Diversity Races now start with More Options. More Options is automiatcally removed after going into one Treasure Room.
* Summoning a co-op baby will now only delete unpurchased Devil Deal items (instead of all items). (This is to prevent using the co-op baby beneficially in certain situations.)
* We Need to Go Deeper! is no longer banned in races to The Lamb.

Patch notes for v0.2.59:
* Fixed the bug with the Schoolbag where the charge sound would play every time you swapped in a fully charged item. (Thanks Cyber_1)
* Fixed the (vanilla) bug with Eden's Soul where it would not start off at 0 charges. (Thanks Krakenos)
* Crystal Ball is now seeded. (We apparently never noticed this before. Now everything in the game should be seeded for real!) (Thanks Krakenos for reporting and Will/blcd for figuring out the drop chances)
* Portals are now seeded. (As a side effect of this, Portals will always spawn 5 enemies instead of 1-5 enemies. This means that focusing them down is more important now.)
* Mom's Hand and Mom's Dead hand will now immediately attack you if there is only one of them in the room.
* Removed Mom's Hand from Devil Room #13.
* Emote changes:
    * Kappa will now take tab priority over Kadda. (InvaderTim fixed this, so thanks to him.)
    * NotLikeThis will take tab priority over NootLikeThis. (InvaderTim fixed this, so thanks to him.)
    * FrankerZ will take tab priority over the other Franker colors. (InvaderTim fixed this, so thanks to him.)
    * Added sillyPoo and sillyPooBlack.

Patch notes for v0.2.58:
* Fixed various bugs with the new crawlspace (free flies on keeper + ocassionally crashes) (Thanks Crafterlynx / Dea1h for reporting, and blcd/Will for the code fix)
* Non-purchasable item pedestals in shops are now seeded.
* On seeded races, Scolex will automatically be replaced with 2 Frails. Don't try to kill both at the same time, or you'll have a bad time. (And this shouldn't happen on unseeded races anymore, thanks Krakenos.)
* Fixed the bug where some items that were supposed to be banned were not being fart-rolled. (Thanks BMZ_Loop)
* Fixed the bug where the mod tried to load the save.dat file on every single frame. (oops) Now the mod should run much faster on potato computers.
* Fixed the bug where PMs weren't working. (InvaderTim fixed this, so thanks to him)
* Fixed the bug where emotes from Discord would look weird in the Racing+ lobby. (InvaderTim fixed this, so thanks to him)

Patch notes for v0.2.57:
* Made crawlspaces use normal room transition animations instead of the long fade. PogCena
* Removed the Blank Card animation when you use it with teleportation cards.
* Centered the Mega Maw in the single Mega Maw room on the Chest (#269). (Thanks REXmoreOP)
* Added a door to the double Mega Maw room on the Chest (#39).
* Fixed the (vanilla) bug where the door opening sound effect would play in crawlspaces.
* Fixed the bug where the Mega Blast placeholder was showing up in item pools instead of The Book of Sin. (Thanks Krakenos)

Patch notes for v0.2.55:
* Fixed a client crash when you quit and continued as Lazarus II or Black Judas.
* The countdown should lag a bit less on potato computers.
* Greatly sped up the attack patterns of Wizoobs and Red Ghosts. PogCena
* Removed invulernability frames from Lil' Haunts. PogCena
* Cursed Eye is now seeded. (I'm finally able to do this due to some added callback functionality that they added in the last patch.)
* Broken Remote is now seeded. (I'm finally able to do this due to some added callback functionality that they added in the last patch.)
* Broken Remote is no longer removed from seeded races. (Everything in the game is now seeded!!!!!)
* Fixed the bug with Schoolbag where items would have more charges than they were supposed to at the beginning of a race.
* Fixed the bug where The Book of Sin did not show up in the Schoolbag. (Thanks Krakenos)
* Fixed the bug where the Mega Blast placeholder did not show up in the Schoolbag.
* Fixed the bug where The Book of Sin would not count towards the Book Worm transformation. (Thanks Krakenos)
* Fixed the bug where The Polaroid / The Negative would not be removed sometimes.
* Fixed the bug where if you consumed a D6 with a Void and then tried to consume another pedestal, it would sometimes duplicate that pedestal. (Thanks Henry)

Patch notes for v0.2.54:
* Fast-clear now works with puzzle rooms. PogCena
* The timer that appears during races will now use real time instead of in-game frames, so it will be a lot more accurate. (This is now possible due to a change in the last patch.)
* Fixed a Larry Jr. room that should not have an entrance from the top. (Thanks BMZ_Loop)
* Added better save file graphics, thanks to Gromfalloon.
* Updated the FAQ at: https://isaacracing.net/info
* Lobby chat is now transfered to the Discord #racing-plus-lobby channel, and vice versa.

Patch notes for v0.2.53:
* The "drop" button will now immediately drop cards and trinkets. (This won't happen if you have the Schoolbag, Starter Deck, Little Baggy, Deep Pockets, or Polydactyly.) PogCena
* Holding R on Eden no longer kills her (since they fixed it in the vanilla game).
* Fixed the crash that occured with Schoolbag when you swapped at the same time as picking up a new item.
* You will no longer recieve the Polaroid and get teleported to Womb 1 if you arrive at the Void floor (since they fixed the instant Void teleport).
* Removed the use animation from Telepills, because it is pointless.
* Fixed a Basement/Cellar room that had a chance to spawn empty because of stacked entities.
* Fixed the Strength card on Keeper, due to some new Lua goodies delivered in the last patch. Note that it will only permanently give you a coin container if you are at 0 or less base coin containers.
* Added two new graphics for save files (fully unlocked and not fully unlocked).
* The Alt+C and Alt+V hotkeys should work more consistently now.

Patch notes for v0.2.49:
* Teleport! is now seeded (per floor). This item is no longer removed in seeded races.
* Undefined is now seeded (per floor). This item is no longer removed in seeded races.
* Telepills is now seeded (per floor, separately from Teleport!).
* Broken Remote is now banned during seeded races. (I forgot to do this initially.)
* Fixed an unavoidable damage I AM ERROR room where you would teleport on top of a Spiked Chest.
* Cleaned up the door placements on some miscellaneous I AM ERROR rooms to ensure that the player always teleports to an intended location.
* Fixed the I AM ERROR room without any entrances.
* Fixed some more out of bounds entities.
* Deleted the 2x2 Depths/Necropolis with 2 Begottens (#422), since they automatically despawn due to a bug.
* Fixed the bug where the damage cache was not properly updated after having Polyphemus and then picking up The Inner Eye or Mutant Spider.
* Updated the "HISTORY.md" file for the Lua mod.
* The title screen has been updated to a beautiful new one created by Gromfalloon.
* Fixed an asymmetric Scarred Guts on a Womb/Utero L room (#757).
* Fixed a Little Horn room (#1095) where there was only a narrow entrance to the top and bottom doors.

Patch notes for v0.2.48:
* Pressing the reset button on Eden now instantly kills her. (It is not possible to fix the resetting bug in a proper way.)
* There will no longer be sound notifications for people starting solo races.
* There will no longer be text notifications for people starting solo races.
* There will no longer be text notifications for test accounts connecting or disconnecting.
* Fixed the bug where the Diversity question marks would stay on the screen in future races. (Thanks Birdie0)

### *v0.2.45* - 

* Co-op baby detection has been rewritten (thanks to Inschato). Now when you spawn a baby, it will:
  1) play AnimateSad
  2) automatically kill the baby
  3) delete all item pedestals in the room
  * This fixes the bug where co-op babies would make the game crash under certain conditions.
  * This also fixes the bug where trying to skip cutscenes would damage you and/or kill you.
* Solo races now start in 3 seconds instead of 10. If this seems too fast for you, remember that you can use the Alt+R hotkey to ready up while inside the game.
* Fixed a bug where "Go!" would appear before the numbers in the countdown on potato computers.
* Fixed a bug where race graphics would stay on the screen after you quit the Racing+ client.

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

### *v0.2.43* - February 19th, 2017

* All characters now start with the Schoolbag from Antibirth. This is experimental.

### *v0.2.42* - February 19th, 2017
* Keeper now starts with the D6 and 4 coin containers (along with Greed's Gullet and Duality).
* Fixed the bug where the D6 doesn't get removed from the pools on Keeper. (thanks @HauntedQuest)
* The client window is now resiable from the top. (thanks @tODDlife)
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

* Diversity races have been added to the Racing+ platform as the third race format.

### *v0.2.33* - February 13th, 2017

* Fixed the Mega Blast build for seeded races. If you try to use Mega Blast before The Hourglass, you will get an "error" sound, and it won't work. This is by design, because the game is bugged such that using Glowing Hour Glass while a Mega Blast is underway doesn't actually delete the beam.

### *v0.2.29* - February 12th, 2017

* Added a global Alt+B hotkey to launch the game.
* The "Race completed" sound effect won't play for solo races.
* Added "Custom" as a new race format. In this format, you can ready up and finish all on your own. This means you can now you can race the vanilla game (or custom mods) on the Racing+ platform.
* Added an Alt+F hotkey for finishing. This only works in the new "Custom" format.
* More countdown sounds have been added (from Mario Kart: Double Dash).
* In the client, you can now hover over emotes to see what they are.
