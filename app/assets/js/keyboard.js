/*
    Keyboard bindings
*/

'use strict';

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const globals     = nodeRequire('./assets/js/globals');
const settings    = nodeRequire('./assets/js/settings');
const misc        = nodeRequire('./assets/js/misc');

// Monitor for keystrokes inside of the browser window
$(document).keydown(function(event) {
    //console.log(event.which); // Find out the number that corresponds to the desired key

    if (event.which === 49) { // "1"
        if (globals.currentScreen === 'title' && settings.get('tutorial') === 'false') {
            event.preventDefault();
            $('#title-login-button').click();
        }

    } else if (event.which === 50) { // "2"
        if (globals.currentScreen === 'title' && settings.get('tutorial') === 'false') {
            event.preventDefault();
            $('#title-register-button').click();
        }

    } else if (event.which === 27) { // "Esc"
        if (globals.currentScreen === 'login') {
            event.preventDefault();
            $('#login-back-button').click();
        } else if (globals.currentScreen === 'forgot') {
            event.preventDefault();
            $('#forgot-back-button').click();
        } else if (globals.currentScreen === 'register') {
            event.preventDefault();
            $('#register-back-button').click();
        } else if (globals.currentScreen === 'lobby') {
            misc.closeAllTooltips();
        }

    } else if (event.which === 38) { // Up arrow
        if (globals.currentScreen === 'lobby' || globals.currentScreen === 'race') {
            if ($('#' + globals.currentScreen + '-chat-box-input').is(':focus')) {
                let room;
                if (globals.currentScreen === 'lobby') {
                    room = 'lobby';
                } else if (globals.currentScreen === 'race') {
                    room = '_race_' + globals.currentRaceID;
                }

                event.preventDefault();
                globals.roomList[room].historyIndex++;

                // Check to see if we have reached the end of the history list
                if (globals.roomList[room].historyIndex > globals.roomList[room].typedHistory.length - 1) {
                    globals.roomList[room].historyIndex--;
                    return;
                }

                // Set the chat input box to what we last typed
                let retrievedHistory = globals.roomList[room].typedHistory[globals.roomList[room].historyIndex];
                $('#' + globals.currentScreen + '-chat-box-input').val(retrievedHistory);
            }
        }

    } else if (event.which === 40) { // Down arrow
        if (globals.currentScreen === 'lobby' || globals.currentScreen === 'race') {
            if ($('#' + globals.currentScreen + '-chat-box-input').is(':focus')) {
                let room;
                if (globals.currentScreen === 'lobby') {
                    room = 'lobby';
                } else if (globals.currentScreen === 'race') {
                    room = '_race_' + globals.currentRaceID;
                }

                event.preventDefault();
                globals.roomList[room].historyIndex--;

                // Check to see if we have reached the beginning of the history list
                if (globals.roomList[room].historyIndex <= -2) { // -2 instead of -1 here because we want down arrow to clear the chat
                    globals.roomList[room].historyIndex = -1;
                    return;
                }

                // Set the chat input box to what we last typed
                let retrievedHistory = globals.roomList[room].typedHistory[globals.roomList[room].historyIndex];
                $('#' + globals.currentScreen + '-chat-box-input').val(retrievedHistory);
            }
        }

    } else if (event.altKey && event.which === 69) { // Alt + e
        if (globals.currentScreen === 'lobby') {
            $('#header-new-race').click();
        }

    } else if (event.altKey && event.which === 83) { // Alt + s
        if (globals.currentScreen === 'lobby') {
            $('#header-settings').click();
        }

    } else if (event.altKey && event.which === 76) { // Alt + l
        if (globals.currentScreen === 'race') {
            $('#header-lobby').click();
        }

    } else if (event.which === 13) { // Enter
        if (globals.currentScreen === 'lobby' && $('#header-new-race').tooltipster('status').open === true) {
            event.preventDefault();
            $('#new-race-form').submit();
        }
    }
});

// Monitor for global hotkeys (caught by electron.globalShortcut in the main process)
const hotkey = function(event, message) {
    globals.log.info('Recieved hotkey message:', message);

    if (message === 'ready') { // Alt + r
        $('#race-ready-checkbox').click();
    } else if (message === 'quit') { // Alt + q
        $('#race-quit-button').click();
    }
};
ipcRenderer.on('hotkey', hotkey);
