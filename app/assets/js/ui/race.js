/*
    Race screen
*/

'use strict';

// Imports
const execFile  = nodeRequire('child_process').execFile;
const path      = nodeRequire('path');
const clipboard = nodeRequire('electron').clipboard;
const globals   = nodeRequire('./assets/js/globals');
const misc      = nodeRequire('./assets/js/misc');
const chat      = nodeRequire('./assets/js/chat');

/*
    Event handlers
*/

$(document).ready(function() {
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
            globals.conn.emit('raceReady', {
                'id': globals.currentRaceID,
            });
        } else {
            globals.conn.emit('raceUnready', {
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

        globals.conn.emit('raceQuit', {
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
        }, globals.fadeTime + 10); // 10 milliseconds of leeway;
        return;
    } else if (globals.currentScreen !== 'lobby') {
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

        // Set the title
        let raceTitle = 'Race ' + globals.currentRaceID;
        if (globals.raceList[globals.currentRaceID].name !== '-') {
            raceTitle += ' &mdash; ' + globals.raceList[globals.currentRaceID].name;
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

        // Set the status and format
        $('#race-title-status').html(globals.raceList[globals.currentRaceID].status.capitalize());
        $('#race-title-format').html(globals.raceList[globals.currentRaceID].ruleset.format.capitalize());
        $('#race-title-character').html(globals.raceList[globals.currentRaceID].ruleset.character);
        $('#race-title-goal').html(globals.raceList[globals.currentRaceID].ruleset.goal);
        $('#race-title-goal').html(globals.raceList[globals.currentRaceID].ruleset.goal);
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

    // The racer's name
    racerDiv += '<td>' + racer.name + '</td>';

    // The racer's status
    racerDiv += '<td id="race-participants-table-' + racer.name + '-status">';
    if (racer.status === 'ready') {
        racerDiv += '<i class="fa fa-check" aria-hidden="true"></i> &nbsp; ';
    } else if (racer.status === 'not ready') {
        racerDiv += '<i class="fa fa-times" aria-hidden="true"></i> &nbsp; ';
    } else if (racer.status === 'racing') {
        racerDiv += '<i class="mdi mdi-chevron-double-right"></i> &nbsp; ';
    } else if (racer.status === 'quit') {
        racerDiv += '<i class="mdi mdi-skull"></i> &nbsp; ';
    } else if (racer.status === 'finished') {
        racerDiv += '<i class="fa fa-check" aria-hidden="true"></i> &nbsp; ';
    }
    racerDiv += '<span lang="en">' + racer.status.capitalize() + '</span></td>';

    // The racer's floor
    racerDiv += '<td id="race-participants-table-' + racer.name + '-floor" class="hidden">';
    racerDiv += racer.floor + '</td>';

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
    $('#race-participants-table-' + racer.name + '-status').attr('colspan', 5);
};

exports.markOnline = function() {
    // TODO
};

exports.startCountdown = function() {
    // Change the functionality of the "Lobby" button in the header
    $('#header-lobby').addClass('disabled');

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
                if (i === 3 || i === 2 || i === 1) {
                    let audio = new Audio('assets/sounds/' + i + '.mp3');
                    audio.volume = globals.settings.volume;
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
    $('#race-title-status').html('<span lang="en">In Progress</span>');

    // Press enter to start the race
    let command = path.join(__dirname, '/assets/programs/raceGo.exe');
    execFile(command);

    // Play the "Go" sound effect
    let audio = new Audio('assets/sounds/go.mp3');
    audio.volume = globals.settings.volume;
    audio.play();

    // Wait 5 seconds, then start to change the controls
    setTimeout(start, 5000);

    // Add default values to the columns to the race participants table
    for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
        globals.raceList[globals.currentRaceID].racerList[i].status = 'racing';

        let racer = globals.raceList[globals.currentRaceID].racerList[i].name;
        let statusDiv = '<i class="mdi mdi-chevron-double-right"></i> &nbsp; <span lang="en">Racing</span>';
        $('#race-participants-table-' + racer + '-status').html(statusDiv);
        $('#race-participants-table-' + racer + '-item').html('-');
        $('#race-participants-table-' + racer + '-time').html('-');
        $('#race-participants-table-' + racer + '-offset').html('-');
        $('#race-participants-table-' + racer + '-offset').fadeIn(globals.fadeTime);
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
    $('#race-participants-table-floor').fadeIn(globals.fadeTime);
    $('#race-participants-table-item').fadeIn(globals.fadeTime);
    $('#race-participants-table-time').fadeIn(globals.fadeTime);
    $('#race-participants-table-offset').fadeIn(globals.fadeTime);
    for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
        $('#race-participants-table-' + globals.raceList[globals.currentRaceID].racerList[i].name + '-status').attr('colspan', 1);
        $('#race-participants-table-' + globals.raceList[globals.currentRaceID].racerList[i].name + '-floor').fadeIn(globals.fadeTime);
        $('#race-participants-table-' + globals.raceList[globals.currentRaceID].racerList[i].name + '-item').fadeIn(globals.fadeTime);
        $('#race-participants-table-' + globals.raceList[globals.currentRaceID].racerList[i].name + '-time').fadeIn(globals.fadeTime);
        $('#race-participants-table-' + globals.raceList[globals.currentRaceID].racerList[i].name + '-offset').fadeIn(globals.fadeTime);
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
