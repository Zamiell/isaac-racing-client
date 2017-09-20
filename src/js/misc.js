/*
    Miscellaneous functions
*/

// Imports
const path = nodeRequire('path');
const { ipcRenderer } = nodeRequire('electron');
const fs = nodeRequire('fs-extra');
const globals = nodeRequire('./js/globals');
const settings = nodeRequire('./js/settings');

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

const errorShow = (message, sendToSentry = true, alternateScreen = '') => {
    // Let the main process know to not overwrite the 3 "save.dat" files in case we are in the middle of a race
    ipcRenderer.send('asynchronous-message', 'error');

    // Come back in a second if we are still in a transition
    if (globals.currentScreen === 'transition') {
        setTimeout(() => {
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

    // We don't have to send some common errors to Sentry
    if (message === 'You have logged on from somewhere else, so you have been disconnected here.') {
        sendToSentry = false;
    } else if (message === 'Error: Steam initialization failed. Steam is not running.') {
        message = 'Steam initialization failed. It appears that Steam is not running. (If it is running, please restart your computer and try again.)';
        sendToSentry = false;
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

    $('#gui').fadeTo(globals.fadeTime, 0.1, () => {
        if (alternateScreen !== '') {
            // Show the specific ID that was passed as an argument to this function
            $(`#${alternateScreen}`).fadeIn(globals.fadeTime);
        } else {
            // Show the error modal
            $('#error-modal').fadeIn(globals.fadeTime);
            $('#error-modal-description').html(message);
        }
    });
};
exports.errorShow = errorShow;

const warningShow = (message) => {
    // Come back in a second if we are still in a transition
    if (globals.currentScreen === 'transition') {
        setTimeout(() => {
            warningShow(message);
        }, globals.fadeTime + 5); // 5 milliseconds of leeway
        return;
    }

    // Log the message
    globals.log.warn(message);

    // Close all tooltips
    closeAllTooltips();

    // Show the warning modal
    $('#gui').fadeTo(globals.fadeTime, 0.1, () => {
        $('#warning-modal').fadeIn(globals.fadeTime);
        $('#warning-modal-description').html(message);
    });
};
exports.warningShow = warningShow;

exports.playSound = (soundFilename, exclusive = false) => {
    // First check to see if sound is disabled
    const volume = settings.get('volume');
    if (volume === 0) {
        return;
    }

    if (exclusive !== false) {
        // For some sound effects, we only want one of them playing at once to prevent confusion
        if (globals.playingSound) {
            return; // Do nothing if we are already playing a sound
        }

        globals.playingSound = true;
        setTimeout(() => {
            globals.playingSound = false;
        }, exclusive); // The 2nd argument to the function should be the length of the sound effect in milliseconds
    }

    // Sometimes this can give "net::ERR_REQUEST_RANGE_NOT_SATISFIABLE" for some reason
    // (might be related to having multiple Electron apps trying to play the same sound at the same time)
    const audioPath = path.join('sounds', `${soundFilename}.mp3`);
    const audio = new Audio(audioPath);
    audio.volume = volume;
    audio.play().catch((err) => {
        globals.log.info(`Failed to play "${audioPath}": ${err}`);
    });
    globals.log.info(`Played "${audioPath}".`);
};

exports.findAjaxError = (jqXHR) => {
    if (jqXHR.readyState === 0) {
        return 'A network error occured. The server might be down!';
    } else if (jqXHR.responseText === '') {
        return 'An unknown error occured.';
    }

    return jqXHR.responseText;
};

const closeAllTooltips = () => {
    const instances = $.tooltipster.instances();
    $.each(instances, (i, instance) => {
        instance.close();
    });
};
exports.closeAllTooltips = closeAllTooltips;

// From: https://stackoverflow.com/questions/20822273/best-way-to-get-folder-and-file-list-in-javascript
exports.getAllFilesFromFolder = (dir) => {
    const results = [];
    fs.readdirSync(dir).forEach((file) => {
        // Commenting this out because we don't need the full path
        /*
        file = dir + '/' + file;
        */

        // Commenting this out because we don't need recursion
        /*
        let stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(getAllFilesFromFolder(file));
        } else {
            results.push(file);
        }
        */
        results.push(file);
    });

    return results;
};

// From: https://stackoverflow.com/questions/3710204/how-to-check-if-a-string-is-a-valid-json-string-in-javascript-without-using-try
const tryParseJSON = (jsonString) => {
    try {
        const o = JSON.parse(jsonString);

        // Handle non-exception-throwing cases:
        // Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
        // but... JSON.parse(null) returns null, and typeof null === 'object',
        // so we must check for that, too. Thankfully, null is falsey, so this suffices:
        if (o && typeof o === 'object') {
            return o;
        }
    } catch (err) {
        // We don't care about the error
    }

    return false;
};
exports.tryParseJSON = tryParseJSON;

exports.getRandomNumber = (min, max) => {
    // Get a random number between min and max
    min = parseInt(min, 10);
    max = parseInt(max, 10);
    return Math.floor(Math.random() * (max - min + 1) + min);
};

// From: https://stackoverflow.com/questions/2332811/capitalize-words-in-string
/* eslint-disable no-extend-native */
String.prototype.capitalize = function stringCapitalize() {
    return this.replace(/(?:^|\s)\S/g, a => a.toUpperCase());
};

// From: https://stackoverflow.com/questions/5517597/plain-count-up-timer-in-javascript
exports.pad = val => (val > 9 ? val : `0${val}`);

// From: https://stackoverflow.com/questions/6234773/can-i-escape-html-special-chars-in-javascript
exports.escapeHtml = unsafe => unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');

// From: https://stackoverflow.com/questions/13627308/add-st-nd-rd-and-th-ordinal-suffix-to-a-number
exports.ordinal_suffix_of = (i) => {
    // Handle French ordinals
    if (settings.get('language') === 'fr') {
        return (i === 1 ? `${i}er` : `${i}ème`);
    }

    // Default to English
    const j = i % 10;
    const k = i % 100;
    if (j === 1 && k !== 11) {
        return `${i}st`;
    }
    if (j === 2 && k !== 12) {
        return `${i}nd`;
    }
    if (j === 3 && k !== 13) {
        return `${i}rd`;
    }
    return `${i}th`;
};
