/*
    Login screen
*/

'use strict';

// Imports
const ipcRenderer    = nodeRequire('electron').ipcRenderer;
const globals        = nodeRequire('./assets/js/globals');
const websocket      = nodeRequire('./assets/js/websocket');
const misc           = nodeRequire('./assets/js/misc');
const registerScreen = nodeRequire('./assets/js/ui/register');

/*
    Event handlers
*/

$(document).ready(function() {
    $('#login-form').submit(function(event) {
        // By default, the form will reload the page, so stop this from happening
        event.preventDefault();

        // Don't do anything if we are already logging in
        if (globals.currentScreen !== 'login') {
            return;
        }

        // Get values from the form
        let username = document.getElementById('login-username').value.trim();
        let password = document.getElementById('login-password').value.trim();
        let remember = document.getElementById('login-remember-checkbox').checked;

        // Validate username/password
        if (username === '') {
            $('#login-error').fadeIn(globals.fadeTime);
            $('#login-error').html('<span lang="en">The username field is required.</span>');
            return;
        } else if (password === '') {
            $('#login-error').fadeIn(globals.fadeTime);
            $('#login-error').html('<span lang="en">The password field is required.</span>');
            return;
        }

        // Fade the form and show the AJAX circle
        globals.currentScreen = 'login-ajax';
        if ($('#login-error').css('display') !== 'none') {
            $('#login-error').fadeTo(globals.fadeTime, 0.25);
        }
        $('#login-form').fadeTo(globals.fadeTime, 0.25);
        $('#login-username').prop('disabled', true);
        $('#login-password').prop('disabled', true);
        $('#login-remember-checkbox').prop('disabled', true);
        $('#login-remember-checkbox-label').css('cursor', 'default');
        $('#login-forgot-button').prop('disabled', true);
        $('#login-submit-button').prop('disabled', true);
        $('#login-back-button').prop('disabled', true);
        $('#login-ajax').fadeIn(globals.fadeTime);

        // Begin the login process
        login1(username, password, remember);
    });

    $('#login-forgot-button').click(function() {
        if (globals.currentScreen !== 'login') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#login').fadeOut(globals.fadeTime, function() {
            // Clear out the login form
            $('#login-error').fadeOut(0);
            $('#login-username').val('');
            $('#login-password').val('');
            $('#login-remember-checkbox').prop('checked', false);

            // Show the forgot password screen
            $('#forgot').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'forgot';
            });
            $('#forgot-email').focus();
        });
    });

    $('#login-back-button').click(function() {
        if (globals.currentScreen !== 'login') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#login').fadeOut(globals.fadeTime, function() {
            // Clear out the login form
            $('#login-error').fadeOut(0);
            $('#login-username').val('');
            $('#login-password').val('');
            $('#login-remember-checkbox').prop('checked', false);

            // Show the title screen
            $('#title').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'title';
            });
        });
    });
});

/*
    Login functions
*/

// Step 1 - Get a login token from Auth0
const login1 = function(username, password, remember) {
    // Don't login yet if we are still checking for updates
    console.log("Logging in with autoUpdateStatus:", globals.autoUpdateStatus);
    if (globals.autoUpdateStatus === null) {
        // This is the first run, so they should be on the most recent version, so continue to login
        // (or we are in a development environment)
    } else if (globals.autoUpdateStatus === 'checking-for-update') {
        setTimeout(function() {
            login1(username, password, remember);
        }, 100);
        return;
    } else if (globals.autoUpdateStatus === 'error') {
        // Allow them to continue to log on if they got an error since we want the service to be usable when GitHub is down
    } else if (globals.autoUpdateStatus === 'update-available') {
        // They are beginning to download the update
        globals.currentScreen = 'transition';
        $('#login').fadeOut(globals.fadeTime, function() {
            $('#updating').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'updating';
            });
        });
        return;
    } else if (globals.autoUpdateStatus === 'update-not-available') {
        // Do nothing special and continue to login
    } else if (globals.autoUpdateStatus === 'update-downloaded') {
        // The update was downloaded in the background while the user was idle at the title or login screen
        // Show them the updating screen so they are not confused at the program restarting
        globals.currentScreen = 'transition';
        $('#login').fadeOut(globals.fadeTime, function() {
            $('#updating').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'updating';

                setTimeout(function() {
                    ipcRenderer.send('asynchronous-message', 'restart');
                }, 1000);
            });
        });
        return;
    }

    // Send a request to Auth0
    console.log('Sending a request to Auth0.');
    let data = {
        'grant_type': 'password',
        'username':   username,
        'password':   password,
        'client_id':  'tqY8tYlobY4hc16ph5B61dpMJ1YzDaAR',
        'connection': 'Isaac-Server-DB-Connection',
    };
    let request = $.ajax({
        url:  'https://isaacserver.auth0.com/oauth/ro',
        type: 'POST',
        data: data,
    });
    request.done(function(data) {
        // We successfully got the token; move on to step 2
        login2(username, password, remember, data);
    });
    request.fail(loginFail);
};
exports.login1 = login1;

// Step 2 - Login with the token to get a cookie
function login2(username, password, remember, data) {
    console.log('Using the Auth0 token to get a cookie.');
    let url = 'http' + (globals.secure ? 's' : '') + '://' + globals.domain + '/login';
    let request = $.ajax({
        url:  url,
        type: 'POST',
        data: JSON.stringify(data),
        contentType: 'application/json',
    });
    request.done(function() {
        // We successfully got a cookie; attempt to establish a WebSocket connection
        websocket.init(username, password, remember);
    });
    request.fail(loginFail);
}

// When an AJAX call fails
function loginFail(jqXHR) {
    console.log('Login failed.');

    // Transition to the login screen if we are not already there
    if (globals.currentScreen === 'title-ajax') {
        globals.currentScreen = 'transition';
        $('#title').fadeOut(globals.fadeTime, function() {
            // Reset the title screen back to normal
            $('#title-buttons').fadeIn(0);
            $('#title-languages').fadeIn(0);
            $('#title-version').fadeIn(0);
            $('#title-ajax').fadeOut(0);

            // Show the login screen
            $('#login').fadeIn(globals.fadeTime);
            $('#login-username').focus();
        });
    } else if (globals.currentScreen === 'login-ajax') {
        globals.currentScreen = 'transition';
        loginReset();
    } else if (globals.currentScreen === 'register-ajax') {
        globals.currentScreen = 'transition';
        $('#register').fadeOut(globals.fadeTime, function() {
            // Reset the register screen back to normal
            registerScreen.registerReset();
            $('#register-username').val('');
            $('#register-password').val('');
            $('#register-email').val('');

            // Show the login screen
            $('#login').fadeIn(globals.fadeTime);
            $('#login-username').focus();
        });
    }

    // Show the error box
    let error = misc.findAjaxError(jqXHR);
    $('#login-error').html('<span lang="en">' + error + '</span>');
    $('#login-error').fadeIn(globals.fadeTime, function() {
        globals.currentScreen = 'login';
    });
}

// A function to return the login form back to the way it was initially
const loginReset = function() {
    $('#login-error').fadeTo(globals.fadeTime, 1);
    $('#login-form').fadeTo(globals.fadeTime, 1);
    $('#login-username').prop('disabled', false);
    $('#login-password').prop('disabled', false);
    $('#login-remember-checkbox').prop('disabled', false);
    $('#login-remember-checkbox-label').css('cursor', 'pointer');
    $('#login-forgot-button').prop('disabled', false);
    $('#login-submit-button').prop('disabled', false);
    $('#login-back-button').prop('disabled', false);
    $('#login-ajax').fadeOut(globals.fadeTime);
    $('#login-username').focus();
};
exports.loginReset = loginReset;
