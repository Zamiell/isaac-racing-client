/*
    Automatic update functions
*/

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const globals = nodeRequire('./js/globals');

/*
    IPC handlers
*/

const autoUpdater = (event, message) => {
    globals.log.info('Recieved autoUpdater message:', message);
    globals.autoUpdateStatus = message;
    if (message === 'error') {
        // Do nothing special; we want the service to be usable when GitHub is down
    } else if (message === 'checking-for-update') {
        // Do nothing special
    } else if (message === 'update-available') {
        // Do nothing special
    } else if (message === 'update-not-available') {
        // Do nothing special
    } else if (message === 'update-downloaded') {
        if (globals.currentScreen === 'transition') {
            setTimeout(() => {
                autoUpdater(event, message);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
        } else if (globals.currentScreen === 'updating') {
            ipcRenderer.send('asynchronous-message', 'quitAndInstall');
        }
    }
};
ipcRenderer.on('autoUpdater', autoUpdater);
