import * as electron from "electron";
import log from "electron-log";
import { FADE_TIME } from "../constants";
import g from "../globals";
import { errorShow } from "../misc";
import * as lobbyScreen from "../ui/lobby";
import * as socket from "./socket";
import * as steamWatcher from "./steamWatcher";

const STEAM_WORKSHOP_MOD_LINK =
  "http://steamcommunity.com/sharedfiles/filedetails/?id=857628390";

export function init(): void {
  electron.ipcRenderer.on("isaac", IPCIsaac);
}

export function start(): void {
  // This tells the main process to do Isaac-related checks
  // (check to see if the Racing+ mod is corrupted, etc.)
  electron.ipcRenderer.send("asynchronous-message", "isaac");
}

// Monitor for notifications from the child process that does file checks and opens Isaac
function IPCIsaac(_event: electron.IpcRendererEvent, message: unknown) {
  log.info(`Renderer process received Isaac child message: ${message}`);

  // All messages should be strings
  if (typeof message !== "string") {
    // This must be a debug message containing an object or array
    return;
  }

  if (message.startsWith("error: ")) {
    // g.currentScreen is equal to "transition" when this is called
    g.currentScreen = "null";

    // This is an ordinary error, so don't report it to Sentry
    const match = /error: (.+)/.exec(message);
    if (match === null) {
      throw new Error(`Failed to parse the error message: ${message}`);
    }
    const error = match[1];
    errorShow(error);
    return;
  }

  switch (message) {
    case "modNotFound": {
      errorShow(
        `The Racing+ mod was not found in your "mods" directory. Have you <a href="${STEAM_WORKSHOP_MOD_LINK}" target="_blank">subscribed to the mod on the Steam Workshop</a>? The Racing+ client needs the mod in place in order to be able to function.`,
      );
      break;
    }

    case "modCorrupt": {
      errorShow(
        "The Racing+ mod has one or more files that are corrupt or missing. Try unsubscribing from the mod on the Steam Workshop and then re-subscribing (so that Steam completely re-downloads it from scratch).",
      );
      break;
    }

    case "startIsaac": {
      electron.ipcRenderer.send("asynchronous-message", "startIsaac");
      break;
    }

    case "isaacChecksComplete": {
      g.currentScreen = "transition";
      $("#file-checking").fadeOut(FADE_TIME, () => {
        lobbyScreen.show();
      });

      // Start the local socket server
      socket.start();

      // Start the Steam watcher process after a short delay
      setTimeout(() => {
        steamWatcher.start();
      }, 5000); // 5 seconds

      break;
    }

    default: {
      break;
    }
  }
}
