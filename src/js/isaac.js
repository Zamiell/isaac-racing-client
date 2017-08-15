/*
    Isaac functions
*/

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const globals = nodeRequire('./js/globals');
const misc = nodeRequire('./js/misc');

// This tells the main process to start launching Isaac
exports.start = () => {
    // "globals.modPath" is set in main.js
    ipcRenderer.send('asynchronous-message', 'isaac', globals.modPath);
};

// Monitor for notifications from the main process that doing the work of opening Isaac
ipcRenderer.on('isaac', (event, message) => {
    if (message.startsWith('error: ')) {
        // globals.currentScreen is equal to "transition" when this is called
        globals.currentScreen = 'null';

        // This is an ordinary error, so don't report it to Sentry
        const error = message.match(/error: (.+)/)[1];
        misc.errorShow(error, false);
        return;
    }

    globals.log.info(message);
});
