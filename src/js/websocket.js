/*
    Websocket handling
*/

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const isDev = nodeRequire('electron-is-dev');
const golem = nodeRequire('./js/lib/golem');
const globals = nodeRequire('./js/globals');
const chat = nodeRequire('./js/chat');
const misc = nodeRequire('./js/misc');
const modLoader = nodeRequire('./js/mod-loader');
const registerScreen = nodeRequire('./js/ui/register');
const lobbyScreen = nodeRequire('./js/ui/lobby');
const raceScreen = nodeRequire('./js/ui/race');
const discordEmotes = nodeRequire('./data/discord-emotes');

exports.init = (username, password, remember) => {
    // We have successfully authenticated with the server, so we no longer need the Greenworks process open
    ipcRenderer.send('asynchronous-message', 'steamExit');

    // Establish a WebSocket connection
    globals.conn = new golem.Connection(globals.websocketURL, isDev); // It will automatically use the cookie that we recieved earlier
    // If the second argument is true, debugging is turned on
    globals.log.info('Establishing WebSocket connection to:', globals.websocketURL);

    /*
        Extended connection functions
    */

    globals.conn.send = (command, data) => {
        globals.conn.emit(command, data);

        // Don't log some commands to reduce spam
        if (
            command === 'raceFloor' ||
            command === 'raceRoom' ||
            command === 'raceItem'
        ) {
            return;
        }
        globals.log.info(`WebSocket sent: ${command} ${JSON.stringify(data)}`);
    };

    /*
        Miscellaneous WebSocket handlers
    */

    globals.conn.on('open', (event) => {
        globals.log.info('WebSocket connection established.');

        // Login success; join the lobby chat channel
        globals.conn.send('roomJoin', {
            room: 'lobby',
        });

        // Do the proper transition to the lobby depending on where we logged in from
        if (globals.currentScreen === 'title-ajax') {
            globals.currentScreen = 'transition';
            $('#title').fadeOut(globals.fadeTime, () => {
                lobbyScreen.show();
            });
        } else if (globals.currentScreen === 'register-ajax') {
            globals.currentScreen = 'transition';
            $('#register').fadeOut(globals.fadeTime, () => {
                registerScreen.reset();
                lobbyScreen.show();
            });
        } else if (globals.currentScreen === 'error') {
            // If we are showing an error screen already, then don't bother going to the lobby
        } else {
            misc.errorShow(`Can't transition to the lobby from screen: ${globals.currentScreen}`);
        }
    });

    globals.conn.on('close', connClose);
    function connClose(event) {
        globals.log.info('WebSocket connection closed.');

        if (globals.currentScreen === 'error') {
            // The client is programmed to close the connection when an error occurs, so if we are already on the error screen, then we don't have to do anything else
        } else {
            // The WebSocket connection dropped because of a bad network connection or similar issue, so show the error screen
            misc.errorShow('Disconnected from the server. Either your Internet is having problems or the server went down!', false);
        }
    }

    globals.conn.on('socketError', (event) => {
        globals.log.info('WebSocket error:', event);
        if (globals.currentScreen === 'title-ajax') {
            const error = 'Failed to connect to the WebSocket server. The server might be down!';
            misc.errorShow(error, false);
        } else if (globals.currentScreen === 'register-ajax') {
            const error = 'Failed to connect to the WebSocket server. The server might be down!';
            const jqXHR = { // Emulate a jQuery error because that is what the "registerFail" function expects
                responseText: error,
            };
            registerScreen.fail(jqXHR);
        } else {
            const error = 'Encountered a WebSocket error. The server might be down!';
            misc.errorShow(error, false);
        }
    });

    /*
        Miscellaneous command handlers
    */

    // Sent if the server rejects a command; we should completely reload the client since something may be out of sync
    globals.conn.on('error', (data) => {
        misc.errorShow(data.message);
    });

    // Sent if the server rejects a command, but in a normal way that does not indicate that anything is out of sync
    globals.conn.on('warning', (data) => {
        if (data.message === 'Someone else has already claimed that stream URL. If you are the real owner of this stream, please contact an administrator.') {
            globals.stream.URL = globals.stream.URLBeforeSubmit;
        }
        misc.warningShow(data.message);
    });

    // Sent after a successful connection
    globals.conn.on('settings', (data) => {
        // Log the event
        globals.log.info(`Websocket - settings - ${JSON.stringify(data)}`);

        // Time
        const now = new Date().getTime();
        globals.timeOffset = data.time - now;

        // Username
        globals.myUsername = data.username;
        globals.Raven.setContext({
            user: { // All errors reported from now on will contain this user's username
                username: data.username,
            },
        });

        // Stream URL
        if (data.streamURL === '-') {
            data.streamURL = '';
        }
        globals.stream.URL = data.streamURL;

        // TwitchBotEnabled
        globals.stream.TwitchBotEnabled = data.twitchBotEnabled;

        // TwitchBotDelay
        globals.stream.TwitchBotDelay = data.twitchBotDelay;
    });

    // Used in the message of the day and other server broadcasts
    globals.conn.on('adminMessage', adminMessage);
    function adminMessage(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                adminMessage(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Send it to the lobby
        chat.draw('lobby', '!server', data.message);

        if (globals.currentRaceID !== false) {
            chat.draw(`_race_${globals.currentRaceID}`, '!server', data.message);
        }
    }

    /*
        Chat command handlers
    */

    globals.conn.on('roomList', (data) => {
        // Log the event
        // globals.log.info(`Websocket - roomJoined - ${JSON.stringify(data)}`);

        // We entered a new room, so keep track of all users in this room
        globals.roomList[data.room] = {
            users: {},
            numUsers: 0,
            chatLine: 0,
            typedHistory: [],
            historyIndex: -1,
        };
        for (let i = 0; i < data.users.length; i++) {
            globals.roomList[data.room].users[data.users[i].name] = data.users[i];
        }
        globals.roomList[data.room].numUsers = data.users.length;

        if (data.room === 'lobby') {
            // Redraw the users list in the lobby
            lobbyScreen.usersDraw();
        } else if (data.room.startsWith('_race_')) {
            const raceID = parseInt(data.room.match(/_race_(\d+)/)[1], 10);
            if (raceID === globals.currentRaceID) {
                // Update the online/offline markers
                for (let i = 0; i < data.users.length; i++) {
                    raceScreen.markOnline(data.users[i]);
                }
            }
        }
    });

    globals.conn.on('roomHistory', (data) => {
        // Figure out what kind of chat room this is
        let destination;
        if (data.room === 'lobby') {
            destination = 'lobby';
        } else {
            destination = 'race';
        }

        // Empty the existing chat room, since there might still be some chat in there from a previous race or session
        $(`#${destination}-chat-text`).html('');

        // Add all of the chat
        for (let i = 0; i < data.history.length; i++) {
            chat.draw(data.room, data.history[i].name, data.history[i].message, data.history[i].datetime);
        }
    });

    globals.conn.on('roomJoined', (data) => {
        // Log the event
        globals.log.info(`Websocket - roomJoined - ${JSON.stringify(data)}`);

        // Keep track of the person who just joined
        globals.roomList[data.room].users[data.user.name] = data.user;
        globals.roomList[data.room].numUsers += 1;

        // Redraw the users list in the lobby
        if (data.room === 'lobby') {
            lobbyScreen.usersDraw();
        }

        // Send a chat notification
        if (data.room === 'lobby') {
            if (data.user.name.startsWith('TestAccount')) {
                return; // Don't send notifications for test accounts connecting
            }

            const message = `${data.user.name} has connected.`;
            chat.draw(data.room, '!server', message);
            if (globals.currentRaceID !== false) {
                chat.draw(`_race_${globals.currentRaceID}`, '!server', message);
            }
        } else {
            chat.draw(data.room, '!server', `${data.user.name} has joined the race.`);
        }
    });

    globals.conn.on('roomLeft', (data) => {
        // Log the event
        globals.log.info(`Websocket - roomLeft - ${JSON.stringify(data)}`);

        // Remove them from the room list
        delete globals.roomList[data.room].users[data.name];
        globals.roomList[data.room].numUsers -= 1;

        // Redraw the users list in the lobby
        if (data.room === 'lobby') {
            lobbyScreen.usersDraw();
        }

        // Send a chat notification
        if (data.room === 'lobby') {
            if (data.name.startsWith('TestAccount')) {
                return; // Don't send notifications for test accounts disconnecting
            }

            const message = `${data.name} has disconnected.`;
            chat.draw(data.room, '!server', message);
            if (globals.currentRaceID !== false) {
                chat.draw(`_race_${globals.currentRaceID}`, '!server', message);
            }
        } else {
            chat.draw(data.room, '!server', `${data.name} has left the race.`);
        }
    });

    globals.conn.on('roomUpdate', (data) => {
        // Log the event
        globals.log.info(`Websocket - roomLeft - ${JSON.stringify(data)}`);

        // Keep track of the person who just joined
        globals.roomList[data.room].users[data.user.name] = data.user;

        // Redraw the users list in the lobby
        if (data.room === 'lobby') {
            lobbyScreen.usersDraw();
        }
    });

    globals.conn.on('roomMessage', (data) => {
        chat.draw(data.room, data.name, data.message);
    });

    globals.conn.on('privateMessage', (data) => {
        chat.draw('PM-from', data.name, data.message);
    });

    // Used when someone types in the Discord server
    globals.conn.on('discordMessage', discordMessage);
    function discordMessage(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                adminMessage(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Convert discord style emotes to Racing+ style emotes
        const messageArray = data.message.split(' ');
        for (let i = 0; i < messageArray.length; i++) {
            if (messageArray[i] in discordEmotes) {
                messageArray[i] = discordEmotes[messageArray[i]];
            }
        }
        const newMessage = messageArray.join(' ');

        // Send it to the lobby
        chat.draw('lobby', data.name, newMessage, null, true);
    }

    /*
        Race command handlers
    */

    // On initial connection, we get a list of all of the races that are currently open or ongoing
    globals.conn.on('raceList', (data) => {
        // Log the event
        globals.log.info(`Websocket - raceList - ${JSON.stringify(data)}`);

        // Check for empty races
        if (data.length === 0) {
            $('#lobby-current-races-table-body').html('');
            $('#lobby-current-races-table').fadeOut(0);
            $('#lobby-current-races-table-no').fadeIn(0);
        }

        // Go through the list of races that were sent
        let mostCurrentRaceID = false;
        for (let i = 0; i < data.length; i++) {
            // Keep track of what races are currently going
            globals.raceList[data[i].id] = data[i];
            globals.raceList[data[i].id].racerList = {};

            // Update the "Current races" area
            lobbyScreen.raceDraw(data[i]);

            // Check to see if we are in any races
            for (let j = 0; j < data[i].racers.length; j++) {
                if (data[i].racers[j] === globals.myUsername) {
                    mostCurrentRaceID = data[i].id;
                    break;
                }
            }
        }
        if (mostCurrentRaceID !== false) {
            // This is normally set at the top of the raceScreen.show function, but we need to set it now since we have to delay
            globals.currentRaceID = mostCurrentRaceID;
            setTimeout(() => {
                raceScreen.show(mostCurrentRaceID);
            }, globals.fadeTime * 2 + 5); // Account for fade out and fade in, then add 5 milliseconds of leeway
        }
    });

    // Sent when we create a race or reconnect in the middle of a race
    globals.conn.on('racerList', (data) => {
        // Log the event
        globals.log.info(`Websocket - racerList - ${JSON.stringify(data)}`);

        // Store the racer list
        const race = globals.raceList[data.id];
        race.racerList = data.racers;

        // Build the table with the race participants on the race screen
        $('#race-participants-table-body').html('');
        for (let i = 0; i < race.racerList.length; i++) {
            raceScreen.participantAdd(i);
        }

        // Update the mod with "myStatus", "placeMid" and "place"
        modLoader.sendPlace();
    });

    globals.conn.on('raceCreated', connRaceCreated);
    function connRaceCreated(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                connRaceCreated(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Log the event
        globals.log.info(`Websocket - raceCreated - ${JSON.stringify(data)}`);

        // Keep track of what races are currently going
        globals.raceList[data.id] = data;

        // Update the "Current races" area
        lobbyScreen.raceDraw(data);

        // Send a chat notification if we did not create this race and this is not a solo race
        if (data.captain !== globals.myUsername && !data.ruleset.solo) {
            const message = `${data.captain} has started a new race.`;
            chat.draw('lobby', '!server', message);
            if (globals.currentRaceID !== false) {
                chat.draw(`_race_${globals.currentRaceID}`, '!server', message);
            }
        }

        // Play the "race created" sound effect if applicable
        let playSound = false;
        if (globals.currentScreen === 'lobby') {
            playSound = true;
        } else if (
            globals.currentScreen === 'race' &&
            !Object.prototype.hasOwnProperty.call(globals.raceList, globals.currentRaceID)
        ) {
            playSound = true;
        }
        if (playSound && !data.ruleset.solo) { // Don't play sounds for solo races
            misc.playSound('race-created');
        }
    }

    globals.conn.on('raceJoined', connRaceJoined);
    function connRaceJoined(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                connRaceJoined(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Due to lag, the race might have been deleted already, so check for that
        if (!Object.prototype.hasOwnProperty.call(globals.raceList, data.id)) {
            return;
        }

        // Log the event
        globals.log.info(`Websocket - raceJoined - ${JSON.stringify(data)}`);

        // Keep track of the people in each race
        globals.raceList[data.id].racers.push(data.name);

        // Update the row for this race in the lobby
        lobbyScreen.raceUpdatePlayers(data.id);

        if (data.name === globals.myUsername) {
            // If we joined this race
            raceScreen.show(data.id);
        } else if (data.id === globals.currentRaceID) {
            // We are in this race, so add this racer to the racerList with all default values (defaults)
            const datetime = new Date().getTime();
            globals.raceList[data.id].racerList.push({
                name: data.name,
                status: 'not ready',
                datetimeJoined: datetime,
                floorNum: 0,
                place: 0,
                placeMid: 1,
                items: [],
            });

            // Update the race screen
            raceScreen.participantAdd(globals.raceList[data.id].racerList.length - 1);

            // Update the mod
            globals.modLoader.numEntrants = globals.raceList[data.id].racerList.length;
            modLoader.send();
            // globals.log.info(`modLoader - Sent a numEntrants of "${globals.modLoader.numEntrants}".`);
        }
    }

    globals.conn.on('raceLeft', connRaceLeft);
    function connRaceLeft(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                connRaceLeft(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Log the event
        globals.log.info(`Websocket - raceLeft - ${JSON.stringify(data)}`);

        // Find out if we are in this race
        let inThisRace = false;
        if (globals.raceList[data.id].racers.indexOf(globals.myUsername) !== -1) {
            inThisRace = true;
        }

        // Delete this person from the "racers" array
        if (globals.raceList[data.id].racers.indexOf(data.name) !== -1) {
            globals.raceList[data.id].racers.splice(globals.raceList[data.id].racers.indexOf(data.name), 1);
        } else {
            misc.errorShow(`"${data.name}" left race #${data.id}, but they were not in the "racers" array.`);
            return;
        }

        // If we are in this race, we also need to delete this person them from the "racerList" array
        if (inThisRace) {
            let foundRacer = false;
            for (let i = 0; i < globals.raceList[data.id].racerList.length; i++) {
                if (data.name === globals.raceList[globals.currentRaceID].racerList[i].name) {
                    foundRacer = true;
                    globals.raceList[data.id].racerList.splice(i, 1);
                    break;
                }
            }
            if (!foundRacer) {
                misc.errorShow(`"${data.name}" left race #${data.id}, but they were not in the "racerList" array.`);
                return;
            }
        }

        // Update the "Current races" area on the lobby
        if (globals.raceList[data.id].racers.length === 0) {
            // Delete the race since the last person in the race left
            delete globals.raceList[data.id];
            lobbyScreen.raceUndraw(data.id);
        } else {
            // Check to see if this person was the captain, and if so, make the next person in line the captain
            if (globals.raceList[data.id].captain === data.name) {
                globals.raceList[data.id].captain = globals.raceList[data.id].racers[0];
            }

            // Update the row for this race in the lobby
            lobbyScreen.raceUpdatePlayers(data.id);
        }

        // If we left the race
        if (data.name === globals.myUsername) {
            // Show the lobby
            lobbyScreen.showFromRace();
            return;
        }

        // If this is the current race
        if (data.id === globals.currentRaceID) {
            // Remove the row for this player
            $(`#race-participants-table-${data.name}`).remove();

            // Fix the bug where the "vertical-center" class causes things to be hidden if there is overflow
            if (globals.raceList[globals.currentRaceID].racerList.length > 6) { // More than 6 races causes the overflow
                $('#race-participants-table-wrapper').removeClass('vertical-center');
            } else {
                $('#race-participants-table-wrapper').addClass('vertical-center');
            }

            if (globals.raceList[globals.currentRaceID].status === 'open') {
                // Update the captian
                // [not implemented]
            }

            // Update the mod
            globals.modLoader.numEntrants = globals.raceList[data.id].racerList.length;
            modLoader.send();
            // globals.log.info(`modLoader - Sent a race numEntrants of "${globals.modLoader.numEntrants}".`);
        }
    }

    globals.conn.on('raceSetStatus', connRaceSetStatus);
    function connRaceSetStatus(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                connRaceSetStatus(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Log the event
        globals.log.info(`Websocket - raceSetStatus - ${JSON.stringify(data)}`);

        // Update the status
        globals.raceList[data.id].status = data.status;

        // Check to see if we are in this race
        if (data.id === globals.currentRaceID) {
            // Update the status of the race in the Lua mod
            // (we will update the status to "in progress" manually when the countdown reaches 0)
            // (and we don't care if the race finishes because we will set the "save#.dat" file to defaults once we personally finish or quit the race)
            if (data.status !== 'in progress' && data.status !== 'finished') {
                globals.modLoader.status = data.status;
                modLoader.send();
                // globals.log.info(`modLoader - Sent a race status of "${data.status}".`);
            }

            // Do different things depending on the status
            if (data.status === 'starting') {
                // Update the status column in the race title
                $('#race-title-status').html('<span class="circle lobby-current-races-starting"></span> &nbsp; <span lang="en">Starting</span>');

                // Start the countdown
                raceScreen.startCountdown();
            } else if (data.status === 'in progress') {
                // Do nothing; after the countdown is finished, the race controls will automatically fade in
            } else if (data.status === 'finished') {
                // Update the status column in the race title
                $('#race-title-status').html('<span class="circle lobby-current-races-finished"></span> &nbsp; <span lang="en">Finished</span>');

                // Remove the race controls
                $('#race-quit-button-container').fadeOut(globals.fadeTime);
                $('#race-controls-padding').fadeOut(globals.fadeTime);
                $('#race-num-left-container').fadeOut(globals.fadeTime, () => {
                    $('#race-countdown').css('font-size', '1.75em');
                    $('#race-countdown').css('bottom', '0.25em');
                    $('#race-countdown').css('color', '#e89980');
                    $('#race-countdown').html('<span lang="en">Race completed</span>!');
                    $('#race-countdown').fadeIn(globals.fadeTime);
                });

                // Play the "race completed!" sound effect (for multiplayer races)
                if (!globals.raceList[globals.currentRaceID].ruleset.solo) {
                    misc.playSound('race-completed', 1300);
                }
            } else {
                misc.errorShow(`Failed to parse the status of race #${data.id}: ${globals.raceList[data.id].status}`);
            }
        }

        // Update the "Status" column in the lobby
        let circleClass;
        if (data.status === 'open') {
            circleClass = 'open';
        } else if (data.status === 'starting') {
            circleClass = 'starting';
            $(`#lobby-current-races-${data.id}`).removeClass('lobby-race-row-open');
            $(`#lobby-current-races-${data.id}`).unbind();
        } else if (data.status === 'in progress') {
            circleClass = 'in-progress';
        } else if (data.status === 'finished') {
            // Delete the race
            delete globals.raceList[data.id];
            lobbyScreen.raceUndraw(data.id);
        } else {
            misc.errorShow('Unable to parse the race status from the raceSetStatus command.');
        }
        $(`#lobby-current-races-${data.id}-status-circle`).removeClass();
        $(`#lobby-current-races-${data.id}-status-circle`).addClass(`circle lobby-current-races-${circleClass}`);
        $(`#lobby-current-races-${data.id}-status`).html(`<span lang="en">${data.status.capitalize()}</span>`);

        // Remove the race if it is finished
        if (data.status === 'finished') {
            delete globals.raceList[data.id];
        }
    }

    globals.conn.on('racerSetStatus', connRacerSetStatus);
    function connRacerSetStatus(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                connRacerSetStatus(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Log the event
        globals.log.info(`Websocket - racerSetStatus - ${JSON.stringify(data)}`);

        // We don't care about racer updates for a race that is not showing on the current screen
        if (data.id !== globals.currentRaceID) {
            return;
        }

        // Find the player in the racerList
        for (let i = 0; i < globals.raceList[data.id].racerList.length; i++) {
            if (data.name === globals.raceList[data.id].racerList[i].name) {
                // Update their status and place locally
                globals.raceList[data.id].racerList[i].status = data.status;
                globals.raceList[data.id].racerList[i].place = data.place;

                // Update the race screen
                if (globals.currentScreen === 'race') {
                    raceScreen.participantsSetStatus(i);
                }

                break;
            }
        }

        // Update the mod with "myStatus", "placeMid" and "place"
        modLoader.sendPlace();
    }

    globals.conn.on('raceSetRuleset', (data) => {
        // Not implemented
    });

    globals.conn.on('raceStart', connRaceStart);
    function connRaceStart(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                connRacerSetStatus(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Log the event
        globals.log.info(`Websocket - raceStart - ${JSON.stringify(data)}`);

        // Check to see if this message actually applies to the race that is showing on the screen
        if (data.id !== globals.currentRaceID) {
            misc.errorShow('Got a "raceStart" command for a race that is not the current race.');
        }

        // Keep track of when the race starts
        globals.raceList[globals.currentRaceID].datetimeStarted = data.time;

        // Schedule the countdown, which will start roughly 5 seconds from now
        // (or 3 seconds from now in a solo race)
        const now = new Date().getTime();
        let timeToStartCountdown = data.time - now - globals.timeOffset - globals.fadeTime;
        if (globals.raceList[globals.currentRaceID].ruleset.solo) {
            timeToStartCountdown -= 3000;
            setTimeout(() => {
                raceScreen.countdownTick(3);
            }, timeToStartCountdown);
        } else {
            timeToStartCountdown -= 5000;
            setTimeout(() => {
                raceScreen.countdownTick(5);
            }, timeToStartCountdown);
        }
    }

    globals.conn.on('racerSetFloor', connRacerSetFloor);
    function connRacerSetFloor(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                connRacerSetFloor(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        if (data.id !== globals.currentRaceID) {
            return;
        }

        // Find the player in the racerList
        for (let i = 0; i < globals.raceList[data.id].racerList.length; i++) {
            if (data.name === globals.raceList[data.id].racerList[i].name) {
                // Update their place and floor locally
                globals.raceList[data.id].racerList[i].floorNum = data.floorNum;
                globals.raceList[data.id].racerList[i].stageType = data.stageType;
                globals.raceList[data.id].racerList[i].datetimeArrivedFloor = data.datetimeArrivedFloor;

                // Update the race screen
                if (globals.currentScreen === 'race') {
                    raceScreen.participantsSetFloor(i);
                }

                break;
            }
        }

        // Update the mod with "myStatus", "placeMid" and "place"
        modLoader.sendPlace();
    }

    globals.conn.on('racerAddItem', connRacerAddItem);
    function connRacerAddItem(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(() => {
                connRacerAddItem(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        if (data.id !== globals.currentRaceID) {
            return;
        }

        // Find the player in the racerList
        for (let i = 0; i < globals.raceList[data.id].racerList.length; i++) {
            if (data.name === globals.raceList[data.id].racerList[i].name) {
                globals.raceList[data.id].racerList[i].items.push(data.item);

                // Update the race screen
                if (globals.currentScreen === 'race') {
                    raceScreen.participantsSetItem(i);
                }

                break;
            }
        }
    }

    globals.conn.on('achievement', connAchievement);
    function connAchievement(data) {
        // Log the event
        globals.log.info(`Websocket - achievement - ${JSON.stringify(data)}`);
    }
};
