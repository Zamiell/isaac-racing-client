/*
    Tutorial screen
*/

// Imports
const settings = nodeRequire('./settings');
const globals = nodeRequire('./js/globals');

$(document).ready(() => {
    if (settings.get('tutorial') === 'true') {
        $('#title-buttons').fadeOut(0);
        $('#title-buttons-tutorial').fadeIn(0);
    }

    /*
        Event handlers
    */

    $('#title-tutorial-button').click(() => {
        if (globals.currentScreen !== 'title') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#title').fadeOut(globals.fadeTime, () => {
            $('#tutorial1').fadeIn(globals.fadeTime, () => {
                globals.currentScreen = 'tutorial1';
            });
        });
    });

    $('#tutorial1-next-button').click(() => {
        if (globals.currentScreen !== 'tutorial1') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#tutorial1').fadeOut(globals.fadeTime, () => {
            $('#tutorial2').fadeIn(globals.fadeTime, () => {
                globals.currentScreen = 'tutorial2';
            });
        });
    });

    $('#tutorial2-next-button').click(() => {
        if (globals.currentScreen !== 'tutorial2') {
            return;
        }
        globals.currentScreen = 'transition';
        $('#tutorial2').fadeOut(globals.fadeTime, () => {
            // Mark that we have completed the tutorial
            settings.set('tutorial', 'false');
            settings.saveSync();

            // Change the title screen to the default
            $('#title-buttons-tutorial').fadeOut(0);
            $('#title-buttons').fadeIn(0);

            // Return to the title screen
            $('#title').fadeIn(globals.fadeTime, () => {
                globals.currentScreen = 'title';
            });
        });
    });
});
