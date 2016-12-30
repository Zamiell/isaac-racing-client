/*
    Racing+ Client
    for The Binding of Isaac: Afterbirth+
    (renderer process)
*/

/*
    TODO

    - message of the day
    - add stream to chat map
    - update columns for race:
        - place
        - seed
        - starting item
        - time offset
        - fill in items
    - "/msg invadertim" shouldn't work
    - should not error if trying to msg someone who isn't online
    - tab complete for chat
    - /r should work
*/

'use strict';

// Import NPM packages
const fs     = nodeRequire('fs');
const path   = nodeRequire('path');
const remote = nodeRequire('electron').remote;
const isDev  = nodeRequire('electron-is-dev');

// Import local modules
const globals         = nodeRequire('./assets/js/globals');
const settings        = nodeRequire('./assets/js/settings');
const automaticUpdate = nodeRequire('./assets/js/automatic-update');
const localization    = nodeRequire('./assets/js/localization');
const keyboard        = nodeRequire('./assets/js/keyboard');
const header          = nodeRequire('./assets/js/ui/header');
const titleScreen     = nodeRequire('./assets/js/ui/title');
const tutorialScreen  = nodeRequire('./assets/js/ui/tutorial');
const loginScreen     = nodeRequire('./assets/js/ui/login');
const forgotScreen    = nodeRequire('./assets/js/ui/forgot');
const registerScreen  = nodeRequire('./assets/js/ui/register');
const lobbyScreen     = nodeRequire('./assets/js/ui/lobby');
const raceScreen      = nodeRequire('./assets/js/ui/race');
const modals          = nodeRequire('./assets/js/ui/modals');

/*
    Development-only stuff
*/

if (isDev) {
    // Importing this adds a right-click menu with 'Inspect Element' option
    let rightClickPosition = null;

    const menu = new remote.Menu();
    const menuItem = new remote.MenuItem({
        label: 'Inspect Element',
        click: function() {
            remote.getCurrentWindow().inspectElement(rightClickPosition.x, rightClickPosition.y);
        },
    });
    menu.append(menuItem);

    window.addEventListener('contextmenu', function(e) {
        e.preventDefault();
        rightClickPosition = {
            x: e.x,
            y: e.y,
        };
        menu.popup(remote.getCurrentWindow());
    }, false);
}

/*
    Initialization
*/

// Get the version
let packageFileLocation = path.join(__dirname, 'package.json');
let packageFile = fs.readFileSync(packageFileLocation, 'utf8');
let version = 'v' + JSON.parse(packageFile).version;

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be@sentry.io/124813', {
    autoBreadcrumbs: true,
    //release: version,
    environment: (isDev ? 'development' : 'production'),
}).install();

// Logging (code duplicated between main and renderer because of require/nodeRequire issues)
globals.log = nodeRequire('tracer').console({
    format: "{{timestamp}} <{{title}}> {{file}}:{{line}}\r\n{{message}}",
    dateformat: "ddd mmm dd HH:MM:ss Z",
    transport: function(data) {
        // #1 - Log to the JavaScript console
        console.log(data.output);

        // #2 - Log to a file
        let logFile = (isDev ? 'Racing+.log' : path.resolve(process.execPath, '..', '..', 'Racing+.log'));
        fs.appendFile(logFile, data.output + '\n', function(err) {
            if (err) {
                throw err;
            }
        });
    }
});

// Version
$(document).ready(function() {
    $('#title-version').html(version);
    $('#settings-version').html(version);
});

// Word list
let wordListLocation = path.join(__dirname, 'assets/words/words.txt');
fs.readFile(wordListLocation, function(err, data) {
    globals.wordList = data.toString().split('\n');
});
