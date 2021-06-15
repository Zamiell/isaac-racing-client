import settings from "../../common/settings";
import { parseIntSafe } from "../../common/util";
import { FADE_TIME } from "../constants";
import g from "../globals";
import * as localization from "../localization";
import { closeAllTooltips } from "../misc";

export function init(): void {
  $("#settings-volume-slider").change(function settingsVolumeSliderChange() {
    $("#settings-volume-slider-value").html(`${$(this).val()}%`);
  });

  $("#settings-volume-test").click(() => {
    const volumeElement = $("#settings-volume-slider");
    const volumeElementValueString = volumeElement.val();
    if (typeof volumeElementValueString !== "string") {
      throw new Error("Failed to get the value of the volume element.");
    }
    const volumeElementValue = parseIntSafe(volumeElementValueString);
    if (Number.isNaN(volumeElementValue)) {
      throw new Error("Failed to parse the value of the volume element.");
    }

    // Play the "Go" sound effect (but only the voice because it sounds better in this context)
    const audio = new Audio("sounds/go-voice.mp3");
    audio.volume = volumeElementValue / 100;
    audio.play().catch((err) => {
      throw new Error(`Failed to play the sound effect: ${err}`);
    });
  });

  $("#settings-stream-url").keyup(settingsStreamURLKeyup);
  function settingsStreamURLKeyup() {
    const oldStreamURL = g.stream.URLBeforeTyping;
    const newStreamURLElement = $("#settings-stream-url");
    const newStreamURL = newStreamURLElement.val();
    if (typeof newStreamURL !== "string") {
      throw new Error("Failed to get the value of the new stream URL element.");
    }

    if (
      oldStreamURL.indexOf("twitch.tv/") === -1 &&
      newStreamURL.indexOf("twitch.tv/") !== -1
    ) {
      // There was no Twitch stream set before, but now there is
      // So, reveal the "Enable Twitch chat bot" and uncheck it
      $("#settings-enable-twitch-bot-checkbox-container").fadeTo(FADE_TIME, 1);
      $("#settings-enable-twitch-bot-checkbox").prop("disabled", false);
      $("#settings-enable-twitch-bot-checkbox-label").css("cursor", "pointer");
      $("#settings-enable-twitch-bot-checkbox").prop("checked", false); // Uncheck it
      $("#settings-twitch-bot-delay-label").fadeTo(FADE_TIME, 0.25);
      $("#settings-twitch-bot-delay").fadeTo(FADE_TIME, 0.25);
      $("#settings-twitch-bot-delay").prop("disabled", true);

      // Wait for the fading to finish
      setTimeout(() => {
        settingsStreamURLKeyup(); // Since the contents of the text box may have changed in the meantime, run the function again to be sure
      }, FADE_TIME + 5); // 5 milliseconds of leeway
    } else if (
      oldStreamURL.indexOf("twitch.tv/") !== -1 &&
      newStreamURL.indexOf("twitch.tv/") === -1
    ) {
      // There was a Twitch stream set before, but now there isn't
      // So, disable the Twitch bot
      $("#settings-enable-twitch-bot-checkbox-container").fadeTo(
        FADE_TIME,
        0.25,
      );
      $("#settings-enable-twitch-bot-checkbox").prop("disabled", true);
      $("#settings-enable-twitch-bot-checkbox-label").css("cursor", "default");
      $("#settings-enable-twitch-bot-checkbox").prop("checked", false); // Uncheck it
      $("#settings-twitch-bot-delay-label").fadeTo(FADE_TIME, 0.25);
      $("#settings-twitch-bot-delay").fadeTo(FADE_TIME, 0.25);
      $("#settings-twitch-bot-delay").prop("disabled", true);

      // Wait for the fading to finish
      setTimeout(() => {
        settingsStreamURLKeyup(); // Since the contents of the text box may have changed in the meantime, run the function again to be sure
      }, FADE_TIME + 5); // 5 milliseconds of leeway
    }

    g.stream.URLBeforeTyping = newStreamURL;
  }

  $("#settings-enable-twitch-bot-checkbox-container").on("mouseover", () => {
    const streamURL = $("#settings-stream-url").val();
    if (typeof streamURL !== "string") {
      throw new Error("Failed to get the value of the stream URL.");
    }

    // Check if the tooltip is open
    if (
      !$("#settings-enable-twitch-bot-checkbox-container").tooltipster("status")
        .open &&
      streamURL.indexOf("twitch.tv/") !== -1 &&
      !$("#settings-enable-twitch-bot-checkbox").is(":checked")
    ) {
      $("#settings-enable-twitch-bot-checkbox-container").tooltipster("open");
    }
  });

  $("#settings-enable-twitch-bot-checkbox").change(() => {
    const isChecked = $("#settings-enable-twitch-bot-checkbox").prop(
      "checked",
    ) as boolean;
    if (isChecked) {
      $("#settings-twitch-bot-delay-label").fadeTo(FADE_TIME, 1);
      $("#settings-twitch-bot-delay").fadeTo(FADE_TIME, 1);
      $("#settings-twitch-bot-delay").prop("disabled", false);
    } else {
      $("#settings-twitch-bot-delay-label").fadeTo(FADE_TIME, 0.25);
      $("#settings-twitch-bot-delay").fadeTo(FADE_TIME, 0.25);
      $("#settings-twitch-bot-delay").prop("disabled", true);
    }
  });

  $("#settings-form").submit(submit);
}

function submit(event: JQuery.SubmitEvent) {
  // By default, the form will reload the page, so stop this from happening
  event.preventDefault();

  // Don't do anything if we are not on the right screen
  if (g.currentScreen !== "lobby") {
    return false;
  }

  // Language
  const language = $("#settings-language").val();
  if (typeof language !== "string") {
    throw new Error("Failed to get the value of the language element.");
  }
  localization.localize(language);

  // Volume
  const volumeString = $("#settings-volume-slider").val();
  if (typeof volumeString !== "string") {
    throw new Error("Failed to get the value of the volume element.");
  }
  const volume = parseIntSafe(volumeString);
  if (Number.isNaN(volume)) {
    throw new Error("Failed to parse the value of the volume element.");
  }
  settings.set("volume", volume / 100);

  // Stream URL
  let newStreamURL = $("#settings-stream-url").val();
  if (typeof newStreamURL !== "string") {
    throw new Error("Failed to get the value of the stream URL element.");
  }
  if (newStreamURL.startsWith("http://")) {
    // Add HTTPS
    newStreamURL = newStreamURL.replace("http://", "https://");
  }
  if (newStreamURL.startsWith("https://twitch.tv/")) {
    // Add the www
    newStreamURL = newStreamURL.replace("twitch.tv", "www.twitch.tv");
  }
  if (newStreamURL.startsWith("twitch.tv/")) {
    // Add the protocol and www
    newStreamURL = `https://www.${newStreamURL}`;
  }
  if (newStreamURL.startsWith("www.twitch.tv/")) {
    // Add the protocol
    newStreamURL = `https://${newStreamURL}`;
  }
  if (newStreamURL.endsWith("/")) {
    // Remove any trailing forward slashes
    newStreamURL = newStreamURL.replace(/\/+$/, "");
  }
  $("#settings-stream-url").val(newStreamURL);
  if (
    !newStreamURL.startsWith("https://www.twitch.tv/") &&
    newStreamURL !== ""
  ) {
    // We tried to enter a non-valid stream URL
    $("#settings-stream-url").tooltipster("open");
    return false;
  }
  $("#settings-stream-url").tooltipster("close");
  if (newStreamURL === "") {
    newStreamURL = "-"; // Streams cannot be blank on the server-side
  }

  // Twitch bot enabled
  const twitchBotElement = $("#settings-enable-twitch-bot-checkbox");
  const newTwitchBotEnabled = twitchBotElement.prop("checked") as boolean;

  // Twitch bot delay
  const twitchBotDelayString = $("#settings-twitch-bot-delay").val();
  if (typeof twitchBotDelayString !== "string") {
    throw new Error("Failed to get the value of the Twitch bot delay element.");
  }
  if (!/^\d+$/.test(twitchBotDelayString)) {
    // We tried to enter a non-number Twitch bot delay
    $("#settings-twitch-bot-delay").tooltipster("open");
    return false;
  }
  const newTwitchBotDelay = parseIntSafe(twitchBotDelayString);
  if (newTwitchBotDelay < 0 || newTwitchBotDelay > 60) {
    // We tried to enter a delay out of the valid range
    $("#settings-twitch-bot-delay").tooltipster("open");
    return false;
  }
  $("#settings-twitch-bot-delay").tooltipster("close");

  // Send new stream settings if something changed
  if (
    newStreamURL !== g.stream.URL ||
    newTwitchBotEnabled !== g.stream.twitchBotEnabled ||
    newTwitchBotDelay !== g.stream.twitchBotDelay
  ) {
    // Back up the stream URL in case we get a error/warning back from the server
    g.stream.URLBeforeSubmit = g.stream.URL;

    // Update the global copies of these settings
    if (newStreamURL === "-") {
      g.stream.URL = "";
    } else {
      g.stream.URL = newStreamURL;
    }
    g.stream.twitchBotEnabled = newTwitchBotEnabled;
    g.stream.twitchBotDelay = newTwitchBotDelay;

    if (g.conn === null) {
      throw new Error("The WebSocket connection was not initialized.");
    }

    // Send them to the server
    g.conn.send("profileSetStream", {
      name: newStreamURL,
      enabled: newTwitchBotEnabled,
      value: newTwitchBotDelay,
    });
  }

  // Close the tooltip (and all error tooltips, if present)
  closeAllTooltips();

  // Return false or else the form will submit and reload the page
  return false;
}

// The "functionBefore" function for Tooltipster
export function tooltipFunctionBefore(): boolean {
  if (g.currentScreen !== "lobby") {
    return false;
  }

  $("#gui").fadeTo(FADE_TIME, 0.1);
  return true;
}

// The "functionReady" function for Tooltipster
export function tooltipFunctionReady(): void {
  // Fill in all of the settings every time the tooltip is opened
  // (this prevents the user having unsaved settings displayed, which is confusing)

  // Username
  $("#settings-username").html(g.myUsername);

  // Language
  const language = settings.get("language") as string;
  $("#settings-language").val(language);

  // Volume
  const volume = settings.get("volume") as number;
  const adjustedVolume = volume * 100;
  $("#settings-volume-slider").val(adjustedVolume);
  $("#settings-volume-slider-value").html(`${adjustedVolume}%`);

  // Change stream URL
  $("#settings-stream-url").val(g.stream.URL);
  g.stream.URLBeforeTyping = g.stream.URL;

  // Partially fade all of the optional settings by default
  $("#settings-enable-twitch-bot-checkbox-container").fadeTo(0, 0.25);
  $("#settings-enable-twitch-bot-checkbox").prop("checked", false);
  $("#settings-enable-twitch-bot-checkbox").prop("disabled", true);
  $("#settings-enable-twitch-bot-checkbox-label").css("cursor", "default");
  $("#settings-twitch-bot-delay-label").fadeTo(0, 0.25);
  $("#settings-twitch-bot-delay").fadeTo(0, 0.25);
  $("#settings-twitch-bot-delay").prop("disabled", true);

  // Twitch bot delay
  $("#settings-twitch-bot-delay").val(g.stream.twitchBotDelay);

  // Show the checkbox they have a Twitch stream set
  if (g.stream.URL.indexOf("twitch.tv/") !== -1) {
    $("#settings-enable-twitch-bot-checkbox-container").fadeTo(0, 1);
    $("#settings-enable-twitch-bot-checkbox").prop("disabled", false);
    $("#settings-enable-twitch-bot-checkbox-label").css("cursor", "pointer");

    // Enable Twitch chat bot
    if (g.stream.twitchBotEnabled) {
      $("#settings-enable-twitch-bot-checkbox").prop("checked", true);
      $("#settings-twitch-bot-delay-label").fadeTo(0, 1);
      $("#settings-twitch-bot-delay").fadeTo(0, 1);
      $("#settings-twitch-bot-delay").prop("disabled", false);
    }
  }

  // Tooltips within tooltips seem to be buggy and can sometimes be uninitialized
  // So, check for this every time the tooltip is opened and reinitialize them if necessary

  if (!$("#settings-log-file-location").hasClass("tooltipstered")) {
    $("#settings-log-file-location").tooltipster({
      theme: "tooltipster-shadow",
      delay: 0,
      content: settings.get("logFilePath"),
    });
  }

  if (!$("#settings-stream-url").hasClass("tooltipstered")) {
    $("#settings-stream-url").tooltipster({
      theme: "tooltipster-shadow",
      delay: 0,
      trigger: "custom",
    });
  }

  if (
    !$("#settings-enable-twitch-bot-checkbox-container").hasClass(
      "tooltipstered",
    )
  ) {
    $("#settings-enable-twitch-bot-checkbox-container").tooltipster({
      theme: "tooltipster-shadow",
      delay: 750,
      trigger: "custom",
      triggerClose: {
        mouseleave: true,
      },
      zIndex: 10000000 /* The default is 9999999, so it just has to be bigger than that so that it appears on top of the settings tooltip */,
      interactive: true,
    });
  }

  if (!$("#settings-twitch-bot-delay").hasClass("tooltipstered")) {
    $("#settings-twitch-bot-delay").tooltipster({
      theme: "tooltipster-shadow",
      delay: 0,
      trigger: "custom",
    });
  }

  // Redraw the tooltip
  $("#header-settings").tooltipster("reposition");
}
