/*
    Settings tooltip
*/

'use strict';

// Imports
const ipcRenderer  = nodeRequire('electron').ipcRenderer;
const remote       = nodeRequire('electron').remote;
const globals      = nodeRequire('./assets/js/globals');
const settings     = nodeRequire('./assets/js/settings');
const misc         = nodeRequire('./assets/js/misc');
const localization = nodeRequire('./assets/js/localization');

/*
    Event handlers
*/

$(document).ready(function() {
    $('#settings-log-file-location-change').click(function() {
        let titleText = $('#select-your-log-file').html();
        let newLogFilePath = remote.dialog.showOpenDialog({
            title: titleText,
            defaultPath: globals.defaultLogFilePath,
            filters: [
                {
                    'name': 'Text',
                    'extensions': ['txt'],
                }
            ],
            properties: ['openFile'],
        });
        if (newLogFilePath === undefined) {
            return;
        } else if (newLogFilePath[0].match(/[/\\]Binding of Isaac Rebirth[/\\]/)) { // Match a forward or backslash
            // Check to make sure they don't have an Rebirth log.txt selected
            misc.warningShow('<p lang="en">It appears that you have selected your Rebirth "log.txt" file, which is different than the Afterbirth+ "log.txt" file.</p><p lang="en">Please try again and select your Afterbirth+ log file.</p><br />');
            return;
        } else if (newLogFilePath[0].match(/[/\\]Binding of Isaac Afterbirth[/\\]/)) {
            // Check to make sure they don't have an Afterbirth log.txt selected
            misc.warningShow('<p lang="en">It appears that you have selected your Afterbirth "log.txt" file, which is different than the Afterbirth+ "log.txt" file.</p><p lang="en">Please try again and select your Afterbirth+ log file.</p><br />');
            return;
        }

        let shortenedPath = newLogFilePath[0].substring(0, 24);
        $('#settings-log-file-location').html('<code>' + shortenedPath + '...</code>');
        $('#settings-log-file-location').tooltipster('content', newLogFilePath[0]);
    });

    $('#settings-volume-slider').change(function() {
        $('#settings-volume-slider-value').html($(this).val() + '%');
    });

    $('#settings-volume-test').click(function() {
        // Play the "Go" sound effect
        let audio = new Audio('assets/sounds/go.mp3');
        audio.volume = $('#settings-volume-slider').val() / 100;
        audio.play();
    });

    $('#settings-stream-url').keyup(settingsStreamURLKeyup);
    function settingsStreamURLKeyup() {
        let oldStreamURL = globals.stream.URLBeforeTyping;
        let newStreamURL = $('#settings-stream-url').val();

        if (oldStreamURL.indexOf('twitch.tv/') === -1 && newStreamURL.indexOf('twitch.tv/') !== -1) {
            // There was no Twitch stream set before, but now there is
            // So, reveal the "Enable Twitch chat bot" and uncheck it
            $('#settings-enable-twitch-bot-checkbox-container').fadeTo(globals.fadeTime, 1);
            $('#settings-enable-twitch-bot-checkbox').prop('disabled', false);
            $('#settings-enable-twitch-bot-checkbox-label').css('cursor', 'pointer');
            $('#settings-enable-twitch-bot-checkbox').prop('checked', false); // Uncheck it
            $('#settings-twitch-bot-delay-label').fadeTo(globals.fadeTime, 0.25);
            $('#settings-twitch-bot-delay').fadeTo(globals.fadeTime, 0.25);
            $('#settings-twitch-bot-delay').prop('disabled', true);

            // Wait for the fading to finish
            setTimeout(function() {
                settingsStreamURLKeyup(); // Since the contents of the text box may have changed in the meantime, run the function again to be sure
            }, globals.fadeTime + 5); // 5 milliseconds of leeway
        } else if (oldStreamURL.indexOf('twitch.tv/') !== -1 && newStreamURL.indexOf('twitch.tv/') === -1) {
            // There was a Twitch stream set before, but now there isn't
            // So, disable the Twitch bot
            $('#settings-enable-twitch-bot-checkbox-container').fadeTo(globals.fadeTime, 0.25);
            $('#settings-enable-twitch-bot-checkbox').prop('disabled', true);
            $('#settings-enable-twitch-bot-checkbox-label').css('cursor', 'default');
            $('#settings-enable-twitch-bot-checkbox').prop('checked', false); // Uncheck it
            $('#settings-twitch-bot-delay-label').fadeTo(globals.fadeTime, 0.25);
            $('#settings-twitch-bot-delay').fadeTo(globals.fadeTime, 0.25);
            $('#settings-twitch-bot-delay').prop('disabled', true);

            // Wait for the fading to finish
            setTimeout(function() {
                settingsStreamURLKeyup(); // Since the contents of the text box may have changed in the meantime, run the function again to be sure
            }, globals.fadeTime + 5); // 5 milliseconds of leeway

        }

        globals.stream.URLBeforeTyping = newStreamURL;
    }
    function settingsStreamURLCheck() {
    }

    $('#settings-enable-twitch-bot-checkbox-container').on('mouseover', function() {
        // Check if the tooltip is open
        if ($('#settings-enable-twitch-bot-checkbox-container').tooltipster('status').open === false &&
            $('#settings-stream-url').val().indexOf('twitch.tv/') !== -1 &&
            $('#settings-enable-twitch-bot-checkbox').is(':checked') === false) {

            $('#settings-enable-twitch-bot-checkbox-container').tooltipster('open');
        }
    });

    $('#settings-enable-twitch-bot-checkbox').change(function(data) {
        if ($('#settings-enable-twitch-bot-checkbox').prop('checked')) {
            $('#settings-twitch-bot-delay-label').fadeTo(globals.fadeTime, 1);
            $('#settings-twitch-bot-delay').fadeTo(globals.fadeTime, 1);
            $('#settings-twitch-bot-delay').prop('disabled', false);
        } else {
            $('#settings-twitch-bot-delay-label').fadeTo(globals.fadeTime, 0.25);
            $('#settings-twitch-bot-delay').fadeTo(globals.fadeTime, 0.25);
            $('#settings-twitch-bot-delay').prop('disabled', true);
        }
    });

    $('#settings-form').submit(function() {
        // By default, the form will reload the page, so stop this from happening
        event.preventDefault();

        // Don't do anything if we are not on the right screen
        if (globals.currentScreen !== 'lobby') {
            return;
        }

        // Log file location
        let newLogFilePath = $('#settings-log-file-location').tooltipster('content');
        let changedLogFilePath = false;
        if (settings.get('logFilePath') !== newLogFilePath) {
            changedLogFilePath = true;
            settings.set('logFilePath', newLogFilePath);
            settings.saveSync();
        }

        // Language
        localization.localize($('#settings-language').val());

        // Volume
        settings.set('volume', $('#settings-volume-slider').val() / 100);
        settings.saveSync();

        // Stream URL
        let newStreamURL = $('#settings-stream-url').val();
        if (newStreamURL.startsWith('http://')) {
            newStreamURL = newStreamURL.replace('http://', 'https://');
        }
        if (newStreamURL.startsWith('https://twitch.tv/')) {
            newStreamURL = newStreamURL.replace('twitch.tv', 'www.twitch.tv');
        }
        if (newStreamURL.startsWith('twitch.tv/')) {
            newStreamURL = 'https://www.' + newStreamURL;
        }
        if (newStreamURL.startsWith('www.twitch.tv/')) {
            newStreamURL = 'https://' + newStreamURL;
        }
        $('#settings-stream-url').val(newStreamURL);
        if (newStreamURL.startsWith('https://www.twitch.tv/') === false && newStreamURL !== '') {
            // We tried to enter a non-valid stream URL
            $('#settings-stream-url').tooltipster('open');
            return;
        } else {
            $('#settings-stream-url').tooltipster('close');
            if (newStreamURL === '') {
                newStreamURL = '-'; // Streams cannot be blank on the server-side
            }
        }

        // Twitch bot enabled
        let newTwitchBotEnabled = $('#settings-enable-twitch-bot-checkbox').prop('checked');

        // Twitch bot delay
        let newTwitchBotDelay = $('#settings-twitch-bot-delay').val();
        if (/^\d+$/.test(newTwitchBotDelay) === false) {
            // We tried to enter a non-number Twitch bot delay
            $('#settings-twitch-bot-delay').tooltipster('open');
            return;
        }
        newTwitchBotDelay = parseInt(newTwitchBotDelay);
        if (newTwitchBotDelay < 0 || newTwitchBotDelay > 60) {
            // We tried to enter a delay out of the valid range
            $('#settings-twitch-bot-delay').tooltipster('open');
            return;
        }
        $('#settings-twitch-bot-delay').tooltipster('close');

        // Send new stream settings if something changed
        if (newStreamURL !== globals.stream.URL ||
            newTwitchBotEnabled !== globals.stream.TwitchBotEnabled ||
            newTwitchBotDelay !== globals.stream.TwitchBotDelay) {

            // Back up the stream URL in case we get a error/warning back from the server
            globals.stream.URLBeforeSubmit = globals.stream.URL;

            // Update the global copies of these settings
            if (newStreamURL === '-') {
                globals.stream.URL = '';
            } else {
                globals.stream.URL = newStreamURL;
            }
            globals.stream.TwitchBotEnabled = newTwitchBotEnabled;
            globals.stream.TwitchBotDelay   = newTwitchBotDelay;

            // Send them to the server
            globals.conn.send('profileSetStream', {
                name:    newStreamURL,
                enabled: newTwitchBotEnabled,
                value:   newTwitchBotDelay,
            });
        }

        // Close the tooltip
        $('#header-settings').tooltipster('close');

        // We only need to exit the program and restart if they changed the log file path
        if (changedLogFilePath) {
            misc.errorShow('Now that you have changed the location of the log file, please restart Racing+.', false, false, '<span lang="en">Success</span>');
        }
    });
});

/*
    Settings tooltip functions
*/

// The "functionBefore" function for Tooltipster
exports.tooltipFunctionBefore = function() {
    if (globals.currentScreen !== 'lobby') {
        return false;
    }

    $('#gui').fadeTo(globals.fadeTime, 0.1);

    return true;
};

// The "functionReady" function for Tooltipster
exports.tooltipFunctionReady = function() {
    /*
        Fill in all of the settings every time the tooltip is opened
        (this prevents the user having unsaved settings displayed, which is confusing)
    */

    // Username
    $('#settings-username').html(globals.myUsername);

    // Log file location
    let shortenedPath = settings.get('logFilePath').substring(0, 24);
    $('#settings-log-file-location').html('<code>' + shortenedPath + '...</code>');

    // Loanguage
    $('#settings-language').val(settings.get('language'));

    // Volume
    $('#settings-volume-slider').val(settings.get('volume') * 100);
    $('#settings-volume-slider-value').html((settings.get('volume') * 100) + '%');

    // Change stream URL
    $('#settings-stream-url').val(globals.stream.URL);
    globals.stream.URLBeforeTyping = globals.stream.URL;

    // Partially fade all of the optional settings by default
    $('#settings-enable-twitch-bot-checkbox-container').fadeTo(0, 0.25);
    $('#settings-enable-twitch-bot-checkbox').prop('checked', false);
    $('#settings-enable-twitch-bot-checkbox').prop('disabled', true);
    $('#settings-enable-twitch-bot-checkbox-label').css('cursor', 'default');
    $('#settings-twitch-bot-delay-label').fadeTo(0, 0.25);
    $('#settings-twitch-bot-delay').fadeTo(0, 0.25);
    $('#settings-twitch-bot-delay').prop('disabled', true);

    // Twitch bot delay
    $('#settings-twitch-bot-delay').val(globals.stream.TwitchBotDelay);

    // Show the checkbox they have a Twitch stream set
    if (globals.stream.URL.indexOf('twitch.tv/') !== -1) {
        $('#settings-enable-twitch-bot-checkbox-container').fadeTo(0, 1);
        $('#settings-enable-twitch-bot-checkbox').prop('disabled', false);
        $('#settings-enable-twitch-bot-checkbox-label').css('cursor', 'pointer');

        // Enable Twitch chat bot
        if (globals.stream.TwitchBotEnabled) {
            $('#settings-enable-twitch-bot-checkbox').prop('checked', true);
            $('#settings-twitch-bot-delay-label').fadeTo(0, 1);
            $('#settings-twitch-bot-delay').fadeTo(0, 1);
            $('#settings-twitch-bot-delay').prop('disabled', false);
        }
    }

    /*
        Tooltips within tooltips seem to be buggy and can sometimes be uninitialized
        So, check for this every time the tooltip is opened and reinitialize them if necessary
    */

    if ($('#settings-log-file-location').hasClass('tooltipstered') === false) {
        $('#settings-log-file-location').tooltipster({
            theme: 'tooltipster-shadow',
            delay: 0,
            content: settings.get('logFilePath'),
        });
    }

    if ($('#settings-stream-url').hasClass('tooltipstered') === false) {
        $('#settings-stream-url').tooltipster({
            theme: 'tooltipster-shadow',
            delay: 0,
            trigger: 'custom',
        });
    }

    if ($('#settings-enable-twitch-bot-checkbox-container').hasClass('tooltipstered') === false) {
        $('#settings-enable-twitch-bot-checkbox-container').tooltipster({
            theme: 'tooltipster-shadow',
            delay: 750,
            trigger: 'custom',
            triggerClose: {
                mouseleave: true,
            },
            zIndex: 10000000, /* The default is 9999999, so it just has to be bigger than that so that it appears on top of the settings tooltip */
            interactive: true,
        });
    }

    if ($('#settings-twitch-bot-delay').hasClass('tooltipstered') === false) {
        $('#settings-twitch-bot-delay').tooltipster({
            theme: 'tooltipster-shadow',
            delay: 0,
            trigger: 'custom',
        });
    }

    // Redraw the tooltip
    $('#header-settings').tooltipster('reposition');
};
