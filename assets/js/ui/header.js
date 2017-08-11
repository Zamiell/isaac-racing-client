/*
    Header buttons
*/

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const shell = nodeRequire('electron').shell;
const globals = nodeRequire('./assets/js/globals');
const lobbyScreen = nodeRequire('./assets/js/ui/lobby');
const settingsTooltip = nodeRequire('./assets/js/ui/settings-tooltip');
const newRaceTooltip = nodeRequire('./assets/js/ui/new-race-tooltip');

/*
    Header event handlers
*/

$(document).ready(function() {
    /*
        Window control buttons
    */

    $('#header-minimize').click(function() {
        ipcRenderer.send('asynchronous-message', 'minimize');
    });

    $('#header-maximize').click(function() {
        ipcRenderer.send('asynchronous-message', 'maximize');
    });

    $('#header-close').click(function() {
        ipcRenderer.send('asynchronous-message', 'close');
    });

    /*
        Lobby links
    */

    $('#header-profile').click(function() {
        const url = 'http' + (globals.secure ? 's' : '') + '://' + (globals.localhost ? 'localhost' : globals.domain) + '/profile/' + globals.myUsername;
        shell.openExternal(url);
    });

    $('#header-leaderboards').click(function() {
        const url = 'http' + (globals.secure ? 's' : '') + '://' + (globals.localhost ? 'localhost' : globals.domain) + '/leaderboards';
        shell.openExternal(url);
    });

    $('#header-help').click(function() {
        const url = 'http' + (globals.secure ? 's' : '') + '://' + (globals.localhost ? 'localhost' : globals.domain) + '/info';
        shell.openExternal(url);
    });

    /*
        Lobby header buttons
    */

    $('#header-lobby').click(function() {
        // Check to make sure we are actually on the race screen
        if (globals.currentScreen !== 'race') {
            return;
        }

        // Don't allow people to spam this
        let now = new Date().getTime();
        if (now - globals.spamTimer < 1000) {
            return;
        } else {
            globals.spamTimer = now;
        }

        // Check to see if the race is over
        if (globals.raceList.hasOwnProperty(globals.currentRaceID) === false) {
            // The race is over, so we just need to leave the channel
            globals.conn.send('roomLeave', {
                room: '_race_' + globals.currentRaceID,
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
               let racer = globals.raceList[globals.currentRaceID].racerList[i];
               if (racer.name === globals.myUsername) {
                   // We are racing, so check to see if we are allowed to go back to the lobby
                   if (racer.status === 'finished' || racer.status === 'quit') {
                       globals.conn.send('roomLeave', {
                           room: '_race_' + globals.currentRaceID,
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
        functionBefore: function() {
            // Check to make sure we are actually on the race screen
            if (globals.currentScreen !== 'race') {
                return false;
            }

            // Check to see if the race is still going
            if (globals.raceList.hasOwnProperty(globals.currentRaceID) === false) {
                // The race is over
                return false;
            }

            // The race is not over, so check to see if it has started yet
            if (globals.raceList[globals.currentRaceID].status !== 'starting' &&
                globals.raceList[globals.currentRaceID].status !== 'in progress') {

                // The race has not started yet
                return false;
            }

            // Check to see if we are still racing
            for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
                let racer = globals.raceList[globals.currentRaceID].racerList[i];
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
    }).tooltipster('instance').on('close', function() {
        // Check if the tooltip is open
        if ($('#header-settings').tooltipster('status').open === false) {
            $('#gui').fadeTo(globals.fadeTime, 1);
        }
    });

    $('#header-settings').tooltipster({
        theme: 'tooltipster-shadow',
        trigger: 'click',
        interactive: true,
        functionBefore: settingsTooltip.tooltipFunctionBefore,
        functionReady: settingsTooltip.tooltipFunctionReady,
    }).tooltipster('instance').on('close', function() {
        if ($('#header-new-race').tooltipster('status').open === false) {
            $('#gui').fadeTo(globals.fadeTime, 1);
        }
    });

    // Automatically hide the lobby links if the window is resized too far horizontally
    $(window).resize(checkHideLinks);
});

/*
    Header functions
*/

const checkHideLinks = function() {
    if ($(window).width() < 980) {
        $('#header-profile').fadeOut(0);
        $('#header-leaderboards').fadeOut(0);
        $('#header-help').fadeOut(0);
    } else {
        if (globals.currentScreen === 'lobby' || globals.currentScreen === 'race') {
            $('#header-profile').fadeIn(0);
            $('#header-leaderboards').fadeIn(0);
            $('#header-help').fadeIn(0);
        }
    }
};
exports.checkHideLinks = checkHideLinks;
