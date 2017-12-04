/*
    Child process that initializes the Steamworks API and generates a login ticket
*/

// Imports
const fs = require('fs-extra');
const isDev = require('electron-is-dev');
const Raven = require('raven');
const greenworks = require('greenworks'); // This is not an NPM module
const version = require('./version');

procoss.send('hi: ' + __dirname);

// Handle errors
process.on('uncaughtException', (err) => {
    greenworksGotError(err);
});
function greenworksGotError(err) {
    process.send(`error: ${err}`, processExit);
}
const processExit = () => {
    process.exit();
};

// The parent will communicate with us, telling us when to exit
process.on('message', (message) => {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    // We need to stay alive until authentication is over, but killed after that so we it will not interfere with launching Isaac
    // (Greenworks uses the same AppID as Isaac, so Steam gets confused)
    if (message === 'exit') {
        process.exit();
    }
});

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
}).install();

/*
    Greenworks stuff
*/

function greenworksInit() {
    // Create the "steam_appid.txt" that Greenworks expects to find in:
    //   C:\Users\james\AppData\Local\Programs\RacingPlus\steam_appid.txt (in production)
    //   or
    //   D:\Repositories\isaac-racing-client\steam_appid.txt (in development)
    // 570660 is the Steam app ID for The Binding of Isaac: Afterbirth+
    try {
        fs.writeFileSync('steam_appid.txt', '250900', 'utf8');
    } catch (err) {
        greenworksGotError(err);
        return;
    }

    // Initialize Greenworks
    try {
        if (greenworks.init() === false) { // This cannot be written as "!greenworks.init()"
            // Don't bother sending this message to Sentry; the user not having Steam open is a fairly ordinary error
            process.send('errorInit', processExit);
            return;
        }
    } catch (err) {
        greenworksGotError(err);
        return;
    }

    // Get the object that contains the computer's Steam ID and screen name
    const steamIDObject = greenworks.getSteamId();

    /*
        The object will look something like the following:
        {
           "flags":{
              "anonymous":false,
              "anonymousGameServer":false,
              "anonymousGameServerLogin":false,
              "anonymousUser":false,
              "chat":false,
              "clan":false,
              "consoleUser":false,
              "contentServer":false,
              "gameServer":false,
              "individual":true,
              "gameServerPersistent":false,
              "lobby":false
           },
           "type":{
              "name":"k_EAccountTypeIndividual",
              "value":1
           },
           "accountId":33000000,
           "steamId":"76561190000000000",
           "staticAccountId":"76561190000000000",
           "isValid":1,
           "level":7,
           "screenName":"Zamie"
        }
    */

    // Check to see if it is valid
    // (I'm not sure what governs this, but probably best to check it to be thorough)
    if (steamIDObject.isValid !== 1) {
        process.send('error: It appears that your Steam account is invalid.');
        return;
    }

    // Get a session ticket from Steam and login to the Racing+ server
    greenworks.getAuthSessionTicket((ticket) => {
        const ticketString = ticket.ticket.toString('hex'); // The ticket object contains other stuff that we don't care about
        process.send({
            id: steamIDObject.steamId,
            accountID: steamIDObject.accountId,
            screenName: steamIDObject.screenName,
            ticket: ticketString,
        });

        // The ticket will become invalid if the process ends
        // Thus, we need to keep the process alive doing nothing until we get a message that the authentication is over
    }, (err) => {
        greenworksGotError(err);
    });
}

greenworksInit();
