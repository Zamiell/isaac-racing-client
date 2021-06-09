import * as electron from "electron";
import pkg from "../../package.json";
import log from "../common/log";
import SteamMessage from "../common/types/SteamMessage";
import { FADE_TIME, IS_DEV, WEBSITE_URL } from "./constants";
import g from "./globals";
import { errorShow, findAjaxError } from "./misc";
import * as registerScreen from "./ui/register";
import * as websocket from "./websocket";

const SECONDS_TO_STALL_FOR_AUTOMATIC_UPDATE = 10;

// const websocket = nodeRequire('./js/websocket');
// const registerScreen = nodeRequire('./js/ui/register');

export function init(): void {
  electron.ipcRenderer.on("steam", IPCSteam);

  if (IS_DEV) {
    initDevButtons();
  }
}

function initDevButtons() {
  // Don't automatically log in with our Steam account
  // We want to choose from a list of login options
  $("#title-ajax").fadeOut(0);
  $("#title-choose").fadeIn(0);

  $("#title-choose-steam").click(() => {
    loginDebug(null);
  });

  for (let i = 1; i <= 10; i++) {
    $(`#title-choose-${i}`).click(() => {
      loginDebug(i);
    });
  }

  $("#title-restart").click(() => {
    // Restart the client
    electron.ipcRenderer.send("asynchronous-message", "restart");
  });
}

function loginDebug(account: number | null) {
  if (g.currentScreen !== "title-ajax") {
    return;
  }

  $("#title-choose").fadeOut(FADE_TIME, () => {
    $("#title-ajax").fadeIn(FADE_TIME);
  });

  if (account === null) {
    // A normal login
    electron.ipcRenderer.send("asynchronous-message", "steam", account);
  } else {
    // A manual login that does not rely on Steam authentication
    g.steam.id = `-${account}`;
    g.steam.accountID = 0;
    g.steam.screenName = `TestAccount${account}`;
    g.steam.ticket = "debug";
    login();
  }
}

// Monitor for notifications from the child process that is getting the data from Greenworks
function IPCSteam(
  _event: electron.IpcRendererEvent,
  message: string | SteamMessage,
) {
  log.info(`Steam child message: ${message}`);

  if (typeof message !== "string") {
    // If the message is not a string, assume that it is an object containing the Steam-related
    // information from Greenworks
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
    // This is some other uncommon error
    const match = /error: (.+)/.exec(message);
    let error: string;
    if (match) {
      error = match[1];
    } else {
      error =
        "Failed to parse an error message from the Greenworks child process.";
    }
    errorShow(error);
  }
}

// Get a WebSocket cookie from the Racing+ server using our Steam ticket generated from Greenworks
// The authentication flow is described here:
// https://partner.steamgames.com/documentation/auth#client_to_backend_webapi
// (you have to be logged in for the link to work)
// The server will validate our session ticket using the Steam web API, and if successful, give us a cookie
// If our Steam ID does not already exist in the database, we will be told to register
function login() {
  switch (g.autoUpdateStatus) {
    case null: {
      // Don't login yet if we are still checking for updates
      // (bit we don't auto-update in development)
      if (!IS_DEV) {
        // The client has not yet begun to check for an update, so stall
        // However, sometimes this can be permanently null in production
        // (maybe after an automatic update?)
        // Allow them to proceed after a while
        const now = new Date().getTime();
        if (
          now - g.timeLaunched <
          SECONDS_TO_STALL_FOR_AUTOMATIC_UPDATE * 1000
        ) {
          log.info("Deferring logging in since autoUpdateStatus is null.");

          setTimeout(() => {
            login();
          }, 250);
          return;
        }
      }

      break;
    }

    case "checking-for-update": {
      log.info(
        'Deferring logging in since autoUpdateStatus is "checking-for-update".',
      );

      setTimeout(() => {
        login();
      }, 250);
      return;
    }

    case "error": {
      // Allow them to continue to log on if they got an error since we want the service to be usable
      // when GitHub is down
      log.info("Logging in (with an automatic update error).");
      break;
    }

    case "update-available": {
      // They are beginning to download the update
      log.info(
        'autoUpdateStatus is "update-available". Showing the "updating" screen...',
      );

      g.currentScreen = "transition";
      $("#title").fadeOut(FADE_TIME, () => {
        $("#updating").fadeIn(FADE_TIME, () => {
          g.currentScreen = "updating";
        });
      });

      return;
    }

    case "update-not-available": {
      // Do nothing special and continue to login
      log.info("Logging in (with no update available).");

      break;
    }

    case "update-downloaded": {
      // The update was downloaded in the background before the user logged in
      // Show them the updating screen so they are not confused at the program restarting
      log.info(
        'autoUpdateStatus is "update-downloaded". Showing the "updating" screen and automatically restarting in 1.5 seconds...',
      );

      g.currentScreen = "transition";
      $("#title").fadeOut(FADE_TIME, () => {
        $("#updating").fadeIn(FADE_TIME, () => {
          g.currentScreen = "updating";

          setTimeout(() => {
            electron.ipcRenderer.send("asynchronous-message", "quitAndInstall");
          }, 1500);
        });
      });

      return;
    }

    default: {
      break;
    }
  }

  // Send a request to the Racing+ server
  log.info("Sending a login request to the Racing+ server.");
  const postData = {
    steamID: g.steam.id,
    ticket: g.steam.ticket, // This will be verified on the server via the Steam web API
    version: pkg.version,
  };
  const url = `${WEBSITE_URL}/login`;

  const request = $.ajax({
    url,
    type: "POST",
    data: postData,
  });
  request.done(loginSuccess); // eslint-disable-line
  request.fail(loginFail); // eslint-disable-line
}

function loginSuccess(rawData: string) {
  const data = rawData.trim();

  if (data === "Accepted") {
    // If the server gives us "Accepted", then our Steam credentials are valid, but we don't have an account on the server yet
    // Let the user pick their username
    registerScreen.show();
  } else {
    // We successfully got a cookie; attempt to establish a WebSocket connection
    websocket.connect();
  }
}

function loginFail(jqXHR: JQuery.jqXHR) {
  log.info("Login failed.");
  log.info(jqXHR);
  const error = findAjaxError(jqXHR);
  errorShow(error);
}
