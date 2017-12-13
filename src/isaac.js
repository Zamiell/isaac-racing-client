/*
    Child process that validates everything is right in the file system
*/

// Imports
const fs = require('fs');
const klawSync = require('klaw-sync');
const path = require('path');
const isDev = require('electron-is-dev');
const Raven = require('raven');
const ps = require('ps-node');
const tasklist = require('tasklist');
const opn = require('opn');
const hashFiles = require('hash-files');
const Registry = require('winreg');
const version = require('./version');

// Handle errors
process.on('uncaughtException', (err) => {
    process.send(`error: ${err}`, processExit);
});
const processExit = () => {
    process.exit();
};

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
let modPath;
let documentsDir;
let IsaacOpen = false;
let IsaacPID;
let fileSystemValid = true; // By default, we assume the mod is not corrupted
let steamCloud; // This will get filled in during the "checkOptionsINI" function to be either true or false
let steamPath; // This will get filled in during the "checkSteam1()" function
let saveFileDir; // This will get filled in during the "checkOneMillionPercent()" function or the "checkSteam3()" function
let fullyUnlockedSaveFileFound = false;

// The parent will communicate with us, telling us the path to the mods path
process.on('message', (message) => {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    if (message === 'exit') {
        process.exit();
    }

    // If the message is not "exit", we can assume that it is the mods path
    modPath = message;
    process.send(`Starting Isaac checks with a mod path of: ${modPath}`);

    // The logic in this file is only written to support Windows, macOS, and Linux
    if (
        process.platform !== 'win32' && // This will return "win32" even on 64-bit Windows
        process.platform !== 'darwin' &&
        process.platform !== 'linux'
    ) {
        process.send(`The "${process.platform}" platform is not supported for the file system integrity checks.`, processExit);
        return;
    }

    // Begin the work
    if (process.platform === 'win32') {
        // This will check to see if the user has at least one fully unlocked save file;
        // however, the code only works on Windows and needs to be made cross-platform
        checkOptionsINI();
    } else {
        // Skip checking for the fully unlocked save file and go to the next thing after that
        checkModIntegrity();
    }
});

function checkOptionsINI() {
    process.send('Checking the "options.ini" file for "SteamCloud".');
    if (process.platform === 'linux') {
        documentsDir = path.join(modPath, '..', '..', 'binding of isaac afterbirth+');
    } else {
        documentsDir = path.join(modPath, '..', '..', 'Binding of Isaac Afterbirth+');
    }
    const optionsPath = path.join(documentsDir, 'options.ini');
    if (!fs.existsSync(optionsPath)) {
        process.send(`error: Failed to find the "options.ini" file at "${optionsPath}".`, processExit);
        return;
    }

    // Check for "SteamCloud=1" in the "options.ini" file
    const optionsFile = fs.readFileSync(optionsPath, 'utf8');
    const match = optionsFile.match(/\bSteamCloud=(\d+)\b/);
    if (match) {
        const value = match[1];
        if (value === '0') {
            steamCloud = false;
        } else if (value === '1') {
            steamCloud = true;
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
        process.send('Save file checking is not supported on macOS / Linux. Skipping this part.');
        checkModIntegrity();
    }

    if (steamCloud) {
        // Their save files are located in their Steam directory, so we have to check 2 registry entries
        checkSteam1();
    } else {
        // Their save files are in the documents directory that we found/declared earlier
        saveFileDir = documentsDir;
        checkOneMillionPercent2();
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

        let steamID = item.value; // This comes from the registry in hexidecimal format
        steamID = parseInt(steamID, 16); // Convert it to decimal, which will match what the directory is
        steamID = steamID.toString(); // Convert it to a string so that it can be used in the path.join() function
        saveFileDir = path.join(steamPath, 'userdata', steamID, '250900', 'remote');
        checkOneMillionPercent2();
    });
}

function checkOneMillionPercent2() {
    // Go through the 3 save files, if they exist
    for (let i = 1; i <= 3; i++) {
        let saveFile;
        if (steamCloud) {
            saveFile = path.join(saveFileDir, `abp_persistentgamedata${i}.dat`);
        } else {
            saveFile = path.join(saveFileDir, `persistentgamedata${i}.dat`);
        }
        checkSaveFile(saveFile);
        if (fullyUnlockedSaveFileFound) {
            break;
        }
    }

    if (!fullyUnlockedSaveFileFound) {
        // We need to send both the steamCloud variable and the path to the save directory so that
        // the client knows the correct prefix for the save file to replace
        process.send(`error: NO SAVE ${(steamCloud ? '1' : '0')} "${saveFileDir}"`, processExit);
        return;
    }

    checkModIntegrity();
}

function checkSaveFile(saveFile) {
    try {
        if (fs.existsSync(saveFile)) {
            const saveFileBytes = fs.readFileSync(saveFile); // We don't specify any encoding to get the raw bytes
            // "saveFileBytes.data" is now an array of bytes

            // Achievements are located at 0x20 (32) + achievement number
            // So we need to check 33 through 371
            for (let i = 33; i <= 371; i++) {
                if (saveFileBytes[i] === 1) {
                    fullyUnlockedSaveFileFound = true;
                    break;
                }
            }
        }
    } catch (err) {
        process.send(`error: Failed to check for the "${saveFile}" file: ${err}`, processExit);
    }
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
        process.send('The Racing+ mod directory has "dev" in it. Skipping Racing+ mod related checks.', processExit);
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

    // Check to see if the mod is corrupt or missing
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
                process.send(`File is corrupt: ${filePath}`);
                copyFile = true;
                try {
                    fs.unlinkSync(filePath);
                } catch (err) {
                    process.send(`error: Failed to delete the "${filePath}" file (since it was corrupt): ${err}`, processExit);
                    return;
                }
            }
        } else {
            process.send(`File is not corrupt but is missing: ${filePath}`);
            copyFile = true;
        }

        // Copy it
        if (copyFile) {
            fileSystemValid = false;
            try {
                // "fs.copyFileSync" is only in Node 8.5.0 and Electron isn't on that version yet
                // fs.copyFileSync(backupFilePath, filePath);
                const data = fs.readFileSync(backupFilePath);
                fs.writeFileSync(filePath, data);
            } catch (err) {
                process.send(`error: Failed to copy over the "${backupFilePath}" file (since the original was corrupt): ${err}`, processExit);
                return;
            }
        }
    }

    // To be thorough, also go through the mod directory and check to see if there are any extraneous files that are not on the hash list
    let modFiles;
    try {
        modFiles = klawSync(modPath);
    } catch (err) {
        process.send(`error: Failed to enumerate the files in the "${modPath}" directory: ${err}`, processExit);
        return;
    }
    for (const fileObject of modFiles) {
        // Get the relative path by chopping off the left side
        const modFile = fileObject.path.substring(modPath.length + 1); // We add one to remove the trailing slash

        if (!fileObject.stats.isFile()) {
            // Ignore directories; even extraneous directories shouldn't cause any harm
            continue;
        } else if (
            path.basename(modFile) === 'metadata.xml' || // This file will be one version number ahead of the one distributed through steam
            path.basename(modFile) === 'save1.dat' || // These are the IPC files, so it doesn't matter if they are different
            path.basename(modFile) === 'save2.dat' ||
            path.basename(modFile) === 'save3.dat' ||
            path.basename(modFile) === 'disable.it' // They might have the mod disabled
        ) {
            continue;
        }

        // Delete all files that are not found within the JSON hashes
        if (!Object.prototype.hasOwnProperty.call(checksums, modFile)) {
            const filePath = path.join(modPath, modFile);
            process.send(`Extraneous file found: ${filePath}`);
            fileSystemValid = false;
            try {
                fs.unlinkSync(filePath);
            } catch (err) {
                process.send(`error: Failed to delete the extraneous "${filePath}" file: ${err}`, processExit);
                return;
            }
        }
    }

    // We are finished checking the integrity of the Racing+ Lua mod
    if (fileSystemValid) {
        // We are done
        process.send('File system validation passed.', processExit);
    } else {
        checkIsaacOpen();
    }
}

// The Racing+ mod was corrupt, so we need to restart Isaac to ensure that everything is loaded correctly
// First, find out if Isaac is open
function checkIsaacOpen() {
    process.send('Checking to see if Isaac is open.');
    if (process.platform === 'win32') { // This will return "win32" even on 64-bit Windows
        // On Windows, we use the taskkill module (the ps-node module is very slow)
        const processName = 'isaac-ng.exe';
        tasklist({
            filter: [`Imagename eq ${processName}`], // https://technet.microsoft.com/en-us/library/bb491010.aspx
        }).then((data) => {
            if (data.length === 0) {
                // Isaac is not open
                closeIsaac();
            } else if (data.length === 1) {
                IsaacOpen = true;
                IsaacPID = data[0].pid;
                closeIsaac();
            } else {
                process.send('error: Somehow, you have more than one "isaac-ng.exe" program open.', processExit);
            }
        }, (err) => {
            // There is a bug with this on non-English platforms:
            // https://github.com/sindresorhus/tasklist/issues/11
            process.send(`error: Failed to detect if Isaac is open: ${err}`, processExit);
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
        // (don't automatically open Isaac for them; it might be annoying, so we can let them open the game manually)
        process.send('File system repair complete. (Isaac was not open.)', processExit);
        return;
    }

    process.send('File system was repaired, so we need to restart Isaac.');
    ps.kill(IsaacPID.toString(), (err) => { // This expects the first argument to be in a string for some reason
        if (err) {
            process.send(`error: Failed to close Isaac: ${err}`, processExit);
            return;
        }

        // Wait a second, and then start Isaac again
        setTimeout(() => {
            startIsaac();
        }, 1000);
    });
}

// Start Isaac
function startIsaac() {
    // Use Steam to launch it so that we don't have to bother with finding out where the binary executable is
    opn('steam://rungameid/250900');

    // The child will stay alive even if the parent has closed
    setTimeout(() => {
        process.exit();
    }, 30000); // Delay 30 seconds before exiting
    // We need to delay before exiting or else Isaac won't actually open
}
