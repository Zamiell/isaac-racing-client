/*
    Login
*/

'use strict';

// Imports
const ipcRenderer    = nodeRequire('electron').ipcRenderer;
const fs             = nodeRequire('fs');
const greenworks     = nodeRequire('greenworks'); // This is not an NPM module
const isDev          = nodeRequire('electron-is-dev');
const globals        = nodeRequire('./assets/js/globals');
const misc           = nodeRequire('./assets/js/misc');
const websocket      = nodeRequire('./assets/js/websocket');
const registerScreen = nodeRequire('./assets/js/ui/register');

/*
    Check to see if Steam is running on startup
*/
$(document).ready(function() {
    // Must do this before initializing Greenworks
    // See: https://github.com/greenheartgames/greenworks/issues/115
    process.activateUvLoop();

    // Create the "steam_appid.txt" that Greenworks expects to find in:
    //   C:\Users\james\AppData\Local\Programs\RacingPlus\steam_appid.txt (in production)
    //   or
    //   D:\Repositories\isaac-racing-client\steam_appid.txt (in development)
    // 113200 is the Steam app ID for The Binding of Isaac (original)
    // We need to use something other than the Rebirth Steam app ID so that it doesn't conflict with opening/closing Rebirth
    fs.writeFileSync('steam_appid.txt', '113200', 'utf8');

    // Initialize Greenworks
    if (greenworks.init() === false) {
        // Don't bother sending this message to Sentry; the user not having Steam open is a fairly ordinary error
        //misc.errorShow('Failed to initialize the Steam API. Please open Steam and relaunch Racing+.', false);

        // Since this is in alpha, we will send this message to Sentry afterall
        misc.errorShow('Failed to initialize the Steam API. Please open Steam and relaunch Racing+.');
        return;
    }

    // Get this computer's Steam ID and screen name
    let steamIDObject = greenworks.getSteamId();
    globals.steam.id = steamIDObject.steamId;
    globals.steam.screenName = steamIDObject.screenName;

    // Get a session ticket from Steam and login to the Racing+ server
    greenworks.getAuthSessionTicket(function(ticket) {
        ticket = ticket.ticket.toString('hex'); // The ticket object contains other stuff that we don't care about
        login(ticket);
    }, function() {
        misc.errorShow('Failed to get a Steam session ticket.');
    });
});

/*
    Login functions
*/

// Get a WebSockets cookie using our Steam ticket
// The authentication flow is described here: https://partner.steamgames.com/documentation/auth#client_to_backend_webapi
// (you have to be logged in for the link to work)
// The server will validate our session ticket using the Steam web API and if successful, give us a cookie
// If our steam ID does not already exist in the database, we will be told to register
function login(ticket) {
    // Don't login yet if we are still checking for updates
    if (globals.autoUpdateStatus === null) {
        if (isDev) {
            // We won't auto-update in development
        } else {
            // The client has not yet begun to check for an update, so stall
            // However, sometimes this can be permanently null in production (maybe after an automatic update?), so allow them to procede after 2 seconds
            let now = new Date().getTime();
            if (now - globals.timeLaunched < 2000) {
                setTimeout(function() {
                    login(ticket);
                }, 250);
                globals.log.info('Logging in (without having checked for an update yet). Stalling for 0.25 seconds...');
                return;
            }
        }
    } else if (globals.autoUpdateStatus === 'checking-for-update') {
        setTimeout(function() {
            login(ticket);
        }, 250);
        globals.log.info('Logging in (while checking for an update). Stalling for 0.25 seconds...');
        return;
    } else if (globals.autoUpdateStatus === 'error') {
        // Allow them to continue to log on if they got an error since we want the service to be usable when GitHub is down
        globals.log.info('Logging in (with an automatic update error).');
    } else if (globals.autoUpdateStatus === 'update-available') {
        // They are beginning to download the update
        globals.currentScreen = 'transition';
        $('#title').fadeOut(globals.fadeTime, function() {
            $('#updating').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'updating';
            });
        });
        globals.log.info('Logging in (with an update available). Showing the "updating" screen.');
        return;
    } else if (globals.autoUpdateStatus === 'update-not-available') {
        // Do nothing special and continue to login
        globals.log.info('Logging in (with no update available).');
    } else if (globals.autoUpdateStatus === 'update-downloaded') {
        // The update was downloaded in the background before the user logged in
        // Show them the updating screen so they are not confused at the program restarting
        globals.currentScreen = 'transition';
        $('#title').fadeOut(globals.fadeTime, function() {
            $('#updating').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'updating';

                setTimeout(function() {
                    ipcRenderer.send('asynchronous-message', 'quitAndInstall');
                }, 1500);
                globals.log.info('Logging in (with an update was downloaded successfully). Showing the "updating" screen and automatically restart in 1.5 seconds."');
            });
        });
        return;
    }

    // Send a request to the Racing+ server
    globals.log.info('Sending a login request to the Racing+ server.');
    let data = {
        steamID: globals.steam.id, // Analogous to our username
        ticket:  ticket,           // Analogous to our password; will be verified on the server via the Steam web API
    };
    let url = 'http' + (globals.secure ? 's' : '') + '://' + globals.domain + '/login';
    let request = $.ajax({
        url:  url,
        type: 'POST',
        data: data,
    });
    request.done(function(data) {
        data = data.trim();
        if (data === 'Accepted') {
            // If the server gives us "Accepeted", then our Steam credentials are valid, but we don't have an account on the server yet
            // Let the user pick their username
            registerScreen.show();
        } else {
            // We successfully got a cookie; attempt to establish a WebSocket connection
            websocket.init();
        }
    });
    request.fail(function(jqXHR) {
        // Show the error screen
        globals.log.info('Login failed.');
        let error = misc.findAjaxError(jqXHR);
        misc.errorShow(error);
    });
}
