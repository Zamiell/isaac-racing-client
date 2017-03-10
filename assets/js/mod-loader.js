/*
    Mod loader
*/

'use strict';

// Imports
const fs          = nodeRequire('fs-extra');
const isDev       = nodeRequire('electron-is-dev');
const globals     = nodeRequire('./assets/js/globals');
const misc        = nodeRequire('./assets/js/misc');
const builds      = nodeRequire('./assets/data/builds');

// We can communicate with the Racing+ Lua mod via file I/O
// Specifically, we use the "save.dat" located in the mod subdirectory
const send = function() {
    // Do nothing if the mod loader file is set to null
    // (this can happen if the user is closing the program, for example)
    if (globals.modLoaderFile === null) {
        return;
    }

    // We don't care if the race is finished
    if (globals.modLoader.status === 'finished') {
        globals.modLoader.status = 'none';
    }

    // Start to compile the list of starting items
    let startingItems = [];
    if (globals.modLoader.rFormat === 'seeded') {
        startingItems.push(21); // The Compass
    } else if (globals.modLoader.rFormat === 'diversity') {
        let items = globals.modLoader.seed.split(',');
        for (let item of items) {
            startingItems.push(parseInt(item)); // The Lua mod expects this to be a number
        }
    }

    // Parse the starting build
    if (globals.modLoader.startingBuild !== -1) {
        for (let item of builds[globals.modLoader.startingBuild]) {
            // The Lua mod just needs the item ID, not the name
            startingItems.push(item.id);
        }
    }

    // Build the Lua table manually
    let saveDat = '{\n';
    saveDat += 'status="' + globals.modLoader.status + '",\n';
    saveDat += 'rType="' + globals.modLoader.rType + '",\n';
    saveDat += 'rFormat="' + globals.modLoader.rFormat + '",\n';
    saveDat += 'character="' + globals.modLoader.character + '",\n';
    saveDat += 'goal="' + globals.modLoader.goal + '",\n';
    saveDat += 'seed="' + (globals.modLoader.rFormat === 'diversity' ? '-' : globals.modLoader.seed) + '",\n';
    saveDat += 'startingItems={';
    if (startingItems.length !== 0) {
        for (let itemID of startingItems) {
            saveDat += itemID + ',';
        }
        saveDat = saveDat.slice(0, -1); // Chop off the trailing comma
    }
    saveDat += '},\n';
    saveDat += 'currentSeed="' + globals.modLoader.currentSeed + '",\n';
    saveDat += 'countdown=' + globals.modLoader.countdown + ',\n';
    saveDat += '}';

    // Write to it
    fs.writeFile(globals.modLoaderFile, saveDat, function(err) {
        if (err) {
            globals.log.info('Error while filling up the "save.dat" file: ' + err);

            // Try again in 1/20 of a second
            setTimeout(function() {
                send();
            }, 50);
        }
    });
};
exports.send = send;

const reset = function() {
    globals.log.info('modLoader - Reset all variables.');
    globals.modLoader = {
        status: 'none',
        rType: 'unranked',
        rFormat: 'unseeded',
        character: 'Judas',
        goal: 'Blue Baby',
        seed: '-',
        startingBuild: -1,
        currentSeed: globals.modLoader.currentSeed, // We don't have to delete this
        countdown: -1,
    };
    send();
};
exports.reset = reset;
