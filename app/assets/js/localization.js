/*
    Localization
*/

'use strict';

// Imports
const globals = nodeRequire('./assets/js/globals');

$(document).ready(function() {
    // Initialize the "globals.lang" variable
    globals.settings.language = localStorage.language;
    if (typeof language === 'undefined') {
        // If this is the first run, default to English
        globals.settings.language = 'en';
        localStorage.language = 'en';
    }
    globals.lang = new Lang(); // Create a language switcher instance
    globals.lang.dynamic('fr', 'assets/languages/fr.json');
    globals.lang.init({
        defaultLang: 'en',
    });

    // If the user is using a non-default language, change all the text on the page
    if (globals.settings.language !== 'en') {
        localize(globals.settings.language);
    }

});

const localize = function(new_language) {
    // Validate function arguments
    if (new_language !== 'en' &&
        new_language !== 'fr' &&
        new_language !== 'es') {

        console.error('Unsupported language.');
        return;
    }

    // Set the new language
    globals.settings.language = new_language;
    localStorage.language = globals.settings.language;

    if (globals.settings.language === 'en') {
        // English
        $('#title-language-english').html('English');
        $('#title-language-english').removeClass('unselected-language');
        $('#title-language-english').addClass('selected-language');
        $('#title-language-english').unbind();
        $('#title-language-french').html('<a>Français</a>');
        $('#title-language-french').removeClass('selected-language');
        $('#title-language-french').addClass('unselected-language');
        $('#title-language-french').click(function() {
            localize('fr');
        });

        globals.lang.change('en');

    } else if (globals.settings.language === 'fr') {
        // French (Français)
        $('#title-language-english').html('<a>English</a>');
        $('#title-language-english').removeClass('selected-language');
        $('#title-language-english').addClass('unselected-language');
        $('#title-language-english').click(function() {
            localize('en');
        });
        $('#title-language-french').html('Français');
        $('#title-language-french').removeClass('unselected-language');
        $('#title-language-french').addClass('selected-language');
        $('#title-language-french').unbind();

        globals.lang.change('fr');
    }
};
exports.localize = localize;
