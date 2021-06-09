# Racing+ Known Bugs

<br />

## Table of Contents

1. [Known Bugs with the Racing+ Mod (e.g. gameplay)](#known-bugs-with-the-racing-mod-eg-gameplay)
4. [Known Bugs with the Client & Server (e.g. the application)](#known-bugs-with-the-client--server-eg-the-application)
5. [Known Bugs with Installing or Automatic Updating the Client](#known-bugs-with-installing-or-automatic-updating-the-client)
6. [Known Bugs with the Website](#known-bugs-with-the-website)
7. [Known Bugs with the Twitch Bot](#known-bugs-with-the-twitch-bot)

<br />

## Known Bugs with the Racing+ Mod (e.g. gameplay)

Racing+ mod bugs are listed on a [separate page](mod/BUGS.md).

<br />

## Known Bugs with the Client & Server (e.g. the application)

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
* Sometimes, when installing the Racing+ client, you will get the error message: "Your internet connection seems to be not permitted or dropped out!" This can happen if your internet connection sucks or you are in a certain country (China, Russia, etc.). To fix this, manually download all of the files from [the latest release](https://github.com/Zamiell/isaac-racing-client/releases) and put them all into the same directory. Then, run "WebSetup.exe".

<br />

## Known Bugs with the Website

* The Unseeded leaderboard is missing some info, such as mgln. (Reported by mgln)
* The 2nd page of race listing is missing. (Reported by mgln)

<br />

## Known Bugs with the Twitch Bot

* If you finish a race and start a new race before all the people in the first race has completed, you will continue to get messages about the people in the first race. (Reported by thereisnofuture)
