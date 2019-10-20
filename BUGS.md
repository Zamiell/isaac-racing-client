# Racing+ Known Bugs

<br />

## Known Bugs with the Racing+ Mod (e.g. gameplay)

Some bugs are not fixable due to the limitations of the Afterbirth+ Lua API.

* Various bugs will happen if you alternate between playing two different runs on two different save files.
* Fast-clear does not apply to Challenge Rooms or the Boss Rush.
* Clearing waves of Challenge Rooms or the Boss Rush won't give any charges to an item in a Schoolbag.
* When returning to the Boss Rush from a crawlspace, the camera will jerk from the door to the location of the crawlspace.
* If you put A Pony or a White Pony into the Schoolbag during the charge, you won't be able to shoot tears. Saving and quitting fixes this.
* If you put Telekinesis into the Schoolbag while the effect is active, your other item will be drained. (Found by TaKer093)
* If you put Unicorn Stump or My Little Unicorn inside a Schoolbag, it will prematurely end any type of shield. (Found by thisguyisbarry)
* If you have Breath of Life inside a Schoolbag, it will automatically be dropped by the Butter! trinket if you hold down the "use item" button instead of immediately releasing it. (Found by Thoday)
* If you "overkill" a Red Champion (such that it does not leave a red flesh pile), fast-clear will not trigger.
* If a Globin spawns as a Red Champion, fast clear will trigger after killing the first flesh-pile instead of after the second one. (Reported by Ibotep)
* If The Forgotten or The Soul falls into a pitfall and dies, then the game will lock up for a few seconds. (Reported by Gamonymous)
* In a multi-character speedrun, if you save and quit on the frame that the Checkpoint spawns, then you will also spawn a trophy. (Reported by thereisnofuture)
* Voiding a Forget Me Now will crash the game if the mod was loaded for the first or second time. (Reported by Gamonymous)
* Bob's Bladder produces green creep instead of blue. (Reported by PassionDrama)
* If there are multiple The Haunts in a room, all of the Lil Haunts will be detached at once, because tracking the individual ones is too difficult. (Reported by thereisnofuture)
* Teleports can be canceled if you trigger them on the frame before going into a new room. For example, trying to use Cursed Eye when going in or coming out of a Cursed Room will not work.

<br />

## Known Bugs with Samael (the new character)

* Picking up a 2nd Sacrificial Dagger will do nothing. Saving and quitting fixes this.
* The Flat Worm trinket causes thrown scythes to glitch out. This is purely a graphical glitch. (Found by TaKer093)
* If you have Ipecac and Death's Touch, the thrown scythe will become invisible. (Reported by Nariom)
* If you have Mom's Knife, you can bypass the throw charge with proper timing to infinitely throw the scythe at close range. (Found by TaKer093)
* You can keep the Scythe shot fully charged without pressing any attack button by charging the scythe and release all attack buttons in a slide transition. Once you press any attack button, the Scythe charge will be released and the bug is fixed. (Found by TaKer093)
* When you have two Wraith Skulls (from using a Diplopia on your initial Wraith Skull), they won't work properly. (Found by Moucheron Quipet)
* Lasers from Jacob's Ladder will only deal 0.1 damage from melee attacks. (Found by Moucheron Quipet)

<br />

## Known Bugs with the Seeded Death Mechanic

* It does not add or remove transformations. (Reported by Moucheron Quipet)
* It does not add the familiars back in the correct order. (Reported by thisguyisbarry)
* It does not properly account for familiars from Cambion Conception and Immaculate Conception.
* It can cause you to get a 2nd Small Rock from a tinted rock. (Reported by Moucheron Quipet)
* It can grant the Stompy transformation if you revive with Magic Mushroom.
* Reviving with Magic Mushroom bugs out the screen. (Reported by thisguyisbarry)
* Being a ghost will prevent Brimstone-style lasers from firing. (Reported by Xelnas)

<br />

## Known Bugs with the Cient & Server (e.g. the application)

* In very close races, a racer may have a better placing with a higher time. This is because the timing system is based on local time, not server time. What this means is that each person will start the race at a slightly different time (depending on their internet connection), and the client reports the total amount of time taken once the race is completed.  However, the Racing+ server uses "first past the post" to determine placing, NOT the local time. Otherwise, a 1st place finish could change to a 2nd place finish afterwards, which would be quite confusing. No-one will likely have a ping of more than 1000ms to the server, so placings will be accurate to that margin of error. For 1v1 tournaments, it is recommended that referees use whoever has the lowest local time to determine the winner instead of who the Racing+ server says the winner is.
* The client will interfere with setting the order for custom challenges. If you are doing offline custom challenges, then don't have the Racing+ client open.
* If you quit a race, quit the client, and reopen the client, the finish sound effect will play again. (Reported by AshDown)
* If you join a race that is being deleted at the same time, you are not able to use the buttons on the R+ client and are forced to restart the client. (Reported by PassionDrama)
* The lobby does not show previous conversations that were copied over from Discord. (Reported by Lobsterosity)
* When something in the chat is tab completed so that the message is longer than the chat window, the cursor does not move. (Reported by LogBasePotato)
* If you somehow start an item without going into any rooms, the Racing+ client won't show that item as your starting item. (Reported by Thoday)
* The client will not properly detect/install a fully unlocked save like it is supposed to.
* Auto-update sometimes doesn't work properly. (Reported by caesar)

<br />

## Known Bugs with Installing or Automatic Updating the Client

* Sometimes, auto-update will not work properly. If this happens, just download the latest version automatically. (Reported by caesar)
* Sometimes, when installing the Racing+ client, you will get the error message: "Your internet connection seems to be not permitted or dropped out!" This can happen if your internet connection sucks or you are in a certain country (China, Russia, etc.). To fix this, manually download all of the files from [the latest release](https://github.com/Zamiell/isaac-racing-client/releases). Then, put them all into the same directory, and run "WebSetup.exe".

<br />

## Known Bugs with the Website

* The Unseeded leaderboard is missing some info, such as mgln. (Reported by mgln)
* The 2nd page of race listing is missing. (Reported by mgln)

<br />

## Known Bugs with the Twitch Bot

* If you finish a race and start a new race before all the people in the first race has completed, you will continue to get messages about the people in the first race. (Reported by thereisnofuture)
