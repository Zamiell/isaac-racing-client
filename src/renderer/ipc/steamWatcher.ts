import * as electron from "electron";
import log from "electron-log";
import g from "../globals";
import { errorShow } from "../misc";

export function init(): void {
  electron.ipcRenderer.on("steamWatcher", IPCSteamWatcher);
}

export function start(): void {
  // The Steam watcher child process will only be started when Isaac-related checks are complete
  // This is because during these checks, Steam might have to be restarted,
  // and the user will obviously be logged out during this time

  // If we are on a test account, the account ID will be 0
  // We don't want to start the Steam watcher if we are on a test account,
  // since they are not associated with Steam accounts
  if (g.steam.accountID !== null && g.steam.accountID > 0) {
    // Send a message to the main process to start up the Steam watcher
    electron.ipcRenderer.send(
      "asynchronous-message",
      "steamWatcher",
      g.steam.accountID,
    );
  }
}

function IPCSteamWatcher(_event: electron.IpcRendererEvent, message: string) {
  log.info(`Renderer process received SteamWatcher child message: ${message}`);

  if (message === "error: It appears that you have logged out of Steam.") {
    errorShow("It appears that you have logged out of Steam.");
    return;
  }

  if (message.startsWith("error: ")) {
    const match = /^error: (.+)/.exec(message);
    if (match !== null) {
      const error = match[1];
      errorShow(
        `Something went wrong with the Steam monitoring program: ${error}`,
      );
    }
  }
}
