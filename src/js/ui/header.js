/*
    Header buttons
*/

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const shell = nodeRequire('electron').shell;
const globals = nodeRequire('./js/globals');
const lobbyScreen = nodeRequire('./js/ui/lobby');
const settingsTooltip = nodeRequire('./js/ui/settings-tooltip');
const newRaceTooltip = nodeRequire('./js/ui/new-race-tooltip');

/*
    Header event handlers
*/

$(document).ready(() => {
    /*
        Window control buttons
    */

    $('#header-minimize').click(() => {
        ipcRenderer.send('asynchronous-message', 'minimize');
    });

    $('#header-maximize').click(() => {
        ipcRenderer.send('asynchronous-message', 'maximize');
    });

    $('#header-close').click(() => {
        ipcRenderer.send('asynchronous-message', 'close');
    });

    /*
        Lobby links
    */


    $('#header-profile').click(() => {
        const url = `${globals.websiteURL}/profile/${globals.myUsername}`;
        shell.openExternal(url);
    });

    $('#header-leaderboards').click(() => {
        const url = `${globals.websiteURL}/leaderboards`;
        shell.openExternal(url);
    });

    $('#header-help').click(() => {
        const url = `${globals.websiteURL}/info`;
        shell.openExternal(url);
    });

    /*
        Lobby header buttons
    */

    $('#header-lobby').click(() => {
        // Check to make sure we are actually on the race screen
        if (globals.currentScreen !== 'race') {
            return;
        }

        // Don't allow people to spam this
        const now = new Date().getTime();
        if (now - globals.spamTimer < 1000) {
            return;
        }
        globals.spamTimer = now;

        // Check to see if the race is over
        if (!Object.prototype.hasOwnProperty.call(globals.raceList, globals.currentRaceID)) {
            // The race is over, so we just need to leave the channel
            globals.conn.send('roomLeave', {
                room: `_race_${globals.currentRaceID}`,
            });
            lobbyScreen.showFromRace();
            return;
        }

        // The race is not over, so check to see if it has started yet
        if (globals.raceList[globals.currentRaceID].status === 'open') {
            // The race has not started yet, so leave the race entirely
            globals.conn.send('raceLeave', {
                id: globals.currentRaceID,
            });
            return;
        }

        // The race is not over, so check to see if it is in progress
        if (globals.raceList[globals.currentRaceID].status === 'in progress') {
            // Check to see if we are still racing
            for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
                const racer = globals.raceList[globals.currentRaceID].racerList[i];
                if (racer.name === globals.myUsername) {
                    // We are racing, so check to see if we are allowed to go back to the lobby
                    if (racer.status === 'finished' || racer.status === 'quit') {
                        globals.conn.send('roomLeave', {
                            room: `_race_${globals.currentRaceID}`,
                        });
                        lobbyScreen.showFromRace();
                    }
                    break;
                }
            }
        }
    });

    $('#header-lobby').tooltipster({
        theme: 'tooltipster-shadow',
        delay: 0,
        functionBefore: () => {
            // Check to make sure we are actually on the race screen
            if (globals.currentScreen !== 'race') {
                return false;
            }

            // Check to see if the race is still going
            if (!Object.prototype.hasOwnProperty.call(globals.raceList, globals.currentRaceID)) {
                // The race is over
                return false;
            }

            // The race is not over, so check to see if it has started yet
            if (
                globals.raceList[globals.currentRaceID].status !== 'starting' &&
                globals.raceList[globals.currentRaceID].status !== 'in progress'
            ) {
                // The race has not started yet
                return false;
            }

            // Check to see if we are still racing
            for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
                const racer = globals.raceList[globals.currentRaceID].racerList[i];
                if (racer.name === globals.myUsername) {
                    // We are racing, so check to see if we have finished or quit
                    if (racer.status === 'finished' || racer.status === 'quit') {
                        return false;
                    }
                    break;
                }
            }

            // The race is either starting or in progress
            return true;
        },
    });

    $('#header-new-race').tooltipster({
        theme: 'tooltipster-shadow',
        trigger: 'click',
        interactive: true,
        functionBefore: newRaceTooltip.tooltipFunctionBefore,
        functionReady: newRaceTooltip.tooltipFunctionReady,
    }).tooltipster('instance').on('close', () => {
        // Check if the tooltip is open
        if (!$('#header-settings').tooltipster('status').open) {
            $('#gui').fadeTo(globals.fadeTime, 1);
        }
    });

    $('#header-settings').tooltipster({
        theme: 'tooltipster-shadow',
        trigger: 'click',
        interactive: true,
        functionBefore: settingsTooltip.tooltipFunctionBefore,
        functionReady: settingsTooltip.tooltipFunctionReady,
    }).tooltipster('instance').on('close', () => {
        if (!$('#header-new-race').tooltipster('status').open) {
            $('#gui').fadeTo(globals.fadeTime, 1);
        }
    });

    // Automatically hide the lobby links if the window is resized too far horizontally
    $(window).resize(checkHideLinks);
});

/*
    Header functions
*/

const checkHideLinks = () => {
    if ($(window).width() < 980) {
        $('#header-profile').fadeOut(0);
        $('#header-leaderboards').fadeOut(0);
        $('#header-help').fadeOut(0);
    } else if (globals.currentScreen === 'lobby' || globals.currentScreen === 'race') {
        $('#header-profile').fadeIn(0);
        $('#header-leaderboards').fadeIn(0);
        $('#header-help').fadeIn(0);
    }
};
exports.checkHideLinks = checkHideLinks;
