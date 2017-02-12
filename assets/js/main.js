/*
    Racing+ Client
    for The Binding of Isaac: Afterbirth+
    (renderer process)
*/

/*
    Patch notes:
    - Added global Alt+B hotkey to launch the game
    - "Race completed" sound effect won't play for solo races
    - Added "Custom" as a format option, where you can ready up and finish all on your own, so now you can race the vanilla game OR any mods you want on Racing+
    - Added Alt+F hotkey for finishing (only for the "Custom" format)
    - More countdown sounds have been added (from Mario Kart: Double Dash)
    - You can now hover over emotes to see what they are

    Bugs to fix:
    - get countdown sounds from mario kart
    - re-add changing color on taskbar when new message
    - detect 1million%
    - dont play race completed for solo races

    - clicking profile doesn't work
    - clicking from 1 player to the next on the lobby doesn't work, tooltips just need to be rewritten entirely to only have 1 tooltip

    - add health column
    - server should remember build # and offer no repeats for seeded races
    - don't show "1 left" in solo race

    - implement names turning red when left

    - pms are broken
    - tab complete doesn't find zamiel2?
    - !entrants command for twitch bot
    - !left command for twitch bot

    - tooltip for "Entrants" row of lobby gets deleted when coming back from that race
        (probably have to reinit tooltipster every time on enter lobby from race function)

    - error while recieving PM during tab transition

    - make spacing slightly smaller for Type and Format on lobby

    - look at sed screenshot, racer is cut off at the top



    Features to add:
    - test if internet drops during race, what happens? safe resume, https://github.com/joewalnes/reconnecting-websocket
    - achievements
    - discord integration
    - show running time on the lobby of a running race
    - automatically sort race table when people move places
    - turn different color in lobby when in a race
    - add stream to chat map
    - update columns for race:
        - time offset
        - fill in items (should also show seed on this screen)
    - /shame - Shame on those who haven't readied up.
    - "/msg invadertim" shouldn't send to server if he is offline
    - "/msg invadertim" should be made to be the right case (on the server)
    - tab complete for chat
    - /r should work
    - volume slider update number better
    - wait until raceList before going to lobby so that we can go directly to current race
    - ask cmondinger if it still gets detected as a virus after log reading is removed



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
const path     = nodeRequire('path');
const execSync = nodeRequire('child_process').execSync;
const remote   = nodeRequire('electron').remote;
const isDev    = nodeRequire('electron-is-dev');
const fs       = nodeRequire('fs-extra');
const tracer   = nodeRequire('tracer');

// Import local modules
const globals         = nodeRequire('./assets/js/globals');
const settings        = nodeRequire('./assets/js/settings');
const misc            = nodeRequire('./assets/js/misc');
const automaticUpdate = nodeRequire('./assets/js/automatic-update');
const localization    = nodeRequire('./assets/js/localization');
const keyboard        = nodeRequire('./assets/js/keyboard');
const steam           = nodeRequire('./assets/js/steam'); // This handles automatic login
const header          = nodeRequire('./assets/js/ui/header');
const tutorialScreen  = nodeRequire('./assets/js/ui/tutorial');
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
globals.Raven = nodeRequire('raven');
globals.Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
    dataCallback: function(data) {
        // We want to report errors to Sentry that are passed to the "errorShow" function
        // But because "captureException" in that function will send us back to this callback, check for that so that we don't report the same error twice
        if (data.exception[0].type !== 'RavenMiscError') {
            misc.errorShow('A unexpected JavaScript error occured. Here\'s what happened:<br /><br />' + JSON.stringify(data.exception), false);
        }
        return data;
    },
}).install();

// Logging (code duplicated between main, renderer, and child processes because of require/nodeRequire issues)
globals.log = tracer.console({
    format: "{{timestamp}} <{{title}}> {{file}}:{{line}} - {{message}}",
    dateformat: "ddd mmm dd HH:MM:ss Z",
    transport: function(data) {
        // #1 - Log to the JavaScript console
        console.log(data.output);

        // #2 - Log to a file
        let logFile = (isDev ? 'Racing+.log' : path.resolve(process.execPath, '..', '..', 'Racing+.log'));
        fs.appendFile(logFile, data.output + (process.platform === 'win32' ? '\r' : '') + '\n', function(err) {
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
let wordListLocation = path.join(__dirname, 'assets', 'words', 'words.txt');
fs.readFile(wordListLocation, function(err, data) {
    if (err) {
        misc.errorShow('Failed to read the "' + wordListLocation + '" file: ' + err);
        return;
    }
    globals.wordList = data.toString().split('\n');
});

// Get the default log file location (which is in the user's Documents directory)
// From: https://steamcommunity.com/app/250900/discussions/0/613941122558099449/
if (process.platform === 'win32') { // This will return "win32" even on 64-bit Windows
    try {
        let command = 'powershell.exe -command "[Environment]::GetFolderPath(\'mydocuments\')"';
        let documentsPath = execSync(command, {
            'encoding': 'utf8',
        });
        documentsPath = $.trim(documentsPath); // Remove the trailing newline
        globals.defaultLogFilePath = path.join(documentsPath, 'My Games', 'Binding of Isaac Afterbirth+', 'log.txt');
    } catch(err) {
        // Executing "powershell.exe" can fail on some computers, so let's try using the "USERPROFILE" environment variable
        let documentsDirNames = ['Documents', 'My Documents'];
        let found = false;
        for (let name of documentsDirNames) {
            let documentsPath = path.join(process.env.USERPROFILE, name);
            if (fs.existsSync(documentsPath)) {
                found = true;
                globals.defaultLogFilePath = path.join(documentsPath, 'My Games', 'Binding of Isaac Afterbirth+', 'log.txt');
                break;
            }
        }
        if (found === false) {
            $(document).ready(function() { // We have to wait for the page to be loaded or else it won't show the error
                misc.errorShow('Failed to find your "Documents" directory. Do you have a non-standard Windows installation? Please contact an administrator for help.');
            });
        }
    }
} else if (process.platform === 'darwin') { // OS X
    globals.defaultLogFilePath = path.join(process.env.HOME, 'Library', 'Application Support', 'Binding of Isaac Afterbirth+', 'log.txt');
} else {
    globals.defaultLogFilePath = path.join(process.env.HOME, '.local', 'share', 'binding of isaac afterbirth+');
}
if (typeof settings.get('logFilePath') === 'undefined') {
    settings.set('logFilePath', globals.defaultLogFilePath);
    settings.saveSync();
}

// We need to have a list of all of the emotes for the purposes of tab completion
let emotePath = path.join(__dirname, 'assets', 'img', 'emotes');
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
