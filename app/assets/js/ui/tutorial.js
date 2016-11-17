/*
    Tutorial screen
*/

'use strict';

// Imports
const globals = nodeRequire('./assets/js/globals');

$(document).ready(function() {
    if (globals.settings.tutorial === 'true') {
        $('#title-buttons').fadeOut(0);
        $('#title-buttons-tutorial').fadeIn(0);
    }

    /*
        Event handlers
    */

    $('#title-tutorial-button').click(function() {
        if (globals.currentScreen !== 'title') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#title').fadeOut(globals.fadeTime, function() {
            $('#tutorial1').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'tutorial1';
            });
        });
    });

    $('#tutorial1-next-button').click(function() {
        if (globals.currentScreen !== 'tutorial1') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#tutorial1').fadeOut(globals.fadeTime, function() {
            $('#tutorial2').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'tutorial2';
            });
        });
    });

    $('#tutorial2-next-button').click(function() {
        if (globals.currentScreen !== 'tutorial2') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#tutorial2').fadeOut(globals.fadeTime, function() {
            // Mark that we have completed the tutorial
            globals.settings.tutorial = 'false';
            localStorage.tutorial = 'false';

            // Change the title screen to the default
            $('#title-buttons-tutorial').fadeOut(0);
            $('#title-buttons').fadeIn(0);

            // Return to the title screen
            $('#title').fadeIn(globals.fadeTime, function() {
                globals.currentScreen = 'title';
            });
        });
    });
});
