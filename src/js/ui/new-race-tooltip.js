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

    $('#new-race-size-solo').change(newRaceSizeChange);
    $('#new-race-size-multiplayer').change(newRaceSizeChange);

    $('#new-race-ranked-no').change(newRaceRankedChange);
    $('#new-race-ranked-yes').change(newRaceRankedChange);

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
        const size = $('input[name=new-race-size]:checked').val();
        if (size !== settings.get('newRaceSize')) {
            settings.set('newRaceSize', size);
            settings.saveSync();
        }
        let ranked = $('input[name=new-race-ranked]:checked').val();
        if (ranked !== settings.get('newRaceRanked')) {
            settings.set('newRaceRanked', ranked);
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

        // The server expects "solo" and "ranked" as bools
        let solo;
        if (size === 'solo') {
            solo = true;
        } else if (size === 'multiplayer') {
            solo = false;
        } else {
            misc.errorShow('Expected either "solo" or "multiplayer" for the value of size.');
        }
        if (ranked === 'yes') {
            ranked = true;
        } else if (ranked === 'no') {
            ranked = false;
        } else {
            misc.errorShow('Expected either "yes" or "no" for the value of ranked.');
        }

        let startingBuild;
        if (format === 'seeded' || format === 'seeded-hard') {
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

        // Truncate names longer than 100 characters
        // (this is also enforced server-side)
        const maximumLength = 100;
        if (title.length > maximumLength) {
            title = title.substring(0, maximumLength);
        }

        // If necessary, get a random character
        if (character === 'random') {
            // We can't reuse the object in "characters.js",
            // because it contains Lazarus II and Dark Judas
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

function newRaceSizeChange(event, fast = false) {
    // Change the displayed icon
    const newSize = $('input[name=new-race-size]:checked').val();
    if (newSize === 'solo') {
        $('#new-race-size-icon-solo').fadeIn((fast ? 0 : globals.fadeTime));
        $('#new-race-size-icon-multiplayer').fadeOut((fast ? 0 : globals.fadeTime));
    } else if (newSize === 'multiplayer') {
        $('#new-race-size-icon-solo').fadeOut((fast ? 0 : globals.fadeTime));
        $('#new-race-size-icon-multiplayer').fadeIn((fast ? 0 : globals.fadeTime));
    }
    $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
}

function newRaceRankedChange(event, fast = false) {
    // Change the displayed icon
    const newRanked = $('input[name=new-race-ranked]:checked').val();
    $('#new-race-ranked-icon').css('background-image', `url("img/ranked/${newRanked}.png")`);

    // Make the format border flash to signify that there are new options there
    if (newRanked === 'no' && !fast) {
        const oldColor = $('#new-race-format').css('border-color');
        $('#new-race-format').css('border-color', 'green');
        setTimeout(() => {
            $('#new-race-format').css('border-color', oldColor);
        }, 350); // The CSS is set to 0.3 seconds, so we need some leeway
    }

    // Change the subsequent options accordingly
    const format = $('#new-race-format').val();
    if (newRanked === 'no') {
        // Show the non-standard formats
        $('#new-race-format-diversity').fadeIn(0);
        $('#new-race-format-unseeded-lite').fadeIn(0);
        $('#new-race-format-seeded-hard').fadeIn(0);
        $('#new-race-format-custom').fadeIn(0);

        // Show the character and goal dropdowns
        setTimeout(() => {
            $('#new-race-character-container').fadeIn((fast ? 0 : globals.fadeTime));
            $('#new-race-goal-container').fadeIn((fast ? 0 : globals.fadeTime));
            if (format === 'seeded' || format === 'seeded-hard') {
                $('#new-race-starting-build-container').fadeIn((fast ? 0 : globals.fadeTime));
            }
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        }, (fast ? 0 : globals.fadeTime));
    } else if (newRanked === 'yes') {
        // Hide the non-standard formats
        $('#new-race-format-diversity').fadeOut(0);
        $('#new-race-format-unseeded-lite').fadeOut(0);
        $('#new-race-format-seeded-hard').fadeOut(0);
        $('#new-race-format-custom').fadeOut(0);

        // Hide the character, goal, and build dropdowns
        $('#new-race-character-container').fadeOut((fast ? 0 : globals.fadeTime));
        $('#new-race-starting-build-container').fadeOut((fast ? 0 : globals.fadeTime)); // This is above the "goal" container below because it may already be hidden and would mess up the callback
        $('#new-race-goal-container').fadeOut((fast ? 0 : globals.fadeTime), () => {
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        });

        // There are only unseeded and seeded formats in ranked races
        if (format !== 'unseeded' && format !== 'seeded') {
            $('#new-race-format').val('unseeded');
            newRaceFormatChange(null, fast);
        }

        // Set default values for the character, goal, and build dropdowns
        const rankedCharacter = 'Judas';
        if ($('#new-race-character').val() !== rankedCharacter) {
            $('#new-race-character').val(rankedCharacter);
            newRaceCharacterChange(null, fast);
        }
        const rankedGoal = 'Blue Baby';
        if ($('#new-race-goal').val() !== rankedGoal) {
            $('#new-race-goal').val(rankedGoal);
            newRaceGoalChange(null, fast);
        }
        const rankedBuild = 'random';
        if ($('#new-race-starting-build').val() !== rankedBuild) {
            $('#new-race-starting-build').val(rankedBuild);
            newRaceStartingBuildChange(null, fast);
        }
    }
}

function newRaceFormatChange(event, fast = false) {
    // Change the displayed icon
    const newFormat = $('#new-race-format').val();
    $('#new-race-format-icon').css('background-image', `url("img/formats/${newFormat}.png")`);

    // Show or hide the starting build row
    const ranked = $('input[name=new-race-ranked]:checked').val();
    if ((newFormat === 'seeded' || newFormat === 'seeded-hard') && ranked === 'no') {
        setTimeout(() => {
            $('#new-race-starting-build-container').fadeIn((fast ? 0 : globals.fadeTime));
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        }, (fast ? 0 : globals.fadeTime));
    } else if ($('#new-race-starting-build-container').is(':visible')) {
        $('#new-race-starting-build-container').fadeOut((fast ? 0 : globals.fadeTime), () => {
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        });
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

    $(`#new-race-size-${settings.get('newRaceSize')}`).prop('checked', true);
    newRaceSizeChange(null, true);
    $(`#new-race-ranked-${settings.get('newRaceRanked')}`).prop('checked', true);
    newRaceRankedChange(null, true);
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
