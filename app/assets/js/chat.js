/*
    Chat functions
*/

'use strict';

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const linkifyHTML = nodeRequire('linkifyjs/html');
const globals     = nodeRequire('./assets/js/globals');
const misc        = nodeRequire('./assets/js/misc');

// Constants
const chatIndentPixels = 50;

exports.send = function(destination) {
    // Don't do anything if we are not on the screen corresponding to the chat input form
    if (destination === 'lobby' && globals.currentScreen !== 'lobby') {
        return;
    } else if (destination === 'race' && globals.currentScreen !== 'race') {
        return;
    }

    // Get values from the form
    let message = document.getElementById(destination + '-chat-box-input').value.trim();

    // Do nothing if the input field is empty
    if (message === '') {
        return;
    }

    // Truncate messages longer than 150 characters (this is also enforced server-side)
    if (message.length > 150) {
        message = message.substring(0, 150);
    }

    // Erase the contents of the input field
    $('#' + destination + '-chat-box-input').val('');

    // Get the room
    let room;
    if (destination === 'lobby') {
        room = 'lobby';
    } else if (destination === 'race') {
        room = '_race_' + globals.currentRaceID;
    }

    // Add it to the history so that we can use up arrow later
    globals.roomList[room].typedHistory.unshift(message);

    // Reset the history index
    globals.roomList[room].historyIndex = -1;

    /*
        Commands
    */

    if (message === '/debug') {
        // /debug - Debug command
        misc.debug();
    } else if (message === '/finish') {
        // /finish - Debug finish
        globals.conn.send('raceFinish', {
            'id': globals.currentRaceID,
        });
    } else if (message === '/restart') {
        // /restart - Restart the client
        ipcRenderer.send('asynchronous-message', 'restart');
    } else if (message.match(/^\/msg .+? .+/)) {
        // /msg - Private message
        let m = message.match(/^\/msg (.+?) (.+)/);
        let name = m[1];
        message = m[2];
        globals.conn.send('privateMessage', {
            'name': name,
            'message': message,
        });

        // We won't get a message back from the server if the sending of the PM was successful, so manually call the draw function now
        draw('PM-to', name, message);
    } else {
        globals.conn.send('roomMessage', {
            'room': room,
            'message':  message,
        });
    }
};

const draw = function(room, name, message, datetime = null) {
    // Check for the existence of a PM
    let privateMessage = false;
    if (room === 'PM-to') {
        privateMessage = 'to';
    } else if (room === 'PM-from') {
        privateMessage = 'from';
    }
    if (room === 'PM-to' || room === 'PM-from') {
        if (globals.currentScreen === 'lobby') {
            room = 'lobby';
        } else if (globals.currentScreen === 'race') {
            room = '_race_' + globals.currentRaceID;
        } else {
            setTimeout(function() {
                draw(room, name, message, datetime);
            }, globals.fadeTime + 5);
        }
    }

    // Don't show messages that are not for the current race
    if (room.startsWith('_race_')) {
        let raceID = parseInt(room.match(/_race_(\d+)/)[1]);
        if (raceID !== globals.currentRaceID) {
            return;
        }
    }

    // Keep track of how many lines of chat have been spoken in this room
    globals.roomList[room].chatLine++;

    // Sanitize the input
    message = misc.escapeHtml(message);

    // Check for links and insert them if present (using linkifyjs)
    message = linkifyHTML(message, {
        attributes: function(href, type) {
            return {
                onclick: 'nodeRequire(\'electron\').shell.openExternal(\'' + href + '\');',
            };
        },
        formatHref: function(href, type) {
            return '#';
        },
        target: '_self',
    });

    // Check for emotes and insert them if present
    message = fillEmotes(message);

    // Get the hours and minutes from the time
    let date;
    if (datetime === null) {
        date = new Date();
    } else {
        date = new Date(datetime);
    }
    let hours = date.getHours();
    if (hours < 10) {
        hours = '0' + hours;
    }
    let minutes = date.getMinutes();
    if (minutes < 10) {
        minutes = '0' + minutes;
    }

    // Construct the chat line
    let chatLine = '<div id="' + room + '-chat-text-line-' + globals.roomList[room].chatLine + '" class="hidden">';
    chatLine += '<span id="' + room + '-chat-text-line-' + globals.roomList[room].chatLine + '-header">';
    chatLine += '[' + hours + ':' + minutes + '] &nbsp; ';
    if (privateMessage !== false) {
        chatLine += '<span class="chat-pm">[PM ' + privateMessage + ' <strong class="chat-pm">' + name + '</strong>]</span> &nbsp; ';
    } else {
        chatLine += '&lt;<strong>' + name + '</strong>&gt; &nbsp; ';
    }
    chatLine += '</span>';
    chatLine += message;
    chatLine += '</div>';

    // Find out whether this is going to "#race-chat-text" or "#lobby-chat-text"
    let destination;
    if (room === 'lobby') {
        destination = 'lobby';
    } else if (room.startsWith('_race_')) {
        destination = 'race';
    } else {
        misc.errorShow('Failed to parse the room in the "chat.draw" function.');
    }

    // Find out if we should automatically scroll down after adding the new line of chat
    let autoScroll = false;
    let bottomPixel = $('#' + destination + '-chat-text').prop('scrollHeight') - $('#' + destination + '-chat-text').height();
    if ($('#' + destination + '-chat-text').scrollTop() === bottomPixel) {
        // If we are already scrolled to the bottom, then it is ok to automatically scroll
        autoScroll = true;
    }

    // Add the new line
    if (datetime === null) {
        $('#' + destination + '-chat-text').append(chatLine);
    } else {
        // We prepend instead of append because the chat history comes in order from most recent to least recent
        $('#' + destination + '-chat-text').prepend(chatLine);
    }
    $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine).fadeIn(globals.fadeTime);

    // Set indentation for long lines
    if (room === 'lobby') {
        // Indent the text to past where the username is (no longer used because it wastes too much space)
        /*let indentPixels = $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine + '-header').css('width');
        $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine).css('padding-left', indentPixels);
        $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine).css('text-indent', '-' + indentPixels);*/

        // Indent the text a little bit to signify that it is a continuation of the last line
        $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine).css('padding-left', chatIndentPixels);
        $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine).css('text-indent', '-' + chatIndentPixels);
    }

    // Automatically scroll
    if (autoScroll) {
        bottomPixel = $('#' + destination + '-chat-text').prop('scrollHeight') - $('#' + destination + '-chat-text').height();
        $('#' + destination + '-chat-text').scrollTop(bottomPixel);
    }
};
exports.draw = draw;

exports.indentAll = function(room) {
    if (typeof globals.roomList[room] === 'undefined') {
        return;
    }

    for (let i = 1; i <= globals.roomList[room].chatLine; i++) {
        // Indent the text to past where the username is (no longer used because it wastes too much space)

        let indentPixels = $('#' + room + '-chat-text-line-' + i + '-header').css('width');
        $('#' + room + '-chat-text-line-' + i).css('padding-left', indentPixels);
        $('#' + room + '-chat-text-line-' + i).css('text-indent', '-' + indentPixels);
        

        // If this line overflows, indent it a little to signify that it is a continuation of the last line
        /*$('#' + room + '-chat-text-line-' + i).css('padding-left', chatIndentPixels);
        $('#' + room + '-chat-text-line-' + i).css('text-indent', '-' + chatIndentPixels);*/
    }
};

function fillEmotes(message) {
    // Get a list of all of the emotes
    let emoteList = misc.getAllFilesFromFolder(__dirname + '/../img/emotes');

    // Chop off the .png from the end of each element of the array
    for (let i = 0; i < emoteList.length; i++) {
        emoteList[i] = emoteList[i].slice(0, -4); // ".png" is 4 characters long
    }

    // Search through the text for each emote
    for (let i = 0; i < emoteList.length; i++) {
        if (message.indexOf(emoteList[i]) !== -1) {
            let emoteTag = '<img class="chat-emote" src="assets/img/emotes/' + emoteList[i] + '.png" alt="' + emoteList[i] + '" />';
            let re = new RegExp('\\b' + emoteList[i] + '\\b', 'g'); // "\b" is a word boundary in regex
            message = message.replace(re, emoteTag);
        }
    }

    return message;
}
