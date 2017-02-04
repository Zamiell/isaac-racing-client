/*
    Child process that validating everything is right in the file system and then launches the game
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
const teeny    = require('teeny-conf');

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
    Settings (on persistent storage)
*/

// Open the file that contains all of the user's settings
// (We use teeny-conf instead of localStorage because localStorage persists after uninstallation)
const settingsFile = (isDev ? 'settings.json' : path.resolve(process.execPath, '..', '..', 'settings.json'));
let settings = new teeny(settingsFile);
settings.loadOrCreateSync();

/*
    Isaac stuff
*/

// Global variables
var modsPath;
var launchIsaac = false; // Whether to actually launch Isaac after all of the file verification

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
        process.send('error: Unable to find your mods folder. Are you sure you chose the correct log file? Try to fix it in the "settings.json" file. By default, it is located at:<br /><br /><code>C:\\Users\\[YourUsername]\\AppData\\Local\\Programs\\settings.json</code>', processExit);
        return;
    }

    // Begin the process of opening Isaac
    checkIsaacOpen();
});

function checkIsaacOpen() {
    log.info('Checking to see if Isaac is open.');
    let processName;
    if (process.platform === 'win32') { // This will return "win32" even on 64-bit Windows
        processName = 'isaac-ng';
    } else if (process.platform === 'darwin') { // OS X
        processName = 'The Binding of Isaac Afterbirth+';
    } else {
        // Linux is not supported
        process.send('Linux is not supported.', processExit);
        return;
    }

    ps.lookup({
        command: processName,
    }, function(err, resultList) {
        if (err) {
            process.send('error: Failed to find the Isaac process: ' + err, processExit);
            return;
        }

        if (resultList.length === 0) {
            // Isaac is not already open, so just do file checking and don't actually launch the game
            // (launchIsaac is set to false by default)
            let check1 = checkRacingPlusLuaModCurrent();
            let check2 = checkOtherModsEnabled();
            checkOptionsINIForModsEnabled(); // This will automatically enable mods (if they are not already enabled)
            if (check1 === true && check2  === false) {
                startIsaac();
            } else {
                deleteOldLuaMod();
            }
        } else {
            // There should only be 1 "isaac-ng.exe" process
            resultList.forEach(function(ps) {
                // Isaac is currently open, so check to see if we need to restart the game
                let check1 = checkRacingPlusLuaModCurrent();
                let check2 = checkOtherModsEnabled();
                let check3 = checkOptionsINIForModsEnabled();
                if (check1 === true && check2  === false && check3 === true) {
                    // We don't need to restart the game, so we don't have to do anything at all
                    process.send('The Lua mod is current and no other mods are enabled.', processExit);
                    return;
                } else {
                    launchIsaac = true;
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
            return;
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
        return;
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
        return;
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

function checkOptionsINIForModsEnabled() {
    // Check to see if the user has ALL mods disabled (by pressing "Tab" in the mods menu)
    log.info('Checking the "options.ini" file to see if "EnabledMods=1".');
    let optionsPath = path.join(modsPath, '..', 'Binding of Isaac Afterbirth+', 'options.ini');
    if (fs.existsSync(optionsPath) === false) {
        process.send('error: The "options.ini" file does not exist.', processExit);
        return;
    }

    // Check for "EnableMods=1" in the "options.ini" file
    let optionsFile = fs.readFileSync(optionsPath, 'utf8');
    let match = optionsFile.match(/EnableMods=0/);
    if (match) {
        // Change it to 1 and rewrite the file
        optionsFile = optionsFile.replace('EnableMods=0', 'EnableMods=1');
        try {
            fs.writeFileSync(optionsPath, optionsFile, 'utf8');
        } catch(err) {
            process.send('error: Failed to write to the "options.ini" file: ' + err, processExit);
            return;
        }
        return false;
    } else {
        return true;
    }
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
                    return;
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
                    return;
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
                return;
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
    let newModPath;
    if (isDev) {
        newModPath = path.join('assets', 'mod', 'Racing+');
    } else {
        newModPath = path.join('app.asar', 'assets', 'mod', 'Racing+');
    }
    fs.copy(newModPath, path.join(modsPath, 'Racing+'), function (err) {
        if (err) {
            process.send('error: Failed to copy the new Racing+ Lua mod: ' + err, processExit);
            return;
        }
        enableBossCutscenes();
    });
}

// We can revert boss cutscenes to vanilla by deleting a single file, for users that are used to vanilla
function enableBossCutscenes() {
    // Default to deleting boss cutscenes
    let bossCutscenes = false;
    if (typeof settings.get('bossCutscenes') !== 'undefined') {
        if (settings.get('bossCutscenes') === true) {
            bossCutscenes = true;
        }
    }

    if (bossCutscenes) {
        log.info('Re-enabling boss cutscenes.');
        try {
            fs.removeSync(path.join(modsPath, 'Racing+', 'resources', 'gfx', 'ui', 'boss', 'versusscreen.anm2'));
        } catch(err) {
            process.send('error: Failed to delete the "versusscreen.anm2" file in order to enable boss cutscenes for the Racing+ Lua mod: ' + err, processExit);
            return;
        }
    }

    startIsaac();
}

// Start Isaac
function startIsaac() {
    // Use Steam to launch it so that we don't have to bother with finding out where the binary is
    if (launchIsaac) {
        log.info('Launching Isaac.');
        opn('steam://rungameid/250900');
    }

    // The child will stay alive even if the parent has closed
    setTimeout(function() {
        process.exit();
    }, 30000); // We need delay before exiting or else Isaac won't actually open
}
