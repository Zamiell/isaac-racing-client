/*
    Child process that validates everything is right in the file system
*/

// Imports
const fs = require('fs-extra');
const path = require('path');
const isDev = require('electron-is-dev');
const Raven = require('raven');
const ps = require('ps-node');
const tasklist = require('tasklist');
const opn = require('opn');
const hashFiles = require('hash-files');
const teeny = require('teeny-conf');
const Registry = require('winreg');

// Handle errors
process.on('uncaughtException', (err) => {
    process.send(`error: ${err}`, processExit);
});
const processExit = () => {
    process.exit();
};

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
let settingsRoot;
if (isDev) {
    // For development, this puts the settings file in the root of the repository
    settingsRoot = path.join(__dirname, '..');
} else {
    // For production, this puts the settings file in the "Programs" directory
    // (the __dirname is "C:\Users\[Username]\AppData\Local\Programs\RacingPlus\resources\app.asar\src")
    settingsRoot = path.join(__dirname, '..', '..', '..', '..');
}
const settingsFile = path.join(settingsRoot, 'settings.json'); // This will be created if it does not exist already
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
let steamCloud; // This will get filled in during the "checkOptionsINIForModsEnabled" function to be either true or false
let steamPath; // This will get filled in during the "checkSteam1" function
let steamID; // This will get filled in during the "checkSteam2" function
let atLeastOneSaveFileChecked = false;
let fullyUnlockedSaveFileFound = false;
let secondTime = false; // We might have to do everything twice

// The parent will communicate with us, telling us the path to the mods path
process.on('message', (message) => {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    if (message === 'exit') {
        process.exit();
    }

    // If the message is not "exit", we can assume that it is the mods path
    modPath = message;
    process.send(`Starting Isaac checks with a mod path of: ${modPath}`);

    // The logic in this file is only written to support Windows, OS X, and Linux
    if (
        process.platform !== 'win32' && // This will return "win32" even on 64-bit Windows
        process.platform !== 'darwin' &&
        process.platform !== 'linux'
    ) {
        process.send(`The "${process.platform}" platform is not supported for the file system integrity checks.`, processExit);
        return;
    }

    // Begin the work
    checkOptionsINIForModsEnabled();
});

function checkOptionsINIForModsEnabled() {
    // Check to see if the user has ALL mods disabled (by pressing "Tab" in the mods menu)
    process.send('Checking the "options.ini" file to see if "EnabledMods=1".');
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

    checkOneMillionPercent();
}

function checkOneMillionPercent() {
    process.send('Checking the save files to see if there is at least one fully unlocked file.');

    if (process.platform !== 'win32') {
        process.send('Save file checking is not supported on OS X / Linux. Skipping this part.');
        checkModIntegrity();
    }

    if (steamCloud) {
        checkSteam1();
    } else {
        checkDocuments();
    }
}

function checkSteam1() {
    // Get the path of where the user has Steam installed to
    // We can find this in the Windows registry
    const steamKey = new Registry({
        hive: Registry.HKCU,
        key: '\\Software\\Valve\\Steam',
    });
    steamKey.get('SteamPath', (err, item) => {
        if (err) {
            process.send('error: Failed to read the Windows registry when trying to figure out what the Steam path is.', processExit);
            return;
        }

        steamPath = item.value;
        checkSteam2();
    });
}

function checkSteam2() {
    process.send(`Steam path found: ${steamPath}`);

    // Get the Steam ID of the active user
    // We can also find this in the Windows registry
    const steamKey = new Registry({
        hive: Registry.HKCU,
        key: '\\Software\\Valve\\Steam\\ActiveProcess',
    });
    steamKey.get('ActiveUser', (err, item) => {
        if (err) {
            process.send('error: Failed to read the Windows registry when trying to figure out what the active Steam user is.', processExit);
            return;
        }

        steamID = item.value;
        checkSteam3();
    });
}

function checkSteam3() {
    // Go through the 3 save files, if they exist
    for (let i = 1; i <= 3; i++) {
        const saveFile = path.join(steamPath, 'userdata', steamID, '250900', 'remote', `abp_persistentgamedata${i}.dat`);
        if (checkSaveFile(saveFile)) {
            break;
        }
    }

    if (!atLeastOneSaveFileChecked || !fullyUnlockedSaveFileFound) {
        process.send(`error: NO SAVE ${steamCloud}`, processExit);
        return;
    }

    checkModIntegrity();
}

function checkDocuments() {
    const documentsPath = path.join(modPath, '..', '..', 'Binding of Isaac Afterbirth+');

    for (let i = 1; i <= 3; i++) {
        const saveFile = path.join(documentsPath, `persistentgamedata${i}.dat`);
        if (checkSaveFile(saveFile)) {
            break;
        }
    }

    if (!atLeastOneSaveFileChecked || !fullyUnlockedSaveFileFound) {
        process.send(`error: NO SAVE ${steamCloud}`, processExit);
        return;
    }

    checkModIntegrity();
}

function checkSaveFile(saveFile) {
    try {
        if (fs.existsSync(saveFile)) {
            atLeastOneSaveFileChecked = true;
            const saveFileBytes = fs.readFileSync(saveFile); // We don't specify any encoding to get the raw bytes
            // "saveFileBytes.data" is now an array of bytes
            // TODO CHECK BYTES

            if (true) {
                fullyUnlockedSaveFileFound = true;
                return true;
            }
        }
    } catch (err) {
        process.send(`error: Failed to check for the "${saveFile}" file: ${err}`, processExit);
    }

    return false;
}

// After an update, Steam can partially download some of the files, which seems to happen pretty commonly
// (not sure exactly what causes it, perhaps opening the game in the middle of the download)
// We computed the SHA1 hash of every file during the build process and wrote it to "sha1.json";
// compare all files in the mod directory to this JSON
function checkModIntegrity() {
    // Check to see if the mods directory exists
    if (!fs.existsSync(modPath)) {
        process.send(`The Racing+ mod was not found at "${modPath}". Skipping Racing+ mod related checks.`);
        checkIsaacOpen();
        return;
    }

    // In development, we don't want to overwrite potential work in progress, so just skip to the next thing
    // (even if we are in production, we don't mess with the mod if it is marked as a development folder)
    if (isDev || modPath.includes('dev')) {
        checkIsaacOpen();
        return;
    }

    process.send('Checking to see if the Racing+ mod is corrupted.');

    // Get the checksums
    let backupModPath;
    if (isDev) {
        backupModPath = 'mod';
    } else {
        backupModPath = path.join('app.asar', 'mod');
    }
    const checksumsPath = path.join(backupModPath, 'sha1.json');
    let checksums;
    try {
        checksums = JSON.parse(fs.readFileSync(checksumsPath, 'utf8'));
    } catch (err) {
        process.send(`error: Failed to read the "${checksumsPath}" file: ${err}`, processExit);
        return;
    }

    // Check to see if it is corrupt or missing
    // (skip this for now)
    enableBossCutscenes();

    /*
    // Each key of the JSON is the relative path to the file
    for (const relativePath of Object.keys(checksums)) {
        const filePath = path.join(modPath, relativePath);
        const backupFilePath = path.join(backupModPath, relativePath);
        const backupFileHash = checksums[relativePath];

        let copyFile = false; // If this gets set to true, the file is missing or corrupt
        if (fs.existsSync(filePath)) {
            const fileHash = hashFiles.sync({ // This defaults to SHA1
                files: filePath,
            });
            if (fileHash !== backupFileHash) {
                copyFile = true;
                try {
                    fs.removeSync(filePath);
                } catch (err) {
                    process.send(`error: Failed to delete the "${filePath}" file (since it was corrupt): ${err}`, processExit);
                    return;
                }
            }
        } else {
            copyFile = true;
        }

        // Copy it
        if (copyFile) {
            process.send(`File is corrupt or missing: ${filePath}`);
            fileSystemValid = false;
            try {
                fs.copySync(backupFilePath, filePath);
            } catch (err) {
                process.send(`error: Failed to copy over the "${backupFilePath}" file (since the original was corrupt): ${err}`, processExit);
                return;
            }
        }
    }

    enableBossCutscenes();
    */
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
            process.send('Re-enabling boss cutscenes.');
            fileSystemValid = false;
            try {
                fs.removeSync(bossCutsceneFile);
            } catch (err) {
                const errorMsg = `error: Failed to delete the "versusscreen.anm2" file in order to enable boss cutscenes for the Racing+ Lua mod: ${err}`;
                process.send(errorMsg, processExit);
                return;
            }
        }
    }

    checkIsaacOpen();
}

// If we make changes to files and Isaac is closed, it will overwrite all of our changes
// So first, we need to find out if it is open
function checkIsaacOpen() {
    // If all of the file system checks passed, we don't care if Isaac is open or not, we are finished
    if (fileSystemValid && !secondTime) {
        process.send('File system validation passed.');
        setTimeout(() => {
            processExit();
        }, 5000);
        return;
    }

    // If we are doing this the second time around, we already know that Isaac is closed
    if (secondTime) {
        startIsaac();
        return;
    }

    process.send('Checking to see if Isaac is open.');
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
        process.send('File system validation passed. (Isaac was not open.)');
        setTimeout(() => {
            processExit();
        }, 5000);
        return;
    }

    process.send('File system checks failed, so we need to restart Isaac.');
    ps.kill(IsaacPID.toString(), (err) => { // This expects the first argument to be in a string for some reason
        if (err) {
            process.send(`error: Failed to close Isaac: ${err}`, processExit);
            return;
        }

        // When Isaac closes, it will overwrite the "options.ini" file
        // So redo all of the steps from before to be thorough
        secondTime = true;
        setTimeout(() => {
            checkOptionsINIForModsEnabled();
        }, 1000); // Pause an extra second to let all file writes occur
    });
}

// Start Isaac
function startIsaac() {
    // Use Steam to launch it so that we don't have to bother with finding out where the binary executable is
    opn('steam://rungameid/250900');

    // The child will stay alive even if the parent has closed
    setTimeout(() => {
        process.exit();
    }, 30000); // We need delay before exiting or else Isaac won't actually open
}
