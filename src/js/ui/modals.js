/*
    Modals
*/

// Imports
const { ipcRenderer, remote, shell } = nodeRequire('electron');
const fs = nodeRequire('fs-extra');
const path = nodeRequire('path');
const globals = nodeRequire('./js/globals');
const settings = nodeRequire('./js/settings');
const misc = nodeRequire('./js/misc');

/*
    Event handlers
*/

$(document).ready(() => {
    /*
        Error modal
    */

    $('#error-modal-button').click(() => {
        if (globals.currentScreen === 'error') {
            ipcRenderer.send('asynchronous-message', 'restart');
        }
    });

    /*
        Warning modal
    */

    $('#warning-modal-button').click(() => {
        // Hide the warning modal
        $('#warning-modal').fadeOut(globals.fadeTime, () => {
            $('#gui').fadeTo(globals.fadeTime, 1);
        });
    });

    /*
        Log file modal
    */

    $('#log-file-link').click(() => {
        const url = 'https://steamcommunity.com/app/250900/discussions/0/613941122558099449/';
        shell.openExternal(url);
    });

    $('#log-file-find').click(() => {
        const titleText = $('#select-your-log-file').html();
        const newLogFilePath = remote.dialog.showOpenDialog({
            title: titleText,
            defaultPath: globals.defaultLogFilePath,
            filters: [
                {
                    name: 'Text',
                    extensions: ['txt'],
                },
            ],
            properties: ['openFile'],
        });
        if (newLogFilePath === undefined) {
            return;
        } else if (newLogFilePath[0].match(/[/\\]Binding of Isaac Rebirth[/\\]/)) { // Match a forward or backslash
            // Check to make sure they don't have an Rebirth log.txt selected
            $('#log-file-description-1').fadeOut(globals.fadeTime);
            $('#log-file-description-2').fadeOut(globals.fadeTime, () => {
                $('#log-file-description-1').html('<p lang="en">It appears that you have selected your Rebirth "log.txt" file, which is different than the Afterbirth+ "log.txt" file.</p><p lang="en">Please try again and select your Afterbirth+ log file.</p><br />');
                $('#log-file-description-1').fadeIn(globals.fadeTime);
            });
            return;
        } else if (newLogFilePath[0].match(/[/\\]Binding of Isaac Afterbirth[/\\]/)) {
            // Check to make sure they don't have an Afterbirth log.txt selected
            $('#log-file-description-1').fadeOut(globals.fadeTime);
            $('#log-file-description-2').fadeOut(globals.fadeTime, () => {
                $('#log-file-description-1').html('<p lang="en">It appears that you have selected your Afterbirth "log.txt" file, which is different than the Afterbirth+ "log.txt" file.</p><p lang="en">Please try again and select your Afterbirth+ log file.</p><br />');
                $('#log-file-description-1').fadeIn(globals.fadeTime);
            });
            return;
        }

        settings.set('logFilePath', newLogFilePath[0]);
        settings.saveSync();

        $('#log-file-description-1').fadeOut(globals.fadeTime);
        $('#log-file-description-2').fadeOut(globals.fadeTime, () => {
            $('#log-file-description-3').fadeIn(globals.fadeTime);
        });
        $('#log-file-find').fadeOut(globals.fadeTime, () => {
            $('#log-file-exit').fadeIn(globals.fadeTime);
        });
    });

    $('#log-file-exit').click(() => {
        ipcRenderer.send('asynchronous-message', 'restart');
    });

    /*
        Save file modal
    */

    $('#save-file-0-slot-1').click(() => {
        saveFileReplace(0, 1);
    });

    $('#save-file-0-slot-2').click(() => {
        saveFileReplace(0, 2);
    });

    $('#save-file-0-slot-3').click(() => {
        saveFileReplace(0, 3);
    });

    $('#save-file-0-exit').click(() => {
        ipcRenderer.send('asynchronous-message', 'close');
    });

    $('#save-file-0-relaunch').click(() => {
        ipcRenderer.send('asynchronous-message', 'restart');
    });

    $('#save-file-1-slot-1').click(() => {
        saveFileReplace(1, 1);
    });

    $('#save-file-1-slot-2').click(() => {
        saveFileReplace(1, 2);
    });

    $('#save-file-1-slot-3').click(() => {
        saveFileReplace(1, 3);
    });

    $('#save-file-1-exit').click(() => {
        ipcRenderer.send('asynchronous-message', 'close');
    });

    $('#save-file-1-relaunch').click(() => {
        ipcRenderer.send('asynchronous-message', 'restart');
    });

    function saveFileReplace(steamCloud, slot) {
        globals.log.info(`Replacing save slot ${slot} (with steam cloud ${steamCloud}.`);

        // Make sure the directory for the old save exists
        let oldSaveFile;
        if (steamCloud === 0) {
            oldSaveFile = path.join(globals.modPath, '..', 'Binding of Isaac Afterbirth+', '');
        } else if (steamCloud === 1) {
            oldSaveFile = path.join(globals.modPath, '..', 'Binding of Isaac Afterbirth+', '');
        } else {
            misc.errorShow('The "saveFileReplace()" function got an invalid value for "steamCloud".');
            return;
        }

        // Make sure the hacked save file is there
        // The current working directory is: C:\Users\james\AppData\Local\Programs\RacingPlus\resources\app.asar\src\js\ui
        const hackedSaveFile = path.join(__dirname, '..', '..', 'data', 'persistentgamedata.dat');
        try {
            if (!fs.existsSync(hackedSaveFile)) {
                misc.errorShow(`The "${hackedSaveFile}" file does not exist! Your Racing+ client may be corrupted.`);
                return;
            }
            fs.copySync(hackedSaveFile, oldSaveFile);
        } catch (err) {
            misc.errorShow(`Failed to copy the "persistentgamedata.dat" file: ${err}`);
            return;
        }

        $(`#save-file-modal-${steamCloud}-description-1`).fadeOut(globals.fadeTime);
        $(`#save-file-modal-${steamCloud}-description-2`).fadeOut(globals.fadeTime, () => {
            $(`#save-file-modal-${steamCloud}-description-3`).fadeIn(globals.fadeTime);
        });
        $(`#save-file-modal-${steamCloud}-slot-1`).fadeOut(globals.fadeTime);
        $(`#save-file-modal-${steamCloud}-slot-2`).fadeOut(globals.fadeTime);
        $(`#save-file-modal-${steamCloud}-slot-3`).fadeOut(globals.fadeTime);
        $(`#save-file-modal-${steamCloud}-exit`).fadeOut(globals.fadeTime, () => {
            $(`#save-file-modal-${steamCloud}-relaunch`).fadeIn(globals.fadeTime);
        });
    }
});
