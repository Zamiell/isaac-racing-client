/*
    New race tooltip
*/

// Imports
const globals = nodeRequire('./js/globals');
const settings = nodeRequire('./js/settings');
const misc = nodeRequire('./js/misc');
const builds = nodeRequire('./data/builds');

/*
    Event handlers
*/

$(document).ready(() => {
    $('#new-race-randomize').click(() => {
        // Don't randomize the race name if we are on a test account
        if (globals.myUsername.match(/TestAccount\d+/)) {
            $('#new-race-title').val('{ test race }');
            return;
        }

        // Get some random words
        const randomNumbers = [];
        const numWords = 2;
        for (let i = 0; i < numWords; i++) {
            let randomNumber;
            do {
                randomNumber = misc.getRandomNumber(0, globals.wordList.length - 1);
            } while (randomNumbers.indexOf(randomNumber) !== -1);
            randomNumbers.push(randomNumber);
        }
        let randomlyGeneratedName = '';
        for (let i = 0; i < numWords; i++) {
            randomlyGeneratedName += `${globals.wordList[randomNumbers[i]]} `;
        }

        // Chop off the trailing space
        randomlyGeneratedName = randomlyGeneratedName.slice(0, -1);

        // Set it
        $('#new-race-title').val(randomlyGeneratedName);

        // Keep track of the last randomly generated name so that we know if they user changes it
        globals.lastRaceTitle = randomlyGeneratedName;

        // Mark that we should use randomly generated names from now on
        settings.set('newRaceTitle', ''); // An empty string means to use the random name generator
        settings.saveSync();
    });

    $('#new-race-type').change(newRaceTypeChange);

    $('#new-race-format').change(newRaceFormatChange);

    $('#new-race-character').change(newRaceCharacterChange);

    $('#new-race-goal').change(newRaceGoalChange);

    // Add the options to the starting build dropdown
    for (let i = 0; i < builds.length; i++) {
        // The 0th element is an empty array
        if (i === 0) {
            continue;
        }

        // Compile the build description string
        let description = '';
        for (const item of builds[i]) {
            description += `${item.name} + `;
        }
        description = description.slice(0, -3); // Chop off the trailing " + "

        // Add the option for this build
        $('#new-race-starting-build').append($('<option></option>').val(i).html(description));
    }

    $('#new-race-starting-build').change(newRaceStartingBuildChange);

    $('#new-race-form').submit((event) => {
        // By default, the form will reload the page, so stop this from happening
        event.preventDefault();

        // Don't do anything if we are not on the right screen
        if (globals.currentScreen !== 'lobby') {
            return false;
        }

        // Get values from the form and update the stored defaults in the settings.json file if necessary
        let title = $('#new-race-title').val().trim();
        if (title !== globals.lastRaceTitle) {
            settings.set('newRaceTitle', title); // An empty string means to use the random name generator
            settings.saveSync();
        }
        const type = $('#new-race-type').val();
        if (type !== settings.get('newRaceType')) {
            settings.set('newRaceType', type);
            settings.saveSync();
        }
        const format = $('#new-race-format').val();
        if (format !== settings.get('newRaceFormat')) {
            settings.set('newRaceFormat', format);
            settings.saveSync();
        }
        let character = $('#new-race-character').val();
        if (character !== settings.get('newRaceCharacter')) {
            settings.set('newRaceCharacter', character);
            settings.saveSync();
        }
        const goal = $('#new-race-goal').val();
        if (goal !== settings.get('newRaceGoal')) {
            settings.set('newRaceGoal', goal);
            settings.saveSync();
        }

        let ranked;
        let solo;
        if (type === 'ranked-solo') {
            ranked = true;
            solo = true;
        } else if (type === 'unranked-solo') {
            ranked = false;
            solo = true;
        } else if (type === 'ranked') {
            ranked = true;
            solo = false;
        } else if (type === 'unranked') {
            ranked = false;
            solo = false;
        }

        let startingBuild;
        if (format === 'seeded') {
            startingBuild = $('#new-race-starting-build').val();
            if (startingBuild !== settings.get('newRaceBuild')) {
                settings.set('newRaceBuild', startingBuild);
                settings.saveSync();
            }
        } else {
            startingBuild = -1;
        }

        // Validate that they are not creating a race with the same title as an existing race
        for (const raceID of Object.keys(globals.raceList)) {
            if (globals.raceList[raceID].name === title) {
                $('#new-race-title').tooltipster('open');
                return false;
            }
        }
        $('#new-race-title').tooltipster('close');

        // Truncate names longer than 100 characters (this is also enforced server-side)
        const maximumLength = 100;
        if (title.length > maximumLength) {
            title = title.substring(0, maximumLength);
        }

        // If necessary, get a random character
        if (character === 'random') {
            const characterArray = [
                'Isaac', // 0
                'Magdalene', // 1
                'Cain', // 2
                'Judas', // 3
                'Blue Baby', // 4
                'Eve', // 5
                'Samson', // 6
                'Azazel', // 7
                'Lazarus', // 8
                'Eden', // 9
                'The Lost', // 10
                'Lilith', // 11
                'Keeper', // 12
                'Apollyon', // 13
                'Samael', // 14
            ];
            const randomNumber = misc.getRandomNumber(0, characterArray.length - 1);
            character = characterArray[randomNumber];
        }

        // If necessary, get a random starting build,
        if (startingBuild === 'random') {
            startingBuild = misc.getRandomNumber(1, builds.length);
        } else if (startingBuild === 'random-single') {
            startingBuild = misc.getRandomNumber(1, 26); // There are 26 starts that have single items
        } else if (startingBuild === 'random-treasure') {
            startingBuild = misc.getRandomNumber(1, 20); // There are 20 Treasure Room starts
        } else {
            // The value was read from the form as a string and needs to be sent to the server as an intenger
            startingBuild = parseInt(startingBuild, 10);
        }

        // Close the tooltip (and all error tooltips, if present)
        misc.closeAllTooltips();

        // Create the race
        const rulesetObject = {
            ranked,
            solo,
            format,
            character,
            goal,
            startingBuild,
        };
        globals.currentScreen = 'waiting-for-server';
        globals.conn.send('raceCreate', {
            name: title,
            ruleset: rulesetObject,
        });

        // Return false or else the form will submit and reload the page
        return false;
    });
});

/*
    New race tooltip functions
*/

function newRaceTypeChange(event, fast = false) {
    const newType = $('#new-race-type').val();

    // Make the format border flash to signify that there are new options there
    if (!fast) {
        const oldColor = $('#new-race-format').css('border-color');
        $('#new-race-format').css('border-color', 'green');
        setTimeout(() => {
            $('#new-race-format').css('border-color', oldColor);
        }, 350); // The CSS is set to 0.3 seconds, so we need some leeway
    }

    // Change the subsequent options accordingly
    const format = $('#new-race-format').val();
    if (newType === 'ranked-solo') {
        // Change the format dropdown
        $('#new-race-format').val('unseeded');
        newRaceFormatChange(null, fast);
        $('#new-race-character').val('Judas');
        newRaceCharacterChange(null, fast);
        $('#new-race-goal').val('Blue Baby');
        newRaceGoalChange(null, fast);

        // Hide the format, character and goal dropdowns if it is not a seeded race
        $('#new-race-format-container').fadeOut((fast ? 0 : globals.fadeTime));
        $('#new-race-character-container').fadeOut((fast ? 0 : globals.fadeTime));
        $('#new-race-goal-container').fadeOut((fast ? 0 : globals.fadeTime), () => {
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        });
    } else if (newType === 'unranked-solo') {
        // Change the format dropdown
        $('#new-race-format-seeded').fadeIn(0);
        $('#new-race-format-diversity').fadeIn(0);
        $('#new-race-format-custom').fadeIn(0);

        // Show the character and goal dropdowns
        setTimeout(() => {
            $('#new-race-format-container').fadeIn((fast ? 0 : globals.fadeTime));
            $('#new-race-character-container').fadeIn((fast ? 0 : globals.fadeTime));
            $('#new-race-goal-container').fadeIn((fast ? 0 : globals.fadeTime));
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        }, (fast ? 0 : globals.fadeTime));
    } else if (newType === 'ranked') {
        // Show the format dropdown
        setTimeout(() => {
            $('#new-race-format-container').fadeIn((fast ? 0 : globals.fadeTime));
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        }, (fast ? 0 : globals.fadeTime));

        // Change the format dropdown
        if (format === 'diversity' || format === 'custom') {
            $('#new-race-format').val('unseeded');
            newRaceFormatChange(null, fast);
            $('#new-race-character').val('Judas');
            newRaceCharacterChange(null, fast);
            $('#new-race-goal').val('Blue Baby');
            newRaceGoalChange(null, fast);
        }
        $('#new-race-format-seeded').fadeIn(0);
        $('#new-race-format-diversity').fadeOut(0);
        $('#new-race-format-custom').fadeOut(0);

        // Hide the character and goal dropdowns if it is not a seeded race
        if (format !== 'seeded') {
            $('#new-race-character-container').fadeOut((fast ? 0 : globals.fadeTime));
            $('#new-race-goal-container').fadeOut((fast ? 0 : globals.fadeTime), () => {
                $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
            });
        }
    } else if (newType === 'unranked') {
        // Change the format dropdown
        $('#new-race-format-diversity').fadeIn(0);
        $('#new-race-format-custom').fadeIn(0);

        // Show the character and goal dropdowns (if it is a seeded race, they should be already shown)
        if (format !== 'seeded') {
            setTimeout(() => {
                $('#new-race-format-container').fadeIn((fast ? 0 : globals.fadeTime));
                $('#new-race-character-container').fadeIn((fast ? 0 : globals.fadeTime));
                $('#new-race-goal-container').fadeIn((fast ? 0 : globals.fadeTime));
                $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
            }, (fast ? 0 : globals.fadeTime));
        }
    }

    // Change the displayed icon
    $('#new-race-type-icon').css('background-image', `url("img/types/${newType}.png")`);
}

function newRaceFormatChange(event, fast = false) {
    // Change the displayed icon
    const newFormat = $('#new-race-format').val();
    $('#new-race-format-icon').css('background-image', `url("img/formats/${newFormat}.png")`);

    // Change to the default character for this ruleset
    let newCharacter;
    if (newFormat === 'unseeded') {
        newCharacter = 'Judas';
    } else if (newFormat === 'seeded') {
        newCharacter = 'Judas';
    } else if (newFormat === 'diversity') {
        newCharacter = 'Judas';
    } else if (newFormat === 'unseeded-lite') {
        newCharacter = 'Judas';
    } else if (newFormat === 'custom') {
        // The custom format has no default character, so don't change anything
        newCharacter = $('#new-race-character').val();
    } else {
        misc.errorShow('That is an unknown format.');
    }
    if ($('#new-race-character').val() !== newCharacter) {
        $('#new-race-character').val(newCharacter);
        newRaceCharacterChange(null, fast);
    }

    // Show or hide the "Custom" goal
    if (newFormat === 'custom') {
        $('#new-race-goal-custom').fadeIn(0);

        // Make the goal border flash to signify that there are new options there
        if (!fast) {
            const oldColor = $('#new-race-goal').css('border-color');
            $('#new-race-goal').css('border-color', 'green');
            setTimeout(() => {
                $('#new-race-goal').css('border-color', oldColor);
            }, 350); // The CSS is set to 0.3 seconds, so we need some leeway
        }
    } else {
        $('#new-race-goal-custom').fadeOut(0);
        if ($('#new-race-goal').val() === 'custom') {
            $('#new-race-goal').val('Blue Baby');
            newRaceGoalChange(null, fast);
        }
    }

    // Show or hide the character, goal, and starting build row
    if (newFormat === 'seeded') {
        setTimeout(() => {
            $('#new-race-character-container').fadeIn((fast ? 0 : globals.fadeTime));
            $('#new-race-goal-container').fadeIn((fast ? 0 : globals.fadeTime));
            $('#new-race-starting-build-container').fadeIn((fast ? 0 : globals.fadeTime));
            newRaceStartingBuildChange(null, fast);
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        }, (fast ? 0 : globals.fadeTime));
    } else {
        const type = $('#new-race-type').val();
        if (type === 'ranked') {
            $('#new-race-character-container').fadeOut((fast ? 0 : globals.fadeTime));
            $('#new-race-goal-container').fadeOut((fast ? 0 : globals.fadeTime));
        }
        if ($('#new-race-starting-build-container').is(':visible')) {
            $('#new-race-starting-build-container').fadeOut((fast ? 0 : globals.fadeTime), () => {
                $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
            });
        }
    }
}

function newRaceCharacterChange(event, fast = false) {
    // Change the displayed icon
    const newCharacter = $('#new-race-character').val();
    $('#new-race-character-icon').css('background-image', `url("img/characters/${newCharacter}.png")`);
}

function newRaceGoalChange(event, fast = false) {
    // Change the displayed icon
    const newGoal = $('#new-race-goal').val();
    $('#new-race-goal-icon').css('background-image', `url("img/goals/${newGoal}.png")`);
}

function newRaceStartingBuildChange(event, fast = false) {
    // Change the displayed icon
    const newBuild = $('#new-race-starting-build').val();
    if (newBuild.startsWith('random')) {
        $('#new-race-starting-build-icon').css('background-image', 'url("img/builds/random.png")');
    } else {
        $('#new-race-starting-build-icon').css('background-image', `url("img/builds/${newBuild}.png")`);
    }
}

// The "functionBefore" function for Tooltipster
exports.tooltipFunctionBefore = () => {
    if (globals.currentScreen !== 'lobby') {
        return false;
    }

    $('#gui').fadeTo(globals.fadeTime, 0.1);
    return true;
};

// The "functionReady" function for Tooltipster
exports.tooltipFunctionReady = () => {
    // Load the default settings from the settings.json file
    // and hide or show some rows based on the race type and format
    // (the first argument is "event", the second argument is "fast")
    const newRaceTitle = settings.get('newRaceTitle');
    if (newRaceTitle === '') {
        // Randomize the race title
        $('#new-race-randomize').click();
    } else {
        $('#new-race-title').val(newRaceTitle);
        globals.lastRaceTitle = newRaceTitle;
    }
    $('#new-race-type').val(settings.get('newRaceType'));
    newRaceTypeChange(null, true);
    $('#new-race-format').val(settings.get('newRaceFormat'));
    newRaceFormatChange(null, true);
    $('#new-race-character').val(settings.get('newRaceCharacter'));
    newRaceCharacterChange(null, true);
    $('#new-race-goal').val(settings.get('newRaceGoal'));
    newRaceGoalChange(null, true);
    $('#new-race-starting-build').val(settings.get('newRaceBuild'));
    newRaceStartingBuildChange(null, true);
    // (the change functions have to be interspersed here, otherwise the format change would overwrite the character change)

    // Focus the race title box
    // (we have to wait 1 millisecond because the above code that changes rows will wrest focus away)
    setTimeout(() => {
        $('#new-race-title').focus();
    }, 1);

    /*
        Tooltips within tooltips seem to be buggy and can sometimes be uninitialized
        So, check for this every time the tooltip is opened and reinitialize them if necessary
    */

    if (!$('#new-race-title').hasClass('tooltipstered')) {
        $('#new-race-title').tooltipster({
            theme: 'tooltipster-shadow',
            delay: 0,
            trigger: 'custom',
        });
    }
};
