/*
    Mod loader
*/

'use strict';

// Imports
const path    = nodeRequire('path');
const fs      = nodeRequire('fs-extra');
const isDev   = nodeRequire('electron-is-dev');
const globals = nodeRequire('./assets/js/globals');
const misc    = nodeRequire('./assets/js/misc');
const builds  = nodeRequire('./assets/data/builds');

// We can communicate with the Racing+ Lua mod via file I/O
// Specifically, we use the 3 "save.dat" files located in the mod subdirectory
const send = function() {
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
    let json = Object.assign({}, globals.modLoader);

    // Start to compile the list of starting items
    json.startingItems = [];
    if (globals.modLoader.rFormat === 'seeded') {
        json.startingItems.push(21); // The Compass
    } else if (globals.modLoader.rFormat === 'diversity') {
        let items = globals.modLoader.seed.split(',');
        for (let item of items) {
            json.startingItems.push(parseInt(item)); // The Lua mod expects this to be a number
        }
    }

    // Parse the starting build
    if (globals.modLoader.startingBuild !== -1) {
        for (let item of builds[globals.modLoader.startingBuild]) {
            // The Lua mod just needs the item ID, not the name
            json.startingItems.push(item.id);
        }
    }
    delete json.startingBuild; // The client only needs "startingItems"

    // This is necessary because the 5 diversity items are communicated through the seed
    if (json.rFormat === 'diversity') {
        json.seed = '-';
    }

    // Delete the speedrun orders (we will add them later)
    delete json['order9-1'];
    delete json['order14-1'];
    delete json['order9-2'];
    delete json['order14-2'];
    delete json['order9-3'];
    delete json['order14-3'];

    // Write to it
    try {
        for (let i = 1; i <= 3; i++) {
            // Add the speedrun orders
            json.order9 = globals.modLoader['order9-' + i];
            json.order14 = globals.modLoader['order14-' + i];

            // This has to be syncronous to prevent bugs with writing to the file multiple times in a row
            let modLoaderFile = path.join(globals.modPath, 'save' + i + '.dat');
            fs.writeFileSync(modLoaderFile, JSON.stringify(json), 'utf8');
        }
    } catch(err) {
        globals.log.info('Error while filling up the "save#.dat" file: ' + err);

        // Try again in 1/20 of a second
        setTimeout(function() {
            send();
        }, 50);
    }
};
exports.send = send;

const reset = function() {
    globals.modLoader.myStatus = 'not ready';
    globals.modLoader.status = 'none';
    globals.modLoader.rType = 'unranked';
    globals.modLoader.solo = false;
    globals.modLoader.rFormat = 'unseeded';
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
const sendPlace = function() {
    if (globals.raceList[globals.currentRaceID].status === 'in progress') {
        // Find our value of "placeMid"
        let numLeft = 0;
        let amRacing = false;
        for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
            let racer = globals.raceList[globals.currentRaceID].racerList[i];

            if (racer.status === 'racing') {
                numLeft++;
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
        if (numLeft === 1 && amRacing && globals.raceList[globals.currentRaceID].racerList.length > 2) {
            globals.modLoader.placeMid = -1; // This will show "last person left"
        }
    } else {
        // Count how many people are ready
        let numReady = 0;
        for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
            let racer = globals.raceList[globals.currentRaceID].racerList[i];

            if (racer.status === 'ready') {
                numReady++;
            }

            if (racer.name === globals.myUsername) {
                globals.modLoader.myStatus = racer.status;
            }
        }
        globals.modLoader.placeMid = numReady;
    }
    globals.modLoader.numEntrants = globals.raceList[globals.currentRaceID].racerList.length;

    send();
    globals.log.info('modLoader - Sent a myStatus of "' + globals.modLoader.status + '" and a numEntrants of "' + globals.modLoader.numEntrants + '" and a place of ' + globals.modLoader.place + ' and a placeMid of ' + globals.modLoader.placeMid + '.');
};
exports.sendPlace = sendPlace;
