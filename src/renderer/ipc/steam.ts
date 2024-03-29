import * as electron from "electron";
import log from "electron-log";
import type { SteamMessage } from "../../common/types/SteamMessage";
import { g } from "../globals";
import { login } from "../login";
import { errorShow } from "../utils";

export function init(): void {
  electron.ipcRenderer.on("steam", IPCSteam);
}

export function start(): void {
  // This tells the main process to start the child process that will initialize Greenworks. That
  // process will get our Steam ID, Steam screen name, and authentication ticket.
  electron.ipcRenderer.send("asynchronous-message", "steam");
}

// Monitor for notifications from the child process that is getting the data from Greenworks.
function IPCSteam(
  _event: electron.IpcRendererEvent,
  message: string | SteamMessage,
) {
  // eslint-disable-next-line @typescript-eslint/no-base-to-string
  log.info(`Renderer process received Steam child message: ${message}`);

  if (typeof message !== "string") {
    // If the message is not a string, assume that it is an object containing the Steam-related
    // information from Greenworks.
    const steamMessage = message;

    g.steam.id = steamMessage.id;
    g.steam.accountID = steamMessage.accountID;
    g.steam.screenName = steamMessage.screenName;
    g.steam.ticket = steamMessage.ticket;

    login();
    return;
  }

  if (
    message === "errorInit" ||
    message.startsWith("error: Error: channel closed") ||
    message.startsWith(
      "error: Error: Steam initialization failed, but Steam is running, and steam_appid.txt is present and valid.",
    )
  ) {
    errorShow(
      "Failed to communicate with Steam. Please open or restart Steam and relaunch Racing+.",
    );
  } else if (message.startsWith("error: ")) {
    // This is some other uncommon error.
    const match = /error: (.+)/.exec(message);
    let error: string;
    if (match === null) {
      error =
        "Failed to parse an error message from the Greenworks child process.";
    } else {
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      error = match[1]!;
    }
    errorShow(error);
  }
}
