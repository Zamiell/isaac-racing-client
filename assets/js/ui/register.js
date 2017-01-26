/*
    Register screen
*/

'use strict';

// Imports
const globals     = nodeRequire('./assets/js/globals');
const misc        = nodeRequire('./assets/js/misc');
const websocket   = nodeRequire('./assets/js/websocket');

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
        if (username === '') {
            $('#register-error').fadeIn(globals.fadeTime);
            $('#register-error').html('<span lang="en">The username field is required.</span>');
            return;
        }

        // Fade the form and show the AJAX circle
        globals.currentScreen = 'register-ajax';
        if ($('#register-error').css('display') !== 'none') {
            $('#register-error').fadeTo(globals.fadeTime, 0.25);
        }
        $('#register-explanation1').fadeTo(globals.fadeTime, 0.25);
        $('#register-explanation2').fadeTo(globals.fadeTime, 0.25);
        $('#register-form').fadeTo(globals.fadeTime, 0.25);
        $('#register-username').prop('disabled', true);
        $('#register-submit-button').prop('disabled', true);
        $('#register-languages').fadeTo(globals.fadeTime, 0.25);
        $('#register-ajax').fadeIn(globals.fadeTime);

        // Register the username with the Racing+ server
        register(username);
    });
});

/*
    Register functions
*/

exports.show = function() {
    globals.currentScreen = 'transition';
    $('#title').fadeOut(globals.fadeTime, function() {
        $('#register').fadeIn(globals.fadeTime, function() {
            globals.currentScreen = 'register';
        });
        $('#register-username').val(globals.steam.screenName);
        $('#register-username').focus();
    });
};

// Register with the Racing+ server
// We will resend our Steam ID and ticket, just like we did previously in the login function, but this time we will also include our desired username
function register(username) {
    globals.log.info('Sending a register request to the Racing+ server.');
    let data = {
        steamID:  globals.steam.id,
        ticket:   globals.steam.ticket, // This will be verified on the server via the Steam web API
        username: username,             // Our desired screen name that will be visible to other racers
    };
    let url = 'http' + (globals.secure ? 's' : '') + '://' + globals.domain + '/register';
    let request = $.ajax({
        url:  url,
        type: 'POST',
        data: data,
    });
    request.done(function(data) {
        // We successfully got a cookie; attempt to establish a WebSocket connection
        websocket.init();
    });
    request.fail(fail);
}

const fail = function(jqXHR) {
    globals.currentScreen = 'transition';
    reset();

    // Fade in the error box
    let error = misc.findAjaxError(jqXHR);
    $('#register-error').html('<span lang="en">' + error + '</span>');
    $('#register-error').fadeTo(globals.fadeTime, 1, function() {
        globals.currentScreen = 'register';
    });
};
exports.fail = fail;

// A function to return the register form back to the way it was initially
const reset = function() {
    $('#register-explanation1').fadeTo(globals.fadeTime, 1);
    $('#register-explanation2').fadeTo(globals.fadeTime, 1);
    $('#register-form').fadeTo(globals.fadeTime, 1);
    $('#register-username').prop('disabled', false);
    $('#register-submit-button').prop('disabled', false);
    $('#register-languages').fadeTo(globals.fadeTime, 1);
    $('#register-ajax').fadeOut(globals.fadeTime);
    $('#register-username').focus();
};
exports.reset = reset;
