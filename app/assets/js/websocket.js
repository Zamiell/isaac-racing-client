/*
    Websocket handling
*/

'use strict';

// Imports
const keytar         = nodeRequire('keytar');
const isDev          = nodeRequire('electron-is-dev');
const globals        = nodeRequire('./assets/js/globals');
const settings       = nodeRequire('./assets/js/settings');
const chat           = nodeRequire('./assets/js/chat');
const misc           = nodeRequire('./assets/js/misc');
const loginScreen    = nodeRequire('./assets/js/ui/login');
const registerScreen = nodeRequire('./assets/js/ui/register');
const lobbyScreen    = nodeRequire('./assets/js/ui/lobby');
const raceScreen     = nodeRequire('./assets/js/ui/race');

exports.init = function(username, password, remember) {
    // Establish a WebSocket connection
    let url = 'ws' + (globals.secure ? 's' : '') + '://' + globals.domain + '/ws';
    globals.conn = new golem.Connection(url, isDev); // It will automatically use the cookie that we recieved earlier
                                                     // If the second argument is true, debugging is turned on
    console.log('Establishing WebSocket connection to:', url);

    /*
        Miscellaneous WebSocket handlers
    */

    globals.conn.on('open', function(event) {
        console.log('WebSocket connection opened.');

        // Login success; join the lobby chat channel
        globals.conn.emit('roomJoin', {
            'room': 'lobby',
        });

        // Save the credentials
        if (remember === true) {
            // Store the username (in the settings.json file)
            settings.set('username', username);
            settings.saveSync();

            // Store the password (in the OS vault)
            keytar.addPassword('Racing+', username, password);
        }

        // Do the proper transition to the lobby depending on where we logged in from
        if (globals.currentScreen === 'title-ajax') {
            globals.currentScreen = 'transition';
            $('#title').fadeOut(globals.fadeTime, function() {
                $('#title-buttons').fadeIn(0);
                $('#title-languages').fadeIn(0);
                $('#title-version').fadeIn(0);
                $('#title-ajax').fadeOut(0);
                lobbyScreen.show();
            });
        } else if (globals.currentScreen === 'login-ajax') {
            globals.currentScreen = 'transition';
            $('#login').fadeOut(globals.fadeTime, function() {
                loginScreen.loginReset();
                lobbyScreen.show();
            });
        } else if (globals.currentScreen === 'register-ajax') {
            globals.currentScreen = 'transition';
            $('#register').fadeOut(globals.fadeTime, function() {
                registerScreen.registerReset();
                lobbyScreen.show();
            });
        } else {
            misc.errorShow('Can\'t transition to the lobby from screen: ' + globals.currentScreen);
        }
    });

    globals.conn.on('close', connClose);
    function connClose(event) {
        console.log('WebSocket connection closed.');

        // Check to see if this was intended
        if (globals.currentScreen === 'error') {
            return;
        } else if (globals.initiatedLogout === false) {
            misc.errorShow('Disconnected from the server. Either your Internet is having problems or the server went down!');
            return;
        }

        // Reset some global variables
        globals.roomList = {};
        globals.raceList = {};
        globals.myUsername = '';
        globals.initiatedLogout = false;

        // Hide the links in the header
        $('#header-profile').fadeOut(globals.fadeTime);
        $('#header-leaderboards').fadeOut(globals.fadeTime);
        $('#header-help').fadeOut(globals.fadeTime);

        // Hide the buttons in the header
        $('#header-lobby').fadeOut(globals.fadeTime);
        $('#header-new-race').fadeOut(globals.fadeTime);
        $('#header-settings').fadeOut(globals.fadeTime);
        $('#header-log-out').fadeOut(globals.fadeTime);

        // Transition to the title screen, depending on what screen we are currently on
        if (globals.currentScreen === 'lobby') {
            // Show the title screen
            globals.currentScreen = 'transition';
            $('#lobby').fadeOut(globals.fadeTime, function() {
                $('#page-wrapper').addClass('vertical-center');
                $('#title').fadeIn(globals.fadeTime, function() {
                    globals.currentScreen = 'title';
                });
            });
        } else if (globals.currentScreen === 'race') {
            // Show the title screen
            globals.currentScreen = 'transition';
            $('#race').fadeOut(globals.fadeTime, function() {
                $('#page-wrapper').addClass('vertical-center');
                $('#title').fadeIn(globals.fadeTime, function() {
                    globals.currentScreen = 'title';
                });
            });
        } else if (globals.currentScreen === 'settings') {
            // Show the title screen
            globals.currentScreen = 'transition';
            $('#settings').fadeOut(globals.fadeTime, function() {
                $('#page-wrapper').addClass('vertical-center');
                $('#title').fadeIn(globals.fadeTime, function() {
                    globals.currentScreen = 'title';
                });
            });
        } else if (globals.currentScreen === 'transition') {
            // Come back when the current transition finishes
            setTimeout(function() {
                connClose(event);
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
        } else {
            misc.errorShow('Unable to parse the "currentScreen" variable in the WebSocket close function.');
        }
    }

    globals.conn.on('socketError', function(event) {
        if (globals.currentScreen === 'title-ajax' ||
            globals.currentScreen === 'login-ajax' ||
            globals.currentScreen === 'register-ajax') {

            let error = 'Failed to connect to the WebSocket server. The server might be down!';
            loginScreen.loginFail(error);
        } else {
            let error = 'Encountered a WebSocket error. The server might be down!';
            misc.errorShow(error);
        }
    });

    /*
        Miscellaneous command handlers
    */

    // Sent upon a successful connection
    globals.conn.on('username', function(data) {
        globals.myUsername = data;
    });

    // Sent upon a successful connection
    globals.conn.on('time', function(data) {
        let now = new Date().getTime();
        globals.timeOffset = data - now;
    });

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
            lobbyScreen.usersDraw(data.room);
        } else if (data.room.startsWith('_race_')) {
            let raceID = data.room.match(/_race_(\d+)/)[1];
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

        // Redraw the users list in the lobby
        if (data.room === 'lobby') {
            lobbyScreen.usersDraw(data.room);
        }
    });

    globals.conn.on('roomLeft', function(data) {
        // Remove them from the room list
        delete globals.roomList[data.room].users[data.name];
        globals.roomList[data.room].numUsers--;

        // Redraw the users list in the lobby
        if (data.room === 'lobby') {
            lobbyScreen.usersDraw(data.room);
        }
    });

    globals.conn.on('roomMessage', function(data) {
        chat.draw(data.room, data.name, data.message);
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

    // Sent when we reconnect in the middle of a race
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

        // Update the "# of Entrants" column in the lobby
        $('#lobby-current-races-' + data.id + '-racers').html(globals.raceList[data.id].racers.length);

        if (data.name === globals.myUsername) {
            // If we joined this race
            raceScreen.show(data.id);
        } else {
            // Update the race screen
            if (data.id === globals.currentRaceID) {
                // We are in this race
                let datetime = new Date().getTime();
                globals.raceList[data.id].racerList.push({
                    'name':   data.name,
                    'status': 'not ready',
                    'datetimeJoined': datetime,
                    'datetimeFinished': 0,
                    'place': 0,
                    'floor': 1,
                    'items': [],
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

        // Delete this person from the race list
        if (globals.raceList[data.id].racers.indexOf(data.name) !== -1) {
            globals.raceList[data.id].racers.splice(globals.raceList[data.id].racers.indexOf(data.name), 1);
        } else {
            misc.errorShow('"' + data.name + '" left race #' + data.id + ', but they were not in the entrant list.');
            return;
        }

        // Update the "Current races" area
        if (globals.raceList[data.id].racers.length === 0) {
            // Delete the race since the last person in the race left
            delete globals.raceList[data.id];
            lobbyScreen.raceUndraw(data.id);
        } else {
            // Check to see if this person was the captain, and if so, make the next person in line the captain
            if (globals.raceList[data.id].captain === data.name) {
                globals.raceList[data.id].captain = globals.raceList[data.id].racers[0];
                $('#lobby-current-races-' + data.id + '-captain').html(globals.raceList[data.id].captain);
            }

            // Update the "# of Entrants" column
            $('#lobby-current-races-' + data.id + '-racers').html(globals.raceList[data.id].racers.length);

        }

        // If we left the race
        if (data.name === globals.myUsername) {
            // Show the lobby
            lobbyScreen.showFromRace();
            return;
        }

        // If we are in this race
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
                $('#race-quit-button').fadeOut(globals.fadeTime, function() {
                    $('#race-countdown').css('font-size', '1.75em');
                    $('#race-countdown').css('bottom', '0.25em');
                    $('#race-countdown').css('color', '#e89980');
                    $('#race-countdown').html('<span lang="en">Race completed</span>!');
                    $('#race-countdown').fadeIn(globals.fadeTime);
                });
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
            globals.currentRaceID = false;
            delete globals.raceList[data.id];
            lobbyScreen.raceUndraw(data.id);
        } else {
            misc.errorShow('Unable to parse the race status from the raceSetStatus command.');
        }
        $('#lobby-current-races-' + data.id + '-status-circle').removeClass();
        $('#lobby-current-races-' + data.id + '-status-circle').addClass('circle lobby-current-races-' + circleClass);
        $('#lobby-current-races-' + data.id + '-status').html(data.status.capitalize());

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
                // Update their status locally
                globals.raceList[data.id].racerList[i].status = data.status;

                // Update the race screen
                if (globals.currentScreen === 'race' && data.id === globals.currentRaceID) {
                    let statusDiv;
                    if (data.status === 'ready') {
                        statusDiv = '<i class="fa fa-check" aria-hidden="true" style="color: green;"></i> &nbsp; ';
                    } else if (data.status === 'not ready') {
                        statusDiv = '<i class="fa fa-times" aria-hidden="true" style="color: red;"></i> &nbsp; ';
                    } else if (data.status === 'racing') {
                        statusDiv = '<i class="mdi mdi-chevron-double-right" style="color: orange;"></i> &nbsp; ';
                    } else if (data.status === 'quit') {
                        statusDiv = '<i class="mdi mdi-skull"></i> &nbsp; ';
                    } else if (data.status === 'finished') {
                        statusDiv = '<i class="fa fa-check" aria-hidden="true" style="color: green;"></i> &nbsp; ';
                    }
                    statusDiv += '<span lang="en">' + data.status.capitalize() + '</span>';
                    $('#race-participants-table-' + data.name + '-status').html(statusDiv);
                }

                break;
            }
        }

        // If we quit
        if (data.name === globals.myUsername && data.status === 'quit') {
            $('#race-quit-button').fadeOut(globals.fadeTime);
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
        setTimeout(raceScreen.go, timeToStartRace);
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
                // Update their floor locally
                globals.raceList[data.id].racerList[i].floor = data.floor;

                // Update the race screen
                if (globals.currentScreen === 'race' && data.id === globals.currentRaceID) {
                    let floorDiv;
                    if (data.floor === 1) {
                        floorDiv = 'B1';
                    } else if (data.floor === 2) {
                        floorDiv = 'B2';
                    } else if (data.floor === 3) {
                        floorDiv = 'C1';
                    } else if (data.floor === 4) {
                        floorDiv = 'C2';
                    } else if (data.floor === 5) {
                        floorDiv = 'D1';
                    } else if (data.floor === 6) {
                        floorDiv = 'D2';
                    } else if (data.floor === 7) {
                        floorDiv = 'W1';
                    } else if (data.floor === 8) {
                        floorDiv = 'W2';
                    } else if (data.floor === 9) {
                        floorDiv = 'Cath';
                    } else if (data.floor === 10) {
                        floorDiv = 'Chest';
                    }
                    $('#race-participants-table-' + data.name + '-floor').html(floorDiv);
                }

                break;
            }
        }
    }
};
