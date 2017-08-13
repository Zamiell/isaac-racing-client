/*
    Chat functions
*/

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const isDev = nodeRequire('electron-is-dev');
const linkifyHTML = nodeRequire('linkifyjs/html');
const globals = nodeRequire('./assets/js/globals');
const misc = nodeRequire('./assets/js/misc');
const debug = nodeRequire('./assets/js/debug');

// Constants
const chatIndentSize = '3.2em';

exports.send = (destination) => {
    // Don't do anything if we are not on the screen corresponding to the chat input form
    if (destination === 'lobby' && globals.currentScreen !== 'lobby') {
        return;
    } else if (destination === 'race' && globals.currentScreen !== 'race') {
        return;
    }

    // Get values from the form
    let message = document.getElementById(`${destination}-chat-box-input`).value.trim();

    // Do nothing if the input field is empty
    if (message === '') {
        return;
    }

    // If this is a command
    let isCommand = false;
    let isPM = false;
    let PMrecipient;
    let PMmessage;
    if (message.startsWith('/')) {
        isCommand = true;

        // Find out if the user is sending a private message
        // /p, /pm, /msg, /m, /whisper, /w, /tell, /t
        if (
            message.match(/^\/p\b/) ||
            message.match(/^\/pm\b/) ||
            message.match(/^\/msg\b/) ||
            message.match(/^\/m\b/) ||
            message.match(/^\/whisper\b/) ||
            message.match(/^\/w\b/) ||
            message.match(/^\/tell\b/) ||
            message.match(/^\/t\b/)
        ) {
            isPM = true;

            // Validate that private messages have a recipient
            const m = message.match(/^\/\w+ (.+?) (.+)/);
            if (m) {
                PMrecipient = m[1];
                PMmessage = m[2];
            } else {
                // Open the error tooltip
                // TODO
                // <span lang="en">The format of a private message is</span>: <code>/pm Alice hello</code>
                return;
            }

            // Get the current list of connected users
            const userList = [];
            for (const user in globals.roomList.lobby.users) {
                if (globals.roomList.lobby.users.hasOwnProperty(user)) {
                    userList.push(user);
                }
            }

            // Validate that the receipient is online
            let isConnected = false;
            for (let i = 0; i < userList.length; i++) {
                if (PMrecipient.toLowerCase() === userList[i].toLowerCase()) {
                    isConnected = true;
                    PMrecipient = userList[i];
                }
            }
            if (isConnected === false) {
                misc.warningShow('That user is not currently online.');
                return;
            }
        }

        // Check if the user is replying to a message
        if (message.match(/^\/r\b/)) {
            isPM = true;

            // Validate that a PM has been received already
            if (globals.lastPM === null) {
                misc.warningShow('No PMs have been received yet.');
                return;
            }

            const m = message.match(/^\/r (.+)/);
            if (m) {
                PMrecipient = globals.lastPM;
                PMmessage = m[1];
            } else {
                misc.warningShow('The format of a reply is: <code>/r [message]</code>');
                return;
            }
        }
    }

    // Erase the contents of the input field
    $(`#${destination}-chat-box-input`).val('');

    // Truncate messages longer than 150 characters (this is also enforced server-side)
    if (message.length > 150) {
        message = message.substring(0, 150);
    }

    // Get the room
    let room;
    if (destination === 'lobby') {
        room = 'lobby';
    } else if (destination === 'race') {
        room = `_race_${globals.currentRaceID}`;
    }

    // Add it to the history so that we can use up arrow later
    globals.roomList[room].typedHistory.unshift(message);

    // Reset the history index
    globals.roomList[room].historyIndex = -1;

    if (isCommand === false) {
        // If this is a normal chat message
        globals.conn.send('roomMessage', {
            room,
            message,
        });
    } else if (isPM) {
        // If this is a PM (which has many aliases)
        globals.conn.send('privateMessage', {
            name: PMrecipient,
            message: PMmessage,
        });

        // We won't get a message back from the server if the sending of the PM was successful, so manually call the draw function now
        draw('PM-to', PMrecipient, PMmessage);
    } else if (message === '/debug') {
        // /debug - Debug command
        if (isDev) {
            globals.log.info('Sending debug command.');
            globals.conn.send('debug', {});

            globals.log.info('Entering debug function.');
            debug();
        }
    } else if (message === '/restart') {
        // /restart - Restart the client
        ipcRenderer.send('asynchronous-message', 'restart');
    } else if (message === '/finish') {
        // /finish - Debug finish
        if (isDev) {
            globals.conn.send('raceFinish', {
                id: globals.currentRaceID,
            });
        }
    } else if (message === '/ready') {
        if (isDev) {
            globals.conn.send('raceReady', {
                id: globals.currentRaceID,
            });
        }
    } else if (message === '/shutdown') {
        if (isDev) {
            globals.conn.send('adminShutdown', {});
        }
    } else if (message === '/unshutdown') {
        if (isDev) {
            globals.conn.send('adminUnshutdown', {});
        }
    }
};

const draw = (room, name, message, datetime = null, discord = false) => {
    // Check for the existence of a PM
    let privateMessage = false;
    if (room === 'PM-to') {
        privateMessage = 'to';
    } else if (room === 'PM-from') {
        privateMessage = 'from';
        globals.lastPM = name;
    }
    if (room === 'PM-to' || room === 'PM-from') {
        if (globals.currentScreen === 'lobby') {
            room = 'lobby';
        } else if (globals.currentScreen === 'race') {
            room = `_race_${globals.currentRaceID}`;
        } else {
            setTimeout(() => {
                draw(room, name, message, datetime);
            }, globals.fadeTime + 5);
        }
    }

    // Don't show messages that are not for the current race
    if (room.startsWith('_race_')) {
        const raceID = parseInt(room.match(/_race_(\d+)/)[1], 10);
        if (raceID !== globals.currentRaceID) {
            return;
        }
    }

    // Make sure that the room still exists in the roomList
    if (globals.roomList.hasOwnProperty(room) === false) {
        return;
    }

    // Keep track of how many lines of chat have been spoken in this room
    globals.roomList[room].chatLine += 1;

    // Sanitize the input
    message = misc.escapeHtml(message);

    // Check for links and insert them if present (using linkifyjs)
    message = linkifyHTML(message, {
        attributes: function(href, type) {
            return {
                onclick: 'nodeRequire(\'electron\').shell.openExternal(\'' + href + '\');',
            };
        },
        formatHref: (href, type) => '#',
        target: '_self',
    });

    // Check for emotes and insert them if present
    message = fillEmotes(message);

    // Get the hours and minutes from the time
    let date;
    if (datetime === null) {
        date = new Date();
    } else {
        date = new Date(datetime * 1000);
    }
    let hours = date.getHours();
    if (hours < 10) {
        hours = `0${hours}`;
    }
    let minutes = date.getMinutes();
    if (minutes < 10) {
        minutes = `0${minutes}`;
    }

    // Construct the chat line
    let chatLine = `<div id="${room}-chat-text-line-${globals.roomList[room].chatLine}" class="hidden">`;
    chatLine += `<span id="${room}-chat-text-line-${globals.roomList[room].chatLine}-header">`;
    chatLine += `[${hours}:${minutes}] &nbsp; `;
    if (discord) {
        chatLine += '<span class="chat-discord">[Discord]</span> ';
    }
    if (privateMessage) {
        chatLine += '<span class="chat-pm">[PM ' + privateMessage + ' <strong class="chat-pm">' + name + '</strong>]</span> &nbsp; ';
    } else if (name === '!server') {
        // Do nothing
    } else {
        chatLine += '&lt;<strong>' + name + '</strong>&gt; &nbsp; ';
    }
    chatLine += '</span>';
    if (name === '!server') {
        chatLine += '<span class="chat-server">' + message + '</span>';
    } else {
        chatLine += message;
    }
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
        // Indent the text to past where the username is
        // (no longer used because it wastes too much space)
        /*
        let indentPixels = $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine + '-header').css('width');
        $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine).css('padding-left', indentPixels);
        $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine).css('text-indent', '-' + indentPixels);
        */

        // Indent the text to the "<Username>" to signify that it is a continuation of the last line
        $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine).css('padding-left', chatIndentSize);
        $('#' + room + '-chat-text-line-' + globals.roomList[room].chatLine).css('text-indent', '-' + chatIndentSize);
    }

    // Automatically scroll
    if (autoScroll) {
        bottomPixel = $('#' + destination + '-chat-text').prop('scrollHeight') - $('#' + destination + '-chat-text').height();
        $('#' + destination + '-chat-text').scrollTop(bottomPixel);
    }
};
exports.draw = draw;

exports.indentAll = (room) => {
    if (typeof globals.roomList[room] === 'undefined') {
        return;
    }

    for (let i = 1; i <= globals.roomList[room].chatLine; i++) {
        // Indent the text to past where the username is
        // (no longer used because it wastes too much space)
        /*
        let indentPixels = $('#' + room + '-chat-text-line-' + i + '-header').css('width');
        $('#' + room + '-chat-text-line-' + i).css('padding-left', indentPixels);
        $('#' + room + '-chat-text-line-' + i).css('text-indent', '-' + indentPixels);
        */

        // If this line overflows, indent it to the "<Username>" to signify that it is a continuation of the last line
        $('#' + room + '-chat-text-line-' + i).css('padding-left', chatIndentSize);
        $('#' + room + '-chat-text-line-' + i).css('text-indent', '-' + chatIndentSize);
    }
};

function fillEmotes(message) {
    // Search through the text for each emote
    for (let i = 0; i < globals.emoteList.length; i++) {
        if (message.indexOf(globals.emoteList[i]) !== -1) {
            const emoteTag = '<img class="chat-emote" src="assets/img/emotes/' + globals.emoteList[i] + '.png" title="' + globals.emoteList[i] + '" />';
            const re = new RegExp('\\b' + globals.emoteList[i] + '\\b', 'g'); // "\b" is a word boundary in regex
            message = message.replace(re, emoteTag);
        }
    }

    // Special emotes that don't match the filenames
    if (message.indexOf('&lt;3') !== -1) {
        const emoteTag = '<img class="chat-emote" src="assets/img/emotes2/3.png" title="&lt;3" />';
        const re = new RegExp('&lt;3', 'g'); // "\b" is a word boundary in regex
        message = message.replace(re, emoteTag);
    }
    if (message.indexOf(':thinking:') !== -1) {
        const emoteTag = '<img class="chat-emote" src="assets/img/emotes2/thinking.svg" title=":thinking:" />';
        const re = new RegExp(':thinking:', 'g'); // "\b" is a word boundary in regex
        message = message.replace(re, emoteTag);
    }

    return message;
}
