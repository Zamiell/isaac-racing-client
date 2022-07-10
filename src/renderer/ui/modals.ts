import crypto from "crypto";
import * as electron from "electron";
import log from "electron-log";
import settings from "../../common/settings";
import {
  FADE_TIME,
  PBKDF2_DIGEST,
  PBKDF2_ITERATIONS,
  PBKDF2_KEYLEN,
} from "../constants";
import g from "../globals";
import { Screen } from "../types/Screen";

export function init(): void {
  initErrorModal();
  initWarningModal();
  initPasswordModal();
  initIsaacPathModal();
}

function initErrorModal() {
  $("#error-modal-button").click(() => {
    if (g.currentScreen === Screen.ERROR) {
      electron.ipcRenderer.send("asynchronous-message", "restart");
    }
  });
}

function initWarningModal() {
  $("#warning-modal-button").click(() => {
    // Hide the warning modal.
    $("#warning-modal").fadeOut(FADE_TIME, () => {
      $("#gui").fadeTo(FADE_TIME, 1);
    });
  });
}

function initPasswordModal() {
  $("#password-input").on("keypress", (e) => {
    if (e.keyCode === 13) {
      e.preventDefault();
      $("#password-modal-ok-button").click();
    } else if (e.keyCode === 27) {
      e.preventDefault();
      $("#password-modal-cancel-button").click();
    }
  });

  $("#password-modal-ok-button").click(() => {
    const passwordInputElement = $("#password-input");

    const plainTextPassword = passwordInputElement.val();
    if (typeof plainTextPassword !== "string") {
      throw new Error("Failed to get the value of the password element.");
    }

    if (plainTextPassword === "") {
      return;
    }

    const raceID = passwordInputElement.data("raceID") as number;
    if (typeof raceID !== "number") {
      throw new Error(
        "Failed to get the value of the race ID from the password element.",
      );
    }

    const raceTitle = passwordInputElement.data("raceTitle") as string;
    if (typeof raceTitle !== "string") {
      throw new Error(
        "Failed to get the value of the race title from the password element.",
      );
    }

    const passwordHash = crypto.pbkdf2Sync(
      plainTextPassword,
      raceTitle,
      PBKDF2_ITERATIONS,
      PBKDF2_KEYLEN,
      PBKDF2_DIGEST,
    );
    const password = passwordHash.toString("base64");

    // Hide the password modal.
    $("#password-modal").fadeOut(FADE_TIME, () => {
      if (g.conn === null) {
        throw new Error("The WebSocket connection was not initialized.");
      }

      $("#gui").fadeTo(FADE_TIME, 1);

      g.currentScreen = Screen.WAITING_FOR_SERVER;
      g.conn.send("raceJoin", {
        id: raceID,
        password,
      });
    });
  });

  $("#password-modal-cancel-button").click(() => {
    // Hide the password modal.
    $("#password-modal").fadeOut(FADE_TIME, () => {
      $("#gui").fadeTo(FADE_TIME, 1);
    });
  });
}

function initIsaacPathModal() {
  $("#isaac-path-find").click(() => {
    const titleText = $("#isaac-path-dialog-title").html();
    const dialogReturn = electron.remote.dialog.showOpenDialogSync({
      title: titleText,
      filters: [
        {
          name: "Programs",
          extensions: ["exe"],
        },
      ],
      properties: ["openFile"],
    });

    if (dialogReturn === undefined || dialogReturn.length === 0) {
      return;
    }

    const isaacPath = dialogReturn[0];
    if (isaacPath === undefined) {
      return;
    }

    log.info("Selected an Isaac path of:", isaacPath);

    const description1 = $("#isaac-path-description-1");
    const description2 = $("#isaac-path-description-2");
    const button1 = $("#isaac-path-find");
    const button2 = $("#isaac-path-exit");

    if (/[\\/]isaac-ng.exe$/.exec(isaacPath) === null) {
      description1.html(
        '<span lang="en">You must select a file that has a name of "isaac-ng.exe".</span>',
      );
      button1.hide(FADE_TIME);
      button2.show(FADE_TIME);
      return;
    }

    settings.set("isaacPath", isaacPath);

    description1.hide(FADE_TIME);
    description2.show(FADE_TIME);
    button1.hide(FADE_TIME);
    button2.show(FADE_TIME);
  });

  $("#isaac-path-exit").click(() => {
    electron.ipcRenderer.send("asynchronous-message", "restart");
  });
}
