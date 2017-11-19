/*
    Settings
*/

// This is for settings related to the program, stored in a file "settings.json".
// For the "Settings" part of the UI, see the "ui/settings-tooltip.js" file.
// "teeny-conf" is used instead of localstorage (cookies) because the main Electron process is not able to natively access cookies, and we might want to do that.

// Imports
const path = nodeRequire('path');
const isDev = nodeRequire('electron-is-dev');
const teeny = nodeRequire('teeny-conf');

// Open the file that contains all of the user's settings
let settingsRoot;
if (isDev) {
    settingsRoot = path.join(__dirname, '..', '..');
} else {
    settingsRoot = path.join(__dirname, '..', '..', '..', '..', '..');
}
const settingsFile = path.join(settingsRoot, 'settings.json'); // This will be created if it does not exist already
const settings = new teeny(settingsFile); // eslint-disable-line new-cap
settings.loadOrCreateSync();
initDefaults();
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
