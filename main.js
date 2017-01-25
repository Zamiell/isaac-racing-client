/*
    Racing+ Client
    for The Binding of Isaac: Afterbirth+
    (main process)
*/

// Log file location:
// %APPDATA%\..\Local\Programs\Racing+.log
// Log file location (for copy pasting into Discord):
// %APPDATA%\\..\Local\Programs\Racing+.log

// Settings file location:
// %APPDATA%\..\Local\Programs\settings.json
// Settings file location (for copy pasting into Discord):
// %APPDATA%\..\Local\Programs\settings.json

// Build:
// npm run dist --python="C:\Python27\python.exe"
// Build and upload to GitHub:
// npm run dist2 --python="C:\Python27\python.exe"

// Reinstall NPM dependencies:
// (ncu updates the package.json, so blow away everything and reinstall)
// ncu -a && rm -rf node_modules && npm install --python="C:\Python27\python.exe"

// To build Greenworks:
// (from: https://github.com/greenheartgames/greenworks)
// cd D:\Repositories\isaac-racing-client\node_modules\greenworks
// set HOME=C:\Users\james\.electron-gyp && node-gyp rebuild --target=1.4.14 --arch=x64 --dist-url=https://atom.io/download/atom-shell

// Count lines of code:
// cloc . --exclude-dir .git,dist,node_modules,css,fonts,words

'use strict';

// Imports
const electron       = require('electron');
const app            = electron.app;
const BrowserWindow  = electron.BrowserWindow;
const ipcMain        = electron.ipcMain;
const globalShortcut = electron.globalShortcut;
const autoUpdater    = require('electron-auto-updater').autoUpdater; // Import electron-builder's autoUpdater as opposed to the generic electron autoUpdater
                                                                     // See: https://github.com/electron-userland/electron-builder/wiki/Auto-Update
const execFile       = require('child_process').execFile;
const fork           = require('child_process').fork;
const fs             = require('fs');
const os             = require('os');
const path           = require('path');
const isDev          = require('electron-is-dev');
const tracer         = require('tracer');
const Raven          = require('raven');
const teeny          = require('teeny-conf');

// Constants
const assetsFolder = path.resolve(process.execPath, '..', '..', '..', '..', 'assets');
const logFile      = (isDev ? 'Racing+.log' : path.resolve(process.execPath, '..', '..', 'Racing+.log'));

// Global variables
var mainWindow; // Keep a global reference of the window object
                // (otherwise the window will be closed automatically when the JavaScript object is garbage collected)
var startedLogWatcher = false;

/*
    Logging (code duplicated between main, renderer, and log-watcher because of require/nodeRequire issues)
*/

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

// Get the version
let packageFileLocation = path.join(__dirname, 'package.json');
let packageFile = fs.readFileSync(packageFileLocation, 'utf8');
let version = 'v' + JSON.parse(packageFile).version;
log.info('Racing+ client', version, 'started!');

// Raven (error logging to Sentry)
Raven.config('https://0d0a2118a3354f07ae98d485571e60be:843172db624445f1acb86908446e5c9d@sentry.io/124813', {
    autoBreadcrumbs: true,
    release: version,
    environment: (isDev ? 'development' : 'production'),
    dataCallback: function(data) {
        log.error(data);
        return data;
    },
}).install();

/*
    Subroutines
*/

function createWindow() {
    // Create the browser window
    let width = 1110;
    let height = 720;
    if (isDev) {
        width += 500;
    }
    mainWindow = new BrowserWindow({
        width:  width,
        height: height,
        icon:   path.resolve(assetsFolder, 'img', 'favicon.png'),
        title:  'Racing+',
        frame:  false,
    });
    if (isDev === true) {
        mainWindow.webContents.openDevTools();
    }
    mainWindow.loadURL(`file://${__dirname}/index.html`);

    // Remove the taskbar flash state (this isn't currently used)
    mainWindow.once('focus', function() {
        mainWindow.flashFrame(false);
    });

    // Dereference the window object when it is closed
    mainWindow.on('closed', function() {
        mainWindow = null;
    });
}

function autoUpdate() {
    // Now that the window is created, check for updates
    if (isDev === false) {
        autoUpdater.on('error', function(err) {
            log.error(err.message);
            Raven.captureException(err);
            mainWindow.webContents.send('autoUpdater', 'error');
        });

        autoUpdater.on('checking-for-update', function() {
            mainWindow.webContents.send('autoUpdater', 'checking-for-update');
        });

        autoUpdater.on('update-available', function() {
            mainWindow.webContents.send('autoUpdater', 'update-available');
        });

        autoUpdater.on('update-not-available', function() {
            mainWindow.webContents.send('autoUpdater', 'update-not-available');
        });

        autoUpdater.on('update-downloaded', function(e, notes, name, date, url) {
            mainWindow.webContents.send('autoUpdater', 'update-downloaded');
        });

        log.info('Checking for updates.');
        autoUpdater.checkForUpdates();
    }
}

function registerKeyboardHotkeys() {
    // Register global hotkeys
    const hotkeyIsaacFocus = globalShortcut.register('Alt+1', function() {
        let command = path.join(__dirname, '/assets/programs/isaacFocus/isaacFocus.exe');
        execFile(command);
    });
    if (!hotkeyIsaacFocus) {
        log.warn('Alt+1 hotkey registration failed.');
    }

    const hotkeyRacingPlusFocus = globalShortcut.register('Alt+2', function() {
        mainWindow.focus();
    });
    if (!hotkeyRacingPlusFocus) {
        log.warn('Alt+2 hotkey registration failed.');
    }

    const hotkeyReady = globalShortcut.register('Alt+R', function() {
        mainWindow.webContents.send('hotkey', 'ready');
    });
    if (!hotkeyReady) {
        log.warn('Alt+R hotkey registration failed.');
    }

    const hotkeyQuit = globalShortcut.register('Alt+Q', function() {
        mainWindow.webContents.send('hotkey', 'quit');
    });
    if (!hotkeyQuit) {
        log.warn('Alt+Q hotkey registration failed.');
    }
}

/*
    Application handlers
*/

// Check to see if the application is already open
if (isDev === false) {
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
app.on('ready', function() {
    createWindow();
    autoUpdate();
    registerKeyboardHotkeys();
});

// Quit when all windows are closed.
app.on('window-all-closed', function() {
    // On OS X it is common for applications and their menu bar
    // to stay active until the user quits explicitly with Cmd + Q
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', function() {
    // On OS X it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (mainWindow === null) {
        createWindow();
    }
});

app.on('will-quit', function() {
    globalShortcut.unregisterAll();
});

/*
    IPC handlers
*/

ipcMain.on('asynchronous-message', function(event, arg) {
    log.info('Main process recieved message:', arg);

    if (arg === 'minimize') {
        mainWindow.minimize();
    } else if (arg === 'maximize') {
        if (mainWindow.isMaximized() === true) {
            mainWindow.unmaximize();
        } else {
            mainWindow.maximize();
        }
    } else if (arg === 'close') {
        app.quit();
    } else if (arg === 'restart') {
        app.relaunch();
        app.quit();
    } else if (arg === 'quitAndInstall') {
        autoUpdater.quitAndInstall();
    } else if (arg.startsWith('logWatcher ') && startedLogWatcher === false) {
        // Start the log watcher in a separate process for performance reasons
        startedLogWatcher = true;
        var child = fork('./log-watcher');
        log.info('Started the log watcher.');

        // Receive notifications from the child process
        child.on('message', function(message) {
            // Pass the message to the renderer (browser) process
            mainWindow.webContents.send('logWatcher', message);
        });

        // Feed the child the path to the Isaac log file
        var logPath = arg.match(/^logWatcher (.+)/)[1];
        child.send(logPath);
    }
});
