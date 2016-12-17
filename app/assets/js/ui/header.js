/*
    Header buttons
*/

'use strict';

// Imports
const ipcRenderer     = nodeRequire('electron').ipcRenderer;
const shell           = nodeRequire('electron').shell;
const keytar          = nodeRequire('keytar');
const globals         = nodeRequire('./assets/js/globals');
const settings        = nodeRequire('./assets/js/settings');
const misc            = nodeRequire('./assets/js/misc');
const lobbyScreen     = nodeRequire('./assets/js/ui/lobby');
const settingsTooltip = nodeRequire('./assets/js/ui/settings-tooltip');

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
        let url = 'http' + (globals.secure ? 's' : '') + '://' + globals.domain + '/profiles/' + globals.myUsername;
        shell.openExternal(url);
    });

    $('#header-leaderboards').click(function() {
        let url = 'http' + (globals.secure ? 's' : '') + '://' + globals.domain + '/leaderboards';
        shell.openExternal(url);
    });

    $('#header-help').click(function() {
        let url = 'http' + (globals.secure ? 's' : '') + '://' + globals.domain + '/info';
        shell.openExternal(url);
    });

    /*
        Lobby header buttons
    */

    $('#header-lobby').click(function() {
        if (globals.currentScreen !== 'race') {
            return;
        }

        // Check to see if we should leave the race
        if (globals.raceList.hasOwnProperty(globals.currentRaceID)) {
            if (globals.raceList[globals.currentRaceID].status === 'open') {
                globals.conn.send('raceLeave', {
                    'id': globals.currentRaceID,
                });
            }
        } else {
            lobbyScreen.showFromRace();
        }
    });

    $('#header-lobby').tooltipster({
        theme: 'tooltipster-shadow',
        delay: 0,
        functionBefore: function() {
            if (globals.currentScreen === 'race') {
                if (globals.raceList.hasOwnProperty(globals.currentRaceID)) {
                    if (globals.raceList[globals.currentRaceID].status === 'starting' ||
                        globals.raceList[globals.currentRaceID].status === 'in progress') {

                        // The race has already started
                        return true;
                    } else {
                        // The race has not started yet
                        return false;
                    }
                } else {
                    // The race is finished
                    return false;
                }
            } else {
                // Not on the race screen
                return false;
            }
        },
    });

    $('#header-new-race').tooltipster({
        theme: 'tooltipster-shadow',
        trigger: 'click',
        interactive: true,
        functionBefore: function() {
            if (globals.currentScreen === 'lobby') {
                $('#gui').fadeTo(globals.fadeTime, 0.1);
                return true;
            } else {
                return false;
            }
        },
    }).tooltipster('instance').on('close', function() {
        if ($('#header-settings').tooltipster('status').open === false) {
            $('#gui').fadeTo(globals.fadeTime, 1);
        }
    });
    $('#header-new-race').on('tooltipopen', function(event, ui) {
        $(this).data('tooltip', true);
    });

    $('#header-new-race').click(function() {
        $('#new-race-name').focus();
    });

    $('#header-settings').tooltipster({
        theme: 'tooltipster-shadow',
        trigger: 'click',
        interactive: true,
        functionBefore: settingsTooltip.beforeClick,
    }).tooltipster('instance').on('close', function() {
        if ($('#header-new-race').tooltipster('status').open === false) {
            $('#gui').fadeTo(globals.fadeTime, 1);
        }
    });

    $('#header-log-out').click(function() {
        // Delete their cached credentials, if any
        let storedUsername = settings.get('username');
        if (typeof storedUsername !== 'undefined') {
            let storedPassword = keytar.getPassword('Racing+', storedUsername);
            if (storedPassword !== null) {
                keytar.deletePassword('Racing+', storedUsername);
            }
            settings.set('username', undefined);
            settings.saveSync();
        }

        // Terminate the WebSocket connection (which will trigger the transition back to the title screen)
        globals.initiatedLogout = true;
        globals.conn.close();
    });

    /*
        Start race tooltip
    */

    $('#new-race-randomize').click(function() {
        // Get some random words
        let randomNumbers = [];
        for (let i = 0; i < 3; i++) {
            while (true) {
                let randomNumber = misc.getRandomNumber(0, globals.wordList.length - 1);
                if (randomNumbers.indexOf(randomNumber) === -1) {
                    randomNumbers.push(randomNumber);
                    break;
                }
            }
        }
        let randomlyGeneratedName = '';
        for (let i = 0; i < 3; i++) {
            randomlyGeneratedName += globals.wordList[randomNumbers[i]] + ' ';
        }

        // Chop off the trailing space
        randomlyGeneratedName = randomlyGeneratedName.slice(0, -1);

        // Set it
        $('#new-race-name').val(randomlyGeneratedName);
    });

    $('#new-race-format').change(function() {
        // Change the displayed icon
        let newFormat = $(this).val();
        $('#new-race-format-icon').css('background-image', 'url("assets/img/formats/' + newFormat + '.png")');

        // Change to the default character for this ruleset
        let newCharacter;
        if ($(this).val() === 'unseeded') {
            newCharacter = 'Judas';
        } else if ($(this).val() === 'seeded') {
            newCharacter = 'Judas';
        } else if ($(this).val() === 'diversity') {
            newCharacter = 'Cain';
        }
        if ($('#new-race-character').val() !== newCharacter) {
            $('#new-race-character').val(newCharacter);
            $('#new-race-character-icon').css('background-image', 'url("assets/img/characters/' + newCharacter + '.png")');
        }

        // Show or hide the starting build row
        if ($(this).val() === 'seeded') {
            $('#new-race-starting-build-1').fadeIn(globals.fadeTime);
            $('#new-race-starting-build-2').fadeIn(globals.fadeTime);
            $('#new-race-starting-build-3').fadeIn(globals.fadeTime);
        } else {
            $('#new-race-starting-build-1').fadeOut(globals.fadeTime);
            $('#new-race-starting-build-2').fadeOut(globals.fadeTime);
            $('#new-race-starting-build-3').fadeOut(globals.fadeTime);
        }
    });

    $('#new-race-character').change(function() {
        // Change the displayed icon
        let newCharacter = $(this).val();
        $('#new-race-character-icon').css('background-image', 'url("assets/img/characters/' + newCharacter + '.png")');
    });

    $('#new-race-goal').change(function() {
        // Change the displayed icon
        let newGoal = $(this).val();
        $('#new-race-goal-icon').css('background-image', 'url("assets/img/goals/' + newGoal + '.png")');
    });

    $('#new-race-starting-build').change(function() {
        // Change the displayed icon
        let newBuild = $(this).val();
        $('#new-race-starting-build-icon').css('background-image', 'url("assets/img/builds/' + newBuild + '.png")');
    });

    $('#new-race-form').submit(function() {
        // Don't do anything if we are not on the right screen
        if (globals.currentScreen !== 'lobby') {
            return;
        }

        // Get values from the form
        let name = $('#new-race-name').val().trim();
        let format = $('#new-race-format').val();
        let character = $('#new-race-character').val();
        let goal = $('#new-race-goal').val();
        let startingBuild;
        if (format === 'seeded') {
            startingBuild = $('#new-race-starting-build').val();
        } else {
            startingBuild = -1;
        }

        // Truncate names longer than 100 characters (this is also enforced server-side)
        let maximumLength = 100;
        if (name.length > maximumLength) {
            name = name.substring(0, maximumLength);
        }

        // If necessary, get a random character
        if (character === 'Random') {
            let characterArray = [
                'Isaac',     // 0
                'Magdalene', // 1
                'Cain',      // 2
                'Judas',     // 3
                'Blue Baby', // 4
                'Eve',       // 5
                'Samson',    // 6
                'Azazel',    // 7
                'Lazarus',   // 8
                'Eden',      // 9
                'The Lost',  // 10
                'Lilith',    // 11
                'Keeper',    // 12
            ];
            let randomNumber = misc.getRandomNumber(0, 12);
            character = characterArray[randomNumber];
        }

        // If necessary, get a random starting build,
        if (startingBuild === 'Random') {
            // There are 31 builds in the Instant Start Mod
            startingBuild = misc.getRandomNumber(1, 31);
        } else {
            // The value was read from the form as a string and needs to be sent to the server as an intenger
            startingBuild = parseInt(startingBuild);
        }

        // Close the tooltip
        $('#header-new-race').tooltipster('close');

        // Create the race
        let rulesetObject = {
            'format': format,
            'character': character,
            'goal': goal,
            'startingBuild': startingBuild,
        };
        globals.currentScreen = 'waiting-for-server';
        globals.conn.send('raceCreate', {
            'name': name,
            'ruleset': rulesetObject,
        });

        // Return false or else the form will submit and reload the page
        return false;
    });
});
