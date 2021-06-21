import * as electron from "electron";
import log from "electron-log";
import { autoUpdater } from "electron-updater";
import { HandlerDetails } from "electron/main";
import path from "path";
import * as file from "../common/file";
import settings from "../common/settings";
import { STATIC_PATH } from "./constants";
import { isaacFocus } from "./focus";
import IS_DEV from "./isDev";
import launchIsaac from "./launchIsaac";

interface WindowSettings {
  width?: number;
  height?: number;
  x?: number;
  y?: number;
}

const DEFAULT_WIDTH = 1110;
const DEFAULT_WIDTH_DEV = 1610;
const DEFAULT_HEIGHT = 720;
const WINDOW_TITLE = "Racing+";
const INDEX_HTML_PATH = path.join(STATIC_PATH, "index.html");
const FAVICON_PATH = path.join(STATIC_PATH, "img", "favicon.png");

if (!file.exists(INDEX_HTML_PATH)) {
  throw new Error(`The index path of "${INDEX_HTML_PATH}" does not exist.`);
}

if (!file.exists(FAVICON_PATH)) {
  throw new Error(`The favicon path of "${FAVICON_PATH}" does not exist.`);
}

export function createWindow(): electron.BrowserWindow {
  // Figure out what the window size and position should be
  const windowSettings: WindowSettings = settings.get(
    "window",
  ) as WindowSettings;

  let width: number;
  if (windowSettings.width === undefined) {
    width = IS_DEV ? DEFAULT_WIDTH_DEV : DEFAULT_WIDTH;
  } else {
    width = windowSettings.width;
  }

  let height: number;
  if (windowSettings.height === undefined) {
    height = DEFAULT_HEIGHT;
  } else {
    height = windowSettings.height;
  }

  let x: number | undefined;
  if (windowSettings.x !== undefined) {
    x = windowSettings.x;
  }

  let y: number | undefined;
  if (windowSettings.y !== undefined) {
    y = windowSettings.y;
  }

  // Create the browser window
  const window = new electron.BrowserWindow({
    x,
    y,
    width,
    height,
    icon: FAVICON_PATH,
    title: WINDOW_TITLE,
    frame: false,
    webPreferences: {
      // Needed to use Node APIs inside of the renderer process
      // https://stackoverflow.com/questions/44391448/electron-require-is-not-defined
      nodeIntegration: true,
      contextIsolation: false,

      // Needed for @electron/remote to work
      // https://github.com/electron/remote
      enableRemoteModule: true,
    },
  });

  // Open the JavaScript console
  if (IS_DEV) {
    window.webContents.openDevTools();
  }

  // Check if the window is off-screen
  // (for example, this can happen if it was put on a second monitor which is currently
  // disconnected)
  if (x !== undefined && y !== undefined && !isInBounds(x, y)) {
    window.center();
  }

  window.loadFile(INDEX_HTML_PATH).catch((err) => {
    log.error(`Failed to load the "index.html" file: ${err}`);
    electron.app.quit();
  });

  // When the app is closed, save the window size and position for next time
  window.on("close", () => {
    settings.set("window", window.getBounds());
  });

  // Make external links (i.e. with target="_blank") open in a real browser
  // https://stackoverflow.com/questions/32402327/how-can-i-force-external-links-from-browser-window-to-open-in-a-default-browser
  window.webContents.setWindowOpenHandler((details: HandlerDetails) => {
    electron.shell.openExternal(details.url).catch((err) => {
      log.error(`Failed open external URL: ${err}`);
    });

    return { action: "deny" };
  });

  return window;
}

// From: https://github.com/saenzramiro/rambox/commit/9dd5380f60d96e0da70bb057192aa67d59efd50f
function isInBounds(x: number, y: number) {
  for (const display of electron.screen.getAllDisplays()) {
    if (
      x >= display.workArea.x &&
      x <= display.workArea.x + display.workArea.width &&
      y >= display.workArea.y &&
      y <= display.workArea.y + display.workArea.height
    ) {
      return true;
    }
  }

  return false;
}

export function registerKeyboardHotkeys(window: electron.BrowserWindow): void {
  const hotkeyIsaacLaunch = electron.globalShortcut.register("Alt+B", () => {
    launchIsaac();
  });
  if (!hotkeyIsaacLaunch) {
    log.warn("Alt+B hotkey registration failed.");
  }

  const hotkeyIsaacFocus = electron.globalShortcut.register(
    "Alt+1",
    isaacFocus,
  );
  if (!hotkeyIsaacFocus) {
    log.warn("Alt+1 hotkey registration failed.");
  }

  const hotkeyRacingPlusFocus = electron.globalShortcut.register(
    "Alt+2",
    () => {
      window.focus();
    },
  );
  if (!hotkeyRacingPlusFocus) {
    log.warn("Alt+2 hotkey registration failed.");
  }

  const hotkeyReady = electron.globalShortcut.register("Alt+R", () => {
    window.webContents.send("hotkey", "ready");
  });
  if (!hotkeyReady) {
    log.warn("Alt+R hotkey registration failed.");
  }

  const hotkeyFinish = electron.globalShortcut.register("Alt+F", () => {
    window.webContents.send("hotkey", "finish");
  });
  if (!hotkeyFinish) {
    log.warn("Alt+F hotkey registration failed.");
  }

  const hotkeyQuit = electron.globalShortcut.register("Alt+Q", () => {
    window.webContents.send("hotkey", "quit");
  });
  if (!hotkeyQuit) {
    log.warn("Alt+Q hotkey registration failed.");
  }
}

export function autoUpdate(window: electron.BrowserWindow): void {
  // Don't check for updates when running the program from source
  if (IS_DEV) {
    return;
  }

  // Only check for updates on Windows
  if (process.platform !== "win32") {
    return;
  }

  autoUpdater.on("error", (err) => {
    log.error(`autoUpdater error: ${err}`);
    window.webContents.send("autoUpdater", "error");
  });

  autoUpdater.on("checking-for-update", () => {
    window.webContents.send("autoUpdater", "checking-for-update");
  });

  autoUpdater.on("update-available", () => {
    window.webContents.send("autoUpdater", "update-available");
  });

  autoUpdater.on("update-not-available", () => {
    window.webContents.send("autoUpdater", "update-not-available");
  });

  autoUpdater.on("update-downloaded", () => {
    window.webContents.send("autoUpdater", "update-downloaded");
  });

  log.info("Checking for updates.");
  autoUpdater.checkForUpdates().catch((err) => {
    log.error(`Failed to check for updates: ${err}`);
  });
}
