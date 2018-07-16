/*
    Global variables
*/

// Configuration
const domain = 'isaacracing.net';
const secure = true; // "true" for HTTPS/WSS and "false" for HTTP/WS
const localhost = false; // "true" for connecting to a test server on localhost and false for connecting to the specified domain
const fadeTime = 300; // In milliseconds
const modName = 'racing+_857628390'; // This is the name of the folder for the Racing+ Lua mod after it is downloaded through Steam
const modNameDev = 'racing+_dev'; // The folder has to be named differently in development or else Steam will automatically delete it
const chineseProxy = '13.229.79.236:3128'; // This is a Singapore AWS instance running Squid proxy
const pbkdf2Digest = 'sha512'; // Digest used for password hashing
const pbkdf2Iterations = 1000; // Number of iterations for password hashing
const pbkdf2Keylen = 150; // Length of resulting password hash in bits

// The object that contains all of the global variables
module.exports = {
    autoUpdateStatus: null,
    builds: null,
    characters: null, // Filled in main.js
    chineseProxy,
    conn: null,
    currentScreen: 'title-ajax', // We always start on the title-ajax screen
    currentRaceID: false, // Equal to false or the ID of the race (as an integer)
    defaultLogFilePath: '',
    domain,
    emoteList: [], // Filled in main.js
    fadeTime,
    gameState: {
        inGame: false, // The log will tell us if we are in the menu or in a run
        hardMode: false, // The log will tell us if a run is started on hard mode or Greed mode
        racingPlusModEnabled: false, // The log will tell us if race validation succeeded, which is an indicator that they have successfully downloaded and are running the Racing+ Lua mod
        fileChecksComplete: false, // This will be set to true when the "isaac.js" subprocess exits
    },
    initError: null, // Filled in main.js (only if there is an error)
    itemList: {}, // Filled in main.js
    lastPM: null,
    lastRaceTitle: '',
    log: null,
    lang: null, // The language switcher instance, set in "localization.js"
    modLoader: {
        status: 'none',
        myStatus: 'not ready',
        ranked: false,
        solo: false,
        rFormat: 'unseeded',
        hard: false,
        character: 3, // Judas
        goal: 'Blue Baby',
        seed: '-',
        startingBuild: -1,
        countdown: -1,
        placeMid: 0,
        place: 1,
        numEntrants: 1,
        order7: [0], // Speedrun orders are filled in isaac.js
        order9: [0],
        order14: [0],
        hotkeyDrop: 0,
        hotkeySwitch: 0,
    },
    modLoaderSlot: 1,
    modName,
    modNameDev,
    modPath: null, // Set in main.js
    myUsername: null,
    playingSound: false,
    pbkdf2Digest,
    pbkdf2Iterations,
    pbkdf2Keylen,
    Raven: null, // Raven (Sentry logging) has to be a global or else it won't be initialized in other JavaScript files
    roomList: {},
    raceList: {},
    saveFileDir: [], // Filled in the "isaac.js" file if no fully unlocked save file is found
    spamTimer: new Date().getTime(),
    steam: { // Filled in steam.js
        id: null,
        accountID: null,
        screenName: null,
        ticket: null,
    },
    stream: {
        URL: '',
        URLBeforeTyping: '',
        URLBeforeSubmit: '',
        TwitchBotEnabled: null,
        TwitchBotDelay: null,
    },
    tabCompleteCounter: 0,
    tabCompleteIndex: 0,
    tabCompleteWordList: null,
    timeLaunched: new Date().getTime(),
    websiteURL: `http${(secure && !localhost ? 's' : '')}://${(localhost ? 'localhost' : domain)}`, // Always default to HTTP if connecting to localhost
    websocketURL: `ws${(secure && !localhost ? 's' : '')}://${(localhost ? 'localhost' : domain)}/ws`, // Always default to HTTP if connecting to localhost
    wordList: null, // Filled in main.js
    version: null, // Filled in main.js
};

/*
    By default, we start on the title screen.
    currentScreen can be the following:
    - title-ajax
    - tutorial1
    - tutorial2
    - login
    - login-ajax
    - forgot
    - forgot-ajax
    - register
    - register-ajax
    - updating
    - lobby
    - race
    - error
    - warning
    - waiting-for-server
    - transition
    - null (a blank screen)
*/
