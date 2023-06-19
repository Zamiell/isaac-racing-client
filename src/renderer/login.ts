// Get a WebSocket cookie from the Racing+ server using our Steam ticket generated from Greenworks.
// The authentication flow is described here:
// https://partner.steamgames.com/documentation/auth#client_to_backend_webapi
// (You have to be logged in for the link to work.) The server will validate our session ticket
// using the Steam web API, and if successful, give us a cookie. If our Steam ID does not already
// exist in the database, we will be told to register.

import * as electron from "electron";
import log from "electron-log";
import pkg from "../../package.json";
import { FADE_TIME, IS_DEV, WEBSITE_URL } from "./constants";
import { g } from "./globals";
import { Screen } from "./types/Screen";
import * as registerScreen from "./ui/register";
import { errorShow, findAjaxError } from "./utils";
import * as websocket from "./websocket";

const SECONDS_TO_STALL_FOR_AUTOMATIC_UPDATE = 5;

export function login(): void {
  log.info("Checking auto update status...");

  switch (g.autoUpdateStatus) {
    case null: {
      // Don't login yet if we are still checking for updates. (But we don't auto-update in
      // development.)
      if (!IS_DEV) {
        // The client has not yet begun to check for an update, so stall. However, sometimes this
        // can be permanently null in production. (Maybe after an automatic update?) Allow them to
        // proceed after a while.
        const now = new Date().getTime();
        if (
          now - g.timeLaunched <
          SECONDS_TO_STALL_FOR_AUTOMATIC_UPDATE * 1000
        ) {
          log.info("Deferring logging in since autoUpdateStatus is null.");

          $("#title-ajax-description").html(
            "Waiting for the automatic updater to initialize...",
          );

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

      $("#title-ajax-description").html(
        "Checking to see if we are on the latest version...",
      );

      setTimeout(() => {
        login();
      }, 250);
      return;
    }

    case "error": {
      // Allow them to continue to log on if they got an error since we want the service to be
      // usable when GitHub is down.
      log.info("Logging in (with an automatic update error).");
      break;
    }

    case "update-available": {
      // They are beginning to download the update.
      log.info(
        'autoUpdateStatus is "update-available". Showing the "updating" screen...',
      );

      g.currentScreen = Screen.TRANSITION;
      $("#title").fadeOut(FADE_TIME, () => {
        $("#updating").fadeIn(FADE_TIME, () => {
          g.currentScreen = Screen.UPDATING;
        });
      });

      return;
    }

    case "update-not-available": {
      // Do nothing special and continue to login.
      log.info("Logging in (with no update available).");

      break;
    }

    case "update-downloaded": {
      // The update was downloaded in the background before the user logged in. Show them the
      // updating screen so they are not confused at the program restarting.
      log.info(
        'autoUpdateStatus is "update-downloaded". Showing the "updating" screen and automatically restarting in 1.5 seconds...',
      );

      g.currentScreen = Screen.TRANSITION;
      $("#title").fadeOut(FADE_TIME, () => {
        $("#updating").fadeIn(FADE_TIME, () => {
          g.currentScreen = Screen.UPDATING;

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

  $("#title-ajax-description").html("Logging in to the Racing+ server...");

  // Send a request to the Racing+ server.
  log.info("Sending a login request to the Racing+ server.");
  const postData = {
    steamID: g.steam.id,
    ticket: g.steam.ticket, // This will be verified on the server via the Steam web API
    version: pkg.version,
  };
  const url = `${WEBSITE_URL}/login`;

  // eslint-disable-next-line isaacscript/no-object-any
  const request = $.ajax({
    url,
    type: "POST",
    data: postData,
  });
  request.done(loginSuccess); // eslint-disable-line
  request.fail(loginFail); // eslint-disable-line
}

function loginSuccess(rawData: string, _status: string, _jqXHR: JQuery.jqXHR) {
  const data = rawData.trim();

  if (data === "Accepted") {
    // If the server gives us "Accepted", then our Steam credentials are valid, but we don't have an
    // account on the server yet. Let the user pick their username.
    registerScreen.show();
  } else {
    // We successfully got a cookie; attempt to establish a WebSocket connection.
    websocket.connect();
  }
}

function loginFail(jqXHR: JQuery.jqXHR) {
  log.info("Login failed.");
  log.info(jqXHR);
  const error = findAjaxError(jqXHR);
  errorShow(error);
}
