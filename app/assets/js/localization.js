/*
    Localization
*/

'use strict';

// Imports
const globals  = nodeRequire('./assets/js/globals');
const settings = nodeRequire('./assets/js/settings');

// Constants
const validLanguages = [
    ['en', 'english', 'English'],
    ['fr', 'french',  'Français'],
    ['es', 'spanish', 'Español'],
    ['ru', 'russian', 'Русский'],
];

$(document).ready(function() {
    // Initialize the "globals.lang" variable
    globals.lang = new Lang(); // Create a language switcher instance
    for (let languageArray of validLanguages) {
        if (languageArray[0] === validLanguages[0][0]) {
            // We don't need to load English
            continue;
        }
        globals.lang.dynamic(languageArray[0], 'assets/languages/' + languageArray[0] + '.json');
    }
    globals.lang.init({
        defaultLang: validLanguages[0][0],
    });

    // If the user is using a non-default language, change all the text on the page
    localize(settings.get('language')); // We still call this if the language is English so that the links get initialized correctly

});

const localize = function(newLanguage) {
    // Validate function arguments
    let validLanguageCodes = [];
    for (let languageArray of validLanguages) {
        validLanguageCodes.push(languageArray[0]);
    }
    if (validLanguageCodes.indexOf(newLanguage) === -1) {
        globals.log.error('Unsupported language: ' + newLanguage);
        return;
    }

    // Define the function for the languge changing links
    const setLocalize = function() {
        // Find the language code that goes with this link
        let languageArray;
        for (languageArray of validLanguages) {
            let thisLanguage = /\w+-\w+-(\w+)/.exec(this.id)[1];
            if (thisLanguage === languageArray[1]) {
                break;
            }
        }

        // Set the language to that one
        localize(languageArray[0]);
    };

    // Update the language setting on disk
    settings.set('language', newLanguage);
    settings.saveSync();

    // Set the new language on the page
    globals.lang.change(newLanguage);
    for (let languageArray of validLanguages) {
        if (languageArray[0] === newLanguage) {
            $('#title-language-' + languageArray[1]).html(languageArray[2]);
            $('#title-language-' + languageArray[1]).removeClass('unselected-language');
            $('#title-language-' + languageArray[1]).addClass('selected-language');
            $('#title-language-' + languageArray[1]).unbind();
        } else {
            $('#title-language-' + languageArray[1]).html('<a>' + languageArray[2] + '</a>');
            $('#title-language-' + languageArray[1]).removeClass('selected-language');
            $('#title-language-' + languageArray[1]).addClass('unselected-language');
            $('#title-language-' + languageArray[1]).click(setLocalize);
        }
    }
};

exports.localize = localize;
