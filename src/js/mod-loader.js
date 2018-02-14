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
    if (globals.modPath === null) {
        return;
    }

    // Do nothing if we are on a test account > 1
    if (globals.myUsername.startsWith('TestAccount') && globals.myUsername !== 'TestAccount1') {
        return;
    }

    // We want to send the "modLoader" object to the Lua mod, but with some modifications
    // So, start by making a copy (just making it equal won't make a copy)
    // From: https://stackoverflow.com/questions/728360/how-do-i-correctly-clone-a-javascript-object
    const json = Object.assign({}, globals.modLoader);

    // Start to compile the list of starting items
    json.startingItems = [];
    if (globals.modLoader.rFormat === 'diversity') {
        const items = globals.modLoader.seed.split(',');
        for (const item of items) {
            json.startingItems.push(parseInt(item, 10)); // The Lua mod expects this to be a number
        }
    }

    // Parse the starting build
    if (globals.modLoader.startingBuild !== -1) {
        for (const item of builds[globals.modLoader.startingBuild]) {
            // The Lua mod just needs the item ID, not the name
            json.startingItems.push(item.id);
        }
    }
    delete json.startingBuild; // The client only needs "startingItems"

    // This is necessary because the 5 diversity items are communicated through the seed
    if (json.rFormat === 'diversity') {
        json.seed = '-';
    }

    // Convert the custom format
    if (json.rFormat === 'seeded-hard') {
        json.rFormat = 'seeded';
        json.hard = true;
    }

    // Write to it
    try {
        // This has to be syncronous to prevent bugs with writing to the file multiple times in a row
        const modLoaderFile = path.join(globals.modPath, `save${globals.modLoaderSlot}.dat`);
        fs.writeFileSync(modLoaderFile, JSON.stringify(json), 'utf8');
        // globals.log.info(`successfully wrote to: ${modLoaderFile}`);
    } catch (err) {
        // Ocassional errors are normal, because there can be a ton of file writes going on,
        // so just try again in 1/20 of a second
        globals.log.info(`Error while filling up the "save${globals.modLoaderSlot}.dat" file: ${err}`);
        setTimeout(() => {
            send();
        }, 50);
    }
};
exports.send = send;

const reset = () => {
    globals.modLoader.status = 'none';
    globals.modLoader.myStatus = 'not ready';
    globals.modLoader.ranked = false;
    globals.modLoader.solo = false;
    globals.modLoader.rFormat = 'unseeded';
    globals.modLoader.hard = false;
    globals.modLoader.character = 3; // Judas
    globals.modLoader.goal = 'Blue Baby';
    globals.modLoader.seed = '-';
    globals.modLoader.startingBuild = -1;
    globals.modLoader.countdown = -1;
    globals.modLoader.numEntrants = 1;
    send();
    globals.log.info('modLoader - Reset all variables.');
};
exports.reset = reset;

// This sends an up-to-date myStatus, numEntrants, placeMid and place to the mod
const sendPlace = () => {
    const race = globals.raceList[globals.currentRaceID];

    if (race.status === 'in progress') {
        // Find our value of "placeMid"
        let numLeft = 0;
        let amRacing = false;
        for (let i = 0; i < race.racerList.length; i++) {
            const racer = race.racerList[i];

            if (racer.status === 'racing') {
                numLeft += 1;
            }

            if (racer.name === globals.myUsername) {
                globals.modLoader.myStatus = racer.status;
                globals.modLoader.placeMid = racer.placeMid;
                globals.modLoader.place = racer.place;
                if (racer.status === 'racing') {
                    amRacing = true;
                }
            }
        }
        if (numLeft === 1 && amRacing && race.racerList.length > 2) {
            globals.modLoader.placeMid = -1; // This will show "last person left"
        }
    } else {
        // Count how many people are ready
        let numReady = 0;
        for (let i = 0; i < race.racerList.length; i++) {
            const racer = race.racerList[i];

            if (racer.status === 'ready') {
                numReady += 1;
            }

            if (racer.name === globals.myUsername) {
                globals.modLoader.myStatus = racer.status;
            }
        }
        globals.modLoader.placeMid = numReady;
    }
    globals.modLoader.numEntrants = race.racerList.length;

    if (race.ruleset.solo) {
        // We don't want to send our final place for solo races to avoid showing the "1st place" graphic at the end of the race
        globals.modLoader.place = 0;
    }

    send();
    // globals.log.info('modLoader - Sent a myStatus of "' + globals.modLoader.status + '" and a numEntrants of "' + globals.modLoader.numEntrants + '" and a place of ' + globals.modLoader.place + ' and a placeMid of ' + globals.modLoader.placeMid + '.');
};
exports.sendPlace = sendPlace;
