import BUILDS from "../../../static/data/builds.json";
import * as chat from "../chat";
import { FADE_TIME } from "../constants";
import g from "../globals";
import { capitalize, errorShow, escapeHTML, pad } from "../misc";
import * as modSocket from "../modSocket";
import Race from "../types/Race";
import * as header from "./header";

export function init(): void {
  $("#lobby-chat-form").submit((event) => {
    // By default, the form will reload the page, so stop this from happening
    event.preventDefault();

    // Validate input and send the chat
    chat.send("lobby");
  });
}

// Called from the login screen or the register screen
export function show(): void {
  // Make sure that all of the forms are cleared out
  $("#login-username").val("");
  $("#login-password").val("");
  $("#login-remember-checkbox").prop("checked", false);
  $("#login-error").fadeOut(0);
  $("#register-username").val("");
  $("#register-password").val("");
  $("#register-email").val("");
  $("#register-error").fadeOut(0);

  // Show the links in the header
  $("#header-profile").fadeIn(FADE_TIME);
  $("#header-leaderboards").fadeIn(FADE_TIME);
  $("#header-help").fadeIn(FADE_TIME);

  // Show the buttons in the header
  $("#header-new-race").fadeIn(FADE_TIME);
  $("#header-settings").fadeIn(FADE_TIME);

  // Show the lobby
  $("#page-wrapper").removeClass("vertical-center");
  $("#lobby").fadeIn(FADE_TIME, () => {
    g.currentScreen = "lobby";
  });

  // Fix the indentation on lines that were drawn when the element was hidden
  chat.indentAll("lobby");

  // Automatically scroll to the bottom of the chat box
  const lobbyChatHeight = $("#lobby-chat-text").height();
  if (lobbyChatHeight === undefined) {
    throw new Error("Failed to get the height of the lobby chat element.");
  }
  const bottomPixel =
    $("#lobby-chat-text").prop("scrollHeight") - lobbyChatHeight;
  $("#lobby-chat-text").scrollTop(bottomPixel);

  // Focus the chat input
  $("#lobby-chat-box-input").focus();
}

export function showFromRace(): void {
  // We should be on the race screen unless there is severe lag
  if (g.currentScreen !== "race") {
    errorShow(
      `Failed to return to the lobby since currentScreen is equal to "${g.currentScreen}".`,
    );
    return;
  }
  g.currentScreen = "transition";
  g.currentRaceID = -1;

  // Update the Racing+ Lua mod
  modSocket.reset();

  // Show and hide some buttons in the header
  $("#header-profile").fadeOut(FADE_TIME);
  $("#header-leaderboards").fadeOut(FADE_TIME);
  $("#header-help").fadeOut(FADE_TIME);
  $("#header-lobby").fadeOut(FADE_TIME, () => {
    $("#header-profile").fadeIn(FADE_TIME);
    $("#header-leaderboards").fadeIn(FADE_TIME);
    $("#header-help").fadeIn(FADE_TIME);
    $("#header-new-race").fadeIn(FADE_TIME);
    $("#header-settings").fadeIn(FADE_TIME);
    header.checkHideLinks(); // We just faded in the links, but they might be hidden on small windows
  });
  $("#race-ready-checkbox-container").tooltipster("close");

  // Show the lobby
  $("#race").fadeOut(FADE_TIME, () => {
    $("#lobby").fadeIn(FADE_TIME, () => {
      g.currentScreen = "lobby";
    });

    // Fix the indentation on lines that were drawn when the element was hidden
    chat.indentAll("lobby");

    // Automatically scroll to the bottom of the chat box
    const lobbyChatHeight = $("#lobby-chat-text").height();
    if (lobbyChatHeight === undefined) {
      throw new Error("Failed to get the height of the lobby chat element.");
    }
    const bottomPixel =
      $("#lobby-chat-text").prop("scrollHeight") - lobbyChatHeight;
    $("#lobby-chat-text").scrollTop(bottomPixel);

    // Focus the chat input
    $("#lobby-chat-box-input").focus();
  });
}

export function raceDraw(race: Race): void {
  // Create the new row
  let raceDiv = `<tr id="lobby-current-races-${race.id}" class="`;
  if (race.status === "open" && !race.ruleset.solo) {
    raceDiv += "lobby-race-row-open ";
  }
  raceDiv += 'hidden">';

  // Column 1 - Name
  raceDiv += `<td id="lobby-current-races-${race.id}-name" class="lobby-current-races-name selectable">`;

  if (race.isPasswordProtected) {
    raceDiv += '<i class="fa fa-lock"></i>&nbsp;';
  }

  if (race.name === "-") {
    raceDiv += `<span lang="en">Race</span> ${race.id}`;
  } else {
    raceDiv += escapeHTML(race.name);
  }
  raceDiv += "</td>";

  // Column 2 - Status
  raceDiv += '<td class="lobby-current-races-status">';
  let circleClass;
  if (race.status === "open") {
    circleClass = "open";
  } else if (race.status === "starting") {
    circleClass = "starting";
  } else if (race.status === "in progress") {
    circleClass = "in-progress";
  }
  raceDiv += `<span id="lobby-current-races-${race.id}-status-circle" class="circle lobby-current-races-${circleClass}"></span>`;
  raceDiv += ` &nbsp; <span id="lobby-current-races-${
    race.id
  }-status"><span lang="en">${capitalize(race.status)}</span></span>`;
  raceDiv += "</td>";

  // Column 3 - Format
  raceDiv += `<td id="lobby-current-races-format-${race.id}" class="lobby-current-races-format">`;

  raceDiv += '<span class="lobby-current-races-size-icon">';
  if (race.ruleset.solo) {
    raceDiv +=
      '<i class="fa fa-user 2x" aria-hidden="true" style="position: relative; left: 0.1em;"></i>';
    // Move this to the right so that it lines up with the center of the multiplayer icon
  } else {
    raceDiv +=
      '<i class="fa fa-users 2x" aria-hidden="true" style="color: blue;"></i>';
  }
  raceDiv += "</span>";

  if (race.ruleset.solo) {
    raceDiv += '<span class="lobby-current-races-type-icon">';
    raceDiv += `<span class="lobby-current-races-${
      race.ruleset.ranked ? "ranked" : "unranked"
    }" lang="en"></span></span>`;
    raceDiv += '<span class="lobby-current-races-spacing"></span>';
  }

  raceDiv += '<span class="lobby-current-races-format-icon">';
  raceDiv += `<span class="lobby-current-races-${race.ruleset.format}" lang="en"></span></span>`;

  // Column 4 - Size
  raceDiv += `<td id="lobby-current-races-${race.id}-size" class="lobby-current-races-size">`;
  // This will get filled in later by the "raceUpdatePlayers" function
  raceDiv += "</td>";

  // Column 5 - Entrants
  raceDiv += `<td id="lobby-current-races-${race.id}-racers" class="lobby-current-races-racers selectable">`;
  // This will get filled in later by the "raceUpdatePlayers" function
  raceDiv += "</td>";

  // Fix the bug where the "vertical-center" class causes things to be hidden if there is overflow
  if (Object.keys(g.raceList).length > 4) {
    // More than 4 races causes the overflow
    $("#lobby-current-races-table-wrapper").removeClass("vertical-center");
  } else {
    $("#lobby-current-races-table-wrapper").addClass("vertical-center");
  }

  // Add it and fade it in
  $("#lobby-current-races-table-body").append(raceDiv);
  if ($("#lobby-current-races-table-no").css("display") !== "none") {
    $("#lobby-current-races-table-no").fadeOut(FADE_TIME, () => {
      $("#lobby-current-races-table").fadeIn(0);
      raceDraw2(race);
    });
  } else {
    raceDraw2(race);
  }
}

function raceDraw2(race: Race) {
  // Fade in the race row
  $(`#lobby-current-races-${race.id}`).fadeIn(FADE_TIME, () => {
    // While we were fading in, the race might have ended
    if (!g.raceList.has(race.id)) {
      return;
    }

    // Make the row clickable
    if (race.status === "open" && !race.ruleset.solo) {
      $(`#lobby-current-races-${race.id}`).click(() => {
        if (g.currentScreen === "lobby") {
          if (race.isPasswordProtected) {
            // Show the password modal
            $("#gui").fadeTo(FADE_TIME, 0.1, () => {
              const passwordInput = $("#password-input");
              passwordInput.val("");
              passwordInput.data("raceID", race.id);
              passwordInput.data("raceTitle", race.name);
              $("#password-modal").fadeIn(FADE_TIME);
              passwordInput.focus();
            });
          } else {
            g.currentScreen = "waiting-for-server";
            if (g.conn === null) {
              throw new Error("The WebSocket connection was not initialized.");
            }
            g.conn.send("raceJoin", {
              id: race.id,
            });
          }
        }
      });
    }

    // Make the format tooltip
    let content = '<ul style="margin-bottom: 0;">';

    content +=
      '<li class="lobby-current-races-format-li"><strong><span lang="en">Size</span>:</strong> ';
    if (race.ruleset.solo) {
      content += '<span lang="en">Solo</span><br />';
      content += '<span lang="en">This is a single-player race.</span>';
    } else {
      content += '<span lang="en">Multiplayer</span><br />';
      if (race.isPasswordProtected) {
        content += '<span lang="en">This race is password protected.</span>';
      } else {
        content += '<span lang="en">Anyone can join this race.</span>';
      }
    }
    content += "</li>";

    content +=
      '<li class="lobby-current-races-format-li"><strong><span lang="en">Ranked</span>:</strong> ';
    if (race.ruleset.ranked) {
      content += '<span lang="en">Yes</span><br />';
      content +=
        '<span lang="en">This race will count towards the leaderboards.</span>';
    } else {
      content += '<span lang="en">No</span><br />';
      content +=
        '<span lang="en">This race will not count towards the leaderboards.</span>';
    }
    content += "</li>";

    const { format } = race.ruleset;
    content +=
      '<li class="lobby-current-races-format-li"><strong><span lang="en">Format</span>:</strong> ';
    if (format === "unseeded") {
      content += '<span lang="en">Unseeded</span><br />';
      content +=
        '<span lang="en">Reset over and over until you find something good from a Treasure Room.</span><br />';
      content +=
        '<span lang="en">You will be playing on an entirely different seed than your opponent(s).</span>';
    } else if (format === "seeded") {
      content += '<span lang="en">Seeded</span><br />';
      content +=
        '<span lang="en">You will play on the same seed as your opponent and start with The Compass.</span>';
    } else if (format === "diversity") {
      content += '<span lang="en">Diversity</span><br />';
      content +=
        '<span lang="en">This is the same as the "Unseeded" format, but you will also start with five random items.</span><br />';
      content +=
        '<span lang="en">All players will start with the same five items.</span>';
    } else if (format === "custom") {
      content += '<li><span lang="en">Custom</span><br />';
      content +=
        '<span lang="en">You make the rules! Make sure that everyone in the race knows what to do before you start.</span>';
    }
    content += "</li>";

    const { character } = race.ruleset;
    content += `<li class="lobby-current-races-format-li"><strong><span lang="en">Character</span>:</strong> ${character}</li>`;

    const { goal } = race.ruleset;
    content += `<li class="lobby-current-races-format-li"><strong><span lang="en">Goal</span>:</strong> ${goal}</li>`;

    if (format === "seeded") {
      const { startingBuild } = race.ruleset;
      content +=
        '<li class="lobby-current-races-format-li"><strong><span lang="en">Starting Build</span>:</strong> ';
      for (const item of BUILDS[startingBuild]) {
        content += `${item.name} + `;
      }
      content = content.slice(0, -3); // Chop off the trailing " + "
      content += "</li>";
    }

    content += "</ul>";
    $(`#lobby-current-races-format-${race.id}`).tooltipster({
      theme: "tooltipster-shadow",
      delay: 0,
      content,
      contentAsHTML: true,
      functionBefore: () => g.currentScreen === "lobby",
    });
  });

  // Now that it has begun to fade in, we can fill it
  raceDrawCheckForOverflow(race.id, "name");

  // Update the players
  raceUpdatePlayers(race.id);
}

export function raceUpdatePlayers(raceID: number): void {
  const race = g.raceList.get(raceID);
  if (race === undefined) {
    return;
  }

  // Draw the new size
  $(`#lobby-current-races-${raceID}-size`).html(race.racers.length.toString());

  // Draw the new racer list
  let racers = "";
  for (const racer of race.racers) {
    if (racer === race.captain) {
      racers += `<strong>${racer}</strong>, `;
    } else {
      racers += `${racer}, `;
    }
  }
  racers = racers.slice(0, -2); // Chop off the trailing comma and space
  $(`#lobby-current-races-${raceID}-racers`).html(racers);

  // Check for overflow in the racer list
  raceDrawCheckForOverflow(raceID, "racers");
}

// Make tooltips for long names if necessary
function raceDrawCheckForOverflow(raceID: number, target: string) {
  const race = g.raceList.get(raceID);
  if (race === undefined) {
    return;
  }

  const element = $(`#lobby-current-races-${raceID}-${target}`);

  // Race name column
  let shortened = false;
  let counter = 0; // It is possible to get stuck in the bottom while loop
  while (element[0].scrollWidth > (element.innerWidth() as number)) {
    counter += 1;
    if (counter >= 1000) {
      // Something is weird and the page is not rendering properly
      break;
    }
    const shortenedName = $(`#lobby-current-races-${raceID}-${target}`)
      .html()
      .slice(0, -1);
    element.html(shortenedName);
    shortened = true;
  }

  let content = "";
  if (target === "name") {
    content = race.name; // This does not need to be escaped because tooltipster displays HTML as plain text
  } else if (target === "racers") {
    for (const racer of race.racers) {
      content += `${racer}, `;
    }
    content = content.slice(0, -2); // Chop off the trailing comma and space
  }
  if (shortened) {
    const shortenedName = element.html().slice(0, -1); // Make it a bit shorter to account for the padding
    element.html(`${shortenedName}...`);
    if (element.hasClass("tooltipstered")) {
      element.tooltipster("content", content);
    } else {
      element.tooltipster({
        theme: "tooltipster-shadow",
        delay: 0,
        content,
        contentAsHTML: true,
        functionBefore: () => g.currentScreen === "lobby",
      });
    }
  } else if (element.hasClass("tooltipstered")) {
    // Delete any existing tooltips, if they exist
    element.tooltipster("content", "");
  }
}

export function raceUndraw(raceID: number): void {
  $(`#lobby-current-races-${raceID}`).fadeOut(FADE_TIME, () => {
    $(`#lobby-current-races-${raceID}`).remove();

    if (Object.keys(g.raceList).length === 0) {
      $("#lobby-current-races-table").fadeOut(0);
      $("#lobby-current-races-table-no").fadeIn(FADE_TIME);
    }
  });

  // Fix the bug where the "vertical-center" class causes things to be hidden if there is overflow
  if (Object.keys(g.raceList).length > 4) {
    // More than 4 races causes the overflow
    $("#lobby-current-races-table-wrapper").removeClass("vertical-center");
  } else {
    $("#lobby-current-races-table-wrapper").addClass("vertical-center");
  }
}

export function usersDraw(): void {
  const lobbyRoom = g.roomList.get("lobby");
  if (lobbyRoom === undefined) {
    throw new Error("Failed to get the lobby room.");
  }

  // Update the header that shows shows the amount of people online or in the race
  $("#lobby-users-online").html(lobbyRoom.numUsers.toString());

  // Make an array with the name of every user and alphabetize it
  const usernameList = [];
  for (const user of lobbyRoom.users.keys()) {
    usernameList.push(user);
  }

  // Case insensitive sort of the connected users
  usernameList.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

  // Empty the existing list
  const usersElement = $("#lobby-users-users");
  usersElement.html("");

  // Add a div for each player
  for (const username of usernameList) {
    if (username === g.myUsername) {
      const userDiv = `<div>${username}</div>`;
      usersElement.append(userDiv);
    } else {
      const userDiv = `
        <div id="lobby-users-user-${username}" class="users-user" data-tooltip-content="#user-click-tooltip">
            ${username}
        </div>
      `;
      usersElement.append(userDiv);
    }
  }
}

export function statusTimer(raceID: number): void {
  // Stop the timer if the race is over
  // (the race is over if the entry in the raceList is deleted)

  const race = g.raceList.get(raceID);
  if (race === undefined) {
    return;
  }

  // Don't replace anything if this race is not in progress
  if (race.status !== "in progress") {
    return;
  }

  // Get the elapsed time in the race and set it to the div
  const now = new Date().getTime();
  const raceMilliseconds = now - race.datetimeStarted;
  const raceTotalSeconds = Math.round(raceMilliseconds / 1000);
  const raceMinutes = Math.floor(raceTotalSeconds / 60);
  const raceSeconds = raceTotalSeconds % 60;
  const timeDiv = `${pad(raceMinutes)}:${pad(raceSeconds)}`;
  $(`#lobby-current-races-${raceID}-status`).html(timeDiv);

  // Update the timer again a second from now
  setTimeout(() => {
    statusTimer(raceID);
  }, 1000);
}
