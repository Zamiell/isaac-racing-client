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

const errorShow = function(message, alternateScreen = false) {
    // Come back in a second if we are still in a transition
    if (globals.currentScreen === 'transition') {
        setTimeout(function() {
            errorShow(message, alternateScreen);
        }, globals.fadeTime + 5); // 5 milliseconds of leeway
        return;
    }

    // Log the message
    if (message !== '') {
        globals.log.error(message);
    } else {
        globals.log.error('Generic error.');
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
    $('#header-log-out').fadeOut(globals.fadeTime);

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

    $('#gui').fadeTo(globals.fadeTime, 0.1, function() {
        // Show the error modal
        $('#warning-modal').fadeIn(globals.fadeTime);
        $('#warning-modal-description').html(message);
    });
};
exports.warningShow = warningShow;

exports.findAjaxError = function(jqXHR) {
    // Find out what error it was
    let error;
    if (jqXHR.hasOwnProperty('readyState')) {
        if (jqXHR.readyState === 4) {
            // HTTP error
            if (tryParseJSON(jqXHR.responseText) !== false) {
                error = JSON.parse(jqXHR.responseText); // jqXHR.response doesn't work for some reason
                if (error.hasOwnProperty('error_description')) { // Some errors have the plain text description in the "error_description" field
                    error = error.error_description;
                } else if (error.hasOwnProperty('description')) { // Some errors have the plain text description in the "description" field
                    error = error.description;
                } else if (error.hasOwnProperty('error')) { // Some errors have the plain text description in the "error" field
                    error = error.error;
                } else {
                    error = 'An unknown HTTP error occured.';
                }
            } else {
                error = jqXHR.responseText;
            }
        } else if (jqXHR.readyState === 0) {
            // Network error (connection refused, access denied, etc.)
            error = 'A network error occured. The server might be down!';
        } else {
            // Unknown error
            error = 'An unknown error occured.';
        }
    } else {
        // Unknown error
        error = 'An unknown error occured.';
    }

    // Auth0 has some crappy error messages, so rewrite them to be more clear
    if (error === 'Wrong email or password.') {
        error = 'Wrong username or password.';
    } else if (error === 'The user already exists.') { // Auth0 has a crappy error message for this, so rewrite it
        error = 'Someone has already registered with that email address.';
    } else if (error === 'invalid email address') {
        error = 'Invalid email address.';
    }

    return error;
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
