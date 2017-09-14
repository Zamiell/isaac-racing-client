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
    // Send a message to the main process to start up the Steam watcher
    // If we are on a test account, the account ID will be 0
    // We don't want to start the Steam watcher if we are on a test account, since they are not associated with Steam accounts
    if (globals.steam.accountID > 0) {
        ipcRenderer.send('asynchronous-message', 'steamWatcher', globals.steam.accountID);
    }
};

// Monitor for notifications from the child process that is doing the log watching
ipcRenderer.on('steamWatcher', (event, message) => {
    globals.log.info(`Recieved steam-watcher notification: ${message}`);

    // TODO check for logout

    if (message.startsWith('error: ')) {
        // First, parse for errors
        const error = message.match(/^error: (.+)/)[1];
        misc.errorShow(`Something went wrong with the Steam monitoring program: ${error}`);
    }
});
