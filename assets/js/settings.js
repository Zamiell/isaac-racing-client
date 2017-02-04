/*
    Settings
*/

// This is for settings related to the program, stored in a file "settings.json".
// For the "Settings" part of the UI, see the "ui/settings-tooltip.js" file.
// "teeny-conf" is used instead of localstorage (cookies) because the main Electron process is not able to natively access cookies, and we might want to do that.

'use strict';

// Imports
const path     = nodeRequire('path');
const isDev    = nodeRequire('electron-is-dev');
const teeny    = nodeRequire('teeny-conf');
const globals  = nodeRequire('./assets/js/globals');

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
// (initialized in main.js since it depends on the return value of a PowerShell command)

// "Don't enter game with Alt+C and Alt+v hotkeys"
if (typeof settings.get('controller') === 'undefined') {
    // If this is the first run, default to false
    settings.set('controller', false);
    settings.saveSync();
}

// "Don't disable boss cutscenes"
if (typeof settings.get('bossCutscenes') === 'undefined') {
    // If this is the first run, default to false
    settings.set('bossCutscenes', false);
    settings.saveSync();
}
