/*
    Racing+ Client
    for The Binding of Isaac: Afterbirth+
    (main process)
*/

/*

Send me your Isaac `log.txt file`, which is located here:
```
C:\Users\james\Documents\My Games\Binding of Isaac Afterbirth+\log.txt
```
And send me your Racing+ log file, which is located here:
```
C:\Users\james\AppData\Local\Programs\Racing+ 2017-##-##.log
```
And if you are still in the race, send me your `save1.dat` file (for save slot #1), which is located here:
```
C:\Users\james\Documents\My Games\Binding of Isaac Afterbirth+ Mods\racing+_857628390\save1.dat
```

*/

// Settings file location:
// C:\Users\james\AppData\Local\Programs\settings.json

// Build:
// npm run dist --python="C:\Python27\python.exe"
// Build and upload to GitHub:
// npm run dist2 --python="C:\Python27\python.exe"

// Reinstall NPM dependencies:
// (ncu updates the package.json, so blow away everything and reinstall)
// ncu -a && rm -rf node_modules && npm install --python="C:\Python27\python.exe"

// Count lines of code:
// cloc . --exclude-dir .git,dist,node_modules,css,fonts,words

// Convert corrupted PNGs with ImageMagick:
// http://forums.gamesalad.com/discussion/67365/problems-with-png-images-use-these-methods-to-fix-your-pngs
// sips --deleteColorManagementProperties ###.png

// List of files to update during Booster Packs:
// 1) mod/content/items.xml
// 2) mod/resources/gfx/items2/items/..
// 3) mod/resources/gfx/items2/trinkets/..
// 4) mod/resources/gfx/items3/items/..
// 5) mod/resources/gfx/items3/trinkets/..
// 6) data/items.json
// 7) data/trinkets.json
// 8) img/items/#.png
// 9) img/trinkets/#.png
// 10) website images copy from item tracker

/*

Other notes:
- Electron 1.7.6 gives error with graceful-fs, so staying on version 1.6.11

*/

// Imports
const fs = require('fs');
const path = require('path');
const { execFile, fork } = require('child_process');
const {
    app,
    BrowserWindow,
    ipcMain,
    globalShortcut,
} = require('electron'); // eslint-disable-line import/no-extraneous-dependencies
// The "electron" package is only allowed to be in the devDependencies section
const { autoUpdater } = require('electron-updater'); // Import electron-builder's autoUpdater as opposed to the generic electron autoUpdater
// See: https://github.com/electron-userland/electron-builder/wiki/Auto-Update
const isDev = require('electron-is-dev');
const Raven = require('raven');
const opn = require('opn');
const globals = require('./js/globals');
const version = require('./version');
const log = require('./log');
const settings = require('./settings');
require('./greenworks'); // Including this in the main process is necessary for the macOS version to work for some reason

// Global variables
let mainWindow;
// Keep a global reference of the window object
// (otherwise the window will be closed automatically when the JavaScript object is garbage collected)
const childProcesses = {};
const childProcessNames = [
    'steam',
    'log-watcher',
    'steam-water',
    'isaac',
];
for (const childProcessName of childProcessNames) {
    childProcesses[childProcessName] = null;
}
let errorHappened = false;

// Welcome message
const middleLine = `Racing+ client ${version} started!`;
let separatorLine = '';
for (let i = 0; i < middleLine.length; i++) {
    separatorLine += '-';
}
log.info(`+-${separatorLine}-+`);
log.info(`| ${middleLine} |`);
log.info(`+-${separatorLine}-+`);

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
    dataCallback: (data) => {
        log.error(data);
        return data;
    },
    shouldSendCallback: (data) => {
        log.info(data);
    },
}).install();

/*
    Subroutines
*/

function createWindow() {
    // Figure out what the window size and position should be
    if (typeof settings.get('window') === 'undefined') {
        // If this is the first run, create an empty window object
        settings.set('window', {});
        settings.saveSync();
    }
    const windowSettings = settings.get('window');

    // Width
    let width;
    if (Object.prototype.hasOwnProperty.call(windowSettings, 'width')) {
        ({ width } = windowSettings);
    } else {
        width = (isDev ? 1610 : 1110);
    }

    // Height
    let height;
    if (Object.prototype.hasOwnProperty.call(windowSettings, 'height')) {
        ({ height } = windowSettings);
    } else {
        height = 720;
    }

    // Create the browser window
    mainWindow = new BrowserWindow({
        x: windowSettings.x,
        y: windowSettings.y,
        width,
        height,
        icon: path.resolve(__dirname, 'img', 'favicon.png'),
        title: 'Racing+',
        frame: false,
    });
    if (isDev) {
        mainWindow.webContents.openDevTools();
    }

    // Figure out if we should use the Singapore proxy or not
    // (only Chinese users should use it)
    // https://github.com/electron/electron/blob/master/docs/api/locales.md
    if (app.getLocale().startsWith('zh')) {
        mainWindow.webContents.session.setProxy({
            proxyRules: globals.chineseProxy,
        }, () => {
            mainWindow.loadURL(`file://${__dirname}/index.html`);
        });
    } else {
        mainWindow.loadURL(`file://${__dirname}/index.html`);
    }

    // Remove the taskbar flash state
    // (this is not currently used)
    mainWindow.once('focus', () => {
        mainWindow.flashFrame(false);
    });

    // Save the window size and position
    mainWindow.on('close', () => {
        const windowBounds = mainWindow.getBounds();

        // We have to re-get the settings, since the renderer process may have changed them
        // If so, our local copy of all of the settings is no longer current
        settings.loadOrCreateSync();
        settings.set('window', windowBounds);
        settings.saveSync();
    });

    // Dereference the window object when it is closed
    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

function autoUpdate() {
    // Don't check for updates when running the program from source
    if (isDev) {
        return;
    }

    // Only check for updates on Windows
    if (process.platform !== 'win32') { // This will return "win32" even on 64-bit Windows
        return;
    }

    // Now that the window is created, check for updates
    autoUpdater.on('error', (err) => {
        log.error(err.message);
        Raven.captureException(err);
        mainWindow.webContents.send('autoUpdater', 'error');
    });

    autoUpdater.on('checking-for-update', () => {
        mainWindow.webContents.send('autoUpdater', 'checking-for-update');
    });

    autoUpdater.on('update-available', (info) => {
        mainWindow.webContents.send('autoUpdater', 'update-available');
    });

    autoUpdater.on('update-not-available', (info) => {
        mainWindow.webContents.send('autoUpdater', 'update-not-available');
    });

    autoUpdater.on('update-downloaded', (info) => {
        mainWindow.webContents.send('autoUpdater', 'update-downloaded');
    });

    // Monkey patch from:
    // https://github.com/electron-userland/electron-builder/issues/2377
    const monkeyPatch = autoUpdater.httpExecutor.doRequest;
    autoUpdater.httpExecutor.doRequest = function monkeyPatchFunction(options, callback) {
        const req = monkeyPatch.call(this, options, callback);
        req.on('redirect', () => req.followRedirect());
        return req;
    };

    log.info('Checking for updates.');
    autoUpdater.checkForUpdatesAndNotify();
}

function registerKeyboardHotkeys() {
    // Register global hotkeys
    const hotkeyIsaacLaunch = globalShortcut.register('Alt+B', () => {
        opn('steam://rungameid/250900');
    });
    if (!hotkeyIsaacLaunch) {
        log.warn('Alt+B hotkey registration failed.');
    }

    const hotkeyIsaacFocus = globalShortcut.register('Alt+1', () => {
        if (process.platform === 'win32') { // This will return "win32" even on 64-bit Windows
            const pathToFocusIsaac = path.join(__dirname, 'programs', 'focusIsaac', 'focusIsaac.exe');
            execFile(pathToFocusIsaac, (error, stdout, stderr) => {
                // We have to attach an empty callback to this or it does not work for some reason
            });
        }
    });
    if (!hotkeyIsaacFocus) {
        log.warn('Alt+1 hotkey registration failed.');
    }

    const hotkeyRacingPlusFocus = globalShortcut.register('Alt+2', () => {
        mainWindow.focus();
    });
    if (!hotkeyRacingPlusFocus) {
        log.warn('Alt+2 hotkey registration failed.');
    }

    const hotkeyReady = globalShortcut.register('Alt+R', () => {
        mainWindow.webContents.send('hotkey', 'ready');
    });
    if (!hotkeyReady) {
        log.warn('Alt+R hotkey registration failed.');
    }

    const hotkeyFinish = globalShortcut.register('Alt+F', () => {
        mainWindow.webContents.send('hotkey', 'finish');
    });
    if (!hotkeyFinish) {
        log.warn('Alt+F hotkey registration failed.');
    }

    const hotkeyQuit = globalShortcut.register('Alt+Q', () => {
        mainWindow.webContents.send('hotkey', 'quit');
    });
    if (!hotkeyQuit) {
        log.warn('Alt+Q hotkey registration failed.');
    }
}

function startChildProcess(name) {
    // Our starting location in the directory structure will be different depending certain factors
    let childProcessBasePath;
    const childProcessOptions = {};
    if (isDev) {
        // In development, "__dirname" is:
        // "C:\Repositories\isaac-racing-client\src"
        childProcessBasePath = __dirname;
    } else if (process.platform === 'darwin') {
        // On a bundled macOS app, "__dirname" is:
        // "/Applications/Racing+.app/Contents/Resources/app.asar/src"
        childProcessBasePath = __dirname;

        // There are problems when forking inside of an ASAR archive
        // See: https://github.com/electron/electron/issues/2708
        childProcessOptions.cwd = path.join(__dirname, '..', '..');
    } else {
        // On a bundled Windows app, "__dirname" is:
        // "C:\Users\[Username]\AppData\Local\Programs\RacingPlus\resources\app.asar\src"
        childProcessBasePath = __dirname;

        // There are problems when forking inside of an ASAR archive
        // See: https://github.com/electron/electron/issues/2708
        childProcessOptions.cwd = path.join(__dirname, '..', '..');
    }
    const childProcessPath = path.join(childProcessBasePath, name);
    // Normally, we would want to check to see if the file exists before running it
    // However, due to oddities with files inside asar archives, if we try to check for it, it won't exist

    // Start it
    childProcesses[name] = fork(childProcessPath, childProcessOptions);
    log.info(`Started the "${childProcessPath}" child process:`);

    // Receive notifications from the child process
    childProcesses[name].on('message', (message) => {
        // Pass the message to the renderer (browser) process
        mainWindow.webContents.send(name, message);
    });

    // Track errors
    childProcesses[name].on('error', (err) => {
        // Pass the error to the renderer (browser) process
        mainWindow.webContents.send(name, `error: ${err}`);
    });

    // Track when the process exits
    childProcesses[name].on('exit', () => {
        // If the user is exiting the program, the main window might have already closed, so check for that
        if (mainWindow !== null) {
            mainWindow.webContents.send(name, 'exited');
        }
    });
}

/*
    Application handlers
*/

// Check to see if the application is already open
if (!isDev) {
    const shouldQuit = app.makeSingleInstance((commandLine, workingDirectory) => {
        // A second instance of the program was opened, so just focus the existing window
        if (mainWindow) {
            if (mainWindow.isMinimized()) mainWindow.restore();
            mainWindow.focus();
        }
    });
    if (shouldQuit) {
        app.quit();
    }
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', () => {
    createWindow();
    autoUpdate();
    registerKeyboardHotkeys();
});

// Quit when all windows are closed.
app.on('window-all-closed', () => {
    // On macOS it is common for applications and their menu bar
    // to stay active until the user quits explicitly with Cmd + Q
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    // On macOS it is common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (mainWindow === null) {
        createWindow();
    }
});

// Write all default values to the "save1.dat", "save2.dat", and "save3.dat" files
app.on('before-quit', () => {
    if (errorHappened) {
        log.info('Not modifying the 3 "save.dat" files since we got an error.');
        return;
    }

    // Find the location of the Isaac mods directory
    let modsPath;
    if (process.platform === 'linux') {
        modsPath = path.join(path.dirname(settings.get('logFilePath')), '..', 'binding of isaac afterbirth+ mods');
    } else {
        modsPath = path.join(path.dirname(settings.get('logFilePath')), '..', 'Binding of Isaac Afterbirth+ Mods');
    }
    if (!fs.existsSync(modsPath)) {
        log.info('Attempted to write default values to the "save.dat" files, but the Isaac mods directory does not appear to exist.');
        return;
    }

    // Find the location of the Racing+ mod, if it exists
    let racingPlusModPath = path.join(modsPath, globals.modNameDev); // Assume a dev environment by default
    if (!fs.existsSync(racingPlusModPath)) {
        racingPlusModPath = path.join(modsPath, globals.modName);
    }
    if (!fs.existsSync(racingPlusModPath)) {
        log.info('Attempted to write default values to the "save.dat" files, but the Racing+ mod does not appear to exist.');
        return;
    }

    // Find the location of "save-defaults.dat", if it exists
    const defaultSaveDat = path.join(racingPlusModPath, 'save-defaults.dat');
    if (!fs.existsSync(defaultSaveDat)) {
        log.info('Attempted to write default values to the "save.dat" files, but the "save-defaults.dat" does not appear to exist.');
        return;
    }

    // Go through the 3 "save.dat" files
    for (let i = 1; i <= 3; i++) {
        // Find the location of the file
        const saveDat = path.join(racingPlusModPath, `save${i}.dat`);
        if (!fs.existsSync(saveDat)) {
            // The "save.dat" file does not exist for some reason
            // This should never happen because all 3 save.dat files are downloaded by default when the user subscribes over Steam
            // Furthermore, if doing non-custom races, the Racing+ client is also writing to these files during races
            // For now, just copy over the default save.dat file
            try {
                // "fs.copyFileSync" is only in Node 8.5.0 and Electron isn't on that version yet
                // fs.copyFileSync(defaultSaveDat, saveDat);
                const data = fs.readFileSync(defaultSaveDat);
                fs.writeFileSync(saveDat, data);
                log.info(`The "${saveDat}" does not exist. (This should never happen.) Made a new one from the "save-defaults.dat" file.`);
            } catch (err) {
                log.error(`Error while copying the the "save-defaults.dat" file to the "save${i}.dat" file: ${err}`);
            }
            continue;
        }

        // Read it and set all non-speedrun order variables to defaults
        let json;
        try {
            json = JSON.parse(fs.readFileSync(saveDat, 'utf8'));
        } catch (err) {
            log.error(`Failed to read the "${saveDat}" file: ${err}`);
            continue;
        }
        json.status = 'none';
        json.myStatus = 'not ready';
        json.ranked = false;
        json.solo = false;
        json.rFormat = 'unseeded';
        json.character = 3;
        json.goal = 'Blue Baby';
        json.seed = '-';
        json.startingItems = [];
        json.countdown = -1;
        json.placeMid = 0;
        json.place = 1;
        if (typeof json.order7 === 'undefined') {
            json.order7 = [0];
        }
        if (typeof json.order9 === 'undefined') {
            json.order9 = [0];
        }
        if (typeof json.order14 === 'undefined') {
            json.order14 = [0];
        }
        try {
            fs.writeFileSync(saveDat, JSON.stringify(json), 'utf8');
            log.info(`Wrote default values to "save${i}.dat".`);
        } catch (err) {
            log.error(`Error while writing the "save${i}.dat" file: ${err}`);
        }
    }
});

app.on('will-quit', () => {
    // Unregister the global keyboard hotkeys
    globalShortcut.unregisterAll();

    // Tell the child processes to exit (in Node, they will live forever even if the parent closes)
    for (const childProcess of Object.values(childProcesses)) {
        if (childProcess !== null) {
            childProcess.send('exit');
        }
    }
});

/*
    IPC handlers
*/

ipcMain.on('asynchronous-message', (event, arg1, arg2) => {
    log.info('Main process recieved message:', arg1);

    if (arg1 === 'minimize') {
        mainWindow.minimize();
    } else if (arg1 === 'maximize') {
        if (mainWindow.isMaximized()) {
            mainWindow.unmaximize();
        } else {
            mainWindow.maximize();
        }
    } else if (arg1 === 'close') {
        app.quit();
    } else if (arg1 === 'restart') {
        errorHappened = true; // Don't reset our 3 "save.dat" files if we did a /restart
        app.relaunch();
        app.quit();
    } else if (arg1 === 'quitAndInstall') {
        autoUpdater.quitAndInstall();
    } else if (arg1 === 'devTools') {
        mainWindow.webContents.openDevTools();
    } else if (arg1 === 'error') {
        errorHappened = true;
    } else if (arg1 === 'steam' && childProcesses.steam === null) {
        // Initialize the Greenworks API in a separate process because otherwise the game will refuse to open if Racing+ is open
        // (Greenworks uses the same AppID as Isaac, so Steam gets confused)
        startChildProcess('steam');
    } else if (arg1 === 'steamExit') {
        // The renderer has successfully authenticated and is now establishing a WebSocket connection, so we can kill the Greenworks process
        if (childProcesses.steam !== null) {
            childProcesses.steam.send('exit');
        }
    } else if (arg1 === 'log-watcher' && childProcesses['log-watcher'] === null) {
        // Start the log watcher in a separate process for performance reasons
        startChildProcess('log-watcher');

        // Feed the child the path to the Isaac log file
        childProcesses['log-watcher'].send(arg2);
    } else if (arg1 === 'steam-watcher' && childProcesses['steam-watcher'] === null) {
        // Start the log watcher in a separate process for performance reasons
        startChildProcess('steam-watcher');

        // Feed the child the ID of the Steam user
        childProcesses['steam-watcher'].send(arg2);
    } else if (arg1 === 'isaac' && childProcesses.isaac === null) {
        // Start the Isaac launcher in a separate process for performance reasons
        startChildProcess('isaac');

        // Feed the child the path to the Isaac mods directory and the "force" boolean
        childProcesses.isaac.send(arg2);
    }
});
