/*
    Register screen
*/

'use strict';

// Imports
const globals     = nodeRequire('./assets/js/globals');
const misc        = nodeRequire('./assets/js/misc');
const loginScreen = nodeRequire('./assets/js/ui/login');

/*
    Event handlers
*/

$(document).ready(function() {
    $('#register-form').submit(function(event) {
        // By default, the form will reload the page, so stop this from happening
        event.preventDefault();

        // Don't do anything if we are already registering
        if (globals.currentScreen !== 'register') {
            return;
        }

        // Validate username/password/email
        let username = document.getElementById('register-username').value.trim();
        let password = document.getElementById('register-password').value.trim();
        let email     = document.getElementById('register-email').value.trim();
        if (username === '') {
            $('#register-error').fadeIn(globals.fadeTime);
            $('#register-error').html('<span lang="en">The username field is required.</span>');
            return;
        } else if (password === '') {
            $('#register-error').fadeIn(globals.fadeTime);
            $('#register-error').html('<span lang="en">The password field is required.</span>');
            return;
        } else if (email === '') {
            $('#register-error').fadeIn(globals.fadeTime);
            $('#register-error').html('<span lang="en">The email field is required.</span>');
            return;
        }

        // Fade the form and show the AJAX circle
        globals.currentScreen = 'register-ajax';
        if ($('#register-error').css('display') !== 'none') {
            $('#register-error').fadeTo(globals.fadeTime, 0.25);
        }
        $('#register-form').fadeTo(globals.fadeTime, 0.25);
        $('#register-username').prop('disabled', true);
        $('#register-password').prop('disabled', true);
        $('#register-email').prop('disabled', true);
        $('#register-submit-button').prop('disabled', true);
        $('#register-back-button').prop('disabled', true);
        $('#register-ajax').fadeIn(globals.fadeTime);

        // Begin the register process
        register(username, password, email);
    });

    $('#register-back-button').click(function() {
        if (globals.currentScreen !== 'register') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#register').fadeOut(globals.fadeTime, function() {
            // Clear out the register form
            $('#register-error').fadeOut(0);
            $('#register-username').val('');
            $('#register-password').val('');
            $('#register-email').val('');

            // Show the title screen
            $('#title').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'title';
            });
        });
    });
});

/*
    Register functions
*/

// Register with Auth0
function register(username, password, email) {
    let data = {
        'client_id':  'tqY8tYlobY4hc16ph5B61dpMJ1YzDaAR',
        'connection': 'Isaac-Server-DB-Connection',
        'username':   username,
        'password':   password,
        'email':      email,
    };
    let request = $.ajax({
        url:  'https://isaacserver.auth0.com/dbconnections/signup',
        type: 'POST',
        data: JSON.stringify(data),
        contentType: 'application/json',
    });
    request.done(function(data) {
        // Fill in the input fields in the login form in case there is an error later on
        $('#login-username').val(username);
        $('#login-password').val(password);

        // The account was successfully created; now begin the log in process
        loginScreen.login1(username, password, false);
    });
    request.fail(registerFail);
}

// When an AJAX call fails
function registerFail(jqXHR) {
    globals.currentScreen = 'transition';
    registerReset();

    // Show the error box
    let error = misc.findAjaxError(jqXHR);
    $('#register-error').html('<span lang="en">' + error + '</span>');
    $('#register-error').fadeTo(globals.fadeTime, 1, function() {
        globals.currentScreen = 'register';
    });
}

// A function to return the register form back to the way it was initially
const registerReset = function() {
    $('#register-form').fadeTo(globals.fadeTime, 1);
    $('#register-username').prop('disabled', false);
    $('#register-password').prop('disabled', false);
    $('#register-email').prop('disabled', false);
    $('#register-submit-button').prop('disabled', false);
    $('#register-back-button').prop('disabled', false);
    $('#register-ajax').fadeOut(globals.fadeTime);
    $('#register-username').focus();
};
exports.registerReset = registerReset;
