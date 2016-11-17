/*
    Localization
*/

'use strict';

// Imports
const globals = nodeRequire('./assets/js/globals');

$(document).ready(function() {
    // Initialize the "globals.lang" variable
    globals.settings.language = localStorage.language;
    if (typeof globals.settings.language === 'undefined') {
        // If this is the first run, default to English
        globals.settings.language = 'en';
        localStorage.language = 'en';
    }
    globals.lang = new Lang(); // Create a language switcher instance
    globals.lang.dynamic('fr', 'assets/languages/fr.json');
    globals.lang.dynamic('es', 'assets/languages/es.json');
    globals.lang.dynamic('ru', 'assets/languages/ru.json');
    globals.lang.init({
        defaultLang: 'en',
    });

    // If the user is using a non-default language, change all the text on the page
    localize(globals.settings.language); // We still call this if the language is English so that the links get initialized correctly

});

const localize = function(newLanguage) {
    // Define valid languages
    let validLanguages = [
        ['en', 'english', 'English'],
        ['fr', 'french', 'Français'],
        ['es', 'spanish', 'Español'],
        ['ru', 'russian', 'Русский'],
    ];

    // Validate function arguments
    let validLanguageCodes = [];
    for (let languageArray of validLanguages) {
        validLanguageCodes.push(languageArray[0]);
    }
    if (validLanguageCodes.indexOf(newLanguage) === -1) {
        console.error('Unsupported language.');
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

    // Set the new language
    globals.settings.language = newLanguage;
    localStorage.language = globals.settings.language;
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
