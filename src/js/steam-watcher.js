/*
    Steam watcher functions
*/

// Imports
const { ipcRenderer } = nodeRequire('electron');
const globals = nodeRequire('./js/globals');
const misc = nodeRequire('./js/misc');

// globals.currentScreen is equal to "transition" when this is called
// Called from the "lobby.show()" function
exports.start = () => {
    // If we are on a test account, the account ID will be 0
    // We don't want to start the Steam watcher if we are on a test account, since they are not associated with Steam accounts
    if (globals.steam.accountID <= 0) {
        return;
    }

    // This feature currently only works on windows
    if (process.platform !== 'win32') {
        return;
    }

    // Send a message to the main process to start up the Steam watcher
    ipcRenderer.send('asynchronous-message', 'steam-watcher', globals.steam.accountID);
};

// Monitor for notifications from the child process that is doing the log watching
ipcRenderer.on('steam-watcher', (event, message) => {
    globals.log.info(`Recieved steam-watcher notification: ${message}`);

    if (message === 'error: It appears that you have logged out of Steam.') {
        // This is an ordinary error, so don't send it to Sentry
        misc.errorShow('It appears that you have logged out of Steam.', false);
    } else if (message.startsWith('error: ')) {
        const error = message.match(/^error: (.+)/)[1];
        misc.errorShow(`Something went wrong with the Steam monitoring program: ${error}`);
    }
});
