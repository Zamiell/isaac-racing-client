/*
    Isaac functions
*/

'use strict';

// Imports
const fs          = nodeRequire('fs-extra');
const path        = nodeRequire('path');
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const ps          = nodeRequire('ps-node');
const globals     = nodeRequire('./assets/js/globals');
const settings    = nodeRequire('./assets/js/settings');
const misc        = nodeRequire('./assets/js/misc');

// globals.currentScreen is equal to "transition" when this is called
exports.start = function() {
    // Check to see if Isaac is already open
    ps.lookup({
        command: 'isaac-ng',
    }, function(err, resultList) {
        if (err) {
            globals.currentScreen = 'null';
            misc.errorShow('Failed to find the Isaac process: ' + err);
            return;
        }

        resultList.forEach(function(process) {
            if (process) {
                // Isaac is open, so close it before proceeding
                start2(process.pid);
            } else {
                // Isaac is not already open, so skip ahead to part 3
                start3();
            }
        });
    });
};

// Close Isaac
function start2(pid) {
    ps.kill(pid, function(err) { // This expects the first argument to be in a string for some reason
        if (err) {
            globals.currentScreen = 'null';
            misc.errorShow('Failed to close Isaac: ' + err);
            return;
        } else {
            globals.log.info('Killed Isaac process: ' + pid);
            start3();
        }
    });
}

// Make sure that we are ONLY running the Racing+ mod, then start Isaac
function start3() {
    // Check to see if the mods directory exists
    let modsPath = path.join(path.dirname(settings.get('logFilePath')), '..', 'Binding of Isaac Afterbirth+ Mods');
    if (fs.existsSync(modsPath) === false) {
        globals.currentScreen = 'null';
        misc.errorShow('Unable to find your mods folder. Are you sure you chose the correct log file? Try to fix it in the "settings.json" file in the Racing+ directory.');
        return;
    }

    // Go through all the subdirectories of the mod folder
    fs.readdirSync(modsPath).filter(function(file) {
        if (file === 'Racing+') {
            // Delete the old Racing+ mod
            try {
                fs.removeSync(path.join(modsPath, file));
            } catch(err) {
                globals.currentScreen = 'null';
                misc.errorShow('Failed to delete the old Racing+ Lua mod: ' + err);
                return;
            }
        } else if (fs.statSync(path.join(modsPath, file)).isDirectory()) {
            // Disable all other mods by writing a 0 byte "disable.it" file
            try {
                fs.writeFileSync(path.join(modsPath, file, 'disable.it'), '', 'utf8');
            } catch(err) {
                globals.currentScreen = 'null';
                misc.errorShow('Failed to disable one of the existing mods: ' + err);
                return;
            }
        }
    });

    // Copy over the new Racing+ mod
    fs.copy(path.join('assets', 'mod', 'Racing+'), path.join(modsPath, 'Racing+'), function (err) {
        if (err) {
            globals.currentScreen = 'null';
            misc.errorShow('Failed to copy the new Racing+ Lua mod: ' + err);
            return;
        }
        start4();
    });
}

// Start Isaac with the "--luadebug" flag
function start4() {
    // steam://rungameid/250900
    
}
