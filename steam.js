/*
    Child process that initializes the Steamworks API and generates a login ticket
*/

'use strict';

// Imports
const fs         = require('fs-extra');
const path       = require('path');
const isDev      = require('electron-is-dev');
const tracer     = require('tracer');
const Raven      = require('raven');
const greenworks = require('greenworks'); // This is not an NPM module

/*
    Handle errors
*/

process.on('uncaughtException', function(err) {
    greenworksGotError(err);
});
function greenworksGotError(err) {
    process.send('error: ' + err, processExit);
}
const processExit = function() {
    process.exit();
};

/*
    Logging (code duplicated between main, renderer, and child processes because of require/nodeRequire issues)
*/

const log = tracer.console({
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

// Get the version
let packageFileLocation = path.join(__dirname, 'package.json');
let packageFile = fs.readFileSync(packageFileLocation, 'utf8');
let version = 'v' + JSON.parse(packageFile).version;

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
}).install();

/*
    Greenworks stuff
*/

// Create the "steam_appid.txt" that Greenworks expects to find in:
//   C:\Users\james\AppData\Local\Programs\RacingPlus\steam_appid.txt (in production)
//   or
//   D:\Repositories\isaac-racing-client\steam_appid.txt (in development)
// 570660 is the Steam app ID for The Binding of Isaac: Afterbirth+
try {
    fs.writeFileSync('steam_appid.txt', '250900', 'utf8');
} catch(err) {
    greenworksGotError(err);
}

// Initialize Greenworks
try {
    if (greenworks.init() === false) {
        // Don't bother sending this message to Sentry; the user not having Steam open is a fairly ordinary error
        process.send('errorInit', function() {
            process.exit();
        });
    }
} catch(err) {
    greenworksGotError(err);
}

// Get the object that contains the computer's Steam ID and screen name
let steamIDObject = greenworks.getSteamId();

// Get a session ticket from Steam and login to the Racing+ server
greenworks.getAuthSessionTicket(function(ticket) {
    let ticketString = ticket.ticket.toString('hex'); // The ticket object contains other stuff that we don't care about
    process.send({
        id:         steamIDObject.steamId,
        screenName: steamIDObject.screenName,
        ticket:     ticketString,
    });

    // The ticket will become invalid if the process ends
    // Thus, we need to keep the process alive doing nothing until we get a message that the authentication is over
}, function(err) {
    greenworksGotError(err);
});

// The parent will communicate with us, telling us when to exit
process.on('message', function(message) {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    // We need to stay alive until authentication is over, but killed after that so we it will not interfere with launching Isaac
    // (Greenworks uses the same AppID as Isaac, so Steam gets confused)
    if (message === 'exit') {
        process.exit();
    }
});
