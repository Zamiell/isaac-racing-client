import log from "electron-log";
import { FADE_TIME, WEBSITE_URL } from "../constants";
import g from "../globals";
import { findAjaxError } from "../misc";
import * as websocket from "../websocket";

export function init(): void {
  $("#register-form").submit((event) => {
    // By default, the form will reload the page, so stop this from happening
    event.preventDefault();

    // Don't do anything if we are already registering
    if (g.currentScreen !== "register") {
      return;
    }

    // Validate username/password/email
    const usernameElement = document.getElementById(
      "register-username",
    ) as HTMLInputElement | null;
    if (usernameElement === null) {
      throw new Error("Failed to get the username element.");
    }
    const username = usernameElement.value.trim();
    if (username === "") {
      $("#register-error").fadeIn(FADE_TIME);
      $("#register-error").html(
        '<span lang="en">The username field is required.</span>',
      );
      return;
    }

    // Fade the form and show the AJAX circle
    g.currentScreen = "register-ajax";
    if ($("#register-error").css("display") !== "none") {
      $("#register-error").fadeTo(FADE_TIME, 0.25);
    }
    $("#register-explanation1").fadeTo(FADE_TIME, 0.25);
    $("#register-explanation2").fadeTo(FADE_TIME, 0.25);
    $("#register-form").fadeTo(FADE_TIME, 0.25);
    $("#register-username").prop("disabled", true);
    $("#register-submit-button").prop("disabled", true);
    $("#register-languages").fadeTo(FADE_TIME, 0.25);
    $("#register-ajax").fadeIn(FADE_TIME);

    // Register the username with the Racing+ server
    register(username);
  });
}

export function show(): void {
  g.currentScreen = "transition";
  $("#title").fadeOut(FADE_TIME, () => {
    $("#register").fadeIn(FADE_TIME, () => {
      g.currentScreen = "register";
    });
    if (g.steam.screenName !== null) {
      $("#register-username").val(g.steam.screenName);
    }
    $("#register-username").focus();
  });
}

// Register with the Racing+ server
// We will resend our Steam ID and ticket, just like we did previously in the login function,
// but this time we will also include our desired username
function register(username: string) {
  log.info("Sending a register request to the Racing+ server.");
  const data = {
    steamID: g.steam.id,
    ticket: g.steam.ticket, // This will be verified on the server via the Steam web API
    username, // Our desired screen name that will be visible to other racers
  };
  const url = `${WEBSITE_URL}/register`;
  const request = $.ajax({
    url,
    type: "POST",
    data,
  });
  // eslint-disable-next-line @typescript-eslint/no-floating-promises
  request.done(() => {
    // We successfully got a cookie; attempt to establish a WebSocket connection
    websocket.connect();
  });
  request.fail(fail); // eslint-disable-line @typescript-eslint/no-floating-promises
}

export function fail(jqXHR: JQuery.jqXHR): void {
  g.currentScreen = "transition";
  reset();

  // Fade in the error box
  const error = findAjaxError(jqXHR);
  $("#register-error").html(`<span lang="en">${error}</span>`);
  $("#register-error").fadeTo(FADE_TIME, 1, () => {
    g.currentScreen = "register";
  });
}

// A function to return the register form back to the way it was initially
export function reset(): void {
  $("#register-explanation1").fadeTo(FADE_TIME, 1);
  $("#register-explanation2").fadeTo(FADE_TIME, 1);
  $("#register-form").fadeTo(FADE_TIME, 1);
  $("#register-username").prop("disabled", false);
  $("#register-submit-button").prop("disabled", false);
  $("#register-languages").fadeTo(FADE_TIME, 1);
  $("#register-ajax").fadeOut(FADE_TIME);
  $("#register-username").focus();
}
