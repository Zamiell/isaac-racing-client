/*
    Settings
*/

'use strict';

// Imports
const execSync = nodeRequire('child_process').execSync;
const path     = nodeRequire('path');
const isDev    = nodeRequire('electron-is-dev');
const teeny    = nodeRequire('teeny-conf');

// Constants
const settingsFile = (isDev ? 'settings.json' : path.resolve(process.execPath, '..', '..', 'settings.json'));

// Open the file that contains all of the user's settings
// (We use teeny-conf instead of localStorage because localStorage persists after uninstallation)
let settings = new teeny(settingsFile);
settings.loadOrCreateSync();
module.exports = settings;

/*
    Initialize defaults
*/

// Language
if (typeof settings.get('language') === 'undefined') {
    // If this is the first run, default to English
    settings.set('language', 'en');
    settings.saveSync();
}

// Tutorial
if (typeof settings.get('tutorial') === 'undefined') {
    // If this is the first run, default to true)
    settings.set('tutorial', 'true');
    settings.saveSync();
}

// Volume
if (typeof settings.get('volume') === 'undefined') {
    // If this is the first run, default to 50%
    settings.set('volume', 0.5);
    settings.saveSync();
}

// Log file path
if (typeof settings.get('logFilePath') === 'undefined') {
    // If this is the first run, set it to the default location (which is in the user's Documents directory)
    let command = 'powershell.exe -command "[Environment]::GetFolderPath(\'mydocuments\')"';
    let documentsPath = execSync(command, {
        'encoding': 'utf8',
    });
    documentsPath = $.trim(documentsPath); // Remove the trailing newline
    let defaultLogFilePath = path.join(documentsPath, 'My Games', 'Binding of Isaac Afterbirth', 'log.txt');

    settings.set('logFilePath', defaultLogFilePath);
    settings.saveSync();
}
