/*
    Child process that monitors the log file
*/

// Imports
const fs = require('fs');
const isDev = require('electron-is-dev');
const Raven = require('raven');
const version = require('./version');

// Handle errors
process.on('uncaughtException', (err) => {
    process.send(`error: ${err}`, processExit);
});
const processExit = () => {
    process.exit();
};

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
}).install();

/*
    Log watcher stuff
*/

// The parent will communicate with us, telling us the path to the log file
process.on('message', (message) => {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    if (message === 'exit') {
        process.exit();
    }

    // If the message is not "exit", we can assume that it is the log path
    const logPath = message;
    if (!fs.existsSync(logPath)) {
        process.send(`error: The "${logPath}" file does not exist.`, processExit);
        return;
    }
    process.send(`Starting to watch log file: ${logPath}`);

    // Before we start to monitor the log file for new lines, we first want to read all of the existing log file to look for the save slot
    // Otherwise, the Racing+ client may not work properly if, for example, the user opens up the game, goes on save file 3,
    // and then opens the client
    let existingLines;
    try {
        existingLines = fs.readFileSync(logPath, 'utf8').split('\n');
    } catch (err) {
        process.send(`error: Failed to read from the "${logPath}" file: ${err}`);
        return;
    }
    for (const line of existingLines) {
        // This code is copy-pasted from below (but added the "[INFO] - " prefix)
        if (line.startsWith('[INFO] - Loading PersistentData ')) {
            // We want to keep track of which save file we are on so that we don't have to write 3 files at a time
            // This line looks like:
            // Loading PersistentData 1 from SteamCloud!
            // or:
            // Loading PersistentData 1 from local folder!
            const match = line.match(/Loading PersistentData (\d) /);
            if (match) {
                const slot = match[1];
                process.send(`Save file slot: ${slot}`);
            } else {
                process.send('error: Failed to parse the save slot number from the log.');
            }
        }
    }

    // None of the existing tail modules on NPM seem to work correctly with the Isaac log, so we have to code our own
    // The Isaac log file is glitchy; it is written to in such a way that the directory does not recieve updates
    // Thus, fs.watch will not work, because it uses the ReadDirectoryChangesW:
    // https://msdn.microsoft.com/en-us/library/windows/desktop/aa365465%28v=vs.85%29.aspx
    // Instead we need to use fs.watchFile, which is polling based and less efficient
    process.send(`Starting to watch file: ${logPath}`);
    const fd = fs.openSync(logPath, 'r');
    fs.watchFile(logPath, {
        interval: 50, // The default is 5007, so we need to poll much more frequently than that
    }, (curr, prev) => {
        if (prev.size === curr.size) {
            // Case 1 - The log file is the same size
            // (occasionally, the log file will be updated but have no new content)
        } else if (prev.size < curr.size) {
            // Case 2 - The log file has grown, so only read the new bytes
            const differential = curr.size - prev.size;
            const buffer = Buffer.alloc(differential);
            fs.read(fd, buffer, 0, differential, prev.size, logReadCallback);
        } else {
            // Case 3 - The log file has been truncated, so read everything
            // (this occurs whenever the game is restarted)
            const buffer = Buffer.alloc(curr.size);
            fs.read(fd, buffer, 0, curr.size, 0, logReadCallback);
        }
    });
});

// Handle the new blob of data
const logReadCallback = (err, bytes, buff) => {
    if (err) {
        process.send(`error: ${err}`, processExit);
        return;
    }

    const lines = buff.toString('utf8').split('\n');
    for (const line of lines) {
        parseLine(line);
    }
};

// Parse each line for relevant events
const parseLine = (line) => {
    // Skip blank lines
    if (line === '') {
        return;
    }

    if (line.startsWith('[INFO] - ')) {
        // Truncate the "[INFO] - " prefix
        line = line.substring(9, line.length);
    } else {
        // We don't care about non-"INFO" lines
        return;
    }

    if (line.startsWith('Loading PersistentData ')) {
        // We want to keep track of which save file we are on so that we don't have to write 3 files at a time
        // This line looks like:
        // Loading PersistentData 1 from SteamCloud!
        // or:
        // Loading PersistentData 1 from local folder!
        const match = line.match(/Loading PersistentData (\d) /);
        if (match) {
            const slot = match[1];
            process.send(`Save file slot: ${slot}`);
        } else {
            process.send('error: Failed to parse the save slot number from the log.');
        }
    } else if (line.startsWith('Menu Title Init')) {
        // They have entered the menu
        process.send('Title menu initialized.');
    } else if (line.startsWith('Lua Debug: Race error: Wrong mode.')) {
        process.send('Race error: Wrong mode.');
    } else if (line.startsWith('Lua Debug: Race validation succeeded.')) {
        // We look for this message to determine that the user has successfully downloaded and is running the Racing+ Lua mod
        process.send('Race validation succeeded.');
    } else if (line.startsWith('Lua Debug: New order9: ')) {
        const m = line.match(/Lua Debug: New order9: {(.+)}/);
        if (m) {
            process.send(`New order9: [${m[1]}]`);
        } else {
            process.send('error: Failed to parse the speedrun order9 from the log.');
        }
    } else if (line.startsWith('Lua Debug: New order14: ')) {
        const m = line.match(/Lua Debug: New order14: {(.+)}/);
        if (m) {
            process.send(`New order14: [${m[1]}]`);
        } else {
            process.send('error: Failed to parse the speedrun order14 from the log.');
        }
    } else if (line.startsWith('Lua Debug: New order7: ')) {
        const m = line.match(/Lua Debug: New order7: {(.+)}/);
        if (m) {
            process.send(`New order7: [${m[1]}]`);
        } else {
            process.send('error: Failed to parse the speedrun order7 from the log.');
        }
    } else if (line.startsWith('Lua Debug: New drop hotkey: ')) {
        const m = line.match(/Lua Debug: New drop hotkey: (.+)/);
        if (m) {
            process.send(`New drop hotkey: ${m[1]}`);
        } else {
            process.send('error: Failed to parse the drop hotkey from the log.');
        }
    } else if (line.startsWith('Lua Debug: New switch hotkey: ')) {
        const m = line.match(/Lua Debug: New switch hotkey: (.+)/);
        if (m) {
            process.send(`New switch hotkey: ${m[1]}`);
        } else {
            process.send('error: Failed to parse the switch hotkey from the log.');
        }
    } else if (line.startsWith('RNG Start Seed: ')) {
        // A new run has begun
        // (send this separately from the seed because race validation messages are checked before parsing the seed)
        process.send('A new run has begun.');

        // Send the seed
        const match = line.match(/RNG Start Seed: (.... ....)/);
        if (match) {
            const seed = match[1];
            process.send(`New seed: ${seed}`);
        } else {
            process.send('error: Failed to parse the run seed from the log.');
        }
    } else if (line.startsWith('Level::Init ')) {
        // A new floor was entered
        const match = line.match(/Level::Init m_Stage (\d+), m_StageType (\d+)/);
        if (match) {
            const stage = match[1];
            const type = match[2];
            process.send(`New floor: ${stage}-${type}`);
        } else {
            process.send('error: Failed to parse the floor from the log.');
        }
    } else if (line === 'Lua Debug: Entered the Mega Satan room.') {
        // The Void is floor 12; we use 13 as a fake floor
        process.send('New floor: 13-0');
    } else if (line.startsWith('Room ')) {
        // A new room was entered
        const match = line.match(/Room (.+?)\(/);
        if (match) {
            const roomID = match[1];
            process.send(`New room: ${roomID}`);
        }
        // Sometimes there are lines of "Room count #", so don't throw an error if the match fails
    } else if (line.startsWith('Adding collectible ')) {
        // A new item was picked up
        const match = line.match(/Adding collectible (\d+) /);
        if (match) {
            const item = match[1];
            process.send(`New item: ${item}`);
        } else {
            process.send('error: Failed to parse the item number from the log.');
        }
    } else if (line === 'playing cutscene 17 (Chest).') {
        process.send('Finished run: Blue Baby');
    } else if (line === 'playing cutscene 18 (Dark Room).') {
        process.send('Finished run: The Lamb');
    } else if (line === 'playing cutscene 19 (Mega Satan).') {
        process.send('Finished run: Mega Satan');
    } else if (line.startsWith('Lua Debug: Finished run - ')) {
        // The trophy was touched
        const match = line.match(/Lua Debug: Finished run - (\d+)/);
        if (match) {
            const time = match[1];
            process.send(`Finished run: Trophy - ${time}`);
        } else {
            process.send('error: Failed to parse the run time from the log.');
        }
    }
};
