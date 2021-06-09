/*
    Mod loader
*/

// Imports
const path = nodeRequire('path');
const fs = nodeRequire('fs');
const globals = nodeRequire('./js/globals');
const builds = nodeRequire('./data/builds');

// We can communicate with the Racing+ Lua mod via file I/O
// Specifically, we use the 3 "save.dat" files located in the mod subdirectory
const send = () => {
    // Do nothing if the mod loader file is set to null
    // (this can happen if the user is closing the program, for example)
    if (g.modPath === null) {
        return;
    }

    // Do nothing if we are on a test account > 1
    if (g.myUsername.startsWith('TestAccount') && g.myUsername !== 'TestAccount1') {
        return;
    }

    // We want to send the "modLoader" object to the Lua mod, but with some modifications
    // So, start by making a copy (just making it equal won't make a copy)
    // From: https://stackoverflow.com/questions/728360/how-do-i-correctly-clone-a-javascript-object
    const json = Object.assign({}, g.modLoader);

    // Start to compile the list of starting items
    json.startingItems = [];
    if (g.modSocket.rFormat === 'diversity') {
        const items = g.modSocket.seed.split(',');
        for (const item of items) {
            json.startingItems.push(parseIntSafe(item)); // The Lua mod expects this to be a number
        }
    } else if (
        g.modSocket.ranked &&
        g.modSocket.solo &&
        g.modSocket.rFormat === 'unseeded'
    ) {
        // The Racing+ Schoolbag has an item ID of 554
        json.startingItems.push(553); // The Lua mod expects this to be a number
    }

    // Parse the starting build
    if (g.modSocket.startingBuild !== -1) {
        for (const item of builds[g.modSocket.startingBuild]) {
            // The Lua mod just needs the item ID, not the name
            json.startingItems.push(item.id);
        }
    }
    delete json.startingBuild; // The client only needs "startingItems"

    // This is necessary because the 5 diversity items are communicated through the seed
    if (json.rFormat === 'diversity') {
        json.seed = '-';
    }

    // Write to it
    try {
        // This has to be synchronous to prevent bugs with writing to the file multiple times in a row
        const modLoaderFile = path.join(g.modPath, `save${g.modLoaderSlot}.dat`);
        fs.writeFileSync(modLoaderFile, JSON.stringify(json), 'utf8');
        // log.info(`successfully wrote to: ${modLoaderFile}`);
    } catch (err) {
        // Occasional errors are normal, because there can be a ton of file writes going on,
        // so just try again in 1/20 of a second
        log.info(`Error while filling up the "save${g.modLoaderSlot}.dat" file: ${err}`);
        setTimeout(() => {
            send();
        }, 50);
    }
};
exports.send = send;

const reset = () => {
    g.modSocket.userID = g.myUserID;
    g.modSocket.raceID = 0;
    g.modSocket.status = 'none';
    g.modSocket.myStatus = 'not ready';
    g.modSocket.ranked = false;
    g.modSocket.solo = false;
    g.modSocket.rFormat = 'unseeded';
    g.modSocket.difficulty = 'normal';
    g.modSocket.character = 3; // Judas
    g.modSocket.goal = 'Blue Baby';
    g.modSocket.seed = '-';
    g.modSocket.startingBuild = -1; // Converted to "startingItems" later on
    g.modSocket.countdown = -1;
    g.modSocket.placeMid = 0;
    g.modSocket.place = 1;
    g.modSocket.numEntrants = 1;
    send();
    log.info('modLoader - Reset all variables.');
};
exports.reset = reset;

// This sends an up-to-date myStatus, numEntrants, placeMid and place to the mod
const sendPlace = () => {
    const race = g.raceList[g.currentRaceID];

    if (race.status === 'in progress') {
        // Find our value of "placeMid"
        let numLeft = 0;
        let amRacing = false;
        for (let i = 0; i < race.racerList.length; i++) {
            const racer = race.racerList[i];

            if (racer.status === 'racing') {
                numLeft += 1;
            }

            if (racer.name === g.myUsername) {
                g.modSocket.myStatus = racer.status;
                g.modSocket.placeMid = racer.placeMid;
                g.modSocket.place = racer.place;
                if (racer.status === 'racing') {
                    amRacing = true;
                }
            }
        }
        if (numLeft === 1 && amRacing && race.racerList.length > 2) {
            g.modSocket.placeMid = -1; // This will show "last person left"
        }
    } else {
        // Count how many people are ready
        let numReady = 0;
        for (let i = 0; i < race.racerList.length; i++) {
            const racer = race.racerList[i];

            if (racer.status === 'ready') {
                numReady += 1;
            }

            if (racer.name === g.myUsername) {
                g.modSocket.myStatus = racer.status;
            }
        }
        g.modSocket.placeMid = numReady;
    }
    g.modSocket.numEntrants = race.racerList.length;

    if (race.ruleset.solo) {
        // We don't want to send our final place for solo races to avoid showing the "1st place" graphic at the end of the race
        g.modSocket.place = 0;
    }

    send();
    // log.info('modLoader - Sent a myStatus of "' + g.modSocket.status + '" and a numEntrants of "' + g.modSocket.numEntrants + '" and a place of ' + g.modSocket.place + ' and a placeMid of ' + g.modSocket.placeMid + '.');
};
exports.sendPlace = sendPlace;
