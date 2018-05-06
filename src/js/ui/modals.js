/*
    Modals
*/

// Imports
const { ipcRenderer, remote, shell } = nodeRequire('electron');
const fs = nodeRequire('fs');
const path = nodeRequire('path');
const settings = nodeRequire('./settings');
const globals = nodeRequire('./js/globals');
const misc = nodeRequire('./js/misc');
const crypto = nodeRequire('crypto');

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
        Password input modal
    */

    $('#password-input').on('keypress', (e) => {
        if (e.keyCode === 13) {
            e.preventDefault();
            $('#password-modal-ok-button').click();
        } else if (e.keyCode === 27) {
            e.preventDefault();
            $('#password-modal-cancel-button').click();
        }
    });

    $('#password-modal-ok-button').click(() => {
        const passwordInput = $('#password-input');

        let password = passwordInput.val();
        const raceId = passwordInput.data('raceId');
        const raceTitle = passwordInput.data('raceTitle');

        if (password === '') {
            return;
        }

        const passwordHash = crypto.pbkdf2Sync(password, raceTitle, globals.pbkdf2Iterations, globals.pbkdf2Keylen, globals.pbkdf2Digest);
        password = passwordHash.toString('base64');

        // Hide the password modal
        $('#password-modal').fadeOut(globals.fadeTime, () => {
            $('#gui').fadeTo(globals.fadeTime, 1);

            globals.currentScreen = 'waiting-for-server';
            globals.conn.send('raceJoin', {
                id: raceId,
                password,
            });
        });
    });

    $('#password-modal-cancel-button').click(() => {
        // Hide the password modal
        $('#password-modal').fadeOut(globals.fadeTime, () => {
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

    $('#save-file-modal-slot-1').click(() => {
        saveFileReplace(1);
    });

    $('#save-file-modal-slot-2').click(() => {
        saveFileReplace(2);
    });

    $('#save-file-modal-slot-3').click(() => {
        saveFileReplace(3);
    });

    $('#save-file-modal-exit').click(() => {
        ipcRenderer.send('asynchronous-message', 'close');
    });

    $('#save-file-modal-relaunch').click(() => {
        ipcRenderer.send('asynchronous-message', 'restart');
    });

    function saveFileReplace(slot) {
        globals.log.info(`Replacing save slot ${slot} (with a steam cloud value of "${globals.saveFileDir[0]}" and a save directory of "${globals.saveFileDir[1]}").`);

        // Make sure the directory for the old save exists
        try {
            if (!fs.existsSync(globals.saveFileDir[1])) {
                misc.errorShow(`Racing+ detected that your Isaac save file directory was at "${globals.saveFileDir[1]}", but that directory doesn't seem to exist.`);
                return;
            }
        } catch (err) {
            misc.errorShow(`Failed to check to see if the "${globals.saveFileDir[1]}" directory exists: ${err}`);
            return;
        }

        // Remove the old save file, if it exists
        let saveFileName;
        if (globals.saveFileDir[0] === '1') {
            // SteamCloud is equal to 1
            saveFileName = `abp_persistentgamedata${slot}.dat`;
        } else if (globals.saveFileDir[0] === '0') {
            // SteamCloud is equal to 0
            saveFileName = `persistentgamedata${slot}.dat`;
        }
        const saveFile = path.join(globals.saveFileDir[1], saveFileName);
        try {
            if (fs.existsSync(saveFile)) {
                fs.unlinkSync(saveFile);
            }
        } catch (err) {
            misc.errorShow(`Failed to check/delete the "${saveFile}" file: ${err}`);
            return;
        }

        // Make sure the fully unlocked save file is there
        // The current working directory is: C:\Users\james\AppData\Local\Programs\RacingPlus\resources\app.asar\src\js\ui
        const hackedSaveFile = path.join(__dirname, '..', '..', 'data', 'persistentgamedata.dat');
        try {
            if (!fs.existsSync(hackedSaveFile)) {
                misc.errorShow(`The "${hackedSaveFile}" file does not exist! Your Racing+ client may be corrupted.`);
                return;
            }

            // "fs.copyFileSync" is only in Node 8.5.0 and Electron isn't on that version yet
            // fs.copyFileSync(hackedSaveFile, saveFile);
            const data = fs.readFileSync(hackedSaveFile);
            fs.writeFileSync(saveFile, data);
        } catch (err) {
            misc.errorShow(`Failed to copy the fully unlocked save file to "${saveFile}": ${err}`);
            return;
        }

        $('#save-file-modal-description-1').fadeOut(globals.fadeTime);
        $('#save-file-modal-description-2').fadeOut(globals.fadeTime, () => {
            $('#save-file-modal-description-3').fadeIn(globals.fadeTime);
            $('#save-file-modal-description-4').fadeIn(globals.fadeTime);
        });
        $('#save-file-modal-replace-buttons').fadeOut(globals.fadeTime, () => {
            $('#save-file-modal-relaunch').fadeIn(globals.fadeTime);
        });
    }
});
