/*
    Settings
*/

// This is for settings related to the program, stored in a file "settings.json".
// For the "Settings" part of the UI, see the "ui/settings-tooltip.js" file.
// "teeny-conf" is used instead of localstorage (cookies) because the main Electron process is not able to natively access cookies, and we might want to do that.

// Imports
const os = require('os');
const path = require('path');
const isDev = require('electron-is-dev');
const teeny = require('teeny-conf');

// Initialize the settings file
// (this is called in both the main and renderer processes)
let settingsRoot;
if (isDev) {
    // For development, this puts the settings file in the root of the repository
    settingsRoot = path.join(__dirname, '..');
} else if (process.platform === 'darwin') {
    // By convention, settings files are usually stored in the "Application Support" directory
    settingsRoot = path.join(os.homedir(), 'Application Support', 'Racing+');
} else {
    // On a bundled Windows app, "__dirname" is:
    // "C:\Users\[Username]\AppData\Local\Programs\RacingPlus\resources\app.asar\src"
    // We want the settings file in the "Programs" directory
    settingsRoot = path.join(__dirname, '..', '..', '..', '..');
}
const settingsPath = path.join(settingsRoot, 'settings.json');
const settings = new teeny(settingsPath); // eslint-disable-line new-cap
settings.loadOrCreateSync(); // This will be created if it does not exist already
initDefaults();

// Export it
module.exports = settings;

// If this is the first run (or the settings.json file got corrupted), set default values
function initDefaults() {
    // Language
    if (typeof settings.get('language') === 'undefined') {
        settings.set('language', 'en'); // English
        settings.saveSync();
    }

    // Tutorial
    if (typeof settings.get('tutorial') === 'undefined') {
        settings.set('tutorial', 'true');
        settings.saveSync();
    }

    // Volume
    if (typeof settings.get('volume') === 'undefined') {
        settings.set('volume', 0.5); // 50%
        settings.saveSync();
    }

    // Log file path
    // n/a
    // (initialized in main.js since it depends on the return value of a PowerShell command)

    // Race creation defaults
    if (typeof settings.get('newRaceTitle') === 'undefined') {
        settings.set('newRaceTitle', ''); // An empty string means to use the random name generator
        settings.saveSync();
    }
    if (typeof settings.get('newRaceSize') === 'undefined') {
        settings.set('newRaceSize', 'solo');
        settings.saveSync();
    }
    if (typeof settings.get('newRaceRanked') === 'undefined') {
        settings.set('newRaceRanked', 'no');
        settings.saveSync();
    }
    if (typeof settings.get('newRaceFormat') === 'undefined') {
        settings.set('newRaceFormat', 'unseeded');
        settings.saveSync();
    }
    if (typeof settings.get('newRaceCharacter') === 'undefined') {
        settings.set('newRaceCharacter', 'Judas');
        settings.saveSync();
    }
    if (typeof settings.get('newRaceGoal') === 'undefined') {
        settings.set('newRaceGoal', 'Blue Baby');
        settings.saveSync();
    }
    if (typeof settings.get('newRaceBuild') === 'undefined') {
        settings.set('newRaceBuild', '1'); // 20/20
        settings.saveSync();
    }
}
