import type * as electron from "electron";
import log from "electron-log";
import { ipcFunctionMap } from "./ipcFunctionMap";

export function onMessage(
  window: electron.BrowserWindow | null,
  arg1: string,
  arg2: string,
): void {
  // Don't log socket messages, as it gets too spammy.
  if (arg1 !== "socket") {
    log.info(
      `Main process received message from renderer process of type: ${arg1}`,
    );
  }

  if (window === null) {
    log.error("Main window is not initialized yet.");
    return;
  }

  const ipcFunction = ipcFunctionMap.get(arg1);
  if (ipcFunction === undefined) {
    log.error(`Unknown message type: ${arg1}`);
  } else {
    ipcFunction(window, arg2);
  }
}
