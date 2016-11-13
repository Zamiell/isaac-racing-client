/*
    Automatic update functions
*/

'use strict';

// Imports
const autoUpdater = nodeRequire('electron').autoUpdater;
const globals     = nodeRequire('./assets/js/globals');

exports.checkForUpdates = function() {
    autoUpdater.on('error', function(err) {
        console.err(`Update error: ${err.message}`);
    });

    autoUpdater.on('checking-for-update', function() {
        console.log('Checking for update.');
    });

    autoUpdater.on('update-available', function() {
        console.log('Update available.');
    });

    autoUpdater.on('update-not-available', function() {
        console.log('No update available.');
    });

    autoUpdater.on('update-downloaded', function(e, notes, name, date, url) {
        console.log(`Update downloaded: ${name}: ${url}`);
    });

    let url = 'http' + (globals.secure ? 's' : '') + '://' + globals.domain + '/update/win32';
    autoUpdater.setFeedURL(url);
    autoUpdater.checkForUpdates();
};
