// Racing+ Client
// for The Binding of Isaac: Repentance
// (main process)

import * as remote from "@electron/remote/main";
import * as electron from "electron";
import electronContextMenu from "electron-context-menu";
import log from "electron-log";
import pkg from "../../package.json";
import initLogging from "../common/initLogging";
import * as settings from "../common/settings";
import * as childProcesses from "./childProcesses";
import * as ipc from "./ipc";
import IS_DEV from "./isDev";
import * as onReady from "./onReady";

let window = null as null | electron.BrowserWindow;

main();

function main() {
  initLogging();
  printWelcomeMessage();
  checkSecondInstance();
  settings.initDefault();
  initElectronHandlers();
}

function printWelcomeMessage() {
  const welcomeText = `Racing+ client ${pkg.version} started.`;
  const hyphens = "-".repeat(welcomeText.length);
  const welcomeTextBorder = `+-${hyphens}-+`;
  log.info(welcomeTextBorder);
  log.info(`| ${welcomeText} |`);
  log.info(welcomeTextBorder);
}

function checkSecondInstance() {
  // Don't allow multiple instances of the program to run
  // (except for in development)
  if (IS_DEV) {
    return;
  }

  const hasLock = electron.app.requestSingleInstanceLock();
  if (!hasLock) {
    log.info("Second instance detected; quitting.");
    electron.app.quit();
  }
}

function initElectronHandlers() {
  // Needed so that remote works in the renderer process
  // https://github.com/electron/remote
  remote.initialize();

  // This method will be called when Electron has finished initialization and is ready to create
  // browser windows
  electron.app.on("ready", () => {
    window = onReady.createWindow();
    onReady.registerKeyboardHotkeys(window);
    onReady.autoUpdate(window);
  });

  electron.app.on("will-quit", () => {
    // Unregister the global keyboard hotkeys
    electron.globalShortcut.unregisterAll();

    // Tell the child processes to exit
    // (in Node, they will live forever even if the parent closes)
    childProcesses.exitAll();
  });

  electron.app.on("second-instance", () => {
    // The end-user launched a second instance of the application
    // They probably forgot that it was already open, so focus the window
    if (window !== null) {
      if (window.isMinimized()) {
        window.restore();
      }

      window.focus();
    }
  });

  electron.ipcMain.on(
    "asynchronous-message",
    (_event: electron.IpcMainEvent, arg1: string, arg2: string) => {
      ipc.onMessage(window, arg1, arg2);
    },
  );

  // By default, Electron does not come with a right-click context menu
  // This library provides some sensible defaults
  electronContextMenu();
}
