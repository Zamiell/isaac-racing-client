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
    let modsPath;
    if (process.platform !== 'win32' && process.platform !== 'darwin') {
        modsPath = path.join(path.dirname(settings.get('logFilePath')), '..', 'share', 'binding of isaac afterbirth+ mods');
    } else {
        modsPath = path.join(path.dirname(settings.get('logFilePath')), '..', 'Binding of Isaac Afterbirth+ Mods');
    }
    ipcRenderer.send('asynchronous-message', 'isaac', modsPath);

    // Set the path to the "save.dat" file used for interprocess communication
    // (if the dev mod directory is there, just use that, even if we are in production)
    let devPath = path.join(modsPath, globals.LuaModDirDev, 'save.dat');
    if (fs.existsSync(devPath)) {
        globals.modLoaderFile = devPath;
    } else {
        globals.modLoaderFile = path.join(modsPath, globals.LuaModDir, 'save.dat');
    }
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
