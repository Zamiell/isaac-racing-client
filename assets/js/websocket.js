/*
    Websocket handling
*/

'use strict';

// Imports
const isDev          = nodeRequire('electron-is-dev');
const golem          = nodeRequire('./assets/js/lib/golem');
const globals        = nodeRequire('./assets/js/globals');
const settings       = nodeRequire('./assets/js/settings');
const chat           = nodeRequire('./assets/js/chat');
const misc           = nodeRequire('./assets/js/misc');
const registerScreen = nodeRequire('./assets/js/ui/register');
const lobbyScreen    = nodeRequire('./assets/js/ui/lobby');
const raceScreen     = nodeRequire('./assets/js/ui/race');

exports.init = function(username, password, remember) {
    // Establish a WebSocket connection
    let url = 'ws' + (globals.secure ? 's' : '') + '://' + globals.domain + '/ws';
    globals.conn = new golem.Connection(url, isDev); // It will automatically use the cookie that we recieved earlier
                                                     // If the second argument is true, debugging is turned on
    globals.log.info('Establishing WebSocket connection to:', url);

    /*
        Extended connection functions
    */

    globals.conn.send = function(command, data) {
        globals.conn.emit(command, data);

        // Don't log some commands to reduce spam
        if (command === 'raceFloor' ||
            command === 'raceRoom' ||
            command === 'raceItem') {

            return;
        }
        globals.log.info('WebSocket sent: ' + command + ' ' + JSON.stringify(data));
    };

    /*
        Miscellaneous WebSocket handlers
    */

    globals.conn.on('open', function(event) {
        globals.log.info('WebSocket connection established.');

        // Login success; join the lobby chat channel
        globals.conn.send('roomJoin', {
            'room': 'lobby',
        });

        // Do the proper transition to the lobby depending on where we logged in from
        if (globals.currentScreen === 'title-ajax') {
            globals.currentScreen = 'transition';
            $('#title').fadeOut(globals.fadeTime, function() {
                lobbyScreen.show();
            });
        } else if (globals.currentScreen === 'register-ajax') {
            globals.currentScreen = 'transition';
            $('#register').fadeOut(globals.fadeTime, function() {
                registerScreen.reset();
                lobbyScreen.show();
            });
        } else {
            misc.errorShow('Can\'t transition to the lobby from screen: ' + globals.currentScreen);
        }
    });

    globals.conn.on('close', connClose);
    function connClose(event) {
        globals.log.info('WebSocket connection closed.');

        if (globals.currentScreen === 'error') {
            // The client is programmed to close the connection when an error occurs, so if we are already on the error screen, then we don't have to do anything else
            return;
        } else {
            // The WebSocket connection dropped because of a bad network connection or similar issue, so show the error screen
            misc.errorShow('Disconnected from the server. Either your Internet is having problems or the server went down!', false);
            return;
        }
    }

    globals.conn.on('socketError', function(event) {
        globals.log.info("WebSocket error:", event);
        if (globals.currentScreen === 'title-ajax') {
            let error = 'Failed to connect to the WebSocket server. The server might be down!';
            misc.errorShow(error, false);
        } else if (globals.currentScreen === 'register-ajax') {
            let error = 'Failed to connect to the WebSocket server. The server might be down!';
            let jqXHR = { // Emulate a jQuery error because that is what the "registerFail" function expects
                responseText: error,
            };
            registerScreen.fail(jqXHR);
        } else {
            let error = 'Encountered a WebSocket error. The server might be down!';
            misc.errorShow(error, false);
        }
    });

    /*
        Miscellaneous command handlers
    */

    // Sent after a successful connection
    globals.conn.on('settings', function(data) {
        // Time (do this first since it is time sensitive)
        let now = new Date().getTime();
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
        globals.myStreamURL = data.streamURL;

        // TwitchBotEnabled
        globals.myTwitchBotEnabled = data.twitchBotEnabled;

        // TwitchBotDelay
        globals.myTwitchBotDelay = data.twitchBotDelay;
    });

    // Sent if the server rejects a command; we should completely reload the client since something may be out of sync
    globals.conn.on('error', function(data) {
        misc.errorShow(data.message);
    });

    /*
        Chat command handlers
    */

    globals.conn.on('roomList', function(data) {
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
            let raceID = parseInt(data.room.match(/_race_(\d+)/)[1]);
            if (raceID === globals.currentRaceID) {
                // Update the online/offline markers
                for (let i = 0; i < data.users.length; i++) {
                    raceScreen.markOnline(data.users[i]);
                }
            }
        }
    });

    globals.conn.on('roomHistory', function(data) {
        // Figure out what kind of chat room this is
        let destination;
        if (data.room === 'lobby') {
            destination = 'lobby';
        } else {
            destination = 'race';
        }

        // Empty the existing chat room, since there might still be some chat in there from a previous race or session
        $('#' + destination + '-chat-text').html('');

        // Add all of the chat
        for (let i = 0; i < data.history.length; i++) {
            chat.draw(data.room, data.history[i].name, data.history[i].message, data.history[i].datetime);
        }
    });

    globals.conn.on('roomJoined', function(data) {
        // Keep track of the person who just joined
        globals.roomList[data.room].users[data.user.name] = data.user;
        globals.roomList[data.room].numUsers++;
        globals.log.info('User "' + data.name + '" joined room:', data.room);

        // Redraw the users list in the lobby
        if (data.room === 'lobby') {
            lobbyScreen.usersDraw();
        }

        // Send a chat notification for races
        chat.draw(data.room, '!server', data.user.name + ' has joined.');
    });

    globals.conn.on('roomLeft', function(data) {
        // Remove them from the room list
        delete globals.roomList[data.room].users[data.name];
        globals.roomList[data.room].numUsers--;

        // Redraw the users list in the lobby
        if (data.room === 'lobby') {
            lobbyScreen.usersDraw();
        }

        // Send a chat notification
        chat.draw(data.room, '!server', data.name + ' has left.');
    });

    globals.conn.on('roomMessage', function(data) {
        chat.draw(data.room, data.name, data.message);
    });

    globals.conn.on('profileSetName', function(data) {
        // Look through all the rooms for this user
        for (let room in globals.roomList) {
            if (!globals.roomList.hasOwnProperty(room)) {
                continue;
            }

            for (let user in globals.roomList[room].users) {
                if (!globals.roomList[room].users.hasOwnProperty(user)) {
                    continue;
                }

                if (user === data.name) {
                    // Delete them and recreate
                    let tempObject = globals.roomList[room].users[data.name];
                    delete globals.roomList[room].users[data.name];
                    globals.roomList[room].users[data.newName] = tempObject;
                    break;
                }
            }
        }

        // Redraw the users list in the lobby
        lobbyScreen.usersDraw();

        // Look through all the races for this user
        for (let raceID in globals.raceList) {
            if (!globals.raceList.hasOwnProperty(raceID)) {
                continue;
            }

            // If the player exists in the "racers" list, rename them
            // (this is used for showing the players in the race from the lobby)
            for (let i = 0; i < globals.raceList[raceID].racers.length; i++) {
                if (globals.raceList[raceID].racers[i] === data.name) {
                    globals.raceList[raceID].racers[i] = data.newName;
                }
            }

            // If the player exists in the "raceList" list, rename them
            if (typeof globals.raceList[raceID].racerList !== 'undefined') {
                for (let i = 0; i < globals.raceList[raceID].racerList.length; i++) {
                    if (globals.raceList[raceID].racerList[i].name === data.name) {
                        globals.raceList[raceID].racerList[i].name = data.newName;
                    }
                }
            }
        }

        // Redraw the user on the race screen, if they exist
        $('#race-participants-table-' + data.name + '-name').attr('id', '#race-participants-table-' + data.newName + '-name');
        $('#race-participants-table-' + data.newName + '-name').html(data.newName);
        // TODO There are other things to update, but the user should not be able to change their name in the middle of the race anyway
    });

    globals.conn.on('privateMessage', function(data) {
        chat.draw('PM-from', data.name, data.message);
    });

    /*
        Race command handlers
    */

    // On initial connection, we get a list of all of the races that are currently open or ongoing
    globals.conn.on('raceList', function(data) {
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
            globals.currentRaceID = mostCurrentRaceID; // This is normally set at the top of the raceScreen.show function, but we need to set it now since we have to delay
            setTimeout(function() {
                raceScreen.show(mostCurrentRaceID);
            }, globals.fadeTime * 2 + 5); // Account for fade out and fade in, then add 5 milliseconds of leeway
        }
    });

    // Sent when we create a race or reconnect in the middle of a race
    globals.conn.on('racerList', function(data) {
        globals.raceList[data.id].racerList = data.racers;

        // Build the table with the race participants on the race screen
        $('#race-participants-table-body').html('');
        for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
            raceScreen.participantAdd(i);
        }
    });

    globals.conn.on('raceCreated', connRaceCreated);
    function connRaceCreated(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(function() {
                connRaceCreated(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Keep track of what races are currently going
        globals.raceList[data.id] = data;

        // Update the "Current races" area
        lobbyScreen.raceDraw(data);

        // Check to see if we created this race
        if (data.captain === globals.myUsername) {
            raceScreen.show(data.id);
        }

        // Play the "race created" sound effect if applicable
        let playSound = false;
        if (globals.currentScreen === 'lobby') {
            playSound = true;
        } else if (globals.currentScreen === 'race' && globals.raceList.hasOwnProperty(globals.currentRaceID) === false) {
            playSound = true;
        }
        if (playSound) {
            misc.playSound('race-created');
        }
    }

    globals.conn.on('raceJoined', connRaceJoined);
    function connRaceJoined(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(function() {
                connRaceJoined(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Keep track of the people in each race
        globals.raceList[data.id].racers.push(data.name);
        globals.log.info('Racer "' + data.name + '" joined race:', data.id);

        // Update the row for this race in the lobby
        lobbyScreen.raceUpdatePlayers(data.id);

        if (data.name === globals.myUsername) {
            // If we joined this race
            raceScreen.show(data.id);
        } else {
            // Update the race screen
            if (data.id === globals.currentRaceID) {
                // We are in this race, so add this racer to the racerList with all default values (defaults)
                let datetime = new Date().getTime();
                globals.raceList[data.id].racerList.push({
                    name:   data.name,
                    status: 'not ready',
                    datetimeJoined: datetime,
                    floorNum: 0,
                    place: 0,
                    placeMid: 1,
                    items: [],
                });
                raceScreen.participantAdd(globals.raceList[data.id].racerList.length - 1);
            }
        }
    }

    globals.conn.on('raceLeft', connRaceLeft);
    function connRaceLeft(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(function() {
                connRaceLeft(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Find out if we are in this race
        let inThisRace = false;
        if (globals.raceList[data.id].racers.indexOf(globals.myUsername) !== -1) {
            inThisRace = true;
        }

        // Delete this person from the "racers" array
        if (globals.raceList[data.id].racers.indexOf(data.name) !== -1) {
            globals.raceList[data.id].racers.splice(globals.raceList[data.id].racers.indexOf(data.name), 1);
        } else {
            misc.errorShow('"' + data.name + '" left race #' + data.id + ', but they were not in the "racers" array.');
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
            if (foundRacer === false) {
                misc.errorShow('"' + data.name + '" left race #' + data.id + ', but they were not in the "racerList" array.');
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
            $('#race-participants-table-' + data.name).remove();

            if (globals.raceList[globals.currentRaceID].status === 'open') {
                // Update the captian
                // [not implemented]
            }
        }
    }

    globals.conn.on('raceSetStatus', connRaceSetStatus);
    function connRaceSetStatus(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(function() {
                connRaceSetStatus(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        // Update the status
        globals.raceList[data.id].status = data.status;

        // Check to see if we are in this race
        if (data.id === globals.currentRaceID) {
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
                $('#header-lobby').removeClass('disabled');
                $('#race-quit-button-container').fadeOut(globals.fadeTime);
                $('#race-controls-padding').fadeOut(globals.fadeTime);
                $('#race-num-left-container').fadeOut(globals.fadeTime, function() {
                    $('#race-countdown').css('font-size', '1.75em');
                    $('#race-countdown').css('bottom', '0.25em');
                    $('#race-countdown').css('color', '#e89980');
                    $('#race-countdown').html('<span lang="en">Race completed</span>!');
                    $('#race-countdown').fadeIn(globals.fadeTime);
                });

                // Play the "race completed!" sound effect
                misc.playSound('race-completed', 1300);
            } else {
                misc.errorShow('Failed to parse the status of race #' + data.id + ': ' + globals.raceList[data.id].status);
            }
        }

        // Update the "Status" column in the lobby
        let circleClass;
        if (data.status === 'open') {
            circleClass = 'open';
        } else if (data.status === 'starting') {
            circleClass = 'starting';
            $('#lobby-current-races-' + data.id).removeClass('lobby-race-row-open');
            $('#lobby-current-races-' + data.id).unbind();
        } else if (data.status === 'in progress') {
            circleClass = 'in-progress';
        } else if (data.status === 'finished') {
            // Delete the race
            delete globals.raceList[data.id];
            lobbyScreen.raceUndraw(data.id);
        } else {
            misc.errorShow('Unable to parse the race status from the raceSetStatus command.');
        }
        $('#lobby-current-races-' + data.id + '-status-circle').removeClass();
        $('#lobby-current-races-' + data.id + '-status-circle').addClass('circle lobby-current-races-' + circleClass);
        $('#lobby-current-races-' + data.id + '-status').html('<span lang="en">' + data.status.capitalize() + '</span>');

        // Remove the race if it is finished
        if (data.status === 'finished') {
            delete globals.raceList[data.id];
        }
    }

    globals.conn.on('racerSetStatus', connRacerSetStatus);
    function connRacerSetStatus(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(function() {
                connRacerSetStatus(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

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
    }

    globals.conn.on('raceSetRuleset', function(data) {
        // Not implemented
    });

    globals.conn.on('raceStart', connRaceStart);
    function connRaceStart(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(function() {
                connRacerSetStatus(data);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
            return;
        }

        if (data.id !== globals.currentRaceID) {
            misc.errorShow('Got a "raceStart" command for a race that is not the current race.');
        }

        // Keep track of when the race starts
        globals.raceList[globals.currentRaceID].datetimeStarted = data.time;

        // Schedule the countdown and race (in two separate callbacks for more accuracy)
        let now = new Date().getTime();
        let timeToStartCountdown = data.time - now - globals.timeOffset - 5000 - globals.fadeTime;
        setTimeout(function() {
            raceScreen.countdownTick(5);
        }, timeToStartCountdown);
        let timeToStartRace = data.time - now - globals.timeOffset;
        setTimeout(function() {
            raceScreen.go(globals.currentRaceID); // Send it the current race ID in case it changes in the meantime
        }, timeToStartRace);
    }

    globals.conn.on('racerSetFloor', connRacerSetFloor);
    function connRacerSetFloor(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(function() {
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
                globals.raceList[data.id].racerList[i].floorArrived = data.floorArrived;

                // Update the race screen
                if (globals.currentScreen === 'race') {
                    raceScreen.participantsSetFloor(i);
                }

                break;
            }
        }
    }

    globals.conn.on('racerAddItem', connRacerAddItem);
    function connRacerAddItem(data) {
        if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(function() {
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
        globals.log.info("Got achievement #" + data.id + ": " + name);
    }
};
