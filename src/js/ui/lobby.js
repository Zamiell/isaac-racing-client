/*
    Lobby screen
*/

// Imports
// const { shell } = nodeRequire('electron');
const globals = nodeRequire('./js/globals');
const misc = nodeRequire('./js/misc');
const chat = nodeRequire('./js/chat');
const logWatcher = nodeRequire('./js/log-watcher');
const steamWatcher = nodeRequire('./js/steam-watcher');
const isaac = nodeRequire('./js/isaac');
const modLoader = nodeRequire('./js/mod-loader');
const header = nodeRequire('./js/ui/header');
const builds = nodeRequire('./data/builds');

/*
    Event handlers
*/

$(document).ready(() => {
    $('#lobby-chat-form').submit((event) => {
        // By default, the form will reload the page, so stop this from happening
        event.preventDefault();

        // Validate input and send the chat
        chat.send('lobby');
    });
});

/*
    Lobby functions
*/

// Called from the login screen or the register screen
exports.show = () => {
    // Start the log watcher
    if (!logWatcher.start()) {
        return;
    }

    // Start the Steam watcher
    steamWatcher.start();

    // Do file-system related checks
    if (!isaac.start()) {
        return;
    }

    // Make sure that all of the forms are cleared out
    $('#login-username').val('');
    $('#login-password').val('');
    $('#login-remember-checkbox').prop('checked', false);
    $('#login-error').fadeOut(0);
    $('#register-username').val('');
    $('#register-password').val('');
    $('#register-email').val('');
    $('#register-error').fadeOut(0);

    // Show the links in the header
    $('#header-profile').fadeIn(globals.fadeTime);
    $('#header-leaderboards').fadeIn(globals.fadeTime);
    $('#header-help').fadeIn(globals.fadeTime);

    // Show the buttons in the header
    $('#header-new-race').fadeIn(globals.fadeTime);
    $('#header-settings').fadeIn(globals.fadeTime);

    // Show the lobby
    $('#page-wrapper').removeClass('vertical-center');
    $('#lobby').fadeIn(globals.fadeTime, () => {
        globals.currentScreen = 'lobby';
    });

    // Fix the indentation on lines that were drawn when the element was hidden
    chat.indentAll('lobby');

    // Automatically scroll to the bottom of the chat box
    const bottomPixel = $('#lobby-chat-text').prop('scrollHeight') - $('#lobby-chat-text').height();
    $('#lobby-chat-text').scrollTop(bottomPixel);

    // Focus the chat input
    $('#lobby-chat-box-input').focus();
};

exports.showFromRace = () => {
    // We should be on the race screen unless there is severe lag
    if (globals.currentScreen !== 'race') {
        misc.errorShow(`Failed to return to the lobby since currentScreen is equal to "${globals.currentScreen}".`);
        return;
    }
    globals.currentScreen = 'transition';
    globals.currentRaceID = false;

    // Show and hide some buttons in the header
    $('#header-profile').fadeOut(globals.fadeTime);
    $('#header-leaderboards').fadeOut(globals.fadeTime);
    $('#header-help').fadeOut(globals.fadeTime);
    $('#header-lobby').fadeOut(globals.fadeTime, () => {
        $('#header-profile').fadeIn(globals.fadeTime);
        $('#header-leaderboards').fadeIn(globals.fadeTime);
        $('#header-help').fadeIn(globals.fadeTime);
        $('#header-new-race').fadeIn(globals.fadeTime);
        $('#header-settings').fadeIn(globals.fadeTime);
        header.checkHideLinks(); // We just faded in the links, but they might be hidden on small windows
    });
    $('#race-ready-checkbox-container').tooltipster('close');

    // Show the lobby
    $('#race').fadeOut(globals.fadeTime, () => {
        $('#lobby').fadeIn(globals.fadeTime, () => {
            globals.currentScreen = 'lobby';
        });

        // Fix the indentation on lines that were drawn when the element was hidden
        chat.indentAll('lobby');

        // Automatically scroll to the bottom of the chat box
        const bottomPixel = $('#lobby-chat-text').prop('scrollHeight') - $('#lobby-chat-text').height();
        $('#lobby-chat-text').scrollTop(bottomPixel);

        // Focus the chat input
        $('#lobby-chat-box-input').focus();

        // Update the Racing+ Lua mod
        modLoader.reset();
    });
};

exports.raceDraw = (race) => {
    // Create the new row
    let raceDiv = `<tr id="lobby-current-races-${race.id}" class="`;
    if (race.status === 'open' && !race.ruleset.solo) {
        raceDiv += 'lobby-race-row-open ';
    }
    raceDiv += 'hidden">';

    // Column 1 - Name
    raceDiv += `<td id="lobby-current-races-${race.id}-name" class="lobby-current-races-name selectable">`;

    if (race.isPasswordProtected) {
        raceDiv += '<i class="fa fa-lock"></i> ';
    }

    if (race.name === '-') {
        raceDiv += `<span lang="en">Race</span> ${race.id}`;
    } else {
        raceDiv += misc.escapeHtml(race.name);
    }
    raceDiv += '</td>';

    // Column 2 - Status
    raceDiv += '<td class="lobby-current-races-status">';
    let circleClass;
    if (race.status === 'open') {
        circleClass = 'open';
    } else if (race.status === 'starting') {
        circleClass = 'starting';
    } else if (race.status === 'in progress') {
        circleClass = 'in-progress';
    }
    raceDiv += `<span id="lobby-current-races-${race.id}-status-circle" class="circle lobby-current-races-${circleClass}"></span>`;
    raceDiv += ` &nbsp; <span id="lobby-current-races-${race.id}-status"><span lang="en">${race.status.capitalize()}</span></span>`;
    raceDiv += '</td>';

    // Column 3 - Format
    raceDiv += `<td id="lobby-current-races-format-${race.id}" class="lobby-current-races-format">`;

    raceDiv += '<span class="lobby-current-races-size-icon">';
    if (race.ruleset.solo) {
        raceDiv += '<i class="fa fa-user 2x" aria-hidden="true" style="position: relative; left: 0.1em;"></i>';
        // Move this to the right so that it lines up with the center of the multiplayer icon
    } else {
        raceDiv += '<i class="fa fa-users 2x" aria-hidden="true" style="color: blue;"></i>';
    }
    raceDiv += '</span>';

    if (race.ruleset.solo) {
        raceDiv += '<span class="lobby-current-races-type-icon">';
        raceDiv += `<span class="lobby-current-races-${(race.ruleset.ranked ? 'ranked' : 'unranked')}" lang="en"></span></span>`;
        raceDiv += '<span class="lobby-current-races-spacing"></span>';
    }

    raceDiv += '<span class="lobby-current-races-format-icon">';
    raceDiv += `<span class="lobby-current-races-${race.ruleset.format}" lang="en"></span></span>`;

    // Column 4 - Size
    raceDiv += `<td id="lobby-current-races-${race.id}-size" class="lobby-current-races-size">`;
    // This will get filled in later by the "raceUpdatePlayers" function
    raceDiv += '</td>';

    // Column 5 - Entrants
    raceDiv += `<td id="lobby-current-races-${race.id}-racers" class="lobby-current-races-racers selectable">`;
    // This will get filled in later by the "raceUpdatePlayers" function
    raceDiv += '</td>';

    // Fix the bug where the "vertical-center" class causes things to be hidden if there is overflow
    if (Object.keys(globals.raceList).length > 4) { // More than 4 races causes the overflow
        $('#lobby-current-races-table-wrapper').removeClass('vertical-center');
    } else {
        $('#lobby-current-races-table-wrapper').addClass('vertical-center');
    }

    // Add it and fade it in
    $('#lobby-current-races-table-body').append(raceDiv);
    if ($('#lobby-current-races-table-no').css('display') !== 'none') {
        $('#lobby-current-races-table-no').fadeOut(globals.fadeTime, () => {
            $('#lobby-current-races-table').fadeIn(0);
            raceDraw2(race);
        });
    } else {
        raceDraw2(race);
    }
};

function raceDraw2(race) {
    // Fade in the race row
    $(`#lobby-current-races-${race.id}`).fadeIn(globals.fadeTime, () => {
        // While we were fading in, the race might have ended
        if (!Object.prototype.hasOwnProperty.call(globals.raceList, race.id)) {
            return;
        }

        // Make the row clickable
        if (globals.raceList[race.id].status === 'open' && !globals.raceList[race.id].ruleset.solo) {
            $(`#lobby-current-races-${race.id}`).click(() => {
                if (globals.currentScreen === 'lobby') {
                    if (race.isPasswordProtected) {
                        // Show the password modal
                        $('#gui').fadeTo(globals.fadeTime, 0.1, () => {
                            const passwordInput = $('#password-input');
                            passwordInput.val('');
                            passwordInput.data('raceId', race.id);
                            passwordInput.data('raceTitle', race.name+'');
                            $('#password-modal').fadeIn(globals.fadeTime);
                            passwordInput.focus();
                        });
                    } else {
                        globals.currentScreen = 'waiting-for-server';
                        globals.conn.send('raceJoin', {
                            id: race.id,
                        });
                    }
                }
            });
        }

        // Make the format tooltip
        let content = '<ul style="margin-bottom: 0;">';

        content += '<li class="lobby-current-races-format-li"><strong><span lang="en">Size</span>:</strong> ';
        if (globals.raceList[race.id].ruleset.solo) {
            content += '<span lang="en">Solo</span><br />';
            content += '<span lang="en">This is a single-player race.</span>';
        } else {
            content += '<span lang="en">Multiplayer</span><br />';
            if (globals.raceList[race.id].isPasswordProtected) {
                content += '<span lang="en">This race is password protected.</span>';
            }
        }
        content += '</li>';

        content += '<li class="lobby-current-races-format-li"><strong><span lang="en">Ranked</span>:</strong> ';
        if (globals.raceList[race.id].ruleset.ranked) {
            content += '<span lang="en">Yes</span><br />';
            content += '<span lang="en">This race will count towards the leaderboards.</span>';
        } else {
            content += '<span lang="en">No</span><br />';
            content += '<span lang="en">This race will not count towards the leaderboards.</span>';
        }
        content += '</li>';

        const { format } = globals.raceList[race.id].ruleset;
        content += '<li class="lobby-current-races-format-li"><strong><span lang="en">Format</span>:</strong> ';
        if (format === 'unseeded') {
            content += '<span lang="en">Unseeded</span><br />';
            content += '<span lang="en">Reset over and over until you find something good from a Treasure Room.</span><br />';
            content += '<span lang="en">You will be playing on an entirely different seed than your opponent(s).</span>';
        } else if (format === 'seeded') {
            content += '<span lang="en">Seeded</span><br />';
            content += '<span lang="en">You will play on the same seed as your opponent and start with The Compass.</span>';
        } else if (format === 'seeded-hard') {
            content += '<span lang="en">Seeded (Hard)</span><br />';
            content += '<span lang="en">You will play on the same seed as your opponent and start with The Compass.</span><br />';
            content += '<span lang="en">You will also play on hard mode.</span><br />';
        } else if (format === 'diversity') {
            content += '<span lang="en">Diversity</span><br />';
            content += '<span lang="en">This is the same as the "Unseeded" format, but you will also start with five random items.</span><br />';
            content += '<span lang="en">All players will start with the same five items.</span>';
        } else if (format === 'unseeded-lite') {
            content += '<span lang="en">Unseeded (Lite)</span><br />';
            content += '<span lang="en">Reset over and over until you find something good from a Treasure Room.</span><br />';
            content += '<span lang="en">You will be playing on an entirely different seed than your opponent(s).</span><br />';
            content += '<span lang="en">Extra changes will also be in effect; see the Racing+ website for details.</span>';
        } else if (format === 'custom') {
            content += '<li><span lang="en">Custom</span><br />';
            content += '<span lang="en">You make the rules! Make sure that everyone in the race knows what to do before you start.</span>';
        }
        content += '</li>';

        const { character } = globals.raceList[race.id].ruleset;
        content += `<li class="lobby-current-races-format-li"><strong><span lang="en">Character</span>:</strong> ${character}</li>`;

        const { goal } = globals.raceList[race.id].ruleset;
        content += `<li class="lobby-current-races-format-li"><strong><span lang="en">Goal</span>:</strong> ${goal}</li>`;

        if (format === 'seeded' || format === 'seeded-hard') {
            const { startingBuild } = globals.raceList[race.id].ruleset;
            content += '<li class="lobby-current-races-format-li"><strong><span lang="en">Starting Build</span>:</strong> ';
            for (const item of builds[startingBuild]) {
                content += `${item.name} + `;
            }
            content = content.slice(0, -3); // Chop off the trailing " + "
            content += '</li>';
        }

        content += '</ul>';
        $(`#lobby-current-races-format-${race.id}`).tooltipster({
            theme: 'tooltipster-shadow',
            delay: 0,
            content,
            contentAsHTML: true,
            functionBefore: () => globals.currentScreen === 'lobby',
        });
    });

    // Now that it has begun to fade in, we can fill it
    raceDrawCheckForOverflow(race.id, 'name');

    // Update the players
    raceUpdatePlayers(race.id);
}

const raceUpdatePlayers = (raceID) => {
    // Draw the new size
    $(`#lobby-current-races-${raceID}-size`).html(globals.raceList[raceID].racers.length);

    // Draw the new racer list
    let racers = '';
    for (const racer of globals.raceList[raceID].racers) {
        if (racer === globals.raceList[raceID].captain) {
            racers += `<strong>${racer}</strong>, `;
        } else {
            racers += `${racer}, `;
        }
    }
    racers = racers.slice(0, -2); // Chop off the trailing comma and space
    $(`#lobby-current-races-${raceID}-racers`).html(racers);

    // Check for overflow in the racer list
    raceDrawCheckForOverflow(raceID, 'racers');
};
exports.raceUpdatePlayers = raceUpdatePlayers;

// Make tooltips for long names if necessary
function raceDrawCheckForOverflow(raceID, target) {
    // Check to make sure that the race hasn't ended in the meantime
    if (typeof $(`#lobby-current-races-${raceID}-${target}`) === 'undefined') {
        const errorMessage = 'The "raceDrawCheckForOverflow" function was called for a race that does not exist anymore.';
        globals.log.info(errorMessage);

        try {
            throw new Error(errorMessage);
        } catch (err) {
            globals.Raven.captureException(err);
        }

        return;
    }

    // Race name column
    let shortened = false;
    let counter = 0; // It is possible to get stuck in the bottom while loop
    while ($(`#lobby-current-races-${raceID}-${target}`)[0].scrollWidth > $(`#lobby-current-races-${raceID}-${target}`).innerWidth()) {
        counter += 1;
        if (counter >= 1000) {
            // Something is weird and the page is not rendering properly
            break;
        }
        const shortenedName = $(`#lobby-current-races-${raceID}-${target}`).html().slice(0, -1);
        $(`#lobby-current-races-${raceID}-${target}`).html(shortenedName);
        shortened = true;
    }
    let content = '';
    if (target === 'name') {
        content = globals.raceList[raceID].name; // This does not need to be escaped because tooltipster displays HTML as plain text
    } else if (target === 'racers') {
        for (const racer of globals.raceList[raceID].racers) {
            content += `${racer}, `;
        }
        content = content.slice(0, -2); // Chop off the trailing comma and space
    }
    if (shortened) {
        const shortenedName = $(`#lobby-current-races-${raceID}-${target}`).html().slice(0, -1); // Make it a bit shorter to account for the padding
        $(`#lobby-current-races-${raceID}-${target}`).html(`${shortenedName}...`);
        if ($(`#lobby-current-races-${raceID}-${target}`).hasClass('tooltipstered')) {
            $(`#lobby-current-races-${raceID}-${target}`).tooltipster('content', content);
        } else {
            $(`#lobby-current-races-${raceID}-${target}`).tooltipster({
                theme: 'tooltipster-shadow',
                delay: 0,
                content,
                contentAsHTML: true,
                functionBefore: () => globals.currentScreen === 'lobby',
            });
        }
    } else if ($(`#lobby-current-races-${raceID}-${target}`).hasClass('tooltipstered')) {
        // Delete any existing tooltips, if they exist
        $(`#lobby-current-races-${raceID}-${target}`).tooltipster('content', null);
    }
}

exports.raceUndraw = (raceID) => {
    $(`#lobby-current-races-${raceID}`).fadeOut(globals.fadeTime, () => {
        $(`#lobby-current-races-${raceID}`).remove();

        if (Object.keys(globals.raceList).length === 0) {
            $('#lobby-current-races-table').fadeOut(0);
            $('#lobby-current-races-table-no').fadeIn(globals.fadeTime);
        }
    });

    // Fix the bug where the "vertical-center" class causes things to be hidden if there is overflow
    if (Object.keys(globals.raceList).length > 4) { // More than 4 races causes the overflow
        $('#lobby-current-races-table-wrapper').removeClass('vertical-center');
    } else {
        $('#lobby-current-races-table-wrapper').addClass('vertical-center');
    }
};

exports.usersDraw = () => {
    // Update the header that shows shows the amount of people online or in the race
    $('#lobby-users-online').html(globals.roomList.lobby.numUsers);

    // Make an array with the name of every user and alphabetize it
    const userList = [];
    for (const user of Object.keys(globals.roomList.lobby.users)) {
        userList.push(user);
    }

    // Case insensitive sort of the connected users
    userList.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

    // Empty the existing list
    $('#lobby-users-users').html('');

    // Add a div for each player
    for (let i = 0; i < userList.length; i++) {
        if (userList[i] === globals.myUsername) {
            const userDiv = `<div>${userList[i]}</div>`;
            $('#lobby-users-users').append(userDiv);
        } else {
            const userDiv = `
                <div id="lobby-users-user-${userList[i]}" class="users-user" data-tooltip-content="#user-click-tooltip">
                    ${userList[i]}
                </div>
            `;
            $('#lobby-users-users').append(userDiv);

            // Add the tooltip (commented out since it doesn't work)
            /*
            $('#lobby-users-' + userList[i]).tooltipster({
                theme: 'tooltipster-shadow',
                trigger: 'click',
                interactive: true,
                side: 'left',
                functionBefore: userTooltipChange(userList[i]),
            });
            */
        }
    }

    /*
    function userTooltipChange(username) {
        $('#user-click-profile').click(() => {
            const url = `${globals.websiteURL}/profile/${username}`;
            shell.openExternal(url);
        });
        $('#user-click-private-message').click(() => {
            const boxContents = `/msg ${username} `;
            if (globals.currentScreen === 'lobby') {
                $('#lobby-chat-box-input').val(boxContents);
                $('#lobby-chat-box-input').focus();
            } else if (globals.currentScreen === 'race') {
                $('#race-chat-box-input').val(boxContents);
                $('#race-chat-box-input').focus();
            } else {
                misc.errorShow(`Failed to fill in the chat box since currentScreen is "${globals.currentScreen}".`);
            }
            misc.closeAllTooltips();
        });
    }
    */
};

const statusTimer = (raceID) => {
    // Stop the timer if the race is over
    // (the race is over if the entry in the raceList is deleted)
    if (!Object.prototype.hasOwnProperty.call(globals.raceList, raceID)) {
        return;
    }
    const race = globals.raceList[raceID];

    // Don't replace anything if this race is not in progress
    if (race.status !== 'in progress') {
        return;
    }

    // Get the elapsed time in the race and set it to the div
    const now = new Date().getTime();
    const raceMilliseconds = now - race.datetimeStarted; // Don't use the offset because we are keeping track of when races start locally
    const raceSeconds = Math.round(raceMilliseconds / 1000);
    const timeDiv = `${misc.pad(parseInt(raceSeconds / 60, 10))}:${misc.pad(raceSeconds % 60)}`;
    $(`#lobby-current-races-${raceID}-status`).html(timeDiv);

    // Update the timer again a second from now
    setTimeout(() => {
        statusTimer(raceID);
    }, 1000);
};
exports.statusTimer = statusTimer;
