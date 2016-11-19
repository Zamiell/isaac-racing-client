/*
    Log watcher functions
*/

'use strict';

// Imports
const os       = nodeRequire('os');
const path     = nodeRequire('path');
const execFile = nodeRequire('child_process').execFile;
const remote   = nodeRequire('electron').remote;
const fs       = nodeRequire('fs-extra');
const Tail     = nodeRequire('tail').Tail;
const isDev    = nodeRequire('electron-is-dev');
const globals  = nodeRequire('./assets/js/globals');
const settings = nodeRequire('./assets/js/settings');
const misc     = nodeRequire('./assets/js/misc');

// globals.currentScreen is equal to "transition" when this is called
exports.start = function() {
    // Check to make sure the log file exists
    if (fs.existsSync(settings.get('logFilePath')) === false) {
        settings.set('logFilePath', null);
        settings.saveSync();
    }

    // Check to ensure that we have a valid log file path
    if (settings.get('logFilePath') === null) {
        globals.currentScreen = 'null';
        misc.errorShow('', true); // Show the log file path modal
        return -1;
    }

    // Get ready to start the log watching program
    let programPath = path.join(__dirname, '../programs/watchLog/dist/watchLog.exe');

    // Check to make sure the log watching program exists
    if (fs.existsSync(programPath) === false) {
        console.error('The log watching program does not exist:', programPath);
        return;
    }

    // Start the log watching program
    let args = (isDev ? [settings.get('logFilePath'), 'dev'] : [settings.get('logFilePath')]);
    globals.logMonitoringProgram = execFile(programPath, args, function(error, stdout, stderr) {
        console.log('The log watching program quit unexpectedly.');
        console.log('error:', error);
        console.log('stdout:', stdout);
        console.log('stderr:', stderr);
    }); // We have to use execFile since watchLog.exe is inside an ASAR archive

    // Tail the IPC file
    let logWatcher = new Tail(path.join(os.tmpdir(), 'Racing+_IPC.txt'));
    logWatcher.on('line', function(line) {
        // Debug
        //console.log('- ' + line);

        // Don't do anything if we are not in a race
        if (globals.currentRaceID === false) {
            return;
        }

        // Don't do anything if we have not started yet or we have quit
        for (let i = 0; i < globals.raceList[globals.currentRaceID].racerList.length; i++) {
            if (globals.raceList[globals.currentRaceID].racerList[i].name === globals.myUsername) {
                if (globals.raceList[globals.currentRaceID].racerList[i].status !== 'racing') {
                    return;
                }
                break;
            }
        }

        // Parse the line
        if (line.startsWith('New seed: ')) {
            let m = line.match(/New seed: (.... ....)/);
            if (m) {
                let seed = m[1];
                console.log('New seed:', seed);
                globals.conn.emit('raceSeed', {
                    'id':   globals.currentRaceID,
                    'seed': seed,
                });
            } else {
                misc.errorShow('Failed to parse the new seed.');
            }
        } else if (line.startsWith('New floor: ')) {
            let m = line.match(/New floor: (\d+)-\d+/);
            if (m) {
                let floor = parseInt(m[1]); // Server expects floor as an integer, not a string
                console.log('New floor:', floor);
                globals.conn.emit('raceFloor', {
                    'id':    globals.currentRaceID,
                    'floor': floor,
                });
            } else {
                misc.errorShow('Failed to parse the new floor.');
            }
        } else if (line.startsWith('New room: ')) {
            let m = line.match(/New room: (\d+)/);
            if (m) {
                let room = m[1];
                console.log('New room:', room);
                globals.conn.emit('raceFloor', {
                    'id':   globals.currentRaceID,
                    'room': room,
                });
            } else {
                misc.errorShow('Failed to parse the new room.');
            }
        } else if (line.startsWith('New item: ')) {
            let m = line.match(/New item: (\d+)/);
            if (m) {
                let itemID = m[1];
                console.log('New item:', itemID);
                globals.conn.emit('raceItem', {
                    'id':   globals.currentRaceID,
                    'itemID': itemID,
                });
            } else {
                misc.errorShow('Failed to parse the new item.');
            }
        } else if (line === 'Finished run: Blue Baby') {
            if (globals.raceList[globals.currentRaceID].ruleset.goal === 'Blue Baby') {
                console.log('Killed Blue Baby!');
                globals.conn.emit('raceFinish', {
                    'id': globals.currentRaceID,
                });
            }
        } else if (line === 'Finished run: The Lamb') {
            if (globals.raceList[globals.currentRaceID].ruleset.goal === 'The Lamb') {
                console.log('Killed The Lamb!');
                globals.conn.emit('raceFinish', {
                    'id': globals.currentRaceID,
                });
            }
        } else if (line === 'Finished run: Mega Satan') {
            if (globals.raceList[globals.currentRaceID].ruleset.goal === 'Mega Satan') {
                console.log('Killed Mega Satan!');
                globals.conn.emit('raceFinish', {
                    'id': globals.currentRaceID,
                });
            }
        }
    });
    logWatcher.on('error', function(error) {
        misc.errorShow('Something went wrong with the log monitoring program: "' + error);
    });
};
