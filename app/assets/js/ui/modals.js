/*
    Modals
*/

'use strict';

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const remote      = nodeRequire('electron').remote;
const shell       = nodeRequire('electron').shell;
const globals     = nodeRequire('./assets/js/globals');

/*
    Event handlers
*/

$(document).ready(function() {
    /*
        Error modal
    */

    $('#error-modal-button').click(function() {
        if (globals.currentScreen === 'error') {
            ipcRenderer.send('asynchronous-message', 'restart');
        }
    });

    /*
        Log file modal
    */

    $('#log-file-link').click(function() {
        let url = 'https://steamcommunity.com/app/250900/discussions/0/613941122558099449/';
        shell.openExternal(url);
    });

    $('#log-file-find').click(function() {
        let titleText = $('#select-your-log-file').html();
        let newLogFilePath = remote.dialog.showOpenDialog({
            title: titleText,
            filters: [
                {
                    'name': 'Text',
                    'extensions': ['txt'],
                }
            ],
            properties: ['openFile'],
        });
        if (newLogFilePath === undefined) {
            return;
        } else {
            globals.settings.logFilePath = newLogFilePath[0];
            localStorage.logFilePath = newLogFilePath[0];

            $('#log-file-description-1').fadeOut(globals.fadeTime);
            $('#log-file-description-2').fadeOut(globals.fadeTime, function() {
                $('#log-file-description-3').fadeIn(globals.fadeTime);
            });
            $('#log-file-find').fadeOut(globals.fadeTime, function() {
                $('#log-file-exit').fadeIn(globals.fadeTime);
            });
        }
    });

    $('#log-file-exit').click(function() {
        if (globals.currentScreen === 'error') {
            ipcRenderer.send('asynchronous-message', 'restart');
        }
    });
});
