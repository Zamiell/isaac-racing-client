/*
    Global variables
*/

'use strict';

// Configuration
const domain       = 'isaacracing.net';
const secure       = true; // "true" for HTTPS/WSS and "false" for HTTP/WS
const squirrelPort = 8443; // The port that the squirrel-updates-server runs on
const fadeTime     = 300; // In milliseconds
const LuaModDir    = 'racing+_857628390'; // This is the name of the folder for the Racing+ Lua mod after it is downloaded through Steam
const LuaModDirDev = 'racing+_dev'; // The folder has to be named differently in development or else Steam will automatically delete it

// Imports
const isDev = nodeRequire('electron-is-dev');

// The object that contains all of the global variables
module.exports = {
    autoUpdateStatus: null,
    builds: null,
    conn: null,
    currentScreen: 'title-ajax', // We always start on the title-ajax screen
    currentRaceID: false, // Equal to false or the ID of the race (as an integer)
    defaultLogFilePath: '',
    domain: domain,
    emoteList: [], // Filled in main.js
    fadeTime: fadeTime,
    gameState: {
        inGame: false,
        blckCndlOn: true, // The log will tell us if a run is started without BLCK CNDL on
        hardMode: false, // The log will tell us if a run is started on a non-normal difficulty
        character: null,
    },
    itemList: {}, // Filled in main.js
    log: null,
    lang: null, // The language switcher instance
    LuaModDir: (isDev ? LuaModDirDev : LuaModDir),
    LuaModDirDev: LuaModDirDev,
    modLoaderFile: null, // Used to communicate with Isaac, set in isaac.js
    modLoader: {
        status: 'none',
        rType: 'unranked',
        rFormat: 'unseeded',
        character: 'Judas',
        goal: 'Blue Baby',
        seed: '-',
        startingBuild: -1,
        currentSeed: '-', // Detected through reading the log file
        countdown: -1,
    },
    myUsername: null,
    playingSound: false,
    Raven: null, // Raven (Sentry logging) has to be a global or else it won't be initialized in other JavaScript files
    roomList: {},
    raceList: {},
    secure: secure,
    spamTimer: new Date().getTime(),
    steam: {
        id: null,
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
    timeOffset: 0,
    trinketList: {}, // Filled in main.js
    wordList: null, // Filled in main.js
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
