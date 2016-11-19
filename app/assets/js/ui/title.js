/*
    Title screen
*/

'use strict';

// Imports
const keytar       = nodeRequire('keytar');
const globals      = nodeRequire('./assets/js/globals');
const settings     = nodeRequire('./assets/js/settings');
const loginScreen  = nodeRequire('./assets/js/ui/login');

$(document).ready(function() {
    // Set the version number on the title screen
    $('#title-version').html('v' + globals.version);

    // Find out if the user has saved credentials
    let storedUsername = settings.get('username');
    if (typeof storedUsername !== 'undefined' && storedUsername !== '') {
        let storedPassword = keytar.getPassword('Racing+', storedUsername);
        if (storedPassword !== null) {
            // Show an AJAX circle
            globals.currentScreen = 'title-ajax';
            $('#title-buttons').fadeOut(0);
            $('#title-languages').fadeOut(0);
            $('#title-version').fadeOut(0);
            $('#title-ajax').fadeIn(0);

            // Fill in the input fields in the login form in case there is an error later on
            $('#login-username').val(storedUsername);
            $('#login-password').val(storedPassword);
            $('#login-remember-checkbox').prop('checked', true);

            // We have a saved username and password, so attempt to log in automatically
            loginScreen.login1(storedUsername, storedPassword, false);
        }
    }

    /*
        Event handlers
    */

    $('#title-login-button').click(function() {
        if (globals.currentScreen !== 'title') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#title').fadeOut(globals.fadeTime, function() {
            $('#login').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'login';
            });
            $('#login-username').focus();
        });
    });

    $('#title-register-button').click(function() {
        if (globals.currentScreen !== 'title') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#title').fadeOut(globals.fadeTime, function() {
            $('#register').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'register';
            });
            $('#register-username').focus();
        });
    });
});
