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
    // We don't care if the race is finished
    if (globals.modLoader.status === 'finished') {
        globals.modLoader.status = 'none';
    }

    // Start to compile the list of starting items
    let startingItems = [];
    if (globals.modLoader.rFormat === 'seeded') {
        startingItems.push(21); // The Compass
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
    saveDat += '  status        = "' + globals.modLoader.status + '",\n';
    saveDat += '  rType         = "' + globals.modLoader.rType + '",\n';
    saveDat += '  rFormat       = "' + globals.modLoader.rFormat + '",\n';
    saveDat += '  character     = "' + globals.modLoader.character + '",\n';
    saveDat += '  goal          = "' + globals.modLoader.goal + '",\n';
    saveDat += '  seed          = "' + globals.modLoader.seed + '",\n';
    saveDat += '  startingItems = {';
    if (startingItems.length !== 0) {
        for (let itemID of startingItems) {
            saveDat += '    ' + itemID + ',\n';
        }
        saveDat = saveDat.slice(0, -2); // Chop off the trailing comma and newline
        saveDat += '\n  ';
    }
    saveDat += '},\n';
    saveDat += '  blckCndlOn      = ' + globals.modLoader.blckCndlOn + ',\n';
    saveDat += '  currentSeed     = "' + globals.modLoader.currentSeed + '",\n';
    saveDat += '  countdown       = ' + globals.modLoader.countdown + ',\n';
    let epoch = Math.floor(new Date().getTime() / 1000);
    saveDat += '  datetimeWritten = ' + epoch + '\n';
    saveDat += '}\n';

    // Truncate all whitepsace to make the file size smaller in production
    if (isDev === false) {
        saveDat = saveDat.replace(/\s/g, '');
    }

    // Write to it
    fs.writeFile(globals.modLoaderFile, saveDat, function(err) {
        if (err) {
            globals.log.info('Error while filling up the "save.dat" file: ' + err);

            // Try again in a few milliseconds
            setTimeout(function() {
                send();
            }, 5);
        }
    });
};
exports.send = send;
