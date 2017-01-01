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

    } else if (event.which === 9) { // "Tab"
        if ($('#' + globals.currentScreen + '-chat-box-input').is(':focus')) {
            event.preventDefault();

            // Get the current list of connected users
            let userList = [];
            for (let user in globals.roomList.lobby.users) {
                if (globals.roomList.lobby.users.hasOwnProperty(user)) {
                    userList.push(user);
                }
            }

            let tabList = globals.emoteList.concat(userList);
            tabList.sort();

            if (globals.tabCompleteCounter === 0){
                let message = document.getElementById(globals.currentScreen + '-chat-box-input').value.trim();
                globals.tabCompleteWordList = message.split(' ');
                let messageEnd = globals.tabCompleteWordList[globals.tabCompleteWordList.length - 1].toLowerCase();
                for (let i = 0; i < tabList.length; i++) {
                    let tabWord = tabList[i];
                    let temp = tabWord.slice(0, messageEnd.length).toLowerCase();
                    if (temp === messageEnd) {
                        globals.tabCompleteIndex = i;
                        globals.tabCompleteCounter += 1;
                        let newMessage = '';
                        for(let j = 0; j < globals.tabCompleteWordList.length-1; j++) {
                            newMessage += globals.tabCompleteWordList[j];
                            newMessage += ' ';
                        }
                        newMessage += tabWord;
                        document.getElementById(globals.currentScreen + '-chat-box-input').value = newMessage;
                        break;
                    }
                }
            } else {
                let index = globals.tabCompleteCounter + globals.tabCompleteIndex;
                let messageEnd = globals.tabCompleteWordList[globals.tabCompleteWordList.length-1].toLowerCase();
                if (globals.tabCompleteCounter >= tabList.length){
                    globals.tabCompleteCounter = 0;
                    document.getElementById(globals.currentScreen + '-chat-box-input').value = messageEnd;
                    index = globals.tabCompleteCounter + globals.tabCompleteIndex;
                }
                let tempSlice = tabList[index].slice(0, messageEnd.length).toLowerCase();
                if (tempSlice === messageEnd) {
                    globals.tabCompleteCounter += 1;
                    let newMessage = '';
                    for(let x = 0; x < globals.tabCompleteWordList.length-1; x++){
                        newMessage += globals.tabCompleteWordList[x];
                        newMessage += ' ';
                    }
                    newMessage += tabList[index];
                    document.getElementById(globals.currentScreen + '-chat-box-input').value = newMessage;
                } else {
                    globals.tabCompleteCounter = 0;
                    let newMessage = '';
                    for (let i = 0; i < globals.tabCompleteWordList.length-1; i++) {
                        newMessage += globals.tabCompleteWordList[i];
                        newMessage += ' ';
                    }
                    newMessage += messageEnd;
                    document.getElementById(globals.currentScreen + '-chat-box-input').value = newMessage;
                }
            }
        }

    } else if (event.which === 8 || event.which === 13 || event.which === 32) { // "Backspace", "Enter", and "Space"
        if ($('#' + globals.currentScreen + '-chat-box-input').is(':focus')) {
            globals.tabCompleteCounter = 0;
            globals.tabCompleteIndex = 0;
            globals.tabCompleteWordList = null;
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
        } else if (globals.currentScreen === 'race') {
            $('#header-lobby').click();
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
