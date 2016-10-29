// Build with:
// npm run dist --python="C:\Python27\python.exe"

'use strict';

/*
	Imports
*/

const electron      = require('electron');
const app           = electron.app; // Module to control application life
const BrowserWindow = electron.BrowserWindow; // Module to create native browser window
const ipcMain       = electron.ipcMain;
const fs            = require('fs');
const os            = require('os');
const ChildProcess  = require('child_process');
const path          = require('path');
const isDev         = require('electron-is-dev');

/*
	Constants
*/

const appFolder      = path.resolve(process.execPath, '..');
const rootAtomFolder = path.resolve(appFolder, '..');
const updateDotExe   = path.resolve(path.join(rootAtomFolder, 'Update.exe'));
const exeName        = path.basename(process.execPath);
const assetsFolder   = path.resolve(appFolder, '..', '..', '..', 'app', 'assets');
const logFile        = path.resolve(rootAtomFolder, 'Racing+.log');

/*
	Initialization
*/

writeLog('App launched.');

/*
	Squirrel stuff
	From: https://github.com/electron/windows-installer#handling-squirrel-events
*/

// This package automatically takes care of everything except for a few edge cases
if (require('electron-squirrel-startup')) {
	return;
}

// If there are arguments and we are not running in a development environment
let firstRun = false;
if (process.argv.length !== 1 && path.basename(process.argv[0]) !== 'electron.exe') {
	const squirrelEvent = process.argv[1];

	// We can't check for updates on the very first run or else bad things will happen
	// (https://github.com/electron/electron/blob/master/docs/api/auto-updater.md)
	if (squirrelEvent === '--squirrel-firstrun') {
		firstRun = true;
	}
}

/*
	Electron boilerplate code
*/

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow;

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
	mainWindow.loadURL(`file://${__dirname}/index.html`);

	// Dev-only stuff
	if (isDev === true) {
		mainWindow.webContents.openDevTools();
	}

	// Emitted when the window is closed.
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

ipcMain.on('asynchronous-message', (event, arg) => {
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
	fs.appendFile(logFile, message);
}
