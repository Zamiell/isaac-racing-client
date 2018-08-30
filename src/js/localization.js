/*
    Localization
*/

// Imports
const settings = nodeRequire('./settings');
const globals = nodeRequire('./js/globals');

// Constants
const validLanguages = [
    ['en', 'english', 'English'],
    ['fr', 'french', 'Français'],
    ['es', 'spanish', 'Español'],
    // ['ru', 'russian', 'Русский'],
];
exports.validLanguages = validLanguages;

$(document).ready(() => {
    // Initialize the "globals.lang" variable
    globals.lang = new Lang(); // Create a language switcher instance
    for (const languageArray of validLanguages) {
        if (languageArray[0] === validLanguages[0][0]) {
            // We don't need to load English
            continue;
        }
        nodeRequire(`./languages/${languageArray[0]}`);
    }
    globals.lang.init({
        defaultLang: validLanguages[0][0],
    });

    // If the user is using a non-default language, change all the text on the page
    // (the above initialization is asynchronous, and we don't know when it will finish, so just wait a while before switching the language)
    setTimeout(() => {
        // We still call this if the language is English so that the links get initialized correctly
        localize(settings.get('language'));
    }, 500);
});

// Define the function for the languge changing links
const setLocalize = function setLocalize() {
    // Find the language code that goes with this link
    let languageArray;
    for (languageArray of validLanguages) {
        const thisLanguage = /\w+-\w+-(\w+)/.exec(this.id)[1];
        if (thisLanguage === languageArray[1]) {
            break;
        }
    }

    // Set the language to that one
    localize(languageArray[0]);
};

const localize = (newLanguage) => {
    // Validate function arguments
    const validLanguageCodes = [];
    for (const languageArray of validLanguages) {
        validLanguageCodes.push(languageArray[0]);
    }
    if (validLanguageCodes.indexOf(newLanguage) === -1) {
        globals.log.error(`Unsupported language: ${newLanguage}`);
        return;
    }

    // Update the language setting on disk
    settings.set('language', newLanguage);
    settings.saveSync();

    // Set the new language on the page
    globals.lang.change(newLanguage);
    for (const languageArray of validLanguages) {
        if (languageArray[0] === newLanguage) {
            $(`#register-language-${languageArray[1]}`).html(languageArray[2]);
            $(`#register-language-${languageArray[1]}`).removeClass('unselected-language');
            $(`#register-language-${languageArray[1]}`).addClass('selected-language');
            $(`#register-language-${languageArray[1]}`).unbind();
        } else {
            $(`#register-language-${languageArray[1]}`).html(`<a>${languageArray[2]}</a>`);
            $(`#register-language-${languageArray[1]}`).removeClass('selected-language');
            $(`#register-language-${languageArray[1]}`).addClass('unselected-language');
            $(`#register-language-${languageArray[1]}`).click(setLocalize);
        }
    }
};
exports.localize = localize;
