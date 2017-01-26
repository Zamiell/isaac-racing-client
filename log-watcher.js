'use strict';

/*
    Child process that monitors the log file
*/

// Imports
const fs     = require('fs');
const path   = require('path');
const isDev  = require('electron-is-dev');
const tracer = require('tracer');
const Raven  = require('raven');

/*
    Logging (code duplicated between main, renderer, and child processes because of require/nodeRequire issues)
*/

const logFile = (isDev ? 'Racing+.log' : path.resolve(process.execPath, '..', '..', 'Racing+.log'));
const log = tracer.console({
    format: "{{timestamp}} <{{title}}> {{file}}:{{line}}\r\n{{message}}",
    dateformat: "ddd mmm dd HH:MM:ss Z",
    transport: function(data) {
        // #1 - Log to the JavaScript console
        console.log(data.output);

        // #2 - Log to a file
        fs.appendFile(logFile, data.output + '\r\n', function(err) {
            if (err) {
                throw err;
            }
        });
    }
});
log.info("Child started: log-watcher");

// Get the version
let packageFileLocation = path.join(__dirname, 'package.json');
let packageFile = fs.readFileSync(packageFileLocation, 'utf8');
let version = 'v' + JSON.parse(packageFile).version;

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
}).install();

// The parent will communicate with us once, telling us the path to the log file
process.on('message', function(message) {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    if (message === 'exit') {
        process.exit();
    }

    // If the message is not "exit", we can assume that it is the log path
    let logPath = message;

    // None of the existing tail modules on NPM seem to work correctly with the Isaac log, so we have to code our own
    // The Isaac log file is glitchy; it is written to in such a way that the directory does not recieve updates
    // Thus, fs.watch will not work, because it uses the ReadDirectoryChangesW:
    // https://msdn.microsoft.com/en-us/library/windows/desktop/aa365465%28v=vs.85%29.aspx
    // Instead we need to use fs.watchFile, which is polling based and less efficient
    log.info("Child log-watcher: Starting log monitoring on file: " + logPath);
    if (fs.existsSync(logPath) === false) {
        process.send('Error: The "' + logPath + '" file does not exist.');
        return;
    }
    var fd = fs.openSync(logPath, 'r');
    fs.watchFile(logPath, {
        interval: 50, // The default is 5007, so we need to poll much more frequently than that
    }, function(curr, prev) {
        if (prev.size === curr.size) {
            // Case 1 - The log file is the same size
            // (occasionally, the log file will be updated but have no new content)
        } else if (prev.size < curr.size) {
            // Case 2 - The log file has grown, so only read the new bytes
            let differential = curr.size - prev.size;
            let buffer = new Buffer(differential);
            fs.read(fd, buffer, 0, differential, prev.size, logReadCallback);
        } else {
            // Case 3 - The log file has been truncated, so read everything
            // (this occurs whenever the game is restarted)
            let buffer = new Buffer(curr.size);
            fs.read(fd, buffer, 0, curr.size, 0, logReadCallback);
        }
    });
});

// Handle the new blob of data
const logReadCallback = function(err, bytes, buff) {
    if (err) {
        process.send('Error: ' + err);
        return;
    }

    let lines = buff.toString('utf8').split('\n');
    for (let line of lines) {
        parseLine(line);
    }
};

// Parse each line for relevant events
const parseLine = function(line) {
    // Skip blank lines
    if (line === '') {
        return;
    }

    // Parse the log for relevant events
    //log.info('log.txt ' + line); // Uncomment this if debugging

    if (line.startsWith('[INFO] - ')) {
        line = line.substring(9, line.length); // Truncate the "[INFO] - " prefix
    } else {
        return; // We don't care about non-"INFO" lines
    }

    if (line.startsWith('Seed 70 added to SaveState')) {
        // TODO
    } else if (line.startsWith('RNG Start Seed: ')) {
        // A new run has begun
        let match = line.match(/\RNG Start Seed: (.... ....)/);
        if (match) {
            let seed = match[1];
            process.send('New seed: ' + seed);
        }
    } else if (line.startsWith('Level::Init ')) {
        // A new floor was entered
        let match = line.match(/\Level::Init m_Stage (\d+), m_StageType (\d+)/);
        if (match) {
            let stage = match[1];
            let type = match[2];
            process.send('New floor: ' + stage + '-' + type);
        }
    } else if (line.startsWith('Room ')) {
        // A new room was entered
        // Sometimes there are lines of "Room count #", so filter those out
        let match = line.match(/Room (\d+\.\d+)\(/);
        if (match) {
            let roomID = match[1];
            process.send('New room: ' + roomID);
        }
    } else if (line.startsWith('Adding collectible ')) {
        // A new item was picked up
        let match = line.match(/Adding collectible (\d+) /);
        if (match) {
            let item = match[1];
            process.send('New item: ' + item);
        }
    } else if (line === 'playing cutscene 17 (Chest).') {
        process.send('Finished run: Blue Baby');
    } else if (line === 'playing cutscene 18 (Dark Room).') {
        process.send('Finished run: The Lamb');
    } else if (line === 'playing cutscene 19 (Mega Satan).') {
        process.send('Finished run: Mega Satan');
    }
};
