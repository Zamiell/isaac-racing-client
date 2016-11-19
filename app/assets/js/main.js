/*
    Racing+ Client
    for The Binding of Isaac: Afterbirth+

    Built with jQuery
*/

/*
    TODO

    - tab complete for chat
    - /r should work
    - test to see if multiple windows works in production
    - columns for race:
      - seed
      - starting item
      - time offset
      - fill in items
*/

'use strict';

// Import NPM packages
const fs       = nodeRequire('fs');
const path     = nodeRequire('path');
const remote   = nodeRequire('electron').remote;
const isDev    = nodeRequire('electron-is-dev');

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
        click: () => {
            remote.getCurrentWindow().inspectElement(rightClickPosition.x, rightClickPosition.y);
        },
    });
    menu.append(menuItem);

    window.addEventListener('contextmenu', (e) => {
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

// Version
let packageLocation = path.join(__dirname, 'package.json');
globals.version = JSON.parse(fs.readFileSync(packageLocation)).version; // This has to be syncronous because we need the variable during "document.ready"

// Word list
let wordListLocation = path.join(__dirname, 'assets/words/words.txt');
fs.readFile(wordListLocation, function(err, data) {
    globals.wordList = data.toString().split('\n');
});
