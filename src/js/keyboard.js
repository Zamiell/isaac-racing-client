/*
    Keyboard bindings
*/

// Imports
const { ipcRenderer } = nodeRequire('electron');
const isDev = nodeRequire('electron-is-dev');
const globals = nodeRequire('./js/globals');
const misc = nodeRequire('./js/misc');

// Monitor for keystrokes inside of the browser window
$(document).keydown((event) => {
    // console.log(event.which); // Uncomment this to find out which number corresponds to the desired key

    if (event.which === 192 && globals.currentScreen === 'title-ajax' && isDev) { // "`"
        event.preventDefault();
        $('#title-choose-steam').click();
    } else if (event.which === 49 && globals.currentScreen === 'title-ajax' && isDev) { // "1"
        event.preventDefault();
        $('#title-choose-1').click();
    } else if (event.which === 50 && globals.currentScreen === 'title-ajax' && isDev) { // "2"
        event.preventDefault();
        $('#title-choose-2').click();
    } else if (event.which === 51 && globals.currentScreen === 'title-ajax' && isDev) { // "3"
        event.preventDefault();
        $('#title-choose-3').click();
    } else if (event.which === 82 && globals.currentScreen === 'title-ajax' && isDev) { // "r"
        event.preventDefault();
        $('#title-restart').click();
    } else if (event.which === 123) { // "F12"
        ipcRenderer.send('asynchronous-message', 'devTools');
    } else if (event.which === 9) { // "Tab"
        if (globals.currentScreen !== 'lobby' && globals.currentScreen !== 'race') {
            return;
        }

        if (!$(`#${globals.currentScreen}-chat-box-input`).is(':focus')) {
            return;
        }

        event.preventDefault();

        // Get the current list of connected users
        const userList = [];
        for (const user of Object.keys(globals.roomList.lobby.users)) {
            userList.push(user);
        }

        // We want to be able to tab complete both users and emotes
        const tabList = globals.emoteList.concat(userList);
        tabList.push(':thinking:'); // Also add some custom emotes to the tab completion list
        tabList.sort();

        // Prioritize the more commonly used NotLikeThis over NootLikeThis
        const notLikeThisIndex = tabList.indexOf('NotLikeThis');
        const nootLikeThisIndex = tabList.indexOf('NootLikeThis');
        tabList[notLikeThisIndex] = 'NootLikeThis';
        tabList[nootLikeThisIndex] = 'NotLikeThis';

        // Prioritize the more commonly used Kappa over Kadda
        const kappaIndex = tabList.indexOf('Kappa');
        const kaddaIndex = tabList.indexOf('Kadda');
        tabList[kaddaIndex] = 'Kappa';
        tabList[kappaIndex] = 'Kadda';

        // Prioritize the more commonly used FrankerZ over all other Franker emotes
        const frankerZIndex = tabList.indexOf('FrankerZ');
        const frankerBIndex = tabList.indexOf('FrankerB');
        let tempEmote1 = tabList[frankerBIndex];
        tabList[frankerBIndex] = 'FrankerZ';
        for (let i = frankerBIndex; i < frankerZIndex; i++) {
            const tempEmote2 = tabList[i + 1];
            tabList[i + 1] = tempEmote1;
            tempEmote1 = tempEmote2;
        }

        if (globals.tabCompleteCounter === 0) {
            // This is the first time we are pressing tab
            const message = $(`#${globals.currentScreen}-chat-box-input`).val().trim();
            globals.tabCompleteWordList = message.split(' ');
            const messageEnd = globals.tabCompleteWordList[globals.tabCompleteWordList.length - 1];
            for (let i = 0; i < tabList.length; i++) {
                const tabWord = tabList[i];
                const temp = tabWord.slice(0, messageEnd.length).toLowerCase();
                if (temp === messageEnd.toLowerCase()) {
                    globals.tabCompleteIndex = i;
                    globals.tabCompleteCounter += 1;
                    let newMessage = '';
                    for (let j = 0; j < globals.tabCompleteWordList.length - 1; j++) {
                        newMessage += globals.tabCompleteWordList[j];
                        newMessage += ' ';
                    }
                    newMessage += tabWord;
                    $(`#${globals.currentScreen}-chat-box-input`).val(newMessage);
                    break;
                }
            }
        } else {
            // We have already pressed tab once and we need to cycle through the rest of the autocompletion words
            let index = globals.tabCompleteCounter + globals.tabCompleteIndex;
            const messageEnd = globals.tabCompleteWordList[globals.tabCompleteWordList.length - 1];
            if (globals.tabCompleteCounter >= tabList.length) {
                globals.tabCompleteCounter = 0;
                $(`#${globals.currentScreen}-chat-box-input`).val(messageEnd);
                index = globals.tabCompleteCounter + globals.tabCompleteIndex;
            }
            const tempSlice = tabList[index].slice(0, messageEnd.length).toLowerCase();
            if (tempSlice === messageEnd.toLowerCase()) {
                globals.tabCompleteCounter += 1;
                let newMessage = '';
                for (let i = 0; i < globals.tabCompleteWordList.length - 1; i++) {
                    newMessage += globals.tabCompleteWordList[i];
                    newMessage += ' ';
                }
                newMessage += tabList[index];
                $(`#${globals.currentScreen}-chat-box-input`).val(newMessage);
            } else {
                globals.tabCompleteCounter = 0;
                let newMessage = '';
                for (let i = 0; i < globals.tabCompleteWordList.length - 1; i++) {
                    newMessage += globals.tabCompleteWordList[i];
                    newMessage += ' ';
                }
                newMessage += messageEnd;
                $(`#${globals.currentScreen}-chat-box-input`).val(newMessage);
            }
        }
    } else if (event.which === 8 || event.which === 13 || event.which === 32) { // "Backspace", "Enter", and "Space"
        if (globals.currentScreen !== 'lobby' && globals.currentScreen !== 'race') {
            return;
        }

        if (!$(`#${globals.currentScreen}-chat-box-input`).is(':focus')) {
            return;
        }

        globals.tabCompleteCounter = 0;
        globals.tabCompleteIndex = 0;
        globals.tabCompleteWordList = null;
    } else if (event.which === 27) { // "Esc"
        if (globals.currentScreen === 'lobby') {
            misc.closeAllTooltips();
        } else if (globals.currentScreen === 'race') {
            $('#header-lobby').click();
        }
    } else if (event.which === 38) { // Up arrow
        if (globals.currentScreen !== 'lobby' && globals.currentScreen !== 'race') {
            return;
        }

        if (!$(`#${globals.currentScreen}-chat-box-input`).is(':focus')) {
            return;
        }

        let room;
        if (globals.currentScreen === 'lobby') {
            room = 'lobby';
        } else if (globals.currentScreen === 'race') {
            room = `_race_${globals.currentRaceID}`;
        }

        event.preventDefault();
        globals.roomList[room].historyIndex += 1;

        // Check to see if we have reached the end of the history list
        if (globals.roomList[room].historyIndex > globals.roomList[room].typedHistory.length - 1) {
            globals.roomList[room].historyIndex -= 1;
            return;
        }

        // Set the chat input box to what we last typed
        const retrievedHistory = globals.roomList[room].typedHistory[globals.roomList[room].historyIndex];
        $(`#${globals.currentScreen}-chat-box-input`).val(retrievedHistory);
    } else if (event.which === 40) { // Down arrow
        if (globals.currentScreen === 'lobby' || globals.currentScreen === 'race') {
            return;
        }

        if (!$(`#${globals.currentScreen}-chat-box-input`).is(':focus')) {
            return;
        }

        let room;
        if (globals.currentScreen === 'lobby') {
            room = 'lobby';
        } else if (globals.currentScreen === 'race') {
            room = `_race_${globals.currentRaceID}`;
        }

        event.preventDefault();
        globals.roomList[room].historyIndex -= 1;

        // Check to see if we have reached the beginning of the history list
        if (globals.roomList[room].historyIndex <= -2) { // -2 instead of -1 here because we want down arrow to clear the chat
            globals.roomList[room].historyIndex = -1;
            return;
        }

        // Set the chat input box to what we last typed
        const retrievedHistory = globals.roomList[room].typedHistory[globals.roomList[room].historyIndex];
        $(`#${globals.currentScreen}-chat-box-input`).val(retrievedHistory);
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
        if (globals.currentScreen === 'lobby' && $('#header-new-race').tooltipster('status').open) {
            event.preventDefault();
            $('#new-race-form').submit();
        }
    }
});

// Monitor for global hotkeys (caught by electron.globalShortcut in the main process)
const hotkey = (event, message) => {
    globals.log.info('Recieved hotkey message:', message);

    if (message === 'ready') { // Alt + r
        $('#race-ready-checkbox').click();
    } else if (message === 'finish') { // Alt + f
        $('#race-finish-button').click();
    } else if (message === 'quit') { // Alt + q
        $('#race-quit-button').click();
    }
};
ipcRenderer.on('hotkey', hotkey);
