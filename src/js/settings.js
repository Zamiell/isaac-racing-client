/*
    Settings
*/

// This is for settings related to the program, stored in a file "settings.json".
// For the "Settings" part of the UI, see the "ui/settings-tooltip.js" file.
// "teeny-conf" is used instead of localstorage (cookies) because the main Electron process is not able to natively access cookies, and we might want to do that.

// Imports
const path = nodeRequire('path');
const teeny = nodeRequire('teeny-conf');

// Open the file that contains all of the user's settings
// (we use teeny-conf instead of localStorage because localStorage persists after uninstallation)
// (code duplicated between main, renderer, and child processes)
const settingsFile = path.join(__dirname, '..', '..', 'settings.json'); // This will be created if it does not exist already
const settings = new teeny(settingsFile); // eslint-disable-line new-cap
settings.loadOrCreateSync();
initDefaults();
module.exports = settings;

function initDefaults() {
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
    // n/a
    // (initialized in main.js since it depends on the return value of a PowerShell command)

    // "Don't disable boss cutscenes"
    if (typeof settings.get('bossCutscenes') === 'undefined') {
        // If this is the first run, default to false
        settings.set('bossCutscenes', false);
        settings.saveSync();
    }
}
