/*
    Child process that checks to see if the user logs out of Steam
*/

// Imports
const fs = require('fs-extra');
const path = require('path');
const isDev = require('electron-is-dev');
const Raven = require('raven');
const Registry = require('winreg');

// Handle errors
process.on('uncaughtException', (err) => {
    process.send(`error: ${err}`, processExit);
});
const processExit = () => {
    process.exit();
};

// Get the version
const packageFileLocation = path.join(__dirname, '..', 'package.json');
const packageFile = fs.readFileSync(packageFileLocation, 'utf8');
const version = `v${JSON.parse(packageFile).version}`;

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
}).install();

/*
    Steam watcher stuff
*/

let steamID = '';

// The parent will communicate with us, telling us the ID of the Steam user
process.on('message', (message) => {
    // The child will stay alive even if the parent has closed, so we depend on the parent telling us when to die
    if (message === 'exit') {
        process.exit();
    }

    // If the message is not "exit", we can assume that it is the log path
    steamID = message;

    setInterval(checkActiveUser, 5000); // Check every 5 seconds
});

function checkActiveUser() {
    const steamKey = new Registry({
        hive: Registry.HKCU,
        key: '\\Software\\Valve\\Steam\\ActiveProcess',
    });
    steamKey.get('ActiveUser', (err, item) => {
        if (err) {
            process.send('error: Failed to read the Windows registry when trying to figure out what the active Steam user is.', processExit);
            return;
        }

        // The active user is stored in the registry as a hexidecimal value, so we have to convert it to base 10
        const activeUserDecimal = parseInt(item.value, 16);

        if (steamID !== activeUserDecimal) {
            process.send('error: It appears that you have logged out of Steam.');
        }
    });
}
