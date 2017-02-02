/*
    Child process that starts Isaac
*/

'use strict';

// Imports
const fs       = require('fs-extra');
const path     = require('path');
const isDev    = require('electron-is-dev');
const tracer   = require('tracer');
const Raven    = require('raven');
const ps       = require('ps-node');
const opn      = require('opn');
const md5      = require('md5');
const execFile = require('child_process').execFile;

/*
    Handle errors
*/

process.on('uncaughtException', function(err) {
    process.send('error: ' + err, processExit);
});
const processExit = function() {
    process.exit();
};

/*
    Logging (code duplicated between main, renderer, and child processes because of require/nodeRequire issues)
*/

const log = tracer.console({
    format: "{{timestamp}} <{{title}}> {{file}}:{{line}} - {{message}}",
    dateformat: "ddd mmm dd HH:MM:ss Z",
    transport: function(data) {
        // #1 - Log to the JavaScript console
        console.log(data.output);

        // #2 - Log to a file
        let logFile = (isDev ? 'Racing+.log' : path.resolve(process.execPath, '..', '..', 'Racing+.log'));
        fs.appendFile(logFile, data.output + (process.platform === 'win32' ? '\r' : '') + '\n', function(err) {
            if (err) {
                throw err;
            }
        });
    }
});

// Get the version
let packageFileLocation = path.join(__dirname, 'package.json');
let packageFile = fs.readFileSync(packageFileLocation, 'utf8');
let version = 'v' + JSON.parse(packageFile).version;

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
}).install();

/*
    Isaac stuff
*/

// Global variables
var modsPath;

// The parent will communicate with us, telling us the path to the log file
process.on('message', function(message) {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    if (message === 'exit') {
        process.exit();
    }

    // If the message is not "exit", we can assume that it is the mods path
    modsPath = message;

    // Check to see if the mods directory exists
    if (fs.existsSync(modsPath) === false) {
        process.send('error: Unable to find your mods folder. Are you sure you chose the correct log file? Try to fix it in the "settings.json" file in the Racing+ directory.', processExit);
    }

    // Begin the process of opening Isaac
    checkIsaacOpen();
});

function checkIsaacOpen() {
    log.info('Checking to see if Isaac is open.');
    let command;
    if (process.platform === 'win32') { // This will return "win32" even on 64-bit Windows
        command = 'isaac-ng';
    } else if (process.platform === 'darwin') { // OS X
        command = 'The Binding of Isaac Afterbirth+';
    } else {
        // Linux is not supported
        process.send('Linux is not supported.', processExit);
    }

    ps.lookup({
        command: command,
    }, function(err, resultList) {
        if (err) {
            process.send('error: Failed to find the Isaac process: ' + err, processExit);
        }

        if (resultList.length === 0) {
            // Isaac is not already open
            if (checkRacingPlusLuaModCurrent() && checkOtherModsEnabled() === false) {
                startIsaac();
            } else {
                deleteOldLuaMod();
            }
        } else {
            // There should only be 1 "isaac-ng.exe" process
            resultList.forEach(function(ps) {
                // Isaac is currently open, so check to see if we need to restart the game
                if (checkRacingPlusLuaModCurrent() && checkOtherModsEnabled() === false) {
                    // We don't need to restart the game, so we don't have to do anything at all
                    process.send('The Lua mod is current and no other mods are enabled.', processExit);
                } else {
                    closeIsaac(ps.pid);
                }
            });
        }
    });
}

function closeIsaac(pid) {
    log.info('Closing Isaac.');
    ps.kill(pid, function(err) { // This expects the first argument to be in a string for some reason
        if (err) {
            process.send('error: Failed to close Isaac: ' + err, processExit);
        } else {
            deleteOldLuaMod();
        }
    });
}

function checkRacingPlusLuaModCurrent() {
    log.info('Checking to see if the Lua mod is current.');

    // Check the old version
    let oldXMLPath = path.join(modsPath, 'Racing+', 'metadata.xml');
    if (fs.existsSync(oldXMLPath) === false) {
        return false;
    }
    let oldXML = fs.readFileSync(path.join(modsPath, 'Racing+', 'metadata.xml')).toString();
    let oldMatch = oldXML.match(/<version>(.+)<\/version>/);
    let oldVersion;
    if (oldMatch) {
        oldVersion = oldMatch[1];
    } else {
        process.send('error: Failed to parse the "' + oldXMLPath + '" file.', processExit);
    }

    // Check the new version
    let newXMLPath;
    if (isDev) {
        newXMLPath = path.join('assets', 'mod', 'Racing+', 'metadata.xml');
    } else {
        newXMLPath = path.join('app.asar', 'assets',  'mod', 'Racing+', 'metadata.xml');
    }
    let newXML = fs.readFileSync(newXMLPath).toString();
    let newMatch = newXML.match(/<version>(.+)<\/version>/);
    let newVersion;
    if (newMatch) {
        newVersion = newMatch[1];
    } else {
        process.send('error: Failed to parse the "' + newXMLPath + '" file.', processExit);
    }

    // Compare
    if (oldVersion !== newVersion) {
        return false;
    }

    // As a secondary check, compare the MD5 hashes of the "main.lua" files
    if (fs.existsSync(path.join(modsPath, 'Racing+', 'main.lua')) === false) {
        return false;
    }
    let oldLua = fs.readFileSync(path.join(modsPath, 'Racing+', 'main.lua'));
    let oldHash = md5(oldLua);
    let newLua;
    if (isDev) {
        newLua = fs.readFileSync(path.join('assets', 'mod', 'Racing+', 'main.lua'));
    } else {
        newLua = fs.readFileSync(path.join('app.asar', 'assets', 'mod', 'Racing+', 'main.lua'));
    }
    let newHash = md5(newLua);
    return oldHash === newHash;
}

function checkOtherModsEnabled() {
    log.info('Checking to see if any other mods are enabled.');

    /*
        Note that it is possible for a mod to have a "disable.it" in the directory but still be enabled in game.
        (This can happen if the "disable.it" file was created after the game was already launched, and perhaps other ways.)
        To counteract this, we could always force Isaac to restart upon Racing+ launching.
        However, this would mean that if a user's internet drops during the race, they would get booted out of the game.
        So let's leave open this loophole for now.
    */

    // Go through all the subdirectories of the mod folder
    let files = fs.readdirSync(modsPath);
    let otherModsEnabled = false;
    for (let file of files) {
        if (fs.statSync(path.join(modsPath, file)).isDirectory() === false) {
            continue;
        }

        if (file === 'Racing+') {
            if (fs.existsSync(path.join(modsPath, file, 'disable.it'))) {
                // The Racing+ mod is not enabled
                otherModsEnabled = true;

                // Enable it by removing the "disable.it" file
                try {
                    fs.removeSync(path.join(modsPath, file, 'disable.it'));
                } catch(err) {
                    process.send('error: Failed to remove the "disable.it" file for the Racing+ Lua mod: ' + err, processExit);
                }
            }
        } else {
            if (fs.existsSync(path.join(modsPath, file, 'disable.it')) === false) {
                log.info('Making a "disable.it" for: ' + file);
                // Some other mod is enabled
                otherModsEnabled = true;

                // Disable it by writing a 0 byte "disable.it" file
                try {
                    fs.writeFileSync(path.join(modsPath, file, 'disable.it'), '', 'utf8');
                } catch(err) {
                    process.send('error: Failed to disable one of the existing mods: ' + err, processExit);
                }
            }
        }
    }

    return otherModsEnabled;
}

function deleteOldLuaMod() {
    log.info('Deleting the old Lua mod.');
    if (fs.existsSync(path.join(modsPath, 'Racing+'))) {
        // Delete the old Racing+ mod
        fs.remove(path.join(modsPath, 'Racing+'), function(err) {
            if (err) {
                process.send('error: Failed to delete the old Racing+ Lua mod: ' + err, processExit);
            }
            copyLuaMod();
        });
    } else {
        copyLuaMod();
    }
}

// Copy over the new Racing+ mod
function copyLuaMod() {
    log.info('Copying over the Lua mod.');
    fs.copy(path.join('assets', 'mod', 'Racing+'), path.join(modsPath, 'Racing+'), function (err) {
        if (err) {
            process.send('error: Failed to copy the new Racing+ Lua mod: ' + err, processExit);
        }
        startIsaac();
    });
}

// Start Isaac
function startIsaac() {
    // Use Steam to launch it so that we don't have to bother with finding out where the binary is
    log.info('Launching Isaac.');
    opn('steam://rungameid/250900');

    // The child will stay alive even if the parent has closed
    setTimeout(function() {
        process.exit();
    }, 30000); // We need delay before exiting or else Isaac won't actually open
}
