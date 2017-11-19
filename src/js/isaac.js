/*
    Isaac functions
*/

// Imports
const path = nodeRequire('path');
const fs = nodeRequire('fs-extra');
const { ipcRenderer } = nodeRequire('electron');
const globals = nodeRequire('./js/globals');
const misc = nodeRequire('./js/misc');

// This tells the main process to do file-related check
// (check for a fully unlocked save file, check to see if the Racing+ mod is corrupted, etc.)
exports.start = () => {
    // "globals.modPath" is set in main.js
    ipcRenderer.send('asynchronous-message', 'isaac', globals.modPath);

    // Check to see if the mod path exists
    // (this may not exist if they are just using Racing+ to race vanilla or some other custom mod)
    if (!fs.existsSync(globals.modPath)) {
        return true;
    }

    // Store what their R+7/9/14 character order is
    const defaultSaveDatFile = path.join(globals.modPath, 'save-defaults.dat');
    if (!fs.existsSync(globals.modPath)) {
        misc.errorShow(`Failed to find the "${defaultSaveDatFile}" file. Is your Racing+ mod corrupted?`);
        return false;
    }
    for (let i = 1; i <= 3; i++) {
        const saveDatFile = path.join(globals.modPath, `save${i}.dat`);
        if (fs.existsSync(saveDatFile)) {
            let json;
            try {
                json = JSON.parse(fs.readFileSync(saveDatFile, 'utf8'));
            } catch (err) {
                misc.errorShow(`Error while reading the "save${i}.dat" file: ${err}`);
                return false;
            }

            // We only want to replace our stored orders if they are changed from the default
            const orders = ['order7', 'order9', 'order14'];
            for (const order of orders) {
                if (
                    typeof json[order] !== 'undefined' &&
                    json[order] !== null &&
                    json[order].toString() !== '0' &&
                    globals.modLoader[order].toString() === '0'
                ) {
                    globals.modLoader[order] = json[order];
                    globals.log.info(`Found property "${order}" on save file ${i}: ${json[order]}`);
                }
            }
        } else {
            // Copy over the default file
            // (this should never occur since fresh save.dat files are delivered with every patch, but handle it just in case)
            try {
                fs.copySync(defaultSaveDatFile, saveDatFile);
            } catch (err) {
                misc.errorShow(`Failed to copy the "${defaultSaveDatFile}" file to "${saveDatFile}": ${err}`);
                return false;
            }
        }
    }

    return true;
};

// Monitor for notifications from the child process that does file checks and opens Isaac
ipcRenderer.on('isaac', (event, message) => {
    // All messages should be strings
    if (typeof message !== 'string') {
        // This must be a debug message containing an object or array
        globals.log.info('Isaac child message:', message);
    } else if (message.startsWith('error: NO SAVE ')) {
        // The user does not have a fully unlocked save file, so show them a custom model
        const m = message.match(/error: NO SAVE (\d) "(.+)"/);
        if (m) {
            globals.saveFileDir = [m[1], m[2]];

            // Show the save file modal
            misc.errorShow('', false, 'save-file-modal');
            return;
        }

        misc.errorShow('Failed to parse the "NO SAVE" message.');
    } else if (message.startsWith('error: ')) {
        // globals.currentScreen is equal to "transition" when this is called
        globals.currentScreen = 'null';

        // This is an ordinary error, so don't report it to Sentry
        const error = message.match(/error: (.+)/)[1];
        misc.errorShow(error, false);
    } else if (message === 'File system was repaired, so we need to restart Isaac.') {
        misc.warningShow('Racing+ detected that your mod was corrupted and automatically fixed it. Your game has been restarted to ensure that everything is now loaded correctly. (If a patch just came out, this message is normal, as Steam has likely not had time to download the newest version yet.)');
    } else {
        // The child process is sending us a message to log
        globals.log.info(`Isaac child message: ${message}`);
    }
});
