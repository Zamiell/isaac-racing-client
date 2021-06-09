/*
const fs = nodeRequire('fs');
const { ipcRenderer } = nodeRequire('electron');
const settings = nodeRequire('./settings');
const globals = nodeRequire('./js/globals');
const modLoader = nodeRequire('./js/mod-loader');
const misc = nodeRequire('./js/misc');
const raceScreen = nodeRequire('./js/ui/race');
*/

// g.currentScreen is equal to "transition" when this is called
// Called from the "lobby.show()" function
export function start() {
    // Check to make sure the log file exists
    let logPath = settings.get('logFilePath');
    if (!fs.existsSync(logPath)) {
        logPath = null;
        settings.set('logFilePath', null);
    }

    // Check to ensure that we have a valid log file path
    if (logPath === null) {
        g.currentScreen = 'null';
        errorShow('', false, 'log-file-modal'); // Show the log file path modal
        return false;
    }

    // Check to make sure they don't have a Rebirth log.txt selected
    if (logPath.match(/[/\\]Binding of Isaac Rebirth[/\\]/)) { // Match a forward or backslash
        $('#log-file-description-1').html('<span lang="en">It appears that you have selected your Rebirth "log.txt" file, which is different than the Afterbirth+ "log.txt" file.</span>');
        g.currentScreen = 'null';
        errorShow('', false, 'log-file-modal'); // Show the log file path modal
        return false;
    }

    // Check to make sure they don't have an Afterbirth log.txt selected
    if (logPath.match(/[/\\]Binding of Isaac Afterbirth[/\\]/)) {
        $('#log-file-description-1').html('<span lang="en">It appears that you have selected your Afterbirth "log.txt" file, which is different than the Afterbirth+ "log.txt" file.</span>');
        g.currentScreen = 'null';
        errorShow('', false, 'log-file-modal'); // Show the log file path modal
        return false;
    }

    // Send a message to the main process to start up the log watcher
    electron.ipcRenderer.send('asynchronous-message', 'log-watcher', logPath);
    return true;
}

// Monitor for notifications from the child process that is doing the log watching
function logWatcherEvent(event, message) {
    // Don't log everything to reduce spam
    if (
        !message.startsWith('New floor: ') &&
        !message.startsWith('New room: ') &&
        !message.startsWith('New item: ')
    ) {
        log.info(`Received log-watcher notification: ${message}`);
    }

    if (message.startsWith('error: ')) {
        // First, parse for errors
        const error = message.match(/^error: (.+)/)[1];
        errorShow(`Something went wrong with the log monitoring program: ${error}`);
        return;
    }

    // Do some things regardless of whether we are in a race or not
    // (all relating to the Racing+ Lua mod)
    if (message.startsWith('Save file slot: ')) {
        // We want to keep track of which save file we are on so that we don't have to write 3 files at a time
        const match = message.match(/Save file slot: (\d)/);
        if (match) {
            g.modLoaderSlot = parseIntSafe(match[1]);
            modSocket.send();
        } else {
            errorShow('Failed to parse the save slot number from the message sent by the log watcher process:', message);
        }
        return;
    }
    if (message === 'Title menu initialized.') {
        g.gameState.inGame = false;
        g.gameState.hardMode = false; // Assume by default that the user is playing on normal mode
        g.gameState.racingPlusModEnabled = false; // Assume by default that the user does not have the Racing+ mod initialized
        raceScreen.checkReadyValid();
        return;
    }
    if (message === 'A new run has begun.') {
        // We detect this through the "RNG Start Seed:" line
        // We could detect this through the "Going to the race room." line but then Racing+ wouldn't work for vanilla / custom mods
        setTimeout(() => {
            // Delay a second before enabling the checkbox to avoid a race condition where they can ready before race validation occurs
            g.gameState.inGame = true;
            raceScreen.checkReadyValid();
        }, 1000);
        return;
    }
    if (message === 'Race error: Wrong mode.') {
        g.gameState.hardMode = true;
        raceScreen.checkReadyValid();
        return;
    }
    if (message === 'Race validation succeeded.') {
        // We look for this message to determine that the user has successfully downloaded and is running the Racing+ Lua mod
        g.gameState.racingPlusModEnabled = true;
        raceScreen.checkReadyValid();
        return;
    }

    /*
        The rest of the log actions involve sending a message to the server
    */

    // If we are currently in a transition, try again in 0.1 seconds
    if (g.currentScreen === 'transition') {
        setTimeout(() => {
            logWatcherEvent(event, message);
        }, 100); // 0.1 seconds
        return;
    }

    // Don't do anything if we are not in a race
    if (g.currentScreen !== 'race' || !g.currentRaceID) {
        return;
    }

    // Don't do anything if the race is over
    if (!g.raceList.has(g.currentRaceID)) {
        return;
    }

    // Don't do anything if we have not started yet or we have quit
    for (let i = 0; i < g.raceList[g.currentRaceID].racerList.length; i++) {
        if (g.raceList[g.currentRaceID].racerList[i].name === g.myUsername) {
            if (g.raceList[g.currentRaceID].racerList[i].status !== 'racing') {
                return;
            }
            break;
        }
    }

    // Parse the message
    if (message.startsWith('New seed: ')) {
        const match = message.match(/New seed: (.... ....)/);
        if (match) {
            const seed = match[1];
            g.conn.send('raceSeed', {
                id: g.currentRaceID,
                seed,
            });
        } else {
            errorShow('Failed to parse the new seed from the message sent by the log watcher process:', message);
        }
    } else if (message.startsWith('New floor: ')) {
        const match = message.match(/New floor: (\d+)-(\d+)/);
        if (match) {
            const floorNum = parseIntSafe(match[1]); // The server expects this to be an integer
            const stageType = parseIntSafe(match[2]); // The server expects this to be an integer
            g.conn.send('raceFloor', {
                id: g.currentRaceID,
                floorNum,
                stageType,
            });
        } else {
            errorShow('Failed to parse the new floor from the message sent by the log watcher process:', message);
        }
    } else if (message.startsWith('New room: ')) {
        const m = message.match(/New room: (.+)/);
        if (m) {
            const roomID = m[1];
            g.conn.send('raceRoom', {
                id: g.currentRaceID,
                roomID,
            });
        } else {
            errorShow('Failed to parse the new room from the message sent by the log watcher process:', message);
        }
    } else if (message.startsWith('New item: ')) {
        const match = message.match(/New item: (\d+)/);
        if (match) {
            const itemID = parseIntSafe(match[1]); // The server expects this to be an integer
            g.conn.send('raceItem', {
                id: g.currentRaceID,
                itemID,
            });
        } else {
            errorShow('Failed to parse the new item from the message sent by the log watcher process:', message);
        }
    } else if (message === 'Finished run: Blue Baby') {
        // This should only happen after they have already jumped into the big chest
        if (g.raceList[g.currentRaceID].ruleset.goal === 'Blue Baby') {
            g.conn.send('raceFinish', {
                id: g.currentRaceID,
            });
        }
    } else if (message === 'Finished run: The Lamb') {
        // This should only happen after they have already jumped into the big chest
        if (g.raceList[g.currentRaceID].ruleset.goal === 'The Lamb') {
            g.conn.send('raceFinish', {
                id: g.currentRaceID,
            });
        }
    } else if (message === 'Finished run: Mega Satan') {
        // This should only happen after they have already jumped into the big chest
        // (or the big chest did not drop and the cutscene started itself automatically)
        if (g.raceList[g.currentRaceID].ruleset.goal === 'Mega Satan') {
            g.conn.send('raceFinish', {
                id: g.currentRaceID,
            });
        }
    } else if (message.startsWith('Finished run: Trophy - ')) {
        const match = message.match(/Finished run: Trophy - (\d+) - (\d+)/);
        if (match) {
            const raceID = parseIntSafe(match[1]);
            const time = parseIntSafe(match[2]);
            if (raceID === g.currentRaceID) {
                g.conn.send('raceFinish', {
                    id: g.currentRaceID,
                    time,
                });
            }
        } else {
            errorShow('Failed to parse the run time from the message sent by the log watcher process:', message);
        }
    }
};
ipcRenderer.on('log-watcher', logWatcherEvent);