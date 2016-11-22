// Build with:
// npm run dist --python="C:\Python27\python.exe"
// npm run dist2 --python="C:\Python27\python.exe"

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

var mainWindow; // Keep a global reference of the window object (otherwise the window will be closed automatically when the JavaScript object is garbage collected)
var checkForUpdates = true;
var settings = new teeny(settingsFile);
settings.loadOrCreateSync();

/*
    Subroutines
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
        show:   false,
    });
    mainWindow.loadURL(`file://${__dirname}/index.html`);

    // Hide the window until it is finished loading
    mainWindow.once('ready-to-show', function() {
        mainWindow.show();
        //if (isDev === true) {
            mainWindow.webContents.openDevTools();
        //}
        windowReady();
    });

    // Dereference the window object when it is closed
    mainWindow.on('closed', function() {
        mainWindow = null;
    });
}

function windowReady() {
    // Now that the window is created, check for updates
    if (checkForUpdates === true && isDev === false) {
        // Import electron-builder's autoUpdater as opposed to the generic electron autoUpdater (https://github.com/electron-userland/electron-builder/wiki/Auto-Update)
        // (We don't import this at the top because it will throw errors in a development environment)
        const autoUpdater = require('electron-auto-updater').autoUpdater;

        autoUpdater.on('error', function(err) {
            writeLog(`Update error: ${err.message}`);
            mainWindow.webContents.send('autoUpdater', 'error');
        });

        autoUpdater.on('checking-for-update', function() {
            writeLog('autoUpdater - checking-for-update');
            mainWindow.webContents.send('autoUpdater', 'checking-for-update');
        });

        autoUpdater.on('update-available', function() {
            writeLog('autoUpdater - update-available');
            mainWindow.webContents.send('autoUpdater', 'update-available');
        });

        autoUpdater.on('update-not-available', function() {
            writeLog('autoUpdater - update-not-available');
            mainWindow.webContents.send('autoUpdater', 'update-not-available');
        });

        autoUpdater.on('update-downloaded', function(e, notes, name, date, url) {
            writeLog('autoUpdater - update-downloaded');
            mainWindow.webContents.send('autoUpdater', 'update-downloaded');
        });

        autoUpdater.checkForUpdates();
    }
}

function writeLog(message) {
    let datetime = new Date().toUTCString();
    message = datetime + ' - ' + message + os.EOL;
    fs.appendFileSync(logFile, message);
    console.log(message); // Also print the message to the screen for debugging purposes
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
