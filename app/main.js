// Build with:
// npm run dist --python="C:\Python27\python.exe"

// Update with:
// ncu --upgradeAll

'use strict';

/*
    Imports
*/

const electron      = require('electron');
const app           = electron.app;
const BrowserWindow = electron.BrowserWindow;
const ipcMain       = electron.ipcMain;
const autoUpdater   = electron.autoUpdater;
const fs            = require('fs');
const os            = require('os');
const ChildProcess  = require('child_process');
const path          = require('path');
const isDev         = require('electron-is-dev');
const teeny         = require('teeny-conf');
const globals       = require('./assets/js/globals');

/*
    Constants
*/

const assetsFolder = path.resolve(process.execPath, '..', '..', '..', '..', 'app', 'assets');
const logFile      = (isDev ? 'Racing+.log' : path.resolve(process.execPath, '..', '..', 'Racing+.log'));
const settingsFile = (isDev ? 'settings.json' : path.resolve(process.execPath, '..', '..', 'settings.json'));

/*
    Global variables
*/

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
var mainWindow;
var checkForUpdates = true;

/*
    Squirrel stuff
    From: https://github.com/electron/windows-installer#handling-squirrel-events
*/

// This package automatically takes care of everything except for a few edge cases
if (require('electron-squirrel-startup')) {
    return;
}

// If there are arguments and we are not running in a development environment
if (process.argv.length !== 1 && isDev === false) {
    let squirrelEvent = process.argv[1];
    writeLog('Recieved squirrelEvent: ' + squirrelEvent);

    // We can't check for updates on the very first run or else bad things will happen
    // (https://github.com/electron/electron/blob/master/docs/api/auto-updater.md)
    if (squirrelEvent === '--squirrel-firstrun') {
        checkForUpdates = false;
    } else if (squirrelEvent === '--squirrel-updated') {
        // If we just updated, we probably already have the latest version
        checkForUpdates = false;
    }
}

/*
    Initialize settings
*/

let settings = new teeny(settingsFile);
settings.loadOrCreateSync();

/*
    Electron boilerplate code
*/

function createWindow() {
    // Create the browser window
    let width = 1110;
    let height = 720;
    //if (isDev) {
        width += 500;
    //}
    mainWindow = new BrowserWindow({
        width:  width,
        height: height,
        icon:   path.resolve(assetsFolder, 'img', 'favicon.png'),
        title:  'Racing+',
        frame:  false,
    });
    mainWindow.loadURL(`file://${__dirname}/index.html`);

    // Dev-only stuff
    //if (isDev === true) {
        mainWindow.webContents.openDevTools();
    //}

    // Now that the window is created, check for updates
    if (checkForUpdates === true && isDev === false) {
        electron.autoUpdater.on('error', function(err) {
            writeLog(`Update error: ${err.message}`);
            mainWindow.webContents.send('autoUpdater', 'error');
        });

        electron.autoUpdater.on('checking-for-update', function() {
            writeLog('autoUpdater - checking-for-update');
            mainWindow.webContents.send('autoUpdater', 'checking-for-update');
        });

        electron.autoUpdater.on('update-available', function() {
            writeLog('autoUpdater - update-available');
            mainWindow.webContents.send('autoUpdater', 'update-available');
        });

        electron.autoUpdater.on('update-not-available', function() {
            writeLog('autoUpdater - update-not-available');
            mainWindow.webContents.send('autoUpdater', 'update-not-available');
        });

        electron.autoUpdater.on('update-downloaded', function(e, notes, name, date, url) {
            writeLog('autoUpdater - update-downloaded');
            mainWindow.webContents.send('autoUpdater', 'update-downloaded');
        });

        let url = 'http' + (globals.secure ? 's' : '') + '://' + globals.domain + ':' + globals.squirrelPort + '/update/win32';
        electron.autoUpdater.setFeedURL(url);
        electron.autoUpdater.checkForUpdates();
    }

    mainWindow.on('closed', function() {
        // Dereference the window object, usually you would store windows
        // in an array if your app supports multi windows, this is the time
        // when you should delete the corresponding element.
        mainWindow = null;
    });
}

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
app.on('ready', createWindow);

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

/*
    IPC handlers
*/

ipcMain.on('asynchronous-message', function(event, arg) {
    console.log('Recieved message:', arg);
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
    }
});

/*
    Miscellaneous functions
*/

function writeLog(message) {
    let datetime = new Date().toUTCString();
    message = datetime + ' - ' + message + os.EOL;
    fs.appendFileSync(logFile, message);
    console.log(message); // Also print the message to the screen for debugging purposes
}
