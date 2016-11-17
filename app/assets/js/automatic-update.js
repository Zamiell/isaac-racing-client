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

ipcRenderer.on('autoUpdater', function(event, message) {
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
        // Do nothing special
    }
});
