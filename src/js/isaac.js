/*
    Isaac functions
*/

// Imports
const { ipcRenderer } = nodeRequire('electron');
const globals = nodeRequire('./js/globals');
const misc = nodeRequire('./js/misc');

// This tells the main process to start launching Isaac
exports.start = () => {
    // "globals.modPath" is set in main.js
    ipcRenderer.send('asynchronous-message', 'isaac', globals.modPath);
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
        misc.warningShow('Racing+ detected that your mod was corrupted and automatically fixed it. Your game has been restarted to ensure that everything is now loaded correctly.');
    } else {
        // The child process is sending us a message to log
        globals.log.info(`Isaac child message: ${message}`);
    }
});
