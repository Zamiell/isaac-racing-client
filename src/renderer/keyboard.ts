import * as electron from "electron";
import log from "electron-log";
import keyboardFunctions from "./keyboardFunctions";

export function init(): void {
  $(document).keydown(keyDown);
  electron.ipcRenderer.on("hotkey", IPCHotkey);
}

// Monitor for keystrokes inside of the browser window
function keyDown(event: JQuery.KeyDownEvent) {
  // console.log(event.which); // Uncomment this to find out which number corresponds to the desired key

  const keyboardFunction = keyboardFunctions.get(event.which);
  if (keyboardFunction !== undefined) {
    keyboardFunction(event);
  }
}

// Monitor for global hotkeys (caught by electron.globalShortcut in the main process)
const IPCHotkey = (_event: electron.IpcRendererEvent, message: string) => {
  log.info("Received hotkey message:", message);

  if (message === "ready") {
    // Alt + r
    $("#race-ready-checkbox").click();
  } else if (message === "finish") {
    // Alt + f
    $("#race-finish-button").click();
  } else if (message === "quit") {
    // Alt + q
    $("#race-quit-button").click();
  }
};
