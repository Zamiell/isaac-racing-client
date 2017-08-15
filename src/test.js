/*
    Child process that validates everything is right in the file system
*/

// Imports
const fs = require('fs-extra');
const path = require('path');
const isDev = require('electron-is-dev');
const Raven = require('raven');
const ps = require('ps-node');
const tasklist = require('tasklist');
const opn = require('opn');
const hashFiles = require('hash-files');
const teeny = require('teeny-conf');
//const windowsRegistry = require('windows-registry');

// Handle errors
process.on('uncaughtException', (err) => {
    process.send(`error: ${err}`, processExit);
});
const processExit = () => {
    process.exit();
};

/*
// Get the version
const packageFileLocation = path.join(__dirname, '..', 'package.json');
const packageFile = fs.readFileSync(packageFileLocation, 'utf8');
const version = `v${JSON.parse(packageFile).version}`;

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
}).install();

// Open the file that contains all of the user's settings
let settingsRoot;
if (isDev) {
    // For development, this puts the log file in the root of the repository
    settingsRoot = path.join(__dirname, '..');
} else {
    // For production, this puts the log file in the "Programs" directory
    // (the __dirname is "C:\Users\[Username]\AppData\Local\Programs\RacingPlus\resources\app.asar\src")
    settingsRoot = path.join(__dirname, '..', '..', '..', '..');
}
const settingsFile = path.join(settingsRoot, 'settings.json'); // This will be created if it does not exist already
const settings = new teeny(settingsFile); // eslint-disable-line new-cap
settings.loadOrCreateSync();
*/

process.send('XXXXXXXXXXXXXXXXXXXXXXXXXXXX', processExit);
