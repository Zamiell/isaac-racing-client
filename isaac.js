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
const tasklist = require('tasklist');
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
var modPath;
var IsaacOpen = false;
var IsaacPID;
var fileSystemValid = true; // By default, we assume the user has everything set up correctly
var steamCloud; // This will get filled in during the "checkOptionsINIForModsEnabled" function
var secondTime = false; // We might have to do everything twice

// The parent will communicate with us, telling us the path to the log file
process.on('message', function(message) {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    if (message === 'exit') {
        process.exit();
    }

    // If the message is not "exit", we can assume that it is the mods path
    modPath = message;
    log.info('Starting Isaac checks with mod path: ' + modPath);

    // The logic in this file is only written to support Windows, OS X, and Linux
    if (process.platform !== 'win32' && // This will return "win32" even on 64-bit Windows
        process.platform !== 'darwin' &&
        process.platform !== 'linux') {

        process.send('The "' + process.platform + '" platform is not supported for the file system integrity checks.', processExit);
        return;
    }

    // Check to see if the mods directory exists
    if (fs.existsSync(modPath) === false) {
        process.send('error: Failed to find the Racing+ mod at:<br/><code>' + modPath + '</code><br />Are you sure that you subscribed to it on the Steam Workshop AND have launched the game at least one time since then? If you did, double check your mods directory to make sure that Steam actually downloaded it.<br /><br />(By default, the mods directory is located at:<br /><code>C:\\Users\\[YourUsername]\\Documents\\My Games\\Binding of Isaac Afterbirth+ Mods\\racing+_857628390\\</code><br />For more information, see the download instructions at: <code>https://isaacracing.net/download</code>', processExit);
        return;
    }

    // Begin the work
    checkIsaacOpen();
});

// If we make changes to files and Isaac is closed, it will overwrite all of our changes
// So first, we need to find out if it is open
function checkIsaacOpen() {
    log.info('Checking to see if Isaac is open.');
    if (process.platform === 'win32') { // This will return "win32" even on 64-bit Windows
        // On Windows, we use the taskkill module (the ps-node module is very slow)
        let processName = 'isaac-ng.exe';
        tasklist({
            filter: ['Imagename eq ' + processName], // https://technet.microsoft.com/en-us/library/bb491010.aspx
        }).then(function(data) {
            if (data.length === 1) {
                IsaacOpen = true;
                IsaacPID = data[0].pid;
                checkOptionsINIForModsEnabled();
            } else {
                process.send('error: Somehow, you have more than one "isaac-ng.exe" program open.', processExit);
                return;
            }
        }, function(err) {
            // Isaac is closed
            checkOptionsINIForModsEnabled();
        });
    } else if (process.platform === 'darwin' || process.platform === 'linux') { // macOS, Linux
        // On macOS and Linux, we use the ps-node module
        let processName = process.platform === 'darwin' ? 'The Binding of Isaac Afterbirth+' : 'isaac\\.(i386|x64)';
        ps.lookup({
            command: processName,
        }, function(err, resultList) {
            if (err) {
                process.send('error: Failed to find the Isaac process: ' + err, processExit);
                return;
            }

            if (resultList.length === 0) {
                // Isaac is closed
                checkOptionsINIForModsEnabled();
            } else {
                // Isaac is already open
                // There should only be 1 "isaac-ng.exe" process
                resultList.forEach(function(ps) {
                    IsaacOpen = true;
                    IsaacPID = ps.pid;
                    checkOptionsINIForModsEnabled();
                });
            }
        });
    }
}

function checkOptionsINIForModsEnabled() {
    // Check to see if the user has ALL mods disabled (by pressing "Tab" in the mods menu)
    log.info('Checking the "options.ini" file to see if "EnabledMods=1".');
    let optionsPath;
    if (process.platform === 'linux') {
        optionsPath = path.join(modPath, '..', '..', 'binding of isaac afterbirth+', 'options.ini');
    } else {
        optionsPath = path.join(modPath, '..', '..', 'Binding of Isaac Afterbirth+', 'options.ini');
    }
    if (fs.existsSync(optionsPath) === false) {
        process.send('error: The "options.ini" file does not exist.', processExit);
        return;
    }

    // Check for "EnableMods=1" in the "options.ini" file
    let optionsFile = fs.readFileSync(optionsPath, 'utf8');
    let match1 = optionsFile.match(/\bEnableMods=(\d+)\b/);
    if (match1) {
        let value = match1[1];
        if (value !== '1') {
            // Change it to 1 and rewrite the file
            fileSystemValid = false;
            optionsFile = optionsFile.replace('EnableMods=' + value, 'EnableMods=1');
            try {
                fs.writeFileSync(optionsPath, optionsFile, 'utf8');
            } catch(err) {
                process.send('error: Failed to write to the "options.ini" file: ' + err, processExit);
                return;
            }
        }
    } else {
        process.send('error: Failed to parse the "options.ini" file for the "EnableMods" field.', processExit);
        return;
    }

    // Check for "SteamCloud=1" in the "options.ini" file
    let match2 = optionsFile.match(/\bSteamCloud=(\d+)\b/);
    if (match2) {
        let value = match1[1];
        if (value === '0') {
            steamCloud = true;
        } else if (value === '1') {
            steamCloud = false;
        } else {
            process.send('error: The "SteamCloud" field in "options.ini" is not set to either 0 or 1.', processExit);
            return;
        }
    } else {
        process.send('error: Failed to parse the "options.ini" file for the "SteamCloud" field.', processExit);
        return;
    }

    checkOtherModsEnabled();
}

function checkOtherModsEnabled() {
    log.info('Checking to see if any other mods are enabled.');

    /*
        Note that it is possible for a mod to have a "disable.it" in a mod's directory but still be enabled in game.
        (This can happen if the "disable.it" file was created after the game was already launched, and perhaps other ways.)
        To counteract this, we could always force Isaac to restart upon Racing+ launching.
        However, this would mean that if a user's internet drops during the race, they would get booted out of the game.
        So let's leave open this loophole for now.
    */

    // Go through all the subdirectories of the "Binding of Isaac Afterbirth+ Mods" folder
    let files = fs.readdirSync(path.join(modPath, '..'));
    let otherModsEnabled = false;
    for (let file of files) {
        // Ignore normal files in this directory (there shouldn't be any)
        if (fs.statSync(path.join(modPath, '..', file)).isDirectory() === false) {
            continue;
        }

        if (file === path.basename(modPath)) {
            // This is the Racing+ mod subdirectory
            if (fs.existsSync(path.join(modPath, 'disable.it'))) {
                // The Racing+ mod is not enabled
                fileSystemValid = false;

                // Enable it by removing the "disable.it" file
                try {
                    fs.removeSync(path.join(modPath, 'disable.it'));
                } catch(err) {
                    process.send('error: Failed to remove the "disable.it" file for the Racing+ Lua mod: ' + err, processExit);
                    return;
                }
            }
        } else {
            if (fs.existsSync(path.join(modPath, '..', file, 'disable.it')) === false) {
                log.info('Making a "disable.it" for: ' + file);
                // Some other mod is enabled
                fileSystemValid = false;

                // Disable it by writing a 0 byte "disable.it" file
                try {
                    fs.writeFileSync(path.join(modPath, '..', file, 'disable.it'), '', 'utf8');
                } catch(err) {
                    process.send('error: Failed to disable one of the existing mods: ' + err, processExit);
                    return;
                }
            }
        }
    }

    enableBossCutscenes();
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
        let bossCutsceneFile = path.join(modPath, 'resources', 'gfx', 'ui', 'boss', 'versusscreen.anm2');
        if (fs.existsSync(bossCutsceneFile)) {
            log.info('Re-enabling boss cutscenes.');
            try {
                fs.removeSync(bossCutsceneFile);
            } catch(err) {
                process.send('error: Failed to delete the "versusscreen.anm2" file in order to enable boss cutscenes for the Racing+ Lua mod: ' + err, processExit);
                return;
            }
        }
    } else {
        let bossCutsceneFile = path.join(modPath, 'resources', 'gfx', 'ui', 'boss', 'versusscreen.anm2');
        if (fs.existsSync(bossCutsceneFile) === false) {
            log.info('Disabling boss cutscenes.');
            let newBossCutsceneFile;
            if (isDev) {
                newBossCutsceneFile = path.join('assets', 'mod', 'versusscreen.anm2');
            } else {
                newBossCutsceneFile = path.join('app.asar', 'assets', 'mod', 'versusscreen.anm2');
            }
            try {
                fs.copySync(newBossCutsceneFile, bossCutsceneFile);
            } catch(err) {
                process.send('error: Failed to copy the "versusscreen.anm2" file in order to disable boss cutscenes for the Racing+ Lua mod: ' + err, processExit);
                return;
            }
        }
    }

    checkOneMillionPercent();
}

function checkOneMillionPercent() {
    if (steamCloud === true) {
        // TODO
    } else if (steamCloud === false) {
        // TODO
    } else {
        process.send('error: Could not detect whether "SteamCloud" was enabled or disabled.', processExit);
        return;
    }

    closeIsaac();
}

function closeIsaac() {
    // If we are doing this the second time around, just jump to the end
    if (secondTime === true) {
        startIsaac();
        return;
    }

    if (IsaacOpen === false) {
        // Isaac wasn't open, we are done
        // Don't automatically open Isaac for them; it might be annoying, so we can let them open the game manually
        log.info('File system validation passed. (Isaac was not open.)');
        setTimeout(function() {
            processExit();
        }, 5000);
        return;
    }

    if (fileSystemValid === true) {
        // Isaac was open, but all of the file system checks passed, so we don't have to reboot Isaac
        log.info('File system validation passed. (Isaac was open.)');
        setTimeout(function() {
            processExit();
        }, 5000);
        return;
    }

    log.info('File system checks failed, so we need to restart Isaac.');
    ps.kill(IsaacPID.toString(), function(err) { // This expects the first argument to be in a string for some reason
        if (err) {
            process.send('error: Failed to close Isaac: ' + err, processExit);
            return;
        } else {
            // We have to redo all of the steps from before, since when Isaac closes it overwrites files
            secondTime = true;
            checkOptionsINIForModsEnabled();
        }
    });
}

// Start Isaac
function startIsaac() {
    // Use Steam to launch it so that we don't have to bother with finding out where the binary is
    opn('steam://rungameid/250900');

    // The child will stay alive even if the parent has closed
    setTimeout(function() {
        process.exit();
    }, 30000); // We need delay before exiting or else Isaac won't actually open
}
