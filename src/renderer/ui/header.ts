import * as electron from "electron";
import { FADE_TIME, WEBSITE_URL } from "../constants";
import g from "../globals";
import { errorShow } from "../misc";
import * as lobbyScreen from "./lobby";
import * as newRaceTooltip from "./newRaceTooltip";
import * as settingsTooltip from "./settingsTooltip";

export function init(): void {
  initWindowControlButtons();
  initLobbyLinks();
  initLobbyHeaderButtons();

  // Automatically hide the lobby links if the window is resized too far horizontally
  $(window).resize(checkHideLinks);
}

function initWindowControlButtons() {
  $("#header-minimize").click(() => {
    electron.ipcRenderer.send("asynchronous-message", "minimize");
  });

  $("#header-maximize").click(() => {
    electron.ipcRenderer.send("asynchronous-message", "maximize");
  });

  $("#header-close").click(() => {
    electron.ipcRenderer.send("asynchronous-message", "close");
  });
}

function initLobbyLinks() {
  $("#header-profile").click(() => {
    const url = `${WEBSITE_URL}/profile/${g.myUsername}`;
    openExternalURL(url);
  });

  $("#header-leaderboards").click(() => {
    const url = `${WEBSITE_URL}/leaderboards`;
    openExternalURL(url);
  });

  $("#header-help").click(() => {
    const url = `${WEBSITE_URL}/info`;
    openExternalURL(url);
  });
}

function openExternalURL(url: string) {
  electron.shell.openExternal(url).catch((err) => {
    errorShow(`Failed to open the URL of "${url}": ${err}`);
  });
}

function initLobbyHeaderButtons() {
  $("#header-lobby").click(() => {
    if (g.conn === null) {
      throw new Error("The WebSocket connection was not initialized.");
    }

    // Check to make sure we are actually on the race screen
    if (g.currentScreen !== "race") {
      return;
    }

    // Don't allow people to spam this
    const now = new Date().getTime();
    if (now - g.spamTimer < 1000) {
      return;
    }
    g.spamTimer = now;

    // Check to see if the race is over
    const race = g.raceList.get(g.currentRaceID);
    if (race === undefined) {
      // The race is over, so we just need to leave the channel
      g.conn.send("roomLeave", {
        room: `_race_${g.currentRaceID}`,
      });
      lobbyScreen.showFromRace();
      return;
    }

    // The race is not over, so check to see if it has started yet
    if (race.status === "open") {
      // The race has not started yet, so leave the race entirely
      g.conn.send("raceLeave", {
        id: g.currentRaceID,
      });
      return;
    }

    // The race is not over, so check to see if it is in progress
    if (race.status === "in progress") {
      // Check to see if we are still racing
      for (let i = 0; i < race.racerList.length; i++) {
        const racer = race.racerList[i];
        if (racer.name === g.myUsername) {
          // We are racing, so check to see if we are allowed to go back to the lobby
          if (racer.status === "finished" || racer.status === "quit") {
            g.conn.send("roomLeave", {
              room: `_race_${g.currentRaceID}`,
            });
            lobbyScreen.showFromRace();
          }
          break;
        }
      }
    }
  });

  $("#header-lobby").tooltipster({
    theme: "tooltipster-shadow",
    delay: 0,
    functionBefore: () => {
      // Check to make sure we are actually on the race screen
      if (g.currentScreen !== "race") {
        return false;
      }

      // Check to see if the race is still going
      const race = g.raceList.get(g.currentRaceID);
      if (race === undefined) {
        // The race is over
        return false;
      }

      // The race is not over, so check to see if it has started yet
      if (race.status !== "starting" && race.status !== "in progress") {
        // The race has not started yet
        return false;
      }

      // Check to see if we are still racing
      for (let i = 0; i < race.racerList.length; i++) {
        const racer = race.racerList[i];
        if (racer.name === g.myUsername) {
          // We are racing, so check to see if we have finished or quit
          if (racer.status === "finished" || racer.status === "quit") {
            return false;
          }
          break;
        }
      }

      // The race is either starting or in progress
      return true;
    },
  });

  $("#header-new-race")
    .tooltipster({
      theme: "tooltipster-shadow",
      trigger: "click",
      interactive: true,
      functionBefore: newRaceTooltip.tooltipFunctionBefore,
      functionReady: newRaceTooltip.tooltipFunctionReady,
    })
    .tooltipster("instance")
    .on("close", () => {
      // Check if the tooltip is open
      if (!$("#header-settings").tooltipster("status").open) {
        $("#gui").fadeTo(FADE_TIME, 1);
      }
    });

  $("#header-settings")
    .tooltipster({
      theme: "tooltipster-shadow",
      trigger: "click",
      interactive: true,
      functionBefore: settingsTooltip.tooltipFunctionBefore,
      functionReady: settingsTooltip.tooltipFunctionReady,
    })
    .tooltipster("instance")
    .on("close", () => {
      if (!$("#header-new-race").tooltipster("status").open) {
        $("#gui").fadeTo(FADE_TIME, 1);
      }
    });
}

export function checkHideLinks(): void {
  const windowElement = $(window);
  const windowWidth = windowElement.width();
  if (windowWidth === undefined) {
    throw new Error("Failed to get the width of the window.");
  }

  if (windowWidth < 980) {
    $("#header-profile").fadeOut(0);
    $("#header-leaderboards").fadeOut(0);
    $("#header-help").fadeOut(0);
  } else if (g.currentScreen === "lobby" || g.currentScreen === "race") {
    $("#header-profile").fadeIn(0);
    $("#header-leaderboards").fadeIn(0);
    $("#header-help").fadeIn(0);
  }
}
