import * as electron from "electron";
import log from "electron-log";
import g from "./globals";

export function init(): void {
  electron.ipcRenderer.on("autoUpdater", IPCAutoUpdater);
}

const IPCAutoUpdater = (_event: electron.IpcRendererEvent, message: string) => {
  log.info("Received autoUpdater message:", message);
  g.autoUpdateStatus = message;

  switch (message) {
    case "error": {
      // Do nothing special; we want the service to be usable if GitHub is down
      break;
    }

    case "checking-for-update":
    case "update-available":
    case "update-not-available": {
      // Do nothing special
      break;
    }

    case "update-downloaded": {
      electron.ipcRenderer.send("asynchronous-message", "quitAndInstall");
      break;
    }

    default: {
      break;
    }
  }
};
