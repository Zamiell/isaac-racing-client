import crypto from "crypto";
import * as electron from "electron";
import {
  FADE_TIME,
  PBKDF2_DIGEST,
  PBKDF2_ITERATIONS,
  PBKDF2_KEYLEN,
} from "../constants";
import g from "../globals";

export function init(): void {
  initErrorModal();
  initWarningModal();
  initPasswordModal();
}

function initErrorModal() {
  $("#error-modal-button").click(() => {
    if (g.currentScreen === "error") {
      electron.ipcRenderer.send("asynchronous-message", "restart");
    }
  });
}

function initWarningModal() {
  $("#warning-modal-button").click(() => {
    // Hide the warning modal
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

    // Hide the password modal
    $("#password-modal").fadeOut(FADE_TIME, () => {
      if (g.conn === null) {
        throw new Error("The WebSocket connection was not initialized.");
      }

      $("#gui").fadeTo(FADE_TIME, 1);

      g.currentScreen = "waiting-for-server";
      g.conn.send("raceJoin", {
        id: raceID,
        password,
      });
    });
  });

  $("#password-modal-cancel-button").click(() => {
    // Hide the password modal
    $("#password-modal").fadeOut(FADE_TIME, () => {
      $("#gui").fadeTo(FADE_TIME, 1);
    });
  });
}
