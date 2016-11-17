/*
    Automatic update functions
*/

'use strict';

// Imports

const ipcRenderer = nodeRequire('electron').ipcRenderer;
const globals     = nodeRequire('./assets/js/globals');
const misc        = nodeRequire('./assets/js/misc');

/*
    IPC handlers
*/

const autoUpdater = function(event, message) {
    console.log('Recieved message:', message);
    globals.autoUpdateStatus = message;
    if (message === 'error') {
        // Do nothing special
        // (the error dialog is not able to be shown from the title menu)
        // misc.errorShow('Failed to check for updates.');
    } else if (message === 'checking-for-update') {
        // Do nothing special
    } else if (message === 'update-available') {
        // Do nothing special
    } else if (message === 'update-not-available') {
        // Do nothing special
    } else if (message === 'update-downloaded') {
        if (globals.currentScreen === 'transition') {
            setTimeout(function() {
                autoUpdater(event, message);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
        } else if (globals.currentScreen === 'updating') {
            ipcRenderer.send('asynchronous-message', 'restart');
        }
    }
};
ipcRenderer.on('autoUpdater', autoUpdater);
