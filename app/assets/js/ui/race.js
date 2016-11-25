/*
    Race screen
*/

'use strict';

// Imports
const execFile  = nodeRequire('child_process').execFile;
const path      = nodeRequire('path');
const clipboard = nodeRequire('electron').clipboard;
const globals   = nodeRequire('./assets/js/globals');
const settings  = nodeRequire('./assets/js/settings');
const misc      = nodeRequire('./assets/js/misc');
const chat      = nodeRequire('./assets/js/chat');

/*
    Event handlers
*/

$(document).ready(function() {
    $('#race-title').tooltipster({
        theme:   'tooltipster-shadow',
        delay:   0,
    });

    $('#race-title-seed').tooltipster({
        theme: 'tooltipster-shadow',
        delay: 0,
        functionBefore: function() {
            if (globals.currentScreen === 'race') {
                return true;
            } else {
                return false;
            }
        },
    });

    $('#race-ready-checkbox').change(function() {
        if (globals.currentScreen !== 'race') {
            return;
        } else if (globals.raceList.hasOwnProperty(globals.currentRaceID) === false) {
            return;
        }

        if (this.checked) {
            globals.conn.send('raceReady', {
                'id': globals.currentRaceID,
            });
        } else {
            globals.conn.send('raceUnready', {
                'id': globals.currentRaceID,
            });
        }
    });

    $('#race-quit-button').click(function() {
        if (globals.currentScreen !== 'race') {
            return;
        } else if (globals.raceList.hasOwnProperty(globals.currentRaceID) === false) {
            return;
        }

        globals.conn.send('raceQuit', {
            'id': globals.currentRaceID,
        });
    });

    $('#race-chat-form').submit(function(event) {
        // By default, the form will reload the page, so stop this from happening
        event.preventDefault();

        // Validate input and send the chat
        chat.send('race');
    });
});

/*
    Race functions
*/

const show = function(raceID) {
    // We should be on the lobby screen unless there is severe lag
    if (globals.currentScreen === 'transition') {
        setTimeout(function() {
            show(raceID);
        }, globals.fadeTime + 5); // 5 milliseconds of leeway
        return;
    } else if (globals.currentScreen !== 'waiting-for-server' && globals.currentScreen !== 'lobby') {
        // currentScreen should be "waiting-for-server" if they created a race or joined a current race
        // currentScreen should be "lobby" if they are rejoining a race after a disconnection
        misc.errorShow('Failed to enter the race screen since currentScreen is equal to "' + globals.currentScreen + '".');
        return;
    }
    globals.currentScreen = 'transition';
    globals.currentRaceID = raceID;

    // Put the seed in the clipboard
    if (globals.raceList[globals.currentRaceID].seed !== '-') {
        clipboard.writeText(globals.raceList[globals.currentRaceID].seed);
    }

    // Show and hide some buttons in the header
    $('#header-profile').fadeOut(globals.fadeTime);
    $('#header-leaderboards').fadeOut(globals.fadeTime);
    $('#header-help').fadeOut(globals.fadeTime);
    $('#header-new-race').fadeOut(globals.fadeTime);
    $('#header-settings').fadeOut(globals.fadeTime, function() {
        $('#header-profile').fadeIn(globals.fadeTime);
        $('#header-leaderboards').fadeIn(globals.fadeTime);
        $('#header-help').fadeIn(globals.fadeTime);
        $('#header-lobby').fadeIn(globals.fadeTime);
    });

    // Close all tooltips
    misc.closeAllTooltips();

    // Show the race screen
    $('#lobby').fadeOut(globals.fadeTime, function() {
        $('#race').fadeIn(globals.fadeTime, function() {
            globals.currentScreen = 'race';
        });

        // Build the title
        let raceTitle = 'Race ' + globals.currentRaceID;
        if (globals.raceList[globals.currentRaceID].name !== '-') {
            // Sanitize the race name
            raceTitle += ' &mdash; ' + misc.escapeHtml(globals.raceList[globals.currentRaceID].name);
        }
        if (raceTitle.length > 60) {
            // Truncate the title
            raceTitle = raceTitle.substring(0, 70) + '...';

            // Enable the tooltip
            let content = globals.raceList[globals.currentRaceID].name; // This does not need to be escaped because tooltipster displays HTML as plain text
            $('#race-title').tooltipster('content', content);
        } else {
            // Disable the tooltip
            $('#race-title').tooltipster('content', null);
        }

        $('#race-title').html(raceTitle);

        // Adjust the font size so that it only takes up one line
        let emSize = 1.75; // In HTML5UP Alpha, h3's are 1.75
        while (true) {
            // Reset the font size (we could be coming from a previous race)
            $('#race-title').css('font-size', emSize + 'em');

            // One line is 45 pixels high
            if ($('#race-title').height() > 45) {
                // Reduce the font size by a little bit
                emSize -= 0.1;
            } else {
                break;
            }
        }

        // Column 1 - Status
        let circleClass;
        if (globals.raceList[globals.currentRaceID].status === 'open') {
            circleClass = 'open';
        } else if (globals.raceList[globals.currentRaceID].status === 'starting') {
            circleClass = 'starting';
        } else if (globals.raceList[globals.currentRaceID].status === 'in progress') {
            circleClass = 'in-progress';
        } else if (globals.raceList[globals.currentRaceID].status === 'finished') {
            circleClass = 'finished';
        }
        let statusText = '<span class="circle lobby-current-races-' + circleClass + '"></span> &nbsp; ';
        statusText += '<span lang="en">' + globals.raceList[globals.currentRaceID].status.capitalize() + '</span>';
        $('#race-title-status').html(statusText);

        // Column 2 - Format
        let formatDiv = '<span class="lobby-current-races-format-icon">';
        formatDiv += '<span class="lobby-current-races-' + globals.raceList[globals.currentRaceID].ruleset.format + '"></span></span>';
        formatDiv += '<span class="lobby-current-races-spacing"></span>';
        formatDiv += '<span lang="en">' + globals.raceList[globals.currentRaceID].ruleset.format.capitalize() + '</span>';
        $('#race-title-format').html(formatDiv);

        // Column 3 - Character
        $('#race-title-character').html(globals.raceList[globals.currentRaceID].ruleset.character);

        // Column 4 - Goal
        //$('#race-title-goal').html(globals.raceList[globals.currentRaceID].ruleset.goal);
        $('#race-title-goal-icon').css('background-image', 'url("assets/img/goals/' + globals.raceList[globals.currentRaceID].ruleset.goal + '.png")');

        // Adjust the racer table depending on the format
        if (globals.raceList[globals.currentRaceID].ruleset.format === 'seeded' ||
            globals.raceList[globals.currentRaceID].ruleset.format === 'diveristy') {

            $('#race-title-table-seed').fadeIn(0);
            $('#race-title-seed').fadeIn(0);
            $('#race-title-seed').html(globals.raceList[globals.currentRaceID].seed);
        } else {
            $('#race-title-table-seed').fadeOut(0);
            $('#race-title-seed').fadeOut(0);
        }
        if (globals.raceList[globals.currentRaceID].ruleset.format === 'seeded') {
            $('#race-title-table-build').fadeIn(0);
            $('#race-title-build').fadeIn(0);
            $('#race-title-build').html(globals.raceList[globals.currentRaceID].ruleset.startingBuild);
        } else {
            $('#race-title-table-build').fadeOut(0);
            $('#race-title-build').fadeOut(0);
        }

        // Show the pre-start race controls
        $('#race-ready-checkbox-container').fadeIn(0);
        $('#race-ready-checkbox').prop('checked', false);
        $('#race-countdown').fadeOut(0);
        $('#race-quit-button').fadeOut(0);

        // Set the race participants table to the pre-game state (with 2 columns)
        $('#race-participants-table-place').fadeOut(0);
        $('#race-participants-table-status').css('width', '70%');
        $('#race-participants-table-floor').fadeOut(0);
        $('#race-participants-table-item').fadeOut(0);
        $('#race-participants-table-time').fadeOut(0);
        $('#race-participants-table-offset').fadeOut(0);

        // Automatically scroll to the bottom of the chat box
        let bottomPixel = $('#race-chat-text').prop('scrollHeight') - $('#race-chat-text').height();
        $('#race-chat-text').scrollTop(bottomPixel);

        // Focus the chat input
        $('#race-chat-box-input').focus();

        // If we disconnected in the middle of the race, we need to update the race controls
        if (globals.raceList[globals.currentRaceID].status === 'starting') {
            misc.errorShow('You rejoined the race during the countdown, which is not supported. Please relaunch the program.');
        } else if (globals.raceList[globals.currentRaceID].status === 'in progress') {
            start();
        }
    });
};
exports.show = show;

// Add a row to the table with the race participants on the race screen
exports.participantAdd = function(i) {
    // Begin building the row
    let racer = globals.raceList[globals.currentRaceID].racerList[i];
    let racerDiv = '<tr id="race-participants-table-' + racer.name + '">';

    // The racer's place
    racerDiv += '<td id="race-participants-table-' + racer.name + '-place" class="hidden">';
    if (racer.place === 0) {
        racerDiv += '-';
    } else {
        racerDiv += racer.place;
    }
    racerDiv += '</td>';

    // The racer's name
    racerDiv += '<td id="race-participants-table-' + racer.name + '-name">' + racer.name + '</td>';

    // The racer's status
    racerDiv += '<td id="race-participants-table-' + racer.name + '-status">';
    // This will get filled in later in the "participantsSetStatus" function
    racerDiv += '</td>';

    // The racer's floor
    racerDiv += '<td id="race-participants-table-' + racer.name + '-floor" class="hidden">';
    let floorDiv;
    if (racer.floor === 1) {
        floorDiv = 'B1';
    } else if (racer.floor === 2) {
        floorDiv = 'B2';
    } else if (racer.floor === 3) {
        floorDiv = 'C1';
    } else if (racer.floor === 4) {
        floorDiv = 'C2';
    } else if (racer.floor === 5) {
        floorDiv = 'D1';
    } else if (racer.floor === 6) {
        floorDiv = 'D2';
    } else if (racer.floor === 7) {
        floorDiv = 'W1';
    } else if (racer.floor === 8) {
        floorDiv = 'W2';
    } else if (racer.floor === 9) {
        floorDiv = 'BW';
    } else if (racer.floor === 10) {
        floorDiv = 'Cath';
    } else if (racer.floor === 11) {
        floorDiv = 'Chest';
    }
    racerDiv += floorDiv;
    racerDiv += '</td>';

    // The racer's starting item
    racerDiv += '<td id="race-participants-table-' + racer.name + '-item" class="hidden">';
    if (racer.items !== null) {
        racerDiv += racer.items[0];
    } else {
        racerDiv += '-';
    }
    racerDiv += '</td>';

    // The racer's time
    racerDiv += '<td id="race-participants-table-' + racer.name + '-time" class="hidden">';
    racerDiv += '</td>';

    // The racer's time offset
    racerDiv += '<td id="race-participants-table-' + racer.name + '-offset" class="hidden">-</td>';

    // Append the row
    racerDiv += '</tr>';
    $('#race-participants-table-body').append(racerDiv);

    // To fix a small visual bug where the left border isn't drawn because of the left-most column being hidden
    $('#race-participants-table-' + racer.name + '-name').css('border-left', 'solid 1px #e5e5e5');

    // Update some values in the row
    participantsSetStatus(racer.name, racer.status);
};

const participantsSetStatus = function(name, status) {
    // Update the status column of the row
    let statusDiv = '';
    if (status === 'ready') {
        statusDiv += '<i class="fa fa-check" aria-hidden="true" style="color: green;"></i> &nbsp; ';
    } else if (status === 'not ready') {
        statusDiv += '<i class="fa fa-times" aria-hidden="true" style="color: red;"></i> &nbsp; ';
    } else if (status === 'racing') {
        statusDiv += '<i class="mdi mdi-chevron-double-right" style="color: orange;"></i> &nbsp; ';
    } else if (status === 'quit') {
        statusDiv += '<i class="mdi mdi-skull"></i> &nbsp; ';
    } else if (status === 'finished') {
        statusDiv += '<i class="fa fa-check" aria-hidden="true" style="color: green;"></i> &nbsp; ';
    }
    statusDiv += '<span lang="en">' + status.capitalize() + '</span>';
    $('#race-participants-table-' + name + '-status').html(statusDiv);

    // Update the place column of the row
    if (status === 'finished') {
        if (typeof(globals.raceList[globals.currentRaceID].nextPlace) === 'undefined') {
            globals.raceList[globals.currentRaceID].nextPlace = 1;
        }

        // Update their place in the raceList
        for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
            if (name === globals.raceList[globals.currentRaceID].racerList[i].name) {
                globals.raceList[globals.currentRaceID].racerList[i].place = globals.raceList[globals.currentRaceID].nextPlace;
            }
        }

        // Update their row on the race screen
        let ordinal = misc.ordinal_suffix_of(globals.raceList[globals.currentRaceID].nextPlace);
        $('#race-participants-table-' + name + '-place').html(ordinal);

        // Increment the nextPlace variable
        globals.raceList[globals.currentRaceID].nextPlace++;
    }
};
exports.participantsSetStatus = participantsSetStatus;

exports.markOnline = function() {
    // TODO
};

exports.startCountdown = function() {
    // Change the functionality of the "Lobby" button in the header
    $('#header-lobby').addClass('disabled');

    // Play the "Let's Go" sound effect
    let audio = new Audio('assets/sounds/lets-go.mp3');
    audio.volume = settings.get('volume');
    audio.play();

    // Show the countdown
    $('#race-ready-checkbox-container').fadeOut(globals.fadeTime, function() {
        $('#race-countdown').css('font-size', '1.75em');
        $('#race-countdown').css('bottom', '0.25em');
        $('#race-countdown').css('color', '#e89980');
        $('#race-countdown').html('<span lang="en">Race starting in 10 seconds!</span>');
        $('#race-countdown').fadeIn(globals.fadeTime);
    });
};

const countdownTick = function(i) {
    if (i > 0) {
        $('#race-countdown').fadeOut(globals.fadeTime, function() {
            $('#race-countdown').css('font-size', '2.5em');
            $('#race-countdown').css('bottom', '0.375em');
            $('#race-countdown').css('color', 'red');
            $('#race-countdown').html(i);
            $('#race-countdown').fadeIn(globals.fadeTime);
            setTimeout(function() {
                // Focus the game with 3 seconds remaining on the countdown
                if (i === 3) {
                    let command = path.join(__dirname, '/assets/programs/isaacFocus/isaacFocus.exe');
                    execFile(command);
                }

                // Play the sound effect associated with the final 3 seconds
                if (i === 3 || i === 2 || i === 1) {
                    let audio = new Audio('assets/sounds/' + i + '.mp3');
                    audio.volume = settings.get('volume');
                    audio.play();
                }
            }, globals.fadeTime / 2);
        });

        setTimeout(function() {
            countdownTick(i - 1);
        }, 1000);
    }
};
exports.countdownTick = countdownTick;

exports.go = function() {
    $('#race-countdown').html('<span lang="en">Go!</span>');
    $('#race-title-status').html('<span class="circle lobby-current-races-in-progress"></span> &nbsp; <span lang="en">In Progress</span>');

    // Press enter inside of the game
    /*let command = path.join(__dirname, '/assets/programs/raceGo/raceGo.exe');
    execFile(command);*/

    // Play the "Go" sound effect
    let audio = new Audio('assets/sounds/go.mp3');
    audio.volume = settings.get('volume');
    audio.play();

    // Wait 5 seconds, then start to change the controls
    setTimeout(start, 5000);

    // Add default values to the columns to the race participants table
    for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
        globals.raceList[globals.currentRaceID].racerList[i].status = 'racing';

        let racer = globals.raceList[globals.currentRaceID].racerList[i].name;
        let statusDiv = '<i class="mdi mdi-chevron-double-right" style="color: orange;"></i> &nbsp; <span lang="en">Racing</span>';
        $('#race-participants-table-' + racer + '-status').html(statusDiv);
        $('#race-participants-table-' + racer + '-item').html('-');
        $('#race-participants-table-' + racer + '-time').html('-');
        $('#race-participants-table-' + racer + '-offset').html('-');
    }
};

const start = function() {
    // In case we coming back after a disconnect, redo all of the stuff that was done in the "startCountdown" function
    $('#header-lobby').addClass('disabled');
    $('#race-ready-checkbox-container').fadeOut(0);

    // Start the race timer
    setTimeout(raceTimerTick, 0);

    // Change the controls on the race screen
    $('#race-countdown').fadeOut(globals.fadeTime, function() {
        // Find out if we have quit this race already
        let alreadyQuit = false;
        for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
            if (globals.raceList[globals.currentRaceID].racerList[i].name === globals.myUsername &&
                globals.raceList[globals.currentRaceID].racerList[i].status === 'quit') {

                alreadyQuit = true;
            }
        }

        if (alreadyQuit === false) {
            $('#race-quit-button').fadeIn(globals.fadeTime);
        }
    });

    // Change the table to have 6 columns instead of 2
    $('#race-participants-table-place').fadeIn(globals.fadeTime);
    $('#race-participants-table-status').css('width', '7.5em');
    $('#race-participants-table-floor').fadeIn(globals.fadeTime);
    $('#race-participants-table-item').fadeIn(globals.fadeTime);
    $('#race-participants-table-time').fadeIn(globals.fadeTime);
    $('#race-participants-table-offset').fadeIn(globals.fadeTime);
    for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
        let racer = globals.raceList[globals.currentRaceID].racerList[i].name;
        $('#race-participants-table-' + racer + '-place').fadeIn(globals.fadeTime);
        $('#race-participants-table-' + racer.name + '-name').css('border-left', '0'); // To fix a small visual bug where the left border isn't drawn because of the left-most column being hidden
        $('#race-participants-table-' + racer + '-floor').fadeIn(globals.fadeTime);
        $('#race-participants-table-' + racer + '-item').fadeIn(globals.fadeTime);
        $('#race-participants-table-' + racer + '-time').fadeIn(globals.fadeTime);
        $('#race-participants-table-' + racer + '-offset').fadeIn(globals.fadeTime);
    }
};
exports.start = start;

function raceTimerTick() {
    // Stop the timer if the race is over
    // (the race is over if the entry in the raceList is deleted)
    if (globals.raceList.hasOwnProperty(globals.currentRaceID) === false) {
        return;
    }

    // Get the elapsed time in the race
    let now = new Date().getTime();
    let raceMilliseconds = now - globals.raceList[globals.currentRaceID].datetimeStarted + globals.timeOffset;
    let raceSeconds = Math.round(raceMilliseconds / 1000);
    let timeDiv = misc.pad(parseInt(raceSeconds / 60, 10)) + ':' + misc.pad(raceSeconds % 60);

    // Update all of the timers
    for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
        if (globals.raceList[globals.currentRaceID].racerList[i].status === 'racing') {
            $('#race-participants-table-' + globals.raceList[globals.currentRaceID].racerList[i].name + '-time').html(timeDiv);
        }
    }

    // Schedule the next tick
    setTimeout(raceTimerTick, 1000);
}
