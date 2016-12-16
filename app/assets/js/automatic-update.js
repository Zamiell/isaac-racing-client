/*
    Automatic update functions
*/

'use strict';

// Imports

const ipcRenderer = nodeRequire('electron').ipcRenderer;
const globals     = nodeRequire('./assets/js/globals');
const misc        = nodeRequire('./assets/js/misc');

/*
    Event handlers
*/

$(document).ready(function() {
    $('#updating-close-button').click(function() {
        if (globals.currentScreen === 'updating') {
            ipcRenderer.send('asynchronous-message', 'quitAndInstall');
        }
    });
});

/*
    IPC handlers
*/

const autoUpdater = function(event, message) {
    globals.log.info('Recieved autoUpdater message:', message);
    globals.autoUpdateStatus = message;
    if (message === 'error') {
        misc.errorShow('Failed to check for updates from GitHub. Either your Internet is having problems or GitHub.com is down.');
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
            $('#updating-ajax').fadeOut(globals.fadeTime);
            $('#updating-1').fadeOut(globals.fadeTime);
            $('#updating-2').fadeOut(globals.fadeTime, function() {
                $('#updating-3').fadeIn(globals.fadeTime);
                $('#updating-close-button').fadeIn(globals.fadeTime);
            });
        } else {
            misc.errorShow('An updated finished downloading but we were not on the "updating" screen.');
        }
    }
};
ipcRenderer.on('autoUpdater', autoUpdater);
