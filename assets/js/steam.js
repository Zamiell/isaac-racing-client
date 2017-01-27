/*
    Steam functions (and automatic login)
*/

'use strict';

// Imports
const ipcRenderer    = nodeRequire('electron').ipcRenderer;
const isDev          = nodeRequire('electron-is-dev');
const globals        = nodeRequire('./assets/js/globals');
const misc           = nodeRequire('./assets/js/misc');
const websocket      = nodeRequire('./assets/js/websocket');
const registerScreen = nodeRequire('./assets/js/ui/register');

// Check to see if Steam is running on startup
$(document).ready(function() {
    if (isDev) {
        // Don't automatically log in with our Steam account
        // We want to choose from a list of login options
        $('#title-ajax').fadeOut(0);
        $('#title-choose').fadeIn(0);

        $('#title-choose-steam').click(function() {
            loginDebug(null);
        });

        $('#title-choose-1').click(function() {
            loginDebug(1);
        });

        $('#title-choose-2').click(function() {
            loginDebug(2);
        });

        $('#title-choose-3').click(function() {
            loginDebug(3);
        });
    } else {
        // Tell the main process to start the child process that will initialize Greenworks
        // That process will get our Steam ID, Steam screen name, and authentication ticket
        ipcRenderer.send('asynchronous-message', 'steam', null);
    }
});

// Monitor for notifications from the child process that is getting the data from Greenworks
const steam = function(event, message) {
    if (message === 'errorInit') {
        // Don't bother sending this message to Sentry; the user not having Steam open is a fairly ordinary error
        misc.errorShow('Failed to talk to Steam. Please open or restart Steam and relaunch Racing+.', false);
        return;
    } else if (typeof(message) === 'string' && message.startsWith('error: ')) {
        let error = message.match(/error: (.+)/)[1];
        misc.errorShow('Failed to talk to Steam: ' + error);
        return;
    } else if (typeof(message) === 'string') {
        // The child process is sending us a message to log
        globals.log.info('Steam child message: ' + message);
    }
    globals.steam.id = message.id;
    globals.steam.screenName = message.screenName;
    globals.steam.ticket = message.ticket;
    login();
};
ipcRenderer.on('steam', steam);

// Get a WebSockets cookie from the Racing+ server using our Steam ticket generated from Greenworks
// The authentication flow is described here: https://partner.steamgames.com/documentation/auth#client_to_backend_webapi
// (you have to be logged in for the link to work)
// The server will validate our session ticket using the Steam web API, and if successful, give us a cookie
// If our steam ID does not already exist in the database, we will be told to register
function login() {
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
                    login();
                }, 250);
                globals.log.info('Logging in (without having checked for an update yet). Stalling for 0.25 seconds...');
                return;
            }
        }
    } else if (globals.autoUpdateStatus === 'checking-for-update') {
        setTimeout(function() {
            login();
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
        steamID: globals.steam.id,
        ticket:  globals.steam.ticket, // This will be verified on the server via the Steam web API
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
        // Show the error screen (and don't bother reporting this to Sentry)
        globals.log.info('Login failed.');
        let error = misc.findAjaxError(jqXHR);
        misc.errorShow(error, false);
    });
}

// Log in manually
function loginDebug(account) {
    if (globals.currentScreen !== 'title-ajax') {
        return;
    }

    $('#title-choose').fadeOut(globals.fadeTime, function() {
        $('#title-ajax').fadeIn(globals.fadeTime);
    });

    if (account === null) {
        // Normal login
        ipcRenderer.send('asynchronous-message', 'steam', account);
    } else if (account === 1) {
        globals.steam.id = '101';
        globals.steam.screenName = 'TestAccount1';
        globals.steam.ticket = 'debug';
        login();
    } else if (account === 2) {
        globals.steam.id = '102';
        globals.steam.screenName = 'TestAccount2';
        globals.steam.ticket = 'debug';
        login();
    } else if (account === 3) {
        globals.steam.id = '103';
        globals.steam.screenName = 'TestAccount3';
        globals.steam.ticket = 'debug';
        login();
    }
}
