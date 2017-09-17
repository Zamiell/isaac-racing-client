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
    if (message.startsWith('error: NO SAVE ')) {
        // The user does not have a fully unlocked save file, so show them a custom model
        const steamCloud = message[message.length - 1];
        // TODO
        return;
    } else if (message.startsWith('error: ')) {
        // globals.currentScreen is equal to "transition" when this is called
        globals.currentScreen = 'null';

        // This is an ordinary error, so don't report it to Sentry
        const error = message.match(/error: (.+)/)[1];
        misc.errorShow(error, false);
        return;
    }

    globals.log.info(message);
});
