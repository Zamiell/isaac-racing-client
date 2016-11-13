/*
    Forgot screen
*/

'use strict';

// Imports
const globals = nodeRequire('./assets/js/globals');
const misc    = nodeRequire('./assets/js/misc');

/*
    Event handlers
*/

$(document).ready(function() {
    $('#forgot-form').submit(function(event) {
        // By default, the form will reload the page, so stop this from happening
        event.preventDefault();

        // Don't do anything if we are already requesting an email
        if (globals.currentScreen !== 'forgot') {
            return;
        }

        // Get values from the form
        let email = document.getElementById('forgot-email').value.trim();

        // Validate email
        if (email === '') {
            $('#forgot-error').fadeIn(globals.fadeTime);
            $('#forgot-error').html('<span lang="en">The email field is required.</span>');
            return;
        }

        // Fade the form and show the AJAX circle
        globals.currentScreen = 'forgot-ajax';
        if ($('#forgot-success').css('display') !== 'none') {
            $('#forgot-success').fadeTo(globals.fadeTime, 0.25);
        }
        if ($('#forgot-error').css('display') !== 'none') {
            $('#forgot-error').fadeTo(globals.fadeTime, 0.25);
        }
        $('#forgot-form').fadeTo(globals.fadeTime, 0.25);
        $('#forgot-email').prop('disabled', true);
        $('#forgot-submit-button').prop('disabled', true);
        $('#forgot-back-button').prop('disabled', true);
        $('#forgot-ajax').fadeIn(globals.fadeTime);

        // Request an email from Auth0
        forgotPassword(email);
    });

    $('#forgot-back-button').click(function() {
        if (globals.currentScreen !== 'forgot') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#forgot').fadeOut(globals.fadeTime, function() {
            // Clear out the login form
            $('#forgot-error').fadeOut(0);
            $('#forgot-email').val('');

            // Show the login screen
            $('#login').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'login';
            });
            $('#login-username').focus();
        });
    });
});

/*
    Forgot password functions
*/

function forgotPassword(email) {
    let data = {
        'client_id':  'tqY8tYlobY4hc16ph5B61dpMJ1YzDaAR',
        'connection': 'Isaac-Server-DB-Connection',
        'email':      email,
    };
    let request = $.ajax({
        url:  'https://isaacserver.auth0.com/dbconnections/change_password',
        type: 'POST',
        data: JSON.stringify(data),
        contentType: 'application/json',
    });
    request.done(function() {
        // The request was successful
        globals.currentScreen = 'transition';
        forgotReset();
        $('#forgot-error').fadeOut(globals.fadeTime);
        $('#forgot-success').fadeIn(globals.fadeTime, function() {
            globals.currentScreen = 'forgot';
        });
        $('#forgot-success').html('<span lang="en">Request successful. Please check your email.</span>');
    });
    request.fail(forgotFail);
}

// When an AJAX call fails
function forgotFail(jqXHR) {
    globals.currentScreen = 'transition';
    forgotReset();

    // Show the error box
    let error = misc.findAjaxError(jqXHR);
    $('#forgot-error').html('<span lang="en">' + error + '</span>');
    $('#forgot-success').fadeOut(globals.fadeTime);
    $('#forgot-error').fadeIn(globals.fadeTime, function() {
        globals.currentScreen = 'forgot';
    });
}

// A function to return the forgot form back to the way it was initially
function forgotReset() {
    if ($('#forgot-success').css('display') !== 'none') {
        $('#forgot-success').fadeTo(globals.fadeTime, 1);
    }
    if ($('#forgot-error').css('display') !== 'none') {
        $('#forgot-error').fadeTo(globals.fadeTime, 1);
    }
    $('#forgot-form').fadeTo(globals.fadeTime, 1);
    $('#forgot-email').prop('disabled', false);
    $('#forgot-submit-button').prop('disabled', false);
    $('#forgot-back-button').prop('disabled', false);
    $('#forgot-ajax').fadeOut(globals.fadeTime);
    $('#forgot-email').focus();
}
