import * as electron from "electron";
import { autoUpdater } from "electron-updater";
import * as childProcesses from "./childProcesses";
import { isaacFocus } from "./focus";
import launchIsaac from "./launchIsaac";

const functionMap = new Map<
  string,
  (window: electron.BrowserWindow, arg2: string) => void
>();
export default functionMap;

functionMap.set("close", (_window: electron.BrowserWindow, _arg2: string) => {
  electron.app.quit();
});

functionMap.set("devTools", (window: electron.BrowserWindow, _arg2: string) => {
  window.webContents.openDevTools();
});

functionMap.set(
  "isaacFocus",
  (_window: electron.BrowserWindow, _arg2: string) => {
    isaacFocus();
  },
);

functionMap.set("minimize", (window: electron.BrowserWindow, _arg2: string) => {
  window.minimize();
});

functionMap.set("maximize", (window: electron.BrowserWindow, _arg2: string) => {
  if (window.isMaximized()) {
    window.unmaximize();
  } else {
    window.maximize();
  }
});

functionMap.set(
  "quitAndInstall",
  (_window: electron.BrowserWindow, _arg2: string) => {
    autoUpdater.quitAndInstall();
  },
);

functionMap.set("restart", (_window: electron.BrowserWindow, _arg2: string) => {
  electron.app.relaunch();
  electron.app.quit();
});

functionMap.set("socket", (window: electron.BrowserWindow, arg2: string) => {
  if (arg2 === "start") {
    // Initialize the socket server in a separate process
    childProcesses.start("socket", window);
  } else {
    // The the command from the renderer process to the child process
    // (e.g. "set countdown 10")
    childProcesses.send("socket", arg2);
  }
});

functionMap.set(
  "startIsaac",
  (_window: electron.BrowserWindow, _arg2: string) => {
    launchIsaac();
  },
);

functionMap.set("steam", (window: electron.BrowserWindow, _arg2: string) => {
  // Initialize the Greenworks API in a separate process because otherwise the game will refuse to
  // open if Racing+ is open
  // (Greenworks uses the same AppID as Isaac, so Steam gets confused)
  childProcesses.start("steam", window);
});

functionMap.set(
  "steamExit",
  (_window: electron.BrowserWindow, _arg2: string) => {
    // The renderer has successfully authenticated and is now establishing a WebSocket connection,
    // so we can kill the Greenworks process
    childProcesses.exit("steam");
  },
);

functionMap.set(
  "steamWatcher",
  (window: electron.BrowserWindow, arg2: string) => {
    // Start the Steam watcher in a separate process
    childProcesses.start("steamWatcher", window);

    // Feed the child the ID of the Steam user
    childProcesses.send("steamWatcher", arg2);
  },
);

functionMap.set("isaac", (window: electron.BrowserWindow, _arg2: string) => {
  // Start the Isaac checker in a separate process
  childProcesses.start("isaac", window);
});
