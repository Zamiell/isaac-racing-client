'use strict';

// Imports
const globals     = nodeRequire('./assets/js/globals');
const title       = nodeRequire('./assets/js/title');
const login       = nodeRequire('./assets/js/login');

setTimeout(function() {
    console.log(globals.currentScreen);
}, 2000);
