import * as electron from "electron";
import { autoUpdater } from "electron-updater";
import * as childProcesses from "./childProcesses";
import { isaacFocus } from "./focus";

const functionMap = new Map<
  string,
  (window: electron.BrowserWindow, arg2: string) => void
>();
export default functionMap;

functionMap.set("close", () => {
  electron.app.quit();
});

functionMap.set("devTools", (window: electron.BrowserWindow) => {
  window.webContents.openDevTools();
});

functionMap.set("isaacFocus", () => {
  isaacFocus();
});

functionMap.set("minimize", (window: electron.BrowserWindow) => {
  window.minimize();
});

functionMap.set("maximize", (window: electron.BrowserWindow) => {
  if (window.isMaximized()) {
    window.unmaximize();
  } else {
    window.maximize();
  }
});

functionMap.set("quitAndInstall", () => {
  autoUpdater.quitAndInstall();
});

functionMap.set("restart", () => {
  electron.app.relaunch();
  electron.app.quit();
});

functionMap.set("steam", (window: electron.BrowserWindow) => {
  // Initialize the Greenworks API in a separate process because otherwise the game will refuse to
  // open if Racing+ is open
  // (Greenworks uses the same AppID as Isaac, so Steam gets confused)
  childProcesses.start("steam", window);
});

functionMap.set("steamExit", () => {
  // The renderer has successfully authenticated and is now establishing a WebSocket connection,
  // so we can kill the Greenworks process
  childProcesses.exit("steam");
});

functionMap.set(
  "steamWatcher",
  (window: electron.BrowserWindow, arg2: string) => {
    // Start the Steam watcher in a separate process
    childProcesses.start("steamWatcher", window);

    // Feed the child the ID of the Steam user
    childProcesses.send("steamWatcher", arg2);
  },
);

functionMap.set("isaac", (window: electron.BrowserWindow) => {
  // Start the Isaac checker in a separate process
  childProcesses.start("isaac", window);
});
