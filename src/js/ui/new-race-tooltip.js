/*
    New race tooltip
*/

// Imports
const globals = nodeRequire('./js/globals');
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
    });

    $('#new-race-type').change(newRaceTypeChange);

    $('#new-race-format').change(function newRaceFormatChange() {
        // Change the displayed icon
        const newFormat = $(this).val();
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
            $('#new-race-character').val(newCharacter).change();
        }

        // Show or hide the "Custom" goal
        if (newFormat === 'custom') {
            $('#new-race-goal-custom').fadeIn(0);

            // Make the goal border flash to signify that there are new options there
            const oldColor = $('#new-race-goal').css('border-color');
            $('#new-race-goal').css('border-color', 'green');
            setTimeout(() => {
                $('#new-race-goal').css('border-color', oldColor);
            }, 350); // The CSS is set to 0.3 seconds, so we need some leeway
        } else {
            $('#new-race-goal-custom').fadeOut(0);
            if ($('#new-race-goal').val() === 'custom') {
                $('#new-race-goal').val('Blue Baby').change();
            }
        }

        // Show or hide the character, goal, and starting build row
        if (newFormat === 'seeded') {
            setTimeout(() => {
                $('#new-race-character-container').fadeIn(globals.fadeTime);
                $('#new-race-goal-container').fadeIn(globals.fadeTime);
                $('#new-race-starting-build-container').fadeIn(globals.fadeTime);
                $('#new-race-starting-build').change();
                $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
            }, globals.fadeTime);
        } else {
            const type = $('#new-race-type').val();
            if (type === 'ranked') {
                $('#new-race-character-container').fadeOut(globals.fadeTime);
                $('#new-race-goal-container').fadeOut(globals.fadeTime);
            }
            if ($('#new-race-starting-build-container').is(':visible')) {
                $('#new-race-starting-build-container').fadeOut(globals.fadeTime, () => {
                    $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
                });
            }
        }
    });

    $('#new-race-character').change(function newRaceCharacterChange() {
        // Change the displayed icon
        const newCharacter = $(this).val();
        $('#new-race-character-icon').css('background-image', `url("img/characters/${newCharacter}.png")`);
    });

    $('#new-race-goal').change(function newRaceGoalChange() {
        // Change the displayed icon
        const newGoal = $(this).val();
        $('#new-race-goal-icon').css('background-image', `url("img/goals/${newGoal}.png")`);
    });

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

    $('#new-race-starting-build').change(function newRaceStartingBuildChange() {
        // Change the displayed icon
        const newBuild = $(this).val();
        if (newBuild.startsWith('random')) {
            $('#new-race-starting-build-icon').css('background-image', 'url("img/builds/random.png")');
        } else {
            $('#new-race-starting-build-icon').css('background-image', `url("img/builds/${newBuild}.png")`);
        }
    });

    $('#new-race-form').submit(() => {
        // By default, the form will reload the page, so stop this from happening
        event.preventDefault();

        // Don't do anything if we are not on the right screen
        if (globals.currentScreen !== 'lobby') {
            return false;
        }

        // Get values from the form
        let title = $('#new-race-title').val().trim();
        let type = $('#new-race-type').val();
        const format = $('#new-race-format').val();
        let character = $('#new-race-character').val();
        const goal = $('#new-race-goal').val();
        let startingBuild;
        let solo = false;
        if (type === 'ranked-solo') {
            type = 'ranked';
            solo = true;
        } else if (type === 'unranked-solo') {
            type = 'unranked';
            solo = true;
        }
        if (format === 'seeded') {
            startingBuild = $('#new-race-starting-build').val();
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
            const randomNumber = misc.getRandomNumber(0, 12);
            character = characterArray[randomNumber];
        }

        // If necessary, get a random starting build,
        if (startingBuild === 'random') {
            startingBuild = misc.getRandomNumber(1, 32); // There are 32 starts
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
            type,
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

function newRaceTypeChange() {
    const newType = $('#new-race-type').val();

    // Make the format border flash to signify that there are new options there
    const oldColor = $('#new-race-format').css('border-color');
    $('#new-race-format').css('border-color', 'green');
    setTimeout(() => {
        $('#new-race-format').css('border-color', oldColor);
    }, 350); // The CSS is set to 0.3 seconds, so we need some leeway

    // Change the subsequent options accordingly
    const format = $('#new-race-format').val();
    if (newType === 'ranked-solo') {
        // Change the format dropdown
        $('#new-race-format').val('unseeded').change();
        $('#new-race-character').val('Judas').change();
        $('#new-race-goal').val('Blue Baby').change();

        // Hide the format, character and goal dropdowns if it is not a seeded race
        $('#new-race-format-container').fadeOut(globals.fadeTime);
        $('#new-race-character-container').fadeOut(globals.fadeTime);
        $('#new-race-goal-container').fadeOut(globals.fadeTime, () => {
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        });
    } else if (newType === 'unranked-solo') {
        // Change the format dropdown
        $('#new-race-format-seeded').fadeIn(0);
        $('#new-race-format-diversity').fadeIn(0);
        $('#new-race-format-custom').fadeIn(0);

        // Show the character and goal dropdowns
        setTimeout(() => {
            $('#new-race-format-container').fadeIn(globals.fadeTime);
            $('#new-race-character-container').fadeIn(globals.fadeTime);
            $('#new-race-goal-container').fadeIn(globals.fadeTime);
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        }, globals.fadeTime);
    } else if (newType === 'ranked') {
        // Show the format dropdown
        setTimeout(() => {
            $('#new-race-format-container').fadeIn(globals.fadeTime);
            $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
        }, globals.fadeTime);

        // Change the format dropdown
        if (format === 'diversity' || format === 'custom') {
            $('#new-race-format').val('unseeded').change();
            $('#new-race-character').val('Judas').change();
            $('#new-race-goal').val('Blue Baby').change();
        }
        $('#new-race-format-seeded').fadeIn(0);
        $('#new-race-format-diversity').fadeOut(0);
        $('#new-race-format-custom').fadeOut(0);

        // Hide the character and goal dropdowns if it is not a seeded race
        if (format !== 'seeded') {
            $('#new-race-character-container').fadeOut(globals.fadeTime);
            $('#new-race-goal-container').fadeOut(globals.fadeTime, () => {
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
                $('#new-race-format-container').fadeIn(globals.fadeTime);
                $('#new-race-character-container').fadeIn(globals.fadeTime);
                $('#new-race-goal-container').fadeIn(globals.fadeTime);
                $('#header-new-race').tooltipster('reposition'); // Redraw the tooltip
            }, globals.fadeTime);
        }
    }

    // Change the displayed icon
    $('#new-race-type-icon').css('background-image', `url("img/types/${newType}.png")`);
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
    // Set default background images
    const typeURL = `img/types/${$('#new-race-type').val()}.png`;
    $('#new-race-type-icon').css('background-image', `url("${typeURL}")`);
    const formatURL = `img/formats/${$('#new-race-format').val()}.png`;
    $('#new-race-format-icon').css('background-image', `url("${formatURL}")`);
    const characterURL = `img/characters/${$('#new-race-character').val()}.png`;
    $('#new-race-character-icon').css('background-image', `url("${characterURL}")`);
    const goalURL = `img/goals/${$('#new-race-goal').val()}.png`;
    $('#new-race-goal-icon').css('background-image', `url("${goalURL}")`);

    // Randomize the race title every time we start a new race
    $('#new-race-randomize').click();
    $('#new-race-title').focus();


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
