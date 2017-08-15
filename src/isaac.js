/*
    Child process that validating everything is right in the file system and then launches the game
*/

// Imports
const fs = require('fs-extra');
const klawSync = require('klaw-sync');
const path = require('path');
const isDev = require('electron-is-dev');
const tracer = require('tracer');
const Raven = require('raven');
const ps = require('ps-node');
const tasklist = require('tasklist');
const opn = require('opn');
const hashFiles = require('hash-files');
const teeny = require('teeny-conf');

// Handle errors
process.on('uncaughtException', (err) => {
    process.send(`error: ${err}`, processExit);
});
const processExit = () => {
    process.exit();
};

// Logging (code duplicated between main, renderer, and child processes because of require/nodeRequire issues)
const log = tracer.dailyfile({
    // Log file settings
    root: path.join(__dirname, '..'),
    logPathFormat: '{{root}}/Racing+ {{date}}.log',
    splitFormat: 'yyyy-mm-dd',
    maxLogFiles: 10,

    // Global tracer settings
    format: '{{timestamp}} <{{title}}> {{file}}:{{line}} - {{message}}',
    dateformat: 'ddd mmm dd HH:MM:ss Z',
    transport: (data) => {
        // Log errors to the JavaScript console in addition to the log file
        console.log(data.output);
    },
});

// Get the version
const packageFileLocation = path.join(__dirname, '..', 'package.json');
const packageFile = fs.readFileSync(packageFileLocation, 'utf8');
const version = `v${JSON.parse(packageFile).version}`;

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
}).install();

// Open the file that contains all of the user's settings
// (we use teeny-conf instead of localStorage because localStorage persists after uninstallation)
const settingsFile = path.join(__dirname, '..', 'settings.json'); // This will be created if it does not exist already
const settings = new teeny(settingsFile); // eslint-disable-line new-cap
settings.loadOrCreateSync();

/*
    Isaac stuff
*/

// Global variables
let modPath;
let IsaacOpen = false;
let IsaacPID;
let fileSystemValid = true; // By default, we assume the user has everything set up correctly
let steamCloud; // This will get filled in during the "checkOptionsINIForModsEnabled" function
let secondTime = false; // We might have to do everything twice

// The parent will communicate with us, telling us the path to the log file
process.on('message', (message) => {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    if (message === 'exit') {
        process.exit();
    }

    // If the message is not "exit", we can assume that it is the mods path
    modPath = message;
    log.info(`Starting Isaac checks with mod path: ${modPath}`);

    // The logic in this file is only written to support Windows, OS X, and Linux
    if (
        process.platform !== 'win32' && // This will return "win32" even on 64-bit Windows
        process.platform !== 'darwin' &&
        process.platform !== 'linux'
    ) {
        process.send(`The "${process.platform}" platform is not supported for the file system integrity checks.`, processExit);
        return;
    }

    // Check to see if the mods directory exists
    if (!fs.existsSync(modPath)) {
        const errorMsg = `error: Failed to find the Racing+ mod at:<br/><code>${modPath}</code><br />Are you sure that you subscribed to it on the Steam Workshop AND have launched the game at least one time since then? If you did, double check your mods directory to make sure that Steam actually downloaded it.<br /><br />(By default, the mods directory is located at:<br /><code>C:\\Users\\[YourUsername]\\Documents\\My Games\\Binding of Isaac Afterbirth+ Mods\\racing+_857628390\\</code><br />For more information, see the download instructions at: <code>https://isaacracing.net/download</code>`;
        process.send(errorMsg, processExit);
        return;
    }

    // Begin the work
    checkOptionsINIForModsEnabled();
});

function checkOptionsINIForModsEnabled() {
    // Check to see if the user has ALL mods disabled (by pressing "Tab" in the mods menu)
    log.info('Checking the "options.ini" file to see if "EnabledMods=1".');
    let optionsPath;
    if (process.platform === 'linux') {
        optionsPath = path.join(modPath, '..', '..', 'binding of isaac afterbirth+', 'options.ini');
    } else {
        optionsPath = path.join(modPath, '..', '..', 'Binding of Isaac Afterbirth+', 'options.ini');
    }
    if (!fs.existsSync(optionsPath)) {
        process.send('error: The "options.ini" file does not exist.', processExit);
        return;
    }

    // Check for "EnableMods=1" in the "options.ini" file
    let optionsFile = fs.readFileSync(optionsPath, 'utf8');
    const match1 = optionsFile.match(/\bEnableMods=(\d+)\b/);
    if (match1) {
        const value = match1[1];
        if (value !== '1') {
            // Change it to 1 and rewrite the file
            fileSystemValid = false;
            optionsFile = optionsFile.replace(`EnableMods=${value}`, 'EnableMods=1');
            try {
                fs.writeFileSync(optionsPath, optionsFile, 'utf8');
            } catch (err) {
                process.send(`error: Failed to write to the "options.ini" file: ${err}`, processExit);
                return;
            }
        }
    } else {
        process.send('error: Failed to parse the "options.ini" file for the "EnableMods" field.', processExit);
        return;
    }

    // Check for "SteamCloud=1" in the "options.ini" file
    const match2 = optionsFile.match(/\bSteamCloud=(\d+)\b/);
    if (match2) {
        const value = match1[1];
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

    checkModIntegrity();
}

function checkModIntegrity() {
    // In development, we don't want to overwrite potential work in progress, so just skip to the next thing
    // (even if we are in production, don't mess with the mod if it is marked as a development folder)
    if (isDev || modPath.includes('dev')) {
        checkOtherModsEnabled();
        return;
    }

    log.info('Checking to see if the Racing+ mod is corrupted.');

    // After an update, Steam can partially download some of the files, which seems to happen pretty commonly
    // (not sure exactly what causes it, perhaps opening the game in the middle of the download)
    let files;
    let backupModPath;
    if (isDev) {
        backupModPath = 'mod';
    } else {
        backupModPath = path.join('app.asar', 'mod');
    }
    try {
        files = klawSync(backupModPath);
    } catch (err) {
        process.send(`error: Failed to enumerate the files in the "${backupModPath}" directory: ${err}`, processExit);
        return;
    }
    for (const fileObject of files) {
        if (!fileObject.stats.isFile()) {
            continue;
        } else if (
            path.basename(fileObject.path) === 'metadata.xml' || // This file will be one version number ahead of the one distributed through steam
            path.basename(fileObject.path) === 'save1.dat' || // These are the IPC files, so it doesn't matter if they are different
            path.basename(fileObject.path) === 'save2.dat' ||
            path.basename(fileObject.path) === 'save3.dat'
        ) {
            continue;
        }

        const path1 = fileObject.path;
        const hash1 = hashFiles.sync({ // This defaults to SHA1
            files: path1,
        });

        // Get the path of the matching file in the real mod directory
        const backupModPathDoubleSlashes = backupModPath.replace(/\\/g, '\\\\');
        const re = new RegExp(`.+${backupModPathDoubleSlashes}(.+)`);
        const suffix = path1.match(re)[1];
        const path2 = path.join(modPath, suffix);

        let copyFile = false;

        if (fs.existsSync(path2)) {
            const hash2 = hashFiles.sync({ // This defaults to SHA1
                files: path2,
            });
            if (hash1 !== hash2) {
                copyFile = true;
                fs.removeSync(path2);
            }
        } else {
            copyFile = true;
        }
        if (copyFile) {
            log.error(`File is corrupt or missing: ${path2}`);
            fileSystemValid = false;
            fs.copySync(path1, path2);
        }
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
    const files = fs.readdirSync(path.join(modPath, '..'));
    for (const file of files) {
        // Ignore normal files in this directory (there shouldn't be any)
        if (!fs.statSync(path.join(modPath, '..', file)).isDirectory()) {
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
                } catch (err) {
                    process.send(`error: Failed to remove the "disable.it" file for the Racing+ Lua mod: ${err}`, processExit);
                    return;
                }
            }
        } else if (!fs.existsSync(path.join(modPath, '..', file, 'disable.it'))) {
            log.info(`Making a "disable.it" for: ${file}`);
            // Some other mod is enabled
            fileSystemValid = false;

            // Disable it by writing a 0 byte "disable.it" file
            try {
                fs.writeFileSync(path.join(modPath, '..', file, 'disable.it'), '', 'utf8');
            } catch (err) {
                process.send(`error: Failed to disable one of the existing mods: ${err}`, processExit);
                return;
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
        if (settings.get('bossCutscenes')) {
            bossCutscenes = true;
        }
    }

    const bossCutsceneFile = path.join(modPath, 'resources', 'gfx', 'ui', 'boss', 'versusscreen.anm2');
    if (bossCutscenes) {
        // Make sure the file is deleted
        if (fs.existsSync(bossCutsceneFile)) {
            log.info('Re-enabling boss cutscenes.');
            try {
                fs.removeSync(bossCutsceneFile);
            } catch (err) {
                const errorMsg = `error: Failed to delete the "versusscreen.anm2" file in order to enable boss cutscenes for the Racing+ Lua mod: ${err}`;
                process.send(errorMsg, processExit);
                return;
            }
        }
    } else if (!fs.existsSync(bossCutsceneFile)) {
        // Make sure the file is there
        log.info('Disabling boss cutscenes.');
        let newBossCutsceneFile;
        if (isDev) {
            newBossCutsceneFile = path.join('mod', 'resources', 'gfx', 'ui', 'boss', 'versusscreen.anm2');
        } else {
            newBossCutsceneFile = path.join('app.asar', 'mod', 'resources', 'gfx', 'ui', 'boss', 'versusscreen.anm2');
        }
        try {
            fs.copySync(newBossCutsceneFile, bossCutsceneFile);
        } catch (err) {
            const errorMsg = `error: Failed to copy the "versusscreen.anm2" file in order to disable boss cutscenes for the Racing+ Lua mod: ${err}`;
            process.send(errorMsg, processExit);
            return;
        }
    }

    checkOneMillionPercent();
}

function checkOneMillionPercent() {
    if (steamCloud) {
        // TODO
    } else {
        // TODO
    }

    closeIsaac();
}

// If we make changes to files and Isaac is closed, it will overwrite all of our changes
// So first, we need to find out if it is open
function checkIsaacOpen() {
    // If we are doing this the second time around, just jump to the end
    if (secondTime) {
        startIsaac();
        return;
    }

    log.info('Checking to see if Isaac is open.');
    if (process.platform === 'win32') { // This will return "win32" even on 64-bit Windows
        // On Windows, we use the taskkill module (the ps-node module is very slow)
        const processName = 'isaac-ng.exe';
        tasklist({
            filter: [`Imagename eq ${processName}`], // https://technet.microsoft.com/en-us/library/bb491010.aspx
        }).then((data) => {
            if (data.length === 1) {
                IsaacOpen = true;
                IsaacPID = data[0].pid;
                closeIsaac();
            } else {
                process.send('error: Somehow, you have more than one "isaac-ng.exe" program open.', processExit);
            }
        }, (err) => {
            // Isaac is closed
            closeIsaac();
        });
    } else if (process.platform === 'darwin' || process.platform === 'linux') { // macOS, Linux
        // On macOS and Linux, we use the ps-node module
        const processName = process.platform === 'darwin' ? 'The Binding of Isaac Afterbirth+' : 'isaac\\.(i386|x64)';
        ps.lookup({
            command: processName,
        }, (err, resultList) => {
            if (err) {
                process.send(`error: Failed to find the Isaac process: ${err}`, processExit);
                return;
            }

            if (resultList.length === 0) {
                // Isaac is closed
                closeIsaac();
            } else {
                // Isaac is already open
                // There should only be 1 "isaac-ng.exe" process
                resultList.forEach((ps2) => {
                    IsaacOpen = true;
                    IsaacPID = ps2.pid;
                    closeIsaac();
                });
            }
        });
    }
}

function closeIsaac() {
    if (!IsaacOpen) {
        // Isaac wasn't open, we are done
        // Don't automatically open Isaac for them; it might be annoying, so we can let them open the game manually
        log.info('File system validation passed. (Isaac was not open.)');
        setTimeout(() => {
            processExit();
        }, 5000);
        return;
    }

    if (fileSystemValid) {
        // Isaac was open, but all of the file system checks passed, so we don't have to reboot Isaac
        log.info('File system validation passed. (Isaac was open.)');
        setTimeout(() => {
            processExit();
        }, 5000);
        return;
    }

    log.info('File system checks failed, so we need to restart Isaac.');
    ps.kill(IsaacPID.toString(), (err) => { // This expects the first argument to be in a string for some reason
        if (err) {
            process.send(`error: Failed to close Isaac: ${err}`, processExit);
        } else {
            // We have to redo all of the steps from before, since when Isaac closes it overwrites files
            secondTime = true;
            setTimeout(() => {
                checkOptionsINIForModsEnabled();
            }, 1000); // Pause an extra second to let all file writes occur
        }
    });
}

// Start Isaac
function startIsaac() {
    // Use Steam to launch it so that we don't have to bother with finding out where the binary is
    opn('steam://rungameid/250900');

    // The child will stay alive even if the parent has closed
    setTimeout(() => {
        process.exit();
    }, 30000); // We need delay before exiting or else Isaac won't actually open
}
