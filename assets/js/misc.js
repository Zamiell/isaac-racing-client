/*
    Miscellaneous functions
*/

'use strict';

// Imports
const fs       = nodeRequire('fs');
const globals  = nodeRequire('./assets/js/globals');
const settings = nodeRequire('./assets/js/settings');

exports.debug = function() {
    // The "/debug" command
    globals.log.info('Entering debug function.');

    //errorShow('debug');
    //console.log(raceList);
    //console.log(currentRaceID);
    globals.conn.send('debug');
};

// Create a custom error type so that the Raven dataCallback knows not to go back to the errorShow function
// The new error object will prototypically inherit from the Error constructor
// From: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error
function RavenMiscError(message) {
    this.name = 'RavenMiscError';
    this.message = message || 'Default Message';
    this.stack = (new Error()).stack;
}
RavenMiscError.prototype = Object.create(Error.prototype);
RavenMiscError.prototype.constructor = RavenMiscError;

const errorShow = function(message, sendToSentry = true, alternateScreen = false) {
    // Come back in a second if we are still in a transition
    if (globals.currentScreen === 'transition') {
        setTimeout(function() {
            errorShow(message, sendToSentry, alternateScreen);
        }, globals.fadeTime + 5); // 5 milliseconds of leeway
        return;
    }

    // Log the message
    if (message !== '') {
        globals.log.error(message);
    } else {
        globals.log.error('Generic error.');
    }

    // Also send it to Sentry
    if (sendToSentry) {
        try {
            throw new RavenMiscError(message);
        } catch (err) {
            globals.Raven.captureException(err);
        }
    }

    // Don't do anything if we are already showing an error
    if (globals.currentScreen === 'error') {
        return;
    }
    globals.currentScreen = 'error';

    // Disconnect from the server, if connected
    if (globals.conn !== null) {
        globals.conn.close();
    }

    // Hide the links in the header
    $('#header-profile').fadeOut(globals.fadeTime);
    $('#header-leaderboards').fadeOut(globals.fadeTime);
    $('#header-help').fadeOut(globals.fadeTime);

    // Hide the buttons in the header
    $('#header-lobby').fadeOut(globals.fadeTime);
    $('#header-new-race').fadeOut(globals.fadeTime);
    $('#header-settings').fadeOut(globals.fadeTime);

    // Close all tooltips
    closeAllTooltips();

    $('#gui').fadeTo(globals.fadeTime, 0.1, function() {
        if (alternateScreen === true) {
            // Show the log file selector screen
            $('#log-file-modal').fadeIn(globals.fadeTime);
        } else {
            // Show the error modal
            $('#error-modal').fadeIn(globals.fadeTime);
            $('#error-modal-description').html(message);
        }
    });
};
exports.errorShow = errorShow;

const warningShow = function(message) {
    // Come back in a second if we are still in a transition
    if (globals.currentScreen === 'transition') {
        setTimeout(function() {
            warningShow(message);
        }, globals.fadeTime + 5); // 5 milliseconds of leeway
        return;
    }

    // Log the message
    globals.log.warn(message);

    // Don't do anything if we are already showing a warning
    if (globals.currentScreen === 'warning') {
        return;
    }
    globals.currentScreen = 'warning';

    // Close all tooltips
    closeAllTooltips();

    // Show the warning modal
    $('#gui').fadeTo(globals.fadeTime, 0.1, function() {
        $('#warning-modal').fadeIn(globals.fadeTime);
        $('#warning-modal-description').html(message);
    });
};
exports.warningShow = warningShow;

exports.playSound = function(path, exclusive = false) {
    // First check to see if sound is disabled
    let volume = settings.get('volume');
    if (volume === 0) {
        return;
    }

    if (exclusive !== false) {
        // For some sound effects, we only want one of them playing at once to prevent confusion
        if (globals.playingSound === true) {
            return; // Do nothing if we are already playing a sound
        }

        globals.playingSound = true;
        setTimeout(function() {
            globals.playingSound = false;
        }, exclusive); // The 2nd argument to the function should be the length of the sound effect in milliseconds
    }

    // Sometimes this can give "net::ERR_REQUEST_RANGE_NOT_SATISFIABLE" for some reason
    // (might be related to having multiple Electron apps trying to play the same sound at the same time)
    let fullPath = 'assets/sounds/' + path + '.mp3';
    try {
        let audio = new Audio(fullPath);
        audio.volume = volume;
        audio.play();
        globals.log.info('Played "' + fullPath + '".');
    } catch(err) {
        globals.log.info('Failed to play "' + fullPath + '":', err);
    }
};

exports.findAjaxError = function(jqXHR) {
    if (jqXHR.readyState === 0) {
        return 'A network error occured. The server might be down!';
    } else if (jqXHR.responseText === '') {
        return 'An unknown error occured.';
    } else {
        return jqXHR.responseText;
    }
};

const closeAllTooltips = function() {
    let instances = $.tooltipster.instances();
    $.each(instances, function(i, instance){
        instance.close();
    });
};
exports.closeAllTooltips = closeAllTooltips;

// From: https://stackoverflow.com/questions/20822273/best-way-to-get-folder-and-file-list-in-javascript
exports.getAllFilesFromFolder = function(dir) {
    let results = [];
    fs.readdirSync(dir).forEach(function(file) {
        // Commenting this out because we don't need the full path
        //file = dir + '/' + file;

        // Commenting this out because we don't need recursion
        /*let stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(getAllFilesFromFolder(file));
        } else {
            results.push(file);
        }*/
        results.push(file);
    });

    return results;
};

// From: https://stackoverflow.com/questions/3710204/how-to-check-if-a-string-is-a-valid-json-string-in-javascript-without-using-try
const tryParseJSON = function(jsonString) {
    try {
        let o = JSON.parse(jsonString);

        // Handle non-exception-throwing cases:
        // Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
        // but... JSON.parse(null) returns null, and typeof null === 'object',
        // so we must check for that, too. Thankfully, null is falsey, so this suffices:
        if (o && typeof o === 'object') {
            return o;
        }
    }
    catch (e) { }

    return false;
};
exports.tryParseJSON = tryParseJSON;

exports.getRandomNumber = function(minNumber, maxNumber) {
    // Get a random number between minNumber and maxNumber
    return Math.floor(Math.random() * (parseInt(maxNumber) - parseInt(minNumber) + 1) + parseInt(minNumber));
};

// From: https://stackoverflow.com/questions/2332811/capitalize-words-in-string
String.prototype.capitalize = function() {
    return this.replace(/(?:^|\s)\S/g, function(a) {
        return a.toUpperCase();
    });
};

// From: https://stackoverflow.com/questions/5517597/plain-count-up-timer-in-javascript
exports.pad = function(val) {
    return val > 9 ? val : '0' + val;
};

// From: https://stackoverflow.com/questions/6234773/can-i-escape-html-special-chars-in-javascript
exports.escapeHtml = function(unsafe) {
    return unsafe
         .replace(/&/g, "&amp;")
         .replace(/</g, "&lt;")
         .replace(/>/g, "&gt;")
         .replace(/"/g, "&quot;")
         .replace(/'/g, "&#039;");
 };

// From: https://stackoverflow.com/questions/13627308/add-st-nd-rd-and-th-ordinal-suffix-to-a-number
exports.ordinal_suffix_of = function(i) {
    if (settings.get('language') === 'fr') {
        if (i === 1) {
            return i + 'er';
        } else {
            return i + 'ème';
        }
    } else { // Default to English
        let j = i % 10;
        let k = i % 100;
        if (j == 1 && k != 11) {
            return i + 'st';
        }
        if (j == 2 && k != 12) {
            return i + 'nd';
        }
        if (j == 3 && k != 13) {
            return i + 'rd';
        }
        return i + 'th';
    }
};
