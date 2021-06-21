import * as electron from "electron";
import log from "electron-log";
import ipcFunctions from "./ipcFunctions";

export function onMessage(
  window: electron.BrowserWindow | null,
  arg1: string,
  arg2: string,
): void {
  // Don't log socket messages, as it gets too spammy
  if (arg1 !== "socket") {
    log.info(
      `Main process received message from renderer process of type: ${arg1}`,
    );
  }

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
