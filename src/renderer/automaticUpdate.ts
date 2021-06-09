import * as electron from "electron";
import log from "../common/log";
import { FADE_TIME } from "./constants";
import g from "./globals";

export function init(): void {
  electron.ipcRenderer.on("autoUpdater", IPCAutoUpdater);
}

const IPCAutoUpdater = (event: electron.IpcRendererEvent, message: string) => {
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
      if (g.currentScreen === "transition") {
        setTimeout(() => {
          IPCAutoUpdater(event, message);
        }, FADE_TIME + 5); // 5 milliseconds of leeway
      } else if (g.currentScreen === "updating") {
        electron.ipcRenderer.send("asynchronous-message", "quitAndInstall");
      }

      break;
    }

    default: {
      break;
    }
  }
};
