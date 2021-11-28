import * as electron from "electron";
import { autoUpdater } from "electron-updater";
import * as childProcesses from "./childProcesses";
import { isaacFocus } from "./focus";
import { launchIsaac } from "./launchIsaac";

export const ipcFunctionMap = new Map<
  string,
  (window: electron.BrowserWindow, arg2: string) => void
>();

ipcFunctionMap.set(
  "close",
  (_window: electron.BrowserWindow, _arg2: string) => {
    electron.app.quit();
  },
);

ipcFunctionMap.set(
  "devTools",
  (window: electron.BrowserWindow, _arg2: string) => {
    window.webContents.openDevTools();
  },
);

ipcFunctionMap.set(
  "isaacFocus",
  (_window: electron.BrowserWindow, _arg2: string) => {
    isaacFocus();
  },
);

ipcFunctionMap.set(
  "minimize",
  (window: electron.BrowserWindow, _arg2: string) => {
    window.minimize();
  },
);

ipcFunctionMap.set(
  "maximize",
  (window: electron.BrowserWindow, _arg2: string) => {
    if (window.isMaximized()) {
      window.unmaximize();
    } else {
      window.maximize();
    }
  },
);

ipcFunctionMap.set(
  "quitAndInstall",
  (_window: electron.BrowserWindow, _arg2: string) => {
    autoUpdater.quitAndInstall();
  },
);

ipcFunctionMap.set(
  "restart",
  (_window: electron.BrowserWindow, _arg2: string) => {
    electron.app.relaunch();
    electron.app.quit();
  },
);

ipcFunctionMap.set("socket", (window: electron.BrowserWindow, arg2: string) => {
  if (arg2 === "start") {
    // Initialize the socket server in a separate process
    childProcesses.start("socket", window);
  } else {
    // Send the command from the renderer process to the child process
    // (e.g. "set countdown 10")
    childProcesses.send("socket", arg2);
  }
});

ipcFunctionMap.set(
  "startIsaac",
  (_window: electron.BrowserWindow, _arg2: string) => {
    launchIsaac();
  },
);

ipcFunctionMap.set("steam", (window: electron.BrowserWindow, _arg2: string) => {
  // Initialize the Greenworks API in a separate process because otherwise the game will refuse to
  // open if Racing+ is open
  // (Greenworks uses the same AppID as Isaac, so Steam gets confused)
  childProcesses.start("steam", window);
});

ipcFunctionMap.set(
  "steamExit",
  (_window: electron.BrowserWindow, _arg2: string) => {
    // The renderer has successfully authenticated and is now establishing a WebSocket connection,
    // so we can kill the Greenworks process
    childProcesses.exit("steam");
  },
);

ipcFunctionMap.set(
  "steamWatcher",
  (window: electron.BrowserWindow, arg2: string) => {
    // Start the Steam watcher in a separate process
    childProcesses.start("steamWatcher", window);

    // Feed the child the ID of the Steam user
    childProcesses.send("steamWatcher", arg2);
  },
);

ipcFunctionMap.set("isaac", (window: electron.BrowserWindow, arg2: string) => {
  // Start the Isaac checker in a separate process
  const isaacPath = arg2;
  childProcesses.start("isaac", window, isaacPath);
});
