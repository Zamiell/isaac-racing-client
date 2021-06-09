// Racing+ Client
// for The Binding of Isaac: Repentance
// (main process)

import * as electron from "electron";
import electronContextMenu from "electron-context-menu";
import pkg from "../../package.json";
import log from "../common/log";
import * as settings from "../common/settings";
import * as childProcesses from "./childProcesses";
import { IS_DEV } from "./constants";
import ipcFunctions from "./ipcFunctions";
import * as onReady from "./onReady";

let window = null as null | electron.BrowserWindow;

printWelcomeMessage();
checkSecondInstance();
settings.initDefault();
initElectronHandlers();

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

  electron.ipcMain.on("asynchronous-message", ipcMessage);

  // By default, Electron does not come with a right-click context menu
  // This library provides some sensible defaults
  electronContextMenu();
}

function ipcMessage(_event: electron.IpcMainEvent, arg1: string, arg2: string) {
  log.info(`Main process received message: ${arg1}`);

  if (window === null) {
    log.error("Main window is not initialized yet.");
    return;
  }

  const ipcFunction = ipcFunctions.get(arg1);
  if (ipcFunction !== undefined) {
    ipcFunction(window, arg2);
  } else {
    log.error(`Unknown message type: ${arg1}`);
  }
}
