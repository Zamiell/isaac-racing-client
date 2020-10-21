/*
    Steam functions (and automatic login)
*/

// Imports
const { ipcRenderer } = nodeRequire('electron');
const globals = nodeRequire('./js/globals');
const misc = nodeRequire('./js/misc');
const websocket = nodeRequire('./js/websocket');
const registerScreen = nodeRequire('./js/ui/register');

const isDev = process.mainModule.filename.indexOf('app.asar') === -1;

// Check to see if Steam is running on startup
$(document).ready(() => {
    if (isDev) {
        // Don't automatically log in with our Steam account
        // We want to choose from a list of login options
        $('#title-ajax').fadeOut(0);
        $('#title-choose').fadeIn(0);

        $('#title-choose-steam').click(() => {
            loginDebug(null);
        });

        for (let i = 1; i <= 10; i++) {
            $(`#title-choose-${i}`).click(() => {
                loginDebug(i);
            });
        }

        $('#title-restart').click(() => {
            // Restart the client
            ipcRenderer.send('asynchronous-message', 'restart');
        });

        // Automatically log in with account #1
        // $('#title-choose-1').click();
    } else {
        // Tell the main process to start the child process that will initialize Greenworks
        // That process will get our Steam ID, Steam screen name, and authentication ticket
        ipcRenderer.send('asynchronous-message', 'steam', null);
    }
});

// Monitor for notifications from the child process that is getting the data from Greenworks
ipcRenderer.on('steam', (event, message) => {
    if (typeof message !== 'string') {
        // The child process is finished and has sent us the Steam-related information that we seek
        globals.steam.id = message.id;
        globals.steam.accountID = message.accountID;
        globals.steam.screenName = message.screenName;
        globals.steam.ticket = message.ticket;
        login();
        return;
    }

    // The child process is sending us a message to log
    globals.log.info(`Steam child message: ${message}`);

    if (
        message === 'errorInit' ||
        message.startsWith('error: Error: channel closed') ||
        message.startsWith('error: Error: Steam initialization failed, but Steam is running, and steam_appid.txt is present and valid.')
    ) {
        // Don't bother sending these messages to Sentry; the user not having Steam open is a fairly ordinary error
        misc.errorShow('Failed to communicate with Steam. Please open or restart Steam and relaunch Racing+.', false);
    } else if (message.startsWith('error: ')) {
        // This is some other uncommon error
        const error = message.match(/error: (.+)/)[1];
        misc.errorShow(error);
    }
});

// Get a WebSockets cookie from the Racing+ server using our Steam ticket generated from Greenworks
// The authentication flow is described here: https://partner.steamgames.com/documentation/auth#client_to_backend_webapi
// (you have to be logged in for the link to work)
// The server will validate our session ticket using the Steam web API, and if successful, give us a cookie
// If our Steam ID does not already exist in the database, we will be told to register
function login() {
    // Don't login yet if we are still checking for updates
    if (globals.autoUpdateStatus === null) {
        if (isDev) {
            // We won't auto-update in development
        } else {
            // The client has not yet begun to check for an update, so stall
            // However, sometimes this can be permanently null in production (maybe after an automatic update?),
            // so allow them to proceed after a while
            const now = new Date().getTime();
            if (now - globals.timeLaunched < 10000) { // 10 seconds
                setTimeout(() => {
                    login();
                }, 250);
                globals.log.info('Logging in (without having checked for an update yet). Stalling for 0.25 seconds...');
                return;
            }
        }
    } else if (globals.autoUpdateStatus === 'checking-for-update') {
        setTimeout(() => {
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
        $('#title').fadeOut(globals.fadeTime, () => {
            $('#updating').fadeIn(globals.fadeTime, () => {
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
        $('#title').fadeOut(globals.fadeTime, () => {
            $('#updating').fadeIn(globals.fadeTime, () => {
                globals.currentScreen = 'updating';

                setTimeout(() => {
                    ipcRenderer.send('asynchronous-message', 'quitAndInstall');
                }, 1500);
                globals.log.info('Logging in (with an update was downloaded successfully). Showing the "updating" screen and automatically restart in 1.5 seconds."');
            });
        });
        return;
    }

    // Send a request to the Racing+ server
    globals.log.info('Sending a login request to the Racing+ server.');
    const postData = {
        steamID: globals.steam.id,
        ticket: globals.steam.ticket, // This will be verified on the server via the Steam web API
        version: globals.version,
    };
    if (process.platform === 'darwin') { // macOS
        // Normally, the server will not allow clients to login if they are running old versions
        // However, on macOS, there is no auto-update mechanism currently
        // Thus, we allow macOS users to login with older versions
        postData.version = 'macOS';
    }
    const url = `${globals.websiteURL}/login`;

    const request = $.ajax({
        url,
        type: 'POST',
        data: postData,
    });
    request.done((data) => {
        data = data.trim();
        if (data === 'Accepted') {
            // If the server gives us "Accepted", then our Steam credentials are valid, but we don't have an account on the server yet
            // Let the user pick their username
            registerScreen.show();
        } else {
            // We successfully got a cookie; attempt to establish a WebSocket connection
            websocket.init();
        }
    });
    request.fail((jqXHR) => {
        // Show the error screen (and don't bother reporting this to Sentry)
        globals.log.info('Login failed.');
        globals.log.info(jqXHR);
        const error = misc.findAjaxError(jqXHR);
        misc.errorShow(error, false);
    });
}

// Log in manually
function loginDebug(account) {
    if (globals.currentScreen !== 'title-ajax') {
        return;
    }

    $('#title-choose').fadeOut(globals.fadeTime, () => {
        $('#title-ajax').fadeIn(globals.fadeTime);
    });

    if (account === null) {
        // Normal login
        ipcRenderer.send('asynchronous-message', 'steam', account);
    } else {
        globals.steam.id = `-${account}`;
        globals.steam.accountID = 0;
        globals.steam.screenName = `TestAccount${account}`;
        globals.steam.ticket = 'debug';
        login();
    }
}
