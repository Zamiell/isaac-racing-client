/*
    Isaac functions
*/

'use strict';

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const path        = nodeRequire('path');
const fs          = nodeRequire('fs-extra');
const globals     = nodeRequire('./assets/js/globals');
const misc        = nodeRequire('./assets/js/misc');
const settings    = nodeRequire('./assets/js/settings');

// This tells the main process to start launching Isaac
exports.start = function() {
    // "globals.modPath" is set in main.js
    ipcRenderer.send('asynchronous-message', 'isaac', globals.modPath);
};

// Monitor for notifications from the main process that doing the work of opening Isaac
ipcRenderer.on('isaac', function(event, message) {
    if (message.startsWith('error: ')) {
        // globals.currentScreen is equal to "transition" when this is called
        globals.currentScreen = 'null';

        // This is an ordinary error, so don't report it to Sentry
        let error = message.match(/error: (.+)/)[1];
        misc.errorShow(error, false);
        return;
    }

    globals.log.info(message);
});
