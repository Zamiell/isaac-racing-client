import * as electron from "electron";
import log from "electron-log";
import { BUILDS, ITEMS } from "isaac-racing-common";
import { parseIntSafe } from "../../common/socket";
import { CHARACTER_MAP } from "../characterMap";
import * as chat from "../chat";
import { FADE_TIME, IMG_URL_PREFIX } from "../constants";
import g from "../globals";
import * as modSocket from "../modSocket";
import { getMyRacer, getNumLeft } from "../race";
import * as sounds from "../sounds";
import { RaceFormat } from "../types/RaceFormat";
import { RaceGoal } from "../types/RaceGoal";
import { RacerStatus } from "../types/RacerStatus";
import { RaceStatus } from "../types/RaceStatus";
import { Screen } from "../types/Screen";
import {
  capitalize,
  closeAllTooltips,
  errorShow,
  escapeHTML,
  getRandomNumber,
  iRange,
  ordinalSuffixOf,
  pad,
  setElementBackgroundImage,
  setElementBuildIcon,
} from "../util";

const FIRST_GOLDEN_TRINKET_ID = 32769;

export function init(): void {
  $("#race-title").tooltipster({
    theme: "tooltipster-shadow",
    delay: 0,
    functionBefore: () => g.currentScreen === Screen.RACE,
  });

  $("#race-title-type-icon").tooltipster({
    theme: "tooltipster-shadow",
    delay: 0,
    contentAsHTML: true,
    functionBefore: () => g.currentScreen === Screen.RACE,
  });

  $("#race-title-format-icon").tooltipster({
    theme: "tooltipster-shadow",
    delay: 0,
    contentAsHTML: true,
    functionBefore: () => g.currentScreen === Screen.RACE,
  });

  $("#race-title-goal-icon").tooltipster({
    theme: "tooltipster-shadow",
    delay: 0,
    contentAsHTML: true,
    functionBefore: () => g.currentScreen === Screen.RACE,
  });

  $("#race-title-build").tooltipster({
    theme: "tooltipster-shadow",
    delay: 0,
    functionBefore: () => g.currentScreen === Screen.RACE,
  });

  $("#race-title-items-blind").tooltipster({
    theme: "tooltipster-shadow",
    delay: 0,
    functionBefore: () => g.currentScreen === Screen.RACE,
    contentAsHTML: true,
    content:
      '<span lang="en">The random items are not revealed until the race begins!</span>',
  });

  $("#race-title-items").tooltipster({
    theme: "tooltipster-shadow",
    delay: 0,
    functionBefore: () => g.currentScreen === Screen.RACE,
  });

  $("#race-ready-checkbox-container").tooltipster({
    theme: "tooltipster-shadow",
    delay: 0,
    contentAsHTML: true,
    trigger: "custom",
    functionBefore: () =>
      g.currentScreen === Screen.RACE &&
      ($("#race-ready-checkbox").prop("disabled") as boolean),
  });

  $("#race-ready-checkbox").change(function raceReadyCheckboxChange() {
    if (g.currentScreen !== Screen.RACE) {
      return;
    }

    const race = g.raceList.get(g.currentRaceID);
    if (race === undefined) {
      return;
    }

    if (race.status !== RaceStatus.OPEN) {
      return;
    }

    // Don't allow people to spam this.
    const now = new Date().getTime();
    if (now - g.spamTimer < 1000) {
      // Undo what they did.
      if ($("#race-ready-checkbox").is(":checked")) {
        $("#race-ready-checkbox").prop("checked", false);
      } else {
        $("#race-ready-checkbox").prop("checked", true);
      }
      return;
    }
    g.spamTimer = now;

    if (g.conn === null) {
      throw new Error("The WebSocket connection is not initialized.");
    }

    const thisInput = this as HTMLInputElement;
    if (thisInput.checked) {
      g.conn.send("raceReady", {
        id: g.currentRaceID,
      });
    } else {
      g.conn.send("raceUnready", {
        id: g.currentRaceID,
      });
    }
  });

  $("#race-quit-button").click(() => {
    if (g.currentScreen !== Screen.RACE) {
      return;
    }

    const race = g.raceList.get(g.currentRaceID);
    if (race === undefined) {
      return;
    }

    if (race.status !== RaceStatus.IN_PROGRESS) {
      return;
    }

    if (!$("#race-quit-button").is(":visible")) {
      // Account for the possibility of an "Alt+Q" keystroke after the race has started but before
      // the controls are visible.
      return;
    }

    // Find out if we already finished or quit this race.
    const myRacer = getMyRacer(race);
    if (myRacer === null || myRacer.status !== RacerStatus.RACING) {
      return;
    }

    // Don't allow people to spam this.
    const now = new Date().getTime();
    if (now - g.spamTimer < 1000) {
      return;
    }
    g.spamTimer = now;

    if (g.conn === null) {
      throw new Error("The WebSocket connection is not initialized.");
    }

    g.conn.send("raceQuit", {
      id: g.currentRaceID,
    });
  });

  $("#race-finish-button").click(() => {
    if (g.currentScreen !== Screen.RACE) {
      return;
    }

    const race = g.raceList.get(g.currentRaceID);
    if (race === undefined) {
      return;
    }

    if (race.status !== RaceStatus.IN_PROGRESS) {
      return;
    }

    if (!$("#race-finish-button").is(":visible")) {
      // Account for the possibility of an "Alt+F" keystroke after the race has started but before
      // the controls are visible.
      return;
    }

    if (
      race.ruleset.format !== RaceFormat.CUSTOM &&
      race.ruleset.goal !== RaceGoal.CUSTOM
    ) {
      // The finish button is for a race with either:
      // 1) a "Custom" format
      // 2) a "Custom" goal (the Racing+ mod normally takes care of finishing the race
      //    automatically)
      return;
    }

    // Find out if we already finished or quit this race.
    const myRacer = getMyRacer(race);
    if (myRacer === null || myRacer.status !== RacerStatus.RACING) {
      return;
    }

    // Don't allow people to spam this.
    const now = new Date().getTime();
    if (now - g.spamTimer < 1000) {
      return;
    }
    g.spamTimer = now;

    if (g.conn === null) {
      throw new Error("The WebSocket connection is not initialized.");
    }

    g.conn.send("raceFinish", {
      id: g.currentRaceID,
    });
  });

  $("#race-chat-form").submit((event) => {
    // By default, the form will reload the page, so stop this from happening.
    event.preventDefault();

    // Validate input and send the chat.
    const element = document.getElementById(
      "race-chat-box-input",
    ) as HTMLInputElement | null;
    if (element !== null) {
      const message = element.value;
      chat.send("race", message);
    }
  });
}

export function show(raceID: number): void {
  // We should be on the lobby screen unless there is severe lag.
  if (g.currentScreen === Screen.TRANSITION) {
    setTimeout(() => {
      show(raceID);
    }, FADE_TIME + 5); // 5 milliseconds of leeway
    return;
  }

  // - `currentScreen` should be `Screen.WAITING_FOR_SERVER` if they created a race or joined a
  //   current race.
  // - currentScreen should be `Screen.LOBBY` if they are rejoining a race after a disconnection.
  if (
    g.currentScreen !== Screen.WAITING_FOR_SERVER &&
    g.currentScreen !== Screen.LOBBY
  ) {
    errorShow(
      `Failed to enter the race screen since currentScreen is equal to "${g.currentScreen}".`,
    );
    return;
  }

  g.currentRaceID = raceID;
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  const character = CHARACTER_MAP.get(race.ruleset.character);
  if (character === undefined) {
    errorShow(
      `The character of "${race.ruleset.character}" is unsupported on the client.`,
    );
    return;
  }

  // We preload sounds now since the user has probably interacted with the page at this point. (This
  // will not be true if they are reconnecting mid-way through a race, but oh well.)
  sounds.preload();

  // Tell the Lua mod that we are in a new race.
  g.modSocket.raceID = race.id;
  g.modSocket.status = race.status;
  g.modSocket.ranked = race.ruleset.ranked;
  g.modSocket.solo = race.ruleset.solo;
  g.modSocket.format = race.ruleset.format;
  g.modSocket.difficulty = race.ruleset.difficulty;
  g.modSocket.character = character;
  g.modSocket.goal = race.ruleset.goal;
  g.modSocket.seed = race.ruleset.seed;
  g.modSocket.startingBuild = race.ruleset.startingBuild;
  g.modSocket.countdown = -1;
  // The real values for the rest will be sent once we receive the "racerList" command from the
  // server.
  g.modSocket.place = 0;
  g.modSocket.placeMid = -1;
  g.modSocket.numReady = 0;
  g.modSocket.numEntrants = 1;
  modSocket.sendAll();

  // Start the UI transition.
  g.currentScreen = Screen.TRANSITION;

  // Show and hide some buttons in the header.
  $("#header-profile").fadeOut(FADE_TIME);
  $("#header-leaderboards").fadeOut(FADE_TIME);
  $("#header-help").fadeOut(FADE_TIME);
  $("#header-new-race").fadeOut(FADE_TIME);
  if (race.status === RaceStatus.IN_PROGRESS) {
    // Check to see if we are still racing.
    const myRacer = getMyRacer(race);
    if (
      myRacer !== null &&
      myRacer.status !== RacerStatus.FINISHED &&
      myRacer.status !== RacerStatus.QUIT
    ) {
      $("#header-lobby").addClass("disabled");
    }
  }
  $("#header-settings").fadeOut(FADE_TIME, () => {
    $("#header-profile").fadeIn(FADE_TIME);
    $("#header-leaderboards").fadeIn(FADE_TIME);
    $("#header-help").fadeIn(FADE_TIME);
    $("#header-lobby").fadeIn(FADE_TIME);
  });

  // Close all tooltips
  closeAllTooltips();

  // Show the race screen.
  $("#lobby").fadeOut(FADE_TIME, () => {
    $("#race").fadeIn(FADE_TIME, () => {
      g.currentScreen = Screen.RACE;
    });

    // Build the title
    let raceTitle: string;
    if (race.name === "-") {
      raceTitle = `Race ${g.currentRaceID}`;
    } else {
      // Sanitize the race name.
      raceTitle = escapeHTML(race.name);
    }
    if (raceTitle.length > 60) {
      // Truncate the title
      raceTitle = `${raceTitle.substring(0, 70)}...`;

      // Enable the tooltip
      const content = race.name; // This does not need to be escaped because tooltipster displays HTML as plain text
      $("#race-title").tooltipster("content", content);
    } else {
      // Disable the tooltip
      $("#race-title").tooltipster("content", "");
    }
    $("#race-title").html(raceTitle);

    // Adjust the font size so that it only takes up one line.
    let emSize = 1.75; // In HTML5UP Alpha, h3's are 1.75
    do {
      // Reset the font size. (We could be coming from a previous race.)
      $("#race-title").css("font-size", `${emSize}em`);

      // Reduce the font size by a little bit.
      emSize -= 0.1;

      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    } while ($("#race-title").height()! > 45); // One line is 45 pixels high.

    // Column 1 - Status.
    let circleClass: RaceStatus;
    if (
      race.status === RaceStatus.OPEN ||
      race.status === RaceStatus.STARTING ||
      race.status === RaceStatus.IN_PROGRESS ||
      race.status === RaceStatus.FINISHED
    ) {
      circleClass = race.status;
    } else {
      errorShow("Unable to parse the race status.");
      return;
    }
    let statusText = `<span class="circle lobby-current-races-${circleClass}"></span> &nbsp; `;
    statusText += `<span lang="en">${capitalize(race.status)}</span>`;
    $("#race-title-status").html(statusText);

    // Column 2 - Ranked.
    const { ranked, solo } = race.ruleset;
    const typeIconURL = `img/types/${ranked ? "ranked" : "unranked"}${
      solo ? "-solo" : ""
    }.png`;
    setElementBackgroundImage("race-title-type-icon", typeIconURL);
    let typeTooltipContent = "<strong>";
    if (solo) {
      typeTooltipContent += '<span lang="en">Solo</span> ';
    }
    if (ranked) {
      typeTooltipContent += '<span lang="en">Ranked</span>:</strong><br />';
      typeTooltipContent +=
        '<span lang="en">This race will count towards the leaderboards.</span>';
    } else {
      typeTooltipContent += '<span lang="en">Unranked</span>:</strong><br />';
      typeTooltipContent +=
        '<span lang="en">This race will not count towards the leaderboards.</span>';
    }
    if (solo) {
      typeTooltipContent +=
        '<br /><span lang="en">No-one else can join this race.</span>';
    }
    $("#race-title-type-icon").tooltipster("content", typeTooltipContent);

    // Column 3 - Format.
    const { format } = race.ruleset;
    setElementBackgroundImage(
      "race-title-format-icon",
      `img/formats/${format}.png`,
    );
    let formatTooltipContent = "<span>";

    switch (format) {
      case RaceFormat.UNSEEDED: {
        formatTooltipContent +=
          '<strong><span lang="en">Unseeded</span>:</strong><br />';
        formatTooltipContent +=
          '<span lang="en">Reset over and over until you find something good from a Treasure Room.</span><br />';
        formatTooltipContent +=
          '<span lang="en">You will be playing on an entirely different seed than your opponent(s).</span>';
        break;
      }

      case RaceFormat.SEEDED: {
        formatTooltipContent +=
          '<strong><span lang="en">Seeded</span>:</strong><br />';
        formatTooltipContent +=
          '<span lang="en">You will play on the same seed as your opponent and start with The Compass.</span>';
        break;
      }

      case RaceFormat.DIVERSITY: {
        formatTooltipContent +=
          '<strong><span lang="en">Diversity</span>:</strong><br />';
        formatTooltipContent +=
          '<span lang="en">This is the same as the "Unseeded" format, but you will also start with five random items.</span><br />';
        formatTooltipContent +=
          '<span lang="en">All players will start with the same five items.</span>';
        break;
      }

      case RaceFormat.CUSTOM: {
        formatTooltipContent +=
          '<strong><span lang="en">Custom</span>:</strong><br />';
        formatTooltipContent +=
          '<span lang="en">You make the rules! Make sure that everyone in the race knows what to do before you start.</span>';
        break;
      }
    }

    formatTooltipContent += "</span>";
    $("#race-title-format-icon").tooltipster("content", formatTooltipContent);

    // Column 4 - Character.
    $("#race-title-character").html(race.ruleset.character.toString());

    // Column 5 - Goal.
    const { goal } = race.ruleset;
    setElementBackgroundImage(
      "race-title-goal-icon",
      `${IMG_URL_PREFIX}/goals/${goal}.png`,
    );
    let goalTooltipContent = "";

    switch (goal) {
      case RaceGoal.BLUE_BABY: {
        goalTooltipContent +=
          '<strong><span lang="en">Blue Baby</span>:</strong><br />';
        goalTooltipContent +=
          '<span lang="en">Defeat Blue Baby (the boss of The Chest)</span><br />';
        goalTooltipContent +=
          '<span lang="en">and touch the trophy that falls down afterward.</span>';
        break;
      }

      case RaceGoal.THE_LAMB: {
        goalTooltipContent +=
          '<strong><span lang="en">The Lamb</span>:</strong><br />';
        goalTooltipContent +=
          '<span lang="en">Defeat The Lamb (the boss of The Dark Room)</span><br />';
        goalTooltipContent +=
          '<span lang="en">and touch the trophy that falls down afterward.</span>';
        break;
      }

      case RaceGoal.MEGA_SATAN: {
        goalTooltipContent +=
          '<strong><span lang="en">Mega Satan</span>:</strong><br />';
        goalTooltipContent +=
          '<span lang="en">Defeat Mega Satan (the boss behind the giant locked door)</span><br />';
        goalTooltipContent +=
          '<span lang="en">and touch the trophy that falls down afterward.</span>';
        break;
      }

      case RaceGoal.HUSH: {
        goalTooltipContent +=
          '<strong><span lang="en">Hush</span>:</strong><br />';
        goalTooltipContent +=
          '<span lang="en">Defeat Hush (the boss in the Blue Womb)</span><br />';
        goalTooltipContent +=
          '<span lang="en">and touch the trophy that falls down afterward.</span>';
        break;
      }

      case RaceGoal.DELIRIUM: {
        goalTooltipContent +=
          '<strong><span lang="en">Delirium</span>:</strong><br />';
        goalTooltipContent +=
          '<span lang="en">Defeat Delirium (the boss in The Void)</span><br />';
        goalTooltipContent +=
          '<span lang="en">and touch the trophy that falls down afterward.</span>';
        break;
      }

      case RaceGoal.MOTHER: {
        goalTooltipContent +=
          '<strong><span lang="en">Mother</span>:</strong><br />';
        goalTooltipContent +=
          '<span lang="en">Defeat Mother (the boss of Corpse II)</span><br />';
        goalTooltipContent +=
          '<span lang="en">and touch the trophy that falls down afterward.</span>';
        break;
      }

      case RaceGoal.THE_BEAST: {
        goalTooltipContent +=
          '<strong><span lang="en">The Beast</span>:</strong><br />';
        goalTooltipContent += '<span lang="en">Defeat The Beast</span><br />';
        goalTooltipContent +=
          '<span lang="en">and touch the trophy that falls down afterward.</span>';
        break;
      }

      case RaceGoal.BOSS_RUSH: {
        goalTooltipContent +=
          '<strong><span lang="en">Boss Rush</span>:</strong><br />';
        goalTooltipContent +=
          '<span lang="en">Complete the Boss Rush (after defeating Mom)</span><br />';
        goalTooltipContent +=
          '<span lang="en">and touch the trophy that falls down afterward.</span>';
        break;
      }

      case RaceGoal.CUSTOM: {
        goalTooltipContent +=
          '<strong><span lang="en">Custom</span>:</strong><br />';
        goalTooltipContent +=
          '<span lang="en">You make the rules! Make sure that everyone in the race knows what to do before you start.</span>';
        break;
      }
    }

    $("#race-title-goal-icon").tooltipster("content", goalTooltipContent);

    // Column 6 - Hard Mode.
    $("#race-title-hard").html(race.ruleset.difficulty);

    // Column 7 - Build. (Only available for seeded races.)
    if (race.ruleset.format === RaceFormat.SEEDED) {
      $("#race-title-table-build").fadeIn(0);
      $("#race-title-build").fadeIn(0);
      const buildIndex = race.ruleset.startingBuild;

      const build = BUILDS[buildIndex];
      if (build === undefined) {
        throw new Error(`Failed to find the build at index: ${buildIndex}`);
      }

      setElementBuildIcon("race-title-build-icon", buildIndex);

      let buildTooltipContent = "";
      for (const item of build) {
        buildTooltipContent += `${item.name} + `;
      }
      buildTooltipContent = buildTooltipContent.slice(0, -3); // Chop off the trailing " + "
      $("#race-title-build").tooltipster("content", buildTooltipContent);
    } else {
      $("#race-title-table-build").fadeOut(0);
      $("#race-title-build").fadeOut(0);
    }

    // Column 7 - Items. (Only available for diversity races.)
    if (race.ruleset.format === RaceFormat.DIVERSITY) {
      $("#race-title-table-items").fadeIn(0);
      $("#race-title-items").fadeIn(0);
      $("#race-title-items-blind").fadeOut(0);

      // The server represents the items for the diversity race through the "seed" value.
      const items = race.ruleset.seed.split(",");

      // Show the graphic corresponding to this item on the race title table.
      for (const i of iRange(1, 3)) {
        setElementBackgroundImage(
          `race-title-items-icon${i}`,
          `${IMG_URL_PREFIX}/items/${items[i]}.png`,
        );
      }

      // Build the tooltip
      let buildTooltipContent = "";
      for (let i = 0; i < items.length; i++) {
        const itemID = items[i];
        if (itemID === undefined) {
          continue;
        }

        if (i === 4) {
          // Item 5 is a trinket.
          let modifiedTrinketID = parseIntSafe(itemID);
          if (modifiedTrinketID < FIRST_GOLDEN_TRINKET_ID) {
            // Trinkets are represented in the "items.json" file as items with IDs past 2000 (but
            // golden trinkets retain their vanilla ID).
            modifiedTrinketID += 2000;
          }

          const key = modifiedTrinketID.toString() as keyof typeof ITEMS;
          const itemEntry = ITEMS[key];
          // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
          if (itemEntry === undefined) {
            errorShow(
              `Trinket ${modifiedTrinketID} was not found in the items list.`,
            );
            return;
          }

          buildTooltipContent += itemEntry.name;
        } else {
          // Items 1 through 4 are passive and active items.
          const key = itemID as keyof typeof ITEMS;
          const itemEntry = ITEMS[key];
          // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
          if (itemEntry === undefined) {
            errorShow(`Collectible ${itemID} was not found in the items list.`);
            return;
          }

          buildTooltipContent += `${itemEntry.name} + `;
        }
      }

      // Add the tooltip
      $("#race-title-items").tooltipster("content", buildTooltipContent);

      // Show 3 question marks as the items if the race has not begun yet.
      if (race.status !== RaceStatus.IN_PROGRESS) {
        $("#race-title-items").fadeOut(0);
        $("#race-title-items-blind").fadeIn(0);
      }
    } else {
      $("#race-title-table-items").fadeOut(0);
      $("#race-title-items-blind").fadeOut(0);
      $("#race-title-items").fadeOut(0);
    }

    // Show the pre-start race controls.
    $("#race-ready-checkbox-container").fadeIn(0);
    $("#race-ready-checkbox").prop("checked", false);
    $("#race-ready-checkbox").prop("disabled", true);
    $("#race-ready-checkbox-label").css("cursor", "default");
    $("#race-ready-checkbox-container").fadeTo(FADE_TIME, 0.38);
    // This will update the tooltip on what the player needs to do in order to become ready.
    checkReadyValid();
    $("#race-countdown").fadeOut(0);
    $("#race-quit-button-container").fadeOut(0);
    $("#race-finish-button-container").fadeOut(0);
    $("#race-controls-padding").fadeOut(0);
    $("#race-num-left-container").fadeOut(0);

    // Set the race participants table to the pre-game state (with 2 columns).
    $("#race-participants-table-place").fadeOut(0);
    $("#race-participants-table-status").css("width", "70%");
    $("#race-participants-table-floor").fadeOut(0);
    $("#race-participants-table-item").fadeOut(0);
    $("#race-participants-table-time").fadeOut(0);
    $("#race-participants-table-offset").fadeOut(0);

    // Automatically scroll to the bottom of the chat box.
    const raceChatHeight = $("#race-chat-text").height();
    if (raceChatHeight === undefined) {
      throw new Error("Failed to get the height of the race chat element.");
    }
    const bottomPixel =
      $("#race-chat-text").prop("scrollHeight") - raceChatHeight;
    $("#race-chat-text").scrollTop(bottomPixel);

    // Focus the chat input.
    $("#race-chat-box-input").focus();

    // If we disconnected in the middle of the race, we need to update the race controls.
    if (race.status === RaceStatus.STARTING) {
      errorShow(
        "You rejoined the race during the countdown, which is not supported. Please relaunch the program.",
      );
    } else if (race.status === RaceStatus.IN_PROGRESS) {
      start();
    }
  });
}

// Add a row to the table with the race participants on the race screen.
export function participantAdd(i: number): void {
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  const racer = race.racerList[i];
  if (racer === undefined) {
    log.error(
      `Failed to get racer #${i} from race #${g.currentRaceID}. (There are only ${race.racerList.length} racers in the race.)`,
    );
    return;
  }
  let racerDiv: string;
  if (racer.name === g.myUsername) {
    racerDiv = `<tr id="race-participants-table-${racer.name}" class="race-participants-table-self-row">`;
  } else {
    racerDiv = `<tr id="race-participants-table-${racer.name}">`;
  }

  // The racer's place
  racerDiv += `<td id="race-participants-table-${racer.name}-place" class="hidden">`;
  if (racer.place === -1 || racer.place === -2) {
    racerDiv += "-"; // They quit or were disqualified
  } else if (racer.place === 0) {
    // If they are still racing.
    if (racer.placeMid === -1) {
      racerDiv += "-";
    } else {
      // This is their non-finished place based on their current floor.
      racerDiv += ordinalSuffixOf(racer.placeMid);
    }
  } else {
    // They finished, so mark the place as a different color to distinguish it from a mid-game
    // place.
    racerDiv += '<span style="color: blue;">';
    racerDiv += ordinalSuffixOf(racer.place);
    racerDiv += "</span>";
  }
  racerDiv += "</td>";

  // The racer's name.
  racerDiv += `<td id="race-participants-table-${racer.name}-name" class="selectable">${racer.name}</td>`;

  // The racer's status.
  racerDiv += `<td id="race-participants-table-${racer.name}-status">`;
  // This will get filled in later in the "participantsSetStatus" function.
  racerDiv += "</td>";

  // The racer's floor.
  racerDiv += `<td id="race-participants-table-${racer.name}-floor" class="hidden">`;
  // This will get filled in later in the "participantsSetFloor" function.
  racerDiv += "</td>";

  // The racer's starting item.
  racerDiv += `<td id="race-participants-table-${racer.name}-item" class="hidden race-participants-table-item">`;
  // This will get filled in later in the "participantsSetStartingItem" function.
  racerDiv += "</td>";

  // The racer's time.
  racerDiv += `<td id="race-participants-table-${racer.name}-time" class="hidden">`;
  racerDiv += "</td>";

  // The racer's time offset.
  racerDiv += `<td id="race-participants-table-${racer.name}-offset" class="hidden">-</td>`;

  // Append the row.
  racerDiv += "</tr>";
  $("#race-participants-table-body").append(racerDiv);

  // Fix a small visual bug where the left border isn't drawn because of the left-most column being
  // hidden.
  $(`#race-participants-table-${racer.name}-name`).css(
    "border-left",
    "solid 1px #e5e5e5",
  );

  // Update some values in the row.
  participantsSetStatus(i, true);
  participantsSetFloor(i);
  participantsSetPlaceMid(i);
  participantsSetStartingItem(i);

  // Fix the bug where the "vertical-center" class causes things to be hidden if there is overflow.
  if (race.racerList.length > 6) {
    // More than 6 races causes the overflow.
    $("#race-participants-table-wrapper").removeClass("vertical-center");
  } else {
    $("#race-participants-table-wrapper").addClass("vertical-center");
  }

  // Now that someone is joined, we want to recheck to see if the ready checkbox should be disabled.
  checkReadyValid();
}

export function participantsSetStatus(i: number, initial = false): void {
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  const racer = race.racerList[i];
  if (racer === undefined) {
    return;
  }

  // Update the status column of the row.
  let statusDiv = "";
  if (racer.status === RacerStatus.READY) {
    statusDiv +=
      '<i class="fa fa-check" aria-hidden="true" style="color: green;"></i> &nbsp; ';
  } else if (racer.status === RacerStatus.NOT_READY) {
    statusDiv +=
      '<i class="fa fa-times" aria-hidden="true" style="color: red;"></i> &nbsp; ';
  } else if (racer.status === RacerStatus.RACING) {
    statusDiv +=
      '<i class="mdi mdi-chevron-double-right" style="color: orange;"></i> &nbsp; ';
  } else if (racer.status === RacerStatus.QUIT) {
    statusDiv += '<i class="mdi mdi-skull"></i> &nbsp; ';
  } else if (racer.status === RacerStatus.FINISHED) {
    statusDiv +=
      '<i class="fa fa-check" aria-hidden="true" style="color: green;"></i> &nbsp; ';
  }
  statusDiv += `<span lang="en">${capitalize(racer.status)}</span>`;
  $(`#race-participants-table-${racer.name}-status`).html(statusDiv);

  // Update the place column of the row.
  if (racer.status === RacerStatus.FINISHED) {
    const ordinal = ordinalSuffixOf(racer.place);
    const placeDiv = `<span style="color: blue;">${ordinal}</span>`;
    $(`#race-participants-table-${racer.name}-place`).html(placeDiv);
  } else if (racer.status === RacerStatus.QUIT) {
    $(`#race-participants-table-${racer.name}-place`).html("-");
  }

  // Find out the number of people left in the race.
  const numLeft = getNumLeft(race);
  $("#race-num-left").html(`${numLeft} left`);
  if (
    racer.status === RacerStatus.FINISHED ||
    racer.status === RacerStatus.QUIT ||
    racer.status === RacerStatus.DISQUALIFIED
  ) {
    if (!initial) {
      log.info("There are", numLeft, "people left in race:", g.currentRaceID);
    }
  }

  // If someone finished, set their time to their actual final time as reported by the server
  // (instead of the client-side approximation).
  if (racer.status === RacerStatus.FINISHED) {
    // This code is partially copied from the "raceTimerTick()" function below.
    const raceTotalSeconds = Math.floor(racer.runTime / 1000); // "runTime" is in milliseconds
    const raceMinutes = Math.floor(raceTotalSeconds / 60);
    const raceSeconds = raceTotalSeconds % 60;
    const timeDiv = `${pad(raceMinutes)}:${pad(raceSeconds)}`;
    $(`#race-participants-table-${racer.name}-time`).html(timeDiv);
  }

  // If someone finished, play a sound effect corresponding to how they did. (But don't play sound
  // effects for 1 player races.)
  if (
    racer.name === g.myUsername &&
    racer.status === RacerStatus.FINISHED &&
    !race.ruleset.solo
  ) {
    if (racer.runTime - g.lastFinishedTime <= 3000) {
      // They finished within 3 seconds of the last player that finished Play the special "NO DUDE"
      // sound effect.
      const randNum = getRandomNumber(1, 8);
      sounds.play(`no/no${randNum}`);
    } else {
      // Play the sound effect that matches their place.
      sounds.play(`place/${racer.place}`, 1800);
    }
  }

  // If we finished or quit.
  if (
    racer.name === g.myUsername &&
    (racer.status === RacerStatus.FINISHED || racer.status === RacerStatus.QUIT)
  ) {
    // Hide the button since we can only finish or quit once.
    if (numLeft === 0) {
      $("#race-controls-padding").fadeOut(0); // If we don't fade out instantly, there will be a graphical glitch with the "Race completed!" fade in
      $("#race-quit-button-container").fadeOut(0);
      $("#race-finish-button-container").fadeOut(0);
    } else {
      $("#race-controls-padding").fadeOut(FADE_TIME);
      $("#race-quit-button-container").fadeOut(FADE_TIME);
      $("#race-finish-button-container").fadeOut(FADE_TIME);
    }

    // Activate the "Lobby" button in the header.
    $("#header-lobby").removeClass("disabled");
  }

  // Play a sound effect if someone quit or finished.
  if (!initial) {
    if (racer.status === RacerStatus.FINISHED) {
      sounds.play("finished");
      g.lastFinishedTime = racer.runTime;
    } else if (racer.status === RacerStatus.QUIT) {
      sounds.play("quit");
    }
  }
}

export function participantsSetFloor(i: number): void {
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  const racer = race.racerList[i];
  if (racer === undefined) {
    return;
  }
  const { name, floorNum, stageType } = racer;

  // Update the floor column of the row.
  const altFloor = stageType === 4 || stageType === 5;
  let floorDiv: string;
  if (floorNum === 0) {
    floorDiv = "-";
  } else if (floorNum === 1) {
    floorDiv = altFloor ? "Do1" : "B1";
  } else if (floorNum === 2) {
    floorDiv = altFloor ? "Do2" : "B2";
  } else if (floorNum === 3) {
    floorDiv = altFloor ? "Mi1" : "C1";
  } else if (floorNum === 4) {
    floorDiv = altFloor ? "Mi2" : "C2";
  } else if (floorNum === 5) {
    floorDiv = altFloor ? "Ma1" : "D1";
  } else if (floorNum === 6) {
    floorDiv = altFloor ? "Ma2" : "D2";
  } else if (floorNum === 7) {
    floorDiv = altFloor ? "Co1" : "W1";
  } else if (floorNum === 8) {
    floorDiv = altFloor ? "Co2" : "W2";
  } else if (floorNum === 9) {
    floorDiv = "BW";
  } else if (floorNum === 10 && stageType === 0) {
    floorDiv = "Sheol"; // 10-0 is Sheol
  } else if (floorNum === 10 && stageType === 1) {
    floorDiv = "Cath"; // 10-1 is Cathedral
  } else if (floorNum === 11 && stageType === 0) {
    floorDiv = "DR"; // 11-0 is Dark Room
  } else if (floorNum === 11 && stageType === 1) {
    floorDiv = "Chest";
  } else if (floorNum === 12) {
    floorDiv = "Void";
  } else if (floorNum === 13) {
    floorDiv = "Home";
  } else if (floorNum === 14) {
    floorDiv = "MS"; // For Mega Satan
  } else {
    errorShow(`The floor for "${name}" is unrecognized: ${floorNum}`);
    return;
  }

  $(`#race-participants-table-${name}-floor`).html(floorDiv);
}

export function participantsSetPlaceMid(i: number): void {
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  const racer = race.racerList[i];
  if (racer === undefined) {
    return;
  }
  const { placeMid } = racer;

  const html = placeMid === -1 ? "-" : ordinalSuffixOf(placeMid);
  $(`#race-participants-table-${racer.name}-place`).html(html);
}

export function participantsSetStartingItem(i: number): void {
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  const racer = race.racerList[i];
  if (racer === undefined) {
    return;
  }
  const { name, startingItem } = racer;

  // Update the starting item column of the row.
  if (startingItem === 0) {
    $(`#race-participants-table-${name}-item`).html("-");
  } else {
    const html = `
      <div class="race-participants-table-starting-item-icon-container">
        <span class="race-participants-table-starting-item-icon" style="background-image: url(${IMG_URL_PREFIX}/items/${startingItem}.png);"></span>
      </div>
    `;
    $(`#race-participants-table-${name}-item`).html(html);
  }
}

export function startCountdown(): void {
  if (g.currentScreen === Screen.TRANSITION) {
    // Come back when the current transition finishes.
    setTimeout(() => {
      startCountdown();
    }, FADE_TIME + 5); // 5 milliseconds of leeway
    return;
  }

  // Don't do anything if we are not on the race screen.
  if (g.currentScreen !== Screen.RACE) {
    return;
  }

  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  // Change the functionality of the "Lobby" button in the header.
  $("#header-lobby").addClass("disabled");

  if (race.ruleset.solo) {
    // Show the countdown instantly without any fade.
    $("#race-ready-checkbox-container").fadeOut(0);
    $("#race-countdown").html("");
    $("#race-countdown").fadeIn(0);
  } else {
    // Play the "Let's Go" sound effect.
    sounds.play("lets-go");

    // Tell the Lua mod that we are starting a race.
    modSocket.send("set", "countdown 10");

    // Show the countdown.
    $("#race-ready-checkbox-container").fadeOut(FADE_TIME, () => {
      $("#race-countdown").css("font-size", "1.75em");
      $("#race-countdown").css("bottom", "0.25em");
      $("#race-countdown").css("color", "#e89980");
      $("#race-countdown").html(
        '<span lang="en">Race starting in 10 seconds!</span>',
      );
      $("#race-countdown").fadeIn(FADE_TIME);
    });
  }

  // Reset the "lastFinishedTime" variable that is used for custom close race sound effects.
  g.lastFinishedTime = 0;
}

export function countdownTick(i: number): void {
  if (g.currentScreen === Screen.TRANSITION) {
    // Come back when the current transition finishes.
    setTimeout(() => {
      countdownTick(i);
    }, FADE_TIME + 5); // 5 milliseconds of leeway
    return;
  }

  // Don't do anything if we are not on the race screen.
  if (g.currentScreen !== Screen.RACE) {
    return;
  }

  // Schedule the next tick.
  if (i >= 0) {
    setTimeout(() => {
      countdownTick(i - 1);
    }, 1000);
  } else {
    return;
  }

  // If only three seconds are left, automatically focus the game.
  if (i === 3) {
    electron.ipcRenderer.send("asynchronous-message", "isaacFocus");
  }

  // Update the Lua mod with how many seconds are left until the race starts.
  g.modSocket.countdown = i;
  if (i === 0) {
    // This is to avoid bugs where things happen out of order.
    g.modSocket.countdown = -1;
    modSocket.send("set", `countdown ${g.modSocket.countdown}`);
    g.modSocket.status = RaceStatus.IN_PROGRESS;
    modSocket.send("set", `status ${g.modSocket.status}`);
    g.modSocket.myStatus = RacerStatus.RACING;
    modSocket.send("set", `myStatus ${g.modSocket.myStatus}`);
    g.modSocket.place = 0;
    modSocket.send("set", `place ${g.modSocket.place}`);
  } else {
    g.modSocket.countdown = i;
    modSocket.send("set", `countdown ${g.modSocket.countdown}`);
  }

  // Play the sound effect associated with the final 3 seconds.
  if (i === 3 || i === 2 || i === 1) {
    sounds.play(i.toString());
  } else if (i === 0) {
    sounds.play("go");
  }

  if (i > 0) {
    countdownTickAboveZero(i);
  } else if (i === 0) {
    countdownReachedZero();
  }
}

function countdownTickAboveZero(i: number) {
  // Change the number on the race controls area (5, 4, 3, 2, 1).
  $("#race-countdown").fadeOut(FADE_TIME, () => {
    $("#race-countdown").css("font-size", "2.5em");
    $("#race-countdown").css("bottom", "0.375em");
    $("#race-countdown").css("color", "red");
    $("#race-countdown").html(i.toString());
    $("#race-countdown").fadeIn(FADE_TIME);
  });
}

function countdownReachedZero() {
  setTimeout(() => {
    const race = g.raceList.get(g.currentRaceID);
    if (race === undefined) {
      return;
    }

    // Update the text to "Go" on the race controls area.
    $("#race-countdown").html('<span lang="en">Go</span>!');
    $("#race-title-status").html(
      '<span class="circle lobby-current-races-in-progress"></span> &nbsp; <span lang="en">In Progress</span>',
    );

    // Wait 3 seconds, then start to change the controls.
    setTimeout(start, 3000);

    // If this is a diversity race, show the three diversity items.
    if (race.ruleset.format === RaceFormat.DIVERSITY) {
      $("#race-title-items-blind").fadeOut(FADE_TIME, () => {
        $("#race-title-items").fadeIn(FADE_TIME);
      });
    }

    // Add default values to the columns to the race participants table.
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];
      if (racer === undefined) {
        continue;
      }

      racer.status = RacerStatus.RACING;
      racer.place = 0;

      racer.placeMid = race.racerList.length; // Set everyone to last place
      participantsSetPlaceMid(i);
      modSocket.sendExtraValues();

      const statusDiv =
        '<i class="mdi mdi-chevron-double-right" style="color: orange;"></i> &nbsp; <span lang="en">Racing</span>';
      $(`#race-participants-table-${racer.name}-status`).html(statusDiv);
      $(`#race-participants-table-${racer.name}-item`).html("-");
      $(`#race-participants-table-${racer.name}-time`).html("-");
      $(`#race-participants-table-${racer.name}-offset`).html("-");
    }
  }, FADE_TIME);
}

function start() {
  // Don't do anything if we are not on the race screen. (It is okay to proceed here if we are on
  // the transition screen since we want the race controls to be drawn before it fades in.)
  if (
    g.currentScreen !== Screen.RACE &&
    g.currentScreen !== Screen.TRANSITION
  ) {
    return;
  }

  // Don't do anything if the race has already ended.
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  // In case we coming back after a disconnect, redo all of the stuff that was done in the
  // "startCountdown" function.
  $("#race-ready-checkbox-container").fadeOut(0);

  // Start the race timer.
  setTimeout(raceTimerTick, 0);

  // Change the controls on the race screen.
  $("#race-countdown").fadeOut(FADE_TIME, () => {
    // Find out if we have quit or finished this race already and count the number of people who are
    // still in the race (which should be everyone, but just in case).
    let alreadyFinished = false;
    let numLeft = 0;
    for (const racer of race.racerList) {
      if (
        racer.name === g.myUsername &&
        (racer.status === RacerStatus.QUIT ||
          racer.status === RacerStatus.FINISHED)
      ) {
        alreadyFinished = true;
      }
      if (racer.status === RacerStatus.RACING) {
        numLeft++;
      }
    }

    // Show the quit button.
    if (!alreadyFinished) {
      $("#race-quit-button-container").fadeIn(FADE_TIME);
      if (
        race.ruleset.format === RaceFormat.CUSTOM ||
        race.ruleset.goal === RaceGoal.CUSTOM
      ) {
        $("#race-finish-button-container").fadeIn(FADE_TIME);
      }
    }

    // Show the number of people left in the race.
    $("#race-num-left").html(`${numLeft} left`);
    if (!race.ruleset.solo) {
      // In solo races, there will always be 1 person left, so showing this is redundant.
      $("#race-controls-padding").fadeIn(FADE_TIME);
      $("#race-num-left-container").fadeIn(FADE_TIME);
    }
  });

  // Change the table to have 6 columns instead of 2.
  $("#race-participants-table-place").fadeIn(FADE_TIME);
  $("#race-participants-table-status").css("width", "8em");
  // $('#race-participants-table-status').css('width', '7.5em');
  $("#race-participants-table-floor").fadeIn(FADE_TIME);
  $("#race-participants-table-item").fadeIn(FADE_TIME);
  $("#race-participants-table-time").fadeIn(FADE_TIME);
  $("#race-participants-table-offset").fadeIn(FADE_TIME);
  for (const racer of race.racerList) {
    $(`#race-participants-table-${racer.name}-place`).fadeIn(FADE_TIME);
    $(`#race-participants-table-${racer.name}-name`).css("border-left", "0");
    // The "border-left" change is is to fix a small visual bug where the left border isn't drawn
    // because of the left-most column being hidden.
    $(`#race-participants-table-${racer.name}-floor`).fadeIn(FADE_TIME);
    $(`#race-participants-table-${racer.name}-item`).fadeIn(FADE_TIME);
    $(`#race-participants-table-${racer.name}-time`).fadeIn(FADE_TIME);
    $(`#race-participants-table-${racer.name}-offset`).fadeIn(FADE_TIME);
  }
}

function raceTimerTick() {
  // Don't do anything if we are not on the race screen. (We can also be on the transition screen if
  // we are reconnecting in the middle of a race.)
  if (
    g.currentScreen !== Screen.RACE &&
    g.currentScreen !== Screen.TRANSITION
  ) {
    return;
  }

  // Stop the timer if the race is over. (The race is over if the entry in the raceList is deleted.)
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  // Get the elapsed time in the race.
  const now = new Date().getTime();
  const raceMilliseconds = now - race.datetimeStarted;
  const raceTotalSeconds = Math.floor(raceMilliseconds / 1000);
  const raceMinutes = Math.floor(raceTotalSeconds / 60);
  const raceSeconds = raceTotalSeconds % 60;
  const timeDiv = `${pad(raceMinutes)}:${pad(raceSeconds)}`;

  // Update all of the timers.
  for (const racer of race.racerList) {
    if (racer.status === RacerStatus.RACING) {
      $(`#race-participants-table-${racer.name}-time`).html(timeDiv);
    }
  }

  // Schedule the next tick.
  setTimeout(raceTimerTick, 1000);
}

export function checkReadyValid(): void {
  if (g.currentScreen === Screen.TRANSITION) {
    // Come back when the current transition finishes.
    setTimeout(() => {
      checkReadyValid();
    }, FADE_TIME + 5); // 5 milliseconds of leeway
    return;
  }

  // Don't do anything if we are not in a race.
  if (g.currentScreen !== Screen.RACE || g.currentRaceID === -1) {
    return;
  }

  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  if (race.status !== RaceStatus.OPEN) {
    return;
  }

  // Due to lag, we might get here before the racerList is defined, so check for that.
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  if (race.racerList === undefined) {
    return;
  }

  // Check for a bunch of things before we allow the user to mark themselves off as ready.
  let valid = true;
  let tooltipContent = "";
  if (!race.ruleset.solo && race.racerList.length === 1) {
    valid = false;
    tooltipContent =
      '<span lang="en">Since this is a multiplayer race, you must wait for someone else to join before marking yourself as ready.</span>';
  } else if (race.ruleset.format === RaceFormat.CUSTOM) {
    // Do nothing. (We want to do no validation for custom rulesets; it's all up to the players to
    // decide when they are ready.)
  } else if (!g.gameState.modConnected) {
    valid = false;
    tooltipContent =
      '<span lang="en">You must have the Racing+ mod enabled in-game before you can mark yourself as ready.</span>';
    tooltipContent +=
      '<br /><span lang="en">(If you do have the Racing+ mod enabled, then restart the run to reconnect to the client.)</span>';
  } else if (!g.gameState.inGame) {
    valid = false;
    tooltipContent =
      '<span lang="en">You have to start a run before you can mark yourself as ready.</span>';
  } else if (!g.gameState.runMatchesRuleset) {
    valid = false;
    tooltipContent =
      '<span lang="en">The type of run that you are on does not match the race\'s ruleset. Make sure that you are not in a challenge and are on the correct difficulty.</span>';
  }

  if (!valid) {
    $("#race-ready-checkbox").prop("disabled", true);
    $("#race-ready-checkbox-label").css("cursor", "default");
    $("#race-ready-checkbox-container").fadeTo(FADE_TIME, 0.38);
    $("#race-ready-checkbox-container").tooltipster("content", tooltipContent);
    $("#race-ready-checkbox-container").tooltipster("open");
    return;
  }

  // We passed all the tests, so make sure that the checkbox is enabled.
  $("#race-ready-checkbox").prop("disabled", false);
  $("#race-ready-checkbox-label").css("cursor", "pointer");
  $("#race-ready-checkbox-container").tooltipster("close");
  $("#race-ready-checkbox-container").fadeTo(FADE_TIME, 1);
}
