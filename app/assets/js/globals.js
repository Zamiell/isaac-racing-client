/*
    Global variables
*/

'use strict';

// Configuration
const domain = 'isaacracing.net';
const secure = true; // "true" for HTTPS/WSS and "false" for HTTP/WS
const fadeTime = 300; // In milliseconds

// The object that contains all of the global variables
module.exports = {
	domain: domain,
	secure: secure,
	fadeTime: fadeTime,
    currentScreen: 'title', // We always start on the title screen
    currentRaceID: false, // Equal to false or the ID of the race
    conn: null,
    logMonitoringProgram: null,
	roomList: {},
    raceList: {},
    myUsername: null,
    timeOffset: 0,
    initiatedLogout: false,
    wordList: null,
    lang: null,
    settings: {
        'language': null,
        'volume': null,
        'logFilePath': null,
    },
    version: null,
	autoUpdateStatus: null,
};

/*
    By default, we start on the title screen.
    currentScreen can be the following:
    - title
    - title-ajax
    - login
    - login-ajax
    - forgot
    - forgot-ajax
    - register
    - register-ajax
    - lobby
    - race
    - settings
    - error
    - warning
    - transition
*/
