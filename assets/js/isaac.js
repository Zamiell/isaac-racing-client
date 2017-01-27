/*
    Isaac functions
*/

'use strict';

// Imports
const fs          = nodeRequire('fs-extra');
const path        = nodeRequire('path');
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const globals     = nodeRequire('./assets/js/globals');
const settings    = nodeRequire('./assets/js/settings');
const misc        = nodeRequire('./assets/js/misc');

// globals.currentScreen is equal to "transition" when this is called
exports.start = function() {
    // Check to see if the mods directory exists
    let modsPath = path.join(path.dirname(settings.get('logFilePath')), '..', 'Binding of Isaac Afterbirth+ Mods');
    if (fs.existsSync(modsPath) === false) {
        globals.currentScreen = 'null';
        misc.errorShow('Unable to find your mods folder. Are you sure you chose the correct log file?');
        return -1;
    }

    // Go through all the subdirectories of the mod folder
    fs.readdirSync(modsPath).filter(function(file) {
        if (fs.statSync(path.join(modsPath, file)).isDirectory()) {
            
        }
    });

};
