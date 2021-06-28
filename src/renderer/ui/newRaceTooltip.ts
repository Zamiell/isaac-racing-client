import crypto from "crypto";
import BUILDS from "../../../static/data/builds.json";
import CHARACTERS from "../../../static/data/characters.json";
import settings from "../../common/settings";
import { parseIntSafe } from "../../common/util";
import {
  FADE_TIME,
  PBKDF2_DIGEST,
  PBKDF2_ITERATIONS,
  PBKDF2_KEYLEN,
} from "../constants";
import g from "../globals";
import {
  closeAllTooltips,
  errorShow,
  getRandomNumber,
  warningShow,
} from "../misc";

export function init(): void {
  $("#new-race-title-randomize").click(() => {
    // Don't randomize the race name if we are on a test account
    const match = /TestAccount\d+/.exec(g.myUsername);
    if (match !== null) {
      $("#new-race-title").val("{ test race }");
      return;
    }

    // Get some random words
    const randomNumbers = [];
    const numWords = 2;
    for (let i = 0; i < numWords; i++) {
      let randomNumber;
      do {
        randomNumber = getRandomNumber(0, g.wordList.length - 1);
      } while (randomNumbers.indexOf(randomNumber) !== -1);
      randomNumbers.push(randomNumber);
    }
    let randomlyGeneratedName = "";
    for (let i = 0; i < numWords; i++) {
      randomlyGeneratedName += `${g.wordList[randomNumbers[i]]} `;
    }

    // Chop off the trailing space
    randomlyGeneratedName = randomlyGeneratedName.slice(0, -1);

    // Set it
    $("#new-race-title").val(randomlyGeneratedName);

    // Keep track of the last randomly generated name so that we know if they user changes it
    g.lastRaceTitle = randomlyGeneratedName;

    // Mark that we should use randomly generated names from now on
    settings.set("newRaceTitle", ""); // An empty string means to use the random name generator
  });

  $("#new-race-character-randomize").click(() => {
    const char = $("#new-race-character").val();
    let randomChar;
    do {
      const randomCharNum = getRandomNumber(0, CHARACTERS.length - 1);
      randomChar = CHARACTERS[randomCharNum];
    } while (randomChar === char);
    $("#new-race-character").val(randomChar);
    newRaceCharacterChange(null);
  });

  $("#new-race-build-randomize").click(() => {
    const oldBuildString = $("#new-race-starting-build").val();
    if (typeof oldBuildString !== "string") {
      throw new Error("Failed to get the starting build.");
    }
    const oldBuild = parseIntSafe(oldBuildString);
    let randomBuild;
    do {
      // The build at index 0 is intentionally blank
      randomBuild = getRandomNumber(1, BUILDS.length - 1);
    } while (randomBuild === oldBuild);
    $("#new-race-starting-build").val(randomBuild);
    newRaceStartingBuildChange(null);
  });

  $("#new-race-size-solo").change(newRaceSizeChange);
  $("#new-race-size-multiplayer").change(newRaceSizeChange);

  $("#new-race-ranked-no").change(newRaceRankedChange);
  $("#new-race-ranked-yes").change(newRaceRankedChange);

  // eslint-disable-next-line
  // @ts-ignore
  $("#new-race-password").on("input", newRacePasswordChange);

  $("#new-race-format").change(newRaceFormatChange);

  // Add the options to the character dropdown
  for (const character of CHARACTERS) {
    const characterElement = $("<option></option>")
      .val(character)
      .html(character);
    $("#new-race-character").append(characterElement);
  }
  $("#new-race-character").append(
    $('<option lang="en"></option>').val("random").html("Random"),
  );

  $("#new-race-character").change(newRaceCharacterChange);

  $("#new-race-goal").change(newRaceGoalChange);

  // Add the options to the starting build dropdown
  for (let i = 0; i < BUILDS.length; i++) {
    // The 0th element is an empty array
    if (i === 0) {
      continue;
    }

    const build = BUILDS[i];

    // Compile the build description string
    let description = "";
    for (const item of build) {
      description += `${item.name} + `;
    }
    description = description.slice(0, -3); // Chop off the trailing " + "

    // Add the option for this build
    $("#new-race-starting-build").append(
      $("<option></option>").val(i).html(description),
    );

    interface BuildItem {
      id: string;
      name: string;
      spacing?: boolean;
    }

    const lastItem = build[build.length - 1] as unknown as BuildItem;
    if (lastItem.spacing === true) {
      const spacing = new Option("─────────────────────────");
      spacing.disabled = true;
      $("#new-race-starting-build").append($(spacing));
    }
  }
  $("#new-race-starting-build").append(
    $('<option lang="en"></option>').val("0").html("Random"),
  );

  $("#new-race-starting-build").change(newRaceStartingBuildChange);

  $("#new-race-difficulty-normal").change(newRaceDifficultyChange);
  $("#new-race-difficulty-hard").change(newRaceDifficultyChange);

  $("#new-race-form").submit(submit);
}

function submit(event: JQuery.SubmitEvent) {
  // By default, the form will reload the page, so stop this from happening
  event.preventDefault();

  // Don't do anything if we are not on the right screen
  if (g.currentScreen !== "lobby") {
    return false;
  }

  // Get values from the form and update the stored defaults in the "settings.json" file if
  // necessary

  const titleValue = $("#new-race-title").val();
  if (typeof titleValue !== "string") {
    throw new Error("Failed to get the value of the title element.");
  }
  let title = titleValue.trim();
  if (title !== g.lastRaceTitle) {
    settings.set("newRaceTitle", title); // An empty string means to use the random name generator
  }

  const passwordValue = $("#new-race-password").val();
  if (typeof passwordValue !== "string") {
    throw new Error("Failed to get the value of the password element.");
  }
  let password = passwordValue.trim();
  if (password !== settings.get("newRacePassword")) {
    settings.set("newRacePassword", password);
  }

  const size = $("input[name=new-race-size]:checked").val();
  if (size !== settings.get("newRaceSize")) {
    settings.set("newRaceSize", size);
  }

  const rankedString = $("input[name=new-race-ranked]:checked").val();
  if (typeof rankedString !== "string") {
    throw new Error("Failed to get the value of the ranked element.");
  }
  if (rankedString !== settings.get("newRaceRanked")) {
    settings.set("newRaceRanked", rankedString);
  }

  const format = $("#new-race-format").val();
  if (format !== settings.get("newRaceFormat")) {
    settings.set("newRaceFormat", format);
  }

  const character = $("#new-race-character").val();
  if (character !== settings.get("newRaceCharacter")) {
    settings.set("newRaceCharacter", character);
  }

  const goal = $("#new-race-goal").val();
  if (goal !== settings.get("newRaceGoal")) {
    settings.set("newRaceGoal", goal);
  }

  // The server expects "solo" and "ranked" as booleans

  let solo: boolean;
  if (size === "solo") {
    solo = true;
  } else if (size === "multiplayer") {
    solo = false;
  } else {
    errorShow('Expected either "solo" or "multiplayer" for the value of size.');
    return false;
  }

  let ranked: boolean;
  if (rankedString === "yes") {
    ranked = true;
  } else if (rankedString === "no") {
    ranked = false;
  } else {
    errorShow('Expected either "yes" or "no" for the value of ranked.');
    return false;
  }

  if (ranked && format === "seeded") {
    warningShow(
      "Solo ranked seeded races are currently disabled, as the leaderboards have not been programmed yet.",
    );
    return false;
  }

  let startingBuild;
  if (format === "seeded") {
    startingBuild = $("#new-race-starting-build").val();
    if (typeof startingBuild !== "string") {
      throw new Error("Failed to get the value of the starting build element.");
    }
    if (startingBuild !== settings.get("newRaceBuild")) {
      settings.set("newRaceBuild", startingBuild);
    }

    // The server expects this to be a number
    startingBuild = parseIntSafe(startingBuild);
  } else {
    startingBuild = -1;
  }

  const difficulty = $("input[name=new-race-difficulty]:checked").val();
  if (difficulty !== settings.get("newRaceDifficulty")) {
    settings.set("newRaceDifficulty", difficulty);
  }

  // Validate that they are not creating a race with the same title as an existing race
  for (const race of g.raceList.values()) {
    if (race.name === title) {
      $("#new-race-title").tooltipster("open");
      return false;
    }
  }
  $("#new-race-title").tooltipster("close");

  // Truncate names longer than 100 characters
  // (this is also enforced server-side)
  const maximumLength = 100;
  if (title.length > maximumLength) {
    title = title.substring(0, maximumLength);
  }

  // Setup password
  if (solo) {
    password = "";
  } else if (password !== "") {
    const passwordHash = crypto.pbkdf2Sync(
      password,
      title,
      PBKDF2_ITERATIONS,
      PBKDF2_KEYLEN,
      PBKDF2_DIGEST,
    );
    password = passwordHash.toString("base64");
  }

  // Close the tooltip (and all error tooltips, if present)
  closeAllTooltips();

  if (g.conn === null) {
    throw new Error("The WebSocket connection was not initialized.");
  }

  // Create the race
  const rulesetObject = {
    ranked,
    solo,
    format,
    character,
    goal,
    startingBuild,
    difficulty,
  };
  g.currentScreen = "waiting-for-server";
  g.conn.send("raceCreate", {
    name: title,
    password,
    ruleset: rulesetObject,
  });

  // Return false or else the form will submit and reload the page
  return false;
}

function newRaceSizeChange(_event: JQuery.ChangeEvent | null, fast = false) {
  // Change the displayed icon
  const newSize = $("input[name=new-race-size]:checked").val();
  if (newSize === "solo") {
    $("#new-race-size-icon-solo").fadeIn(fast ? 0 : FADE_TIME);
    $("#new-race-size-icon-multiplayer").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-ranked-row").fadeIn(fast ? 0 : FADE_TIME);
    $("#new-race-ranked-row-padding").fadeIn(fast ? 0 : FADE_TIME);
    $("#new-race-password-row").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-password-row-padding").fadeOut(fast ? 0 : FADE_TIME);
    $("#header-new-race").tooltipster("reposition"); // Redraw the tooltip
  } else if (newSize === "multiplayer") {
    $("#new-race-size-icon-solo").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-size-icon-multiplayer").fadeIn(fast ? 0 : FADE_TIME);
    $("#new-race-ranked-row").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-ranked-row-padding").fadeOut(fast ? 0 : FADE_TIME, () => {
      // Unlike the fade in above, the fade out needs to complete before the tooltip is redrawn
      $("#header-new-race").tooltipster("reposition"); // Redraw the tooltip
    });
    $("#new-race-password-row").fadeIn(fast ? 0 : FADE_TIME);
    $("#new-race-password-row-padding").fadeIn(fast ? 0 : FADE_TIME);

    // Multiplayer races must be unranked
    $("#new-race-ranked-no").prop("checked", true);
    newRaceRankedChange(null, true);
  }
}

function newRaceRankedChange(_event: JQuery.ChangeEvent | null, fast = false) {
  // Change the displayed icon
  const newRanked = $("input[name=new-race-ranked]:checked").val();
  $("#new-race-ranked-icon").css(
    "background-image",
    `url("img/ranked/${newRanked}.png")`,
  );

  // Make the format border flash to signify that there are new options there
  if (newRanked === "no" && !fast) {
    const oldColor = $("#new-race-format").css("border-color");
    $("#new-race-format").css("border-color", "green");
    setTimeout(() => {
      $("#new-race-format").css("border-color", oldColor);
    }, 350); // The CSS is set to 0.3 seconds, so we need some leeway
  }

  // Change the subsequent options accordingly
  const format = $("#new-race-format").val();
  if (newRanked === "no") {
    // Show the non-standard formats
    $("#new-race-format-diversity").fadeIn(0);
    $("#new-race-format-custom").fadeIn(0);

    // Show the character and goal drop-downs
    setTimeout(
      () => {
        $("#new-race-character-container").fadeIn(fast ? 0 : FADE_TIME);
        $("#new-race-goal-container").fadeIn(fast ? 0 : FADE_TIME);
        if (format === "seeded") {
          $("#new-race-starting-build-container").fadeIn(fast ? 0 : FADE_TIME);
        }
        $("#header-new-race").tooltipster("reposition"); // Redraw the tooltip
      },
      fast ? 0 : FADE_TIME,
    );
  } else if (newRanked === "yes") {
    // Hide the non-standard formats
    $("#new-race-format-diversity").fadeOut(0);
    $("#new-race-format-custom").fadeOut(0);

    // Hide the character, goal, and build drop-downs
    $("#new-race-character-container").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-starting-build-container").fadeOut(fast ? 0 : FADE_TIME); // This is above the "goal" container below because it may already be hidden and would mess up the callback
    $("#new-race-goal-container").fadeOut(fast ? 0 : FADE_TIME, () => {
      $("#header-new-race").tooltipster("reposition"); // Redraw the tooltip
    });

    // There are only unseeded and seeded formats in ranked races
    if (format !== "unseeded" && format !== "seeded") {
      $("#new-race-format").val("unseeded");
      newRaceFormatChange(null, fast);
    }

    // Set default values for the character, goal, and build drop-downs
    const rankedCharacter = "Judas";
    if ($("#new-race-character").val() !== rankedCharacter) {
      $("#new-race-character").val(rankedCharacter);
      newRaceCharacterChange(null);
    }
    const rankedGoal = "Blue Baby";
    if ($("#new-race-goal").val() !== rankedGoal) {
      $("#new-race-goal").val(rankedGoal);
      newRaceGoalChange(null);
    }
    const rankedBuild = "0"; // random
    if ($("#new-race-starting-build").val() !== rankedBuild) {
      $("#new-race-starting-build").val(rankedBuild);
      newRaceStartingBuildChange(null);
    }
  }
}

function newRacePasswordChange(
  _event: JQuery.ChangeEvent | null,
  fast = false,
) {
  const password = $("#new-race-password").val();
  if (password === null || password === "") {
    $("#new-race-password-no-password-icon").fadeIn(fast ? 0 : FADE_TIME);
    $("#new-race-password-has-password-icon").fadeOut(fast ? 0 : FADE_TIME);
  } else {
    $("#new-race-password-no-password-icon").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-password-has-password-icon").fadeIn(fast ? 0 : FADE_TIME);
  }
}

function newRaceFormatChange(_event: JQuery.ChangeEvent | null, fast = false) {
  // Change the displayed icon
  const newFormat = $("#new-race-format").val();
  $("#new-race-format-icon").css(
    "background-image",
    `url("img/formats/${newFormat}.png")`,
  );

  // Show or hide the starting build row
  const ranked = $("input[name=new-race-ranked]:checked").val();
  if (newFormat === "seeded" && ranked === "no") {
    setTimeout(
      () => {
        $("#new-race-starting-build-container").fadeIn(fast ? 0 : FADE_TIME);
        $("#header-new-race").tooltipster("reposition"); // Redraw the tooltip
      },
      fast ? 0 : FADE_TIME,
    );
  } else if ($("#new-race-starting-build-container").is(":visible")) {
    $("#new-race-starting-build-container").fadeOut(
      fast ? 0 : FADE_TIME,
      () => {
        $("#header-new-race").tooltipster("reposition"); // Redraw the tooltip
      },
    );
  }
}

function newRaceCharacterChange(_event: JQuery.ChangeEvent | null) {
  // Change the displayed icon
  const newCharacter = $("#new-race-character").val();
  $("#new-race-character-icon").css(
    "background-image",
    `url("img/characters/${newCharacter}.png")`,
  );
}

function newRaceGoalChange(_event: JQuery.ChangeEvent | null) {
  // Change the displayed icon
  const newGoal = $("#new-race-goal").val();
  $("#new-race-goal-icon").css(
    "background-image",
    `url("img/goals/${newGoal}.png")`,
  );
}

function newRaceStartingBuildChange(_event: JQuery.ChangeEvent | null) {
  // Change the displayed icon
  const newBuildString = $("#new-race-starting-build").val();
  if (typeof newBuildString !== "string") {
    throw new Error(
      'The value of the "new-race-starting-build" element was not a string.',
    );
  }

  const newBuild = parseIntSafe(newBuildString);
  if (Number.isNaN(newBuild)) {
    throw new Error(
      `Failed to convert the build of "${newBuildString}" to a number.`,
    );
  }

  if (newBuild === 0) {
    $("#new-race-starting-build-icon").css(
      "background-image",
      'url("img/builds/random.png")',
    );
  } else {
    const build = BUILDS[newBuild];
    if (build === undefined) {
      throw new Error(`Failed to find the build at index: ${newBuild}`);
    }
    const firstItemOfBuild = build[0];
    $("#new-race-starting-build-icon").css(
      "background-image",
      `url("img/builds/${firstItemOfBuild.id}.png")`,
    );
  }
}

function newRaceDifficultyChange(_event: JQuery.ChangeEvent | null) {
  // Change the displayed icon
  const newDifficulty = $("input[name=new-race-difficulty]:checked").val();
  if (newDifficulty === "normal") {
    $("#new-race-difficulty-icon-i").css("color", "green");
  } else {
    $("#new-race-difficulty-icon-i").css("color", "red");
  }
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
  // Load the default settings from the settings.json file
  // and hide or show some rows based on the race type and format
  // (the first argument is "event", the second argument is "fast")
  const newRaceTitle = settings.get("newRaceTitle") as string;
  if (newRaceTitle === "") {
    // Randomize the race title
    $("#new-race-title-randomize").click();
  } else {
    $("#new-race-title").val(newRaceTitle);
    g.lastRaceTitle = newRaceTitle;
  }

  const newRacePassword = settings.get("newRacePassword") as string;
  if (newRacePassword !== undefined && newRacePassword !== null) {
    $("#new-race-password").val(newRacePassword);
  }
  newRacePasswordChange(null, true);

  $(`#new-race-size-${settings.get("newRaceSize")}`).prop("checked", true);
  newRaceSizeChange(null, true);
  $(`#new-race-ranked-${settings.get("newRaceRanked")}`).prop("checked", true);
  newRaceRankedChange(null, true);
  $("#new-race-format").val(`${settings.get("newRaceFormat")}`);
  newRaceFormatChange(null, true);
  $("#new-race-character").val(`${settings.get("newRaceCharacter")}`);
  newRaceCharacterChange(null);
  $("#new-race-goal").val(`${settings.get("newRaceGoal")}`);
  newRaceGoalChange(null);
  $("#new-race-starting-build").val(`${settings.get("newRaceBuild")}`);
  newRaceStartingBuildChange(null);
  $(`#new-race-difficulty-${settings.get("newRaceDifficulty")}`).prop(
    "checked",
    true,
  );
  newRaceDifficultyChange(null);
  // (the change functions have to be interspersed here,
  // otherwise the format change would overwrite the character change)

  // Focus the race title box
  // (we have to wait 1 millisecond because the above code that changes rows will wrest focus away)
  setTimeout(() => {
    $("#new-race-title").focus();
  }, 1);

  // Tooltips within tooltips seem to be buggy and can sometimes be uninitialized
  // So, check for this every time the tooltip is opened and reinitialize them if necessary
  if (!$("#new-race-title").hasClass("tooltipstered")) {
    $("#new-race-title").tooltipster({
      theme: "tooltipster-shadow",
      delay: 0,
      trigger: "custom",
    });
  }
}
