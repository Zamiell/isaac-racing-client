import * as electron from "electron";
import log from "../common/log";
import g from "./globals";
import { errorShow, warningShow } from "./misc";
import * as raceScreen from "./ui/race";

export function init(): void {
  electron.ipcRenderer.on("isaac", IPCIsaac);
}

// This tells the main process to do Isaac-related checks
// (check to see if the Racing+ mod is corrupted, etc.)
export function start(): void {
  electron.ipcRenderer.send("asynchronous-message", "isaac");
}

// Monitor for notifications from the child process that does file checks and opens Isaac
function IPCIsaac(_event: electron.IpcRendererEvent, message: unknown) {
  log.info("Isaac child message:", message);

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
    if (!match) {
      throw new Error(`Failed to parse the error message: ${message}`);
    }
    const error = match[1];
    errorShow(error);
  } else if (message === "We need to restart Isaac.") {
    warningShow(
      "Racing+ detected that your mod was corrupted and automatically fixed it. Your game has been restarted to ensure that everything is now loaded correctly. (If a patch just came out, this message is normal, as Steam has likely not had time to download the newest version yet.)",
    );
  } else if (message === "exited") {
    g.gameState.fileChecksComplete = true;
    raceScreen.checkReadyValid();
  }
}
