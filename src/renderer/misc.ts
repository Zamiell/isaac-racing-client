import log from "electron-log";
import path from "path";
import settings from "../common/settings";
import { FADE_TIME } from "./constants";
import g from "./globals";

export function amSecondTestAccount(): boolean {
  return (
    g.myUsername.startsWith("TestAccount") && g.myUsername !== "TestAccount1"
  );
}

// From: https://stackoverflow.com/questions/2332811/capitalize-words-in-string
export function capitalize(str: string): string {
  return str.replace(/(?:^|\s)\S/g, (a) => a.toUpperCase());
}

// From: https://stackoverflow.com/questions/27709489/jquery-tooltipster-plugin-hide-all-tips
export function closeAllTooltips(): void {
  const instances = $.tooltipster.instances();
  $.each(instances, (_i, instance) => {
    if (instance.status().open) {
      instance.close();
    }
  });
}

// From: https://stackoverflow.com/questions/6234773/can-i-escape-html-special-chars-in-javascript
export function escapeHTML(unsafe: string): string {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

export function findAjaxError(jqXHR: JQuery.jqXHR): string {
  if (jqXHR.readyState === 0) {
    return "A network error occurred. The server might be down!";
  }

  if (jqXHR.responseText === "") {
    return "An unknown error occurred.";
  }

  return jqXHR.responseText;
}

export function errorShow(message: string): void {
  // Come back in a second if we are still in a transition
  if (g.currentScreen === "transition") {
    setTimeout(() => {
      errorShow(message);
    }, FADE_TIME + 5); // 5 milliseconds of leeway
    return;
  }

  // Log the message
  if (message !== "") {
    log.error(message);
  } else {
    log.error("Generic error.");
  }

  // Don't do anything if we are already showing an error
  if (g.currentScreen === "error") {
    return;
  }
  g.currentScreen = "error";

  // Disconnect from the server, if connected
  if (g.conn !== null) {
    g.conn.close();
  }

  // Hide the links in the header
  $("#header-profile").fadeOut(FADE_TIME);
  $("#header-leaderboards").fadeOut(FADE_TIME);
  $("#header-help").fadeOut(FADE_TIME);

  // Hide the buttons in the header
  $("#header-lobby").fadeOut(FADE_TIME);
  $("#header-new-race").fadeOut(FADE_TIME);
  $("#header-settings").fadeOut(FADE_TIME);

  // Close all tooltips
  closeAllTooltips();

  $("#gui").fadeTo(FADE_TIME, 0.1, () => {
    // Show the error modal
    $("#error-modal").fadeIn(FADE_TIME);
    $("#error-modal-description").html(message);
  });
}

export function getRandomNumber(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1) + min);
}

// From: https://stackoverflow.com/questions/13627308/add-st-nd-rd-and-th-ordinal-suffix-to-a-number
export function ordinalSuffixOf(i: number): string {
  // Handle French ordinals
  if (settings.get("language") === "fr") {
    return i === 1 ? `${i}er` : `${i}ème`;
  }

  // Default to English
  const j = i % 10;
  const k = i % 100;
  if (j === 1 && k !== 11) {
    return `${i}st`;
  }
  if (j === 2 && k !== 12) {
    return `${i}nd`;
  }
  if (j === 3 && k !== 13) {
    return `${i}rd`;
  }
  return `${i}th`;
}

// From: https://stackoverflow.com/questions/5517597/plain-count-up-timer-in-javascript
export function pad(value: number): string {
  return value > 9 ? value.toString() : `0${value}`;
}

export function playSound(soundFilename: string, lengthOfSound = -1): void {
  // First check to see if sound is disabled
  const volume = settings.get("volume") as number;
  if (volume === 0) {
    return;
  }

  if (lengthOfSound !== -1) {
    // For some sound effects, we only want one of them playing at once to prevent confusion
    if (g.playingSound) {
      return; // Do nothing if we are already playing a sound
    }

    g.playingSound = true;
    setTimeout(() => {
      g.playingSound = false;
    }, lengthOfSound);
    // (the 2nd argument to "setTimeout()" should be the length of the sound effect in milliseconds)
  }

  // Sometimes this can give "net::ERR_REQUEST_RANGE_NOT_SATISFIABLE" for some reason
  // (might be related to having multiple Electron apps trying to play the same sound at the same
  // time)
  const audioPath = path.join("sounds", `${soundFilename}.mp3`);
  const audio = new Audio(audioPath);
  audio.volume = volume;
  audio.play().catch((err) => {
    log.info(`Failed to play "${audioPath}": ${err}`);
  });
  log.info(`Played "${audioPath}".`);
}

export function warningShow(message: string): void {
  // Come back in a second if we are still in a transition
  if (g.currentScreen === "transition") {
    setTimeout(() => {
      warningShow(message);
    }, FADE_TIME + 5); // 5 milliseconds of leeway
    return;
  }

  // Log the message
  log.warn(message);

  // Close all tooltips
  closeAllTooltips();

  // Show the warning modal
  $("#gui").fadeTo(FADE_TIME, 0.1, () => {
    $("#warning-modal").fadeIn(FADE_TIME);
    $("#warning-modal-description").html(message);
  });
}
