import * as electron from "electron";
import log from "electron-log";
import { keyboardFunctionMap } from "./keyboardFunctionMap";

export function init(): void {
  $(document).keydown(keyDown);
  electron.ipcRenderer.on("hotkey", IPCHotkey);
}

// Monitor for keystrokes inside of the browser window.
function keyDown(event: JQuery.KeyDownEvent) {
  // Uncomment this to find out which number corresponds to the desired key.
  /// console.log(event.which);

  const keyboardFunction = keyboardFunctionMap.get(event.which);
  if (keyboardFunction !== undefined) {
    keyboardFunction(event);
  }
}

// Monitor for global hotkeys (caught by electron.globalShortcut in the main process).
const IPCHotkey = (_event: electron.IpcRendererEvent, message: string) => {
  log.info("Received hotkey message:", message);

  switch (message) {
    case "ready": {
      // Alt + r
      $("#race-ready-checkbox").click();

      break;
    }

    case "finish": {
      // Alt + f
      $("#race-finish-button").click();

      break;
    }

    case "quit": {
      // Alt + q
      $("#race-quit-button").click();

      break;
    }

    default: {
      break;
    }
  }
};
