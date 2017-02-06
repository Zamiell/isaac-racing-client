/*
    Isaac functions
*/

'use strict';

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const path        = nodeRequire('path');
const globals     = nodeRequire('./assets/js/globals');
const misc        = nodeRequire('./assets/js/misc');
const settings    = nodeRequire('./assets/js/settings');

// This tells the main process to start launching Isaac
exports.start = function() {
    let modsPath = path.join(path.dirname(settings.get('logFilePath')), '..', 'Binding of Isaac Afterbirth+ Mods');
    globals.modLoaderFile = path.join(modsPath, globals.LuaModDir, 'save.dat');
    ipcRenderer.send('asynchronous-message', 'isaac', modsPath);
};

// Monitor for notifications from the main process that doing the work of opening Isaac
ipcRenderer.on('isaac', function(event, message) {
    if (message.startsWith('error: ')) {
        // globals.currentScreen is equal to "transition" when this is called
        globals.currentScreen = 'null';

        let error = message.match(/error: (.+)/)[1];
        if (error === 'Failed to find the Racing+ mod in your mods directory. Are you sure that you subscribed to it on the Steam Workshop? For more information, see the download instructions at: https://isaacracing.net/download') {
            misc.errorShow(error);
        } else {
            // This is an ordinary error, so don't report it to Sentry
            misc.errorShow(error, false);
        }
        return;
    }

    globals.log.info(message);
});
