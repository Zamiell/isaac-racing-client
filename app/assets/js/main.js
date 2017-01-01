/*
    Racing+ Client
    for The Binding of Isaac: Afterbirth+
    (renderer process)
*/

/*
    Bugs to fix:
    - Add [?? Joined] to race chat
    - log watcher 74 - Uncaught TypeError: Cannot read property 'racerList' of undefined
    - There are 0 people left in the race. - remove this line (only dont display it during start / resume?)
    - test if internet drops during race, what happens? safe resume

    - move log out button to settings
    - double check correct window.change # for hide links

    - look at sed screenshot, racer is cut off at the top

    - look at indentation, its too much

    - clicking profile doesn't work
    - clicking from 1 player to the next on the lobby doesn't work, tooltips just need to be rewritten entirely to only have 1 tooltip

    - get sentry working with line numbers - https://forum.sentry.io/t/sentry-js-submitting-incomplete-stack-trace/703

    Things to verify:
    - get sillypears to verify crash test after sentry line numbers fix

    Features to add:
    - achievements
    - discord integration
    - show running time on the lobby of a running race
    - automatically sort race table when people move places
    - turn different color in lobby when in a race
    - message of the day
    - add stream to chat map
    - update columns for race:
        - time offset
        - fill in items (should also show seed on this screen)
    - "/msg invadertim" shouldn't send to server if he is offline
    - "/msg invadertim" should be made to be the right case (on the server)
    - tab complete for chat
    - /r should work
    - volume slider update number better
    - wait until raceList before going to lobby so that we can go directly to current race



    Features to add (low priority):
    - make UI expand horizontally properly
    - implement <3 emote (can't have < or > in filenames so it requires custom code)
    - add items + date to "Top 10 Unseeded Times" leaderboard

    Bugs to fix (low priority):
    - french race tables rows are not confined to 1 line, so they look bad
    - Personnage (french) is too close to character in new-race tooltip
    - horizontal scroll bar appears when resizing smaller

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
const misc            = nodeRequire('./assets/js/misc');
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
    release: version,
    environment: (isDev ? 'development' : 'production'),
    dataCallback: function(data) {
        // Disable this for now since Sentry doesn't show us the line numbers, which is probably a bug with the SDK
        //misc.errorShow('A unexpected JavaScript error occured. Here\'s what happened:<br /><br />' + JSON.stringify(data.exception.values), false);
    },
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

// We need to have a list of all of the emotes for the purposes of tab completion
let emotePath = path.join(__dirname + '/assets/img/emotes');
globals.emoteList = misc.getAllFilesFromFolder(emotePath);
for (let i = 0; i < globals.emoteList.length; i++) { // Remove ".png" from each elemet of emoteList
    globals.emoteList[i] = globals.emoteList[i].slice(0, -4); // ".png" is 4 characters long
}

// Preload some sounds by playing all of them
$(document).ready(function() {
    let soundFiles = ['1', '2', '3', 'finished', 'go', 'lets-go', 'quit', 'race-completed'];
    for (let file of soundFiles) {
        let audio = new Audio('assets/sounds/' + file + '.mp3');
        audio.volume = 0;
        audio.play();
    }
    for (let i = 1; i <= 16; i++) {
        let audio = new Audio('assets/sounds/place/' + i + '.mp3');
        audio.volume = 0;
        audio.play();
    }
});
