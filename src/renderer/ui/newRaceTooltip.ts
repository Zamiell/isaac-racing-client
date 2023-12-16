import {
  getRandomArrayElement,
  getRandomArrayIndex,
  getRandomInt,
  parseIntSafe,
  repeat,
} from "isaacscript-common-ts";
import crypto from "node:crypto";
import { settings } from "../../common/settings";
import {
  BUILDS,
  CHARACTERS,
  FADE_TIME,
  IMG_URL_PREFIX,
  PBKDF2_DIGEST,
  PBKDF2_ITERATIONS,
  PBKDF2_KEYLEN,
  RANDOM_BUILD,
} from "../constants";
import { g } from "../globals";
import { Screen } from "../types/Screen";
import {
  closeAllTooltips,
  errorShow,
  setElementBackgroundImage,
  setElementBuildIcon,
} from "../utils";

export function init(): void {
  $("#new-race-title-randomize").click(() => {
    // Don't randomize the race name if we are on a test account.
    const match = /TestAccount\d+/.exec(g.myUsername);
    if (match !== null) {
      $("#new-race-title").val("{ test race }");
      return;
    }

    // Get some random words.
    const randomIndexes: number[] = [];
    const numWords = 2;
    repeat(numWords, () => {
      const randomArrayIndex = getRandomArrayIndex(g.wordList, randomIndexes);
      randomIndexes.push(randomArrayIndex);
    });

    const randomWords = randomIndexes.map(
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      (randomIndex) => g.wordList[randomIndex]!,
    );
    const randomlyGeneratedName = randomWords.join(" ");

    // Set it
    $("#new-race-title").val(randomlyGeneratedName);

    // Keep track of the last randomly generated name so that we know if they user changes it.
    g.lastRaceTitle = randomlyGeneratedName;

    // Mark that we should use randomly generated names from now on.
    settings.set("newRaceTitle", ""); // An empty string means to use the random name generator
  });

  $("#new-race-character-randomize").click(() => {
    const char = $("#new-race-character").val();
    let randomChar: string;
    do {
      const randomCharIndex = getRandomInt(0, CHARACTERS.length - 1);
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      randomChar = CHARACTERS[randomCharIndex]!;
    } while (randomChar === char);
    $("#new-race-character").val(randomChar);
    newRaceCharacterChange(null);
  });

  $("#new-race-build-randomize").click(() => {
    const oldBuildString = $("#new-race-starting-build").val();
    if (typeof oldBuildString !== "string") {
      throw new TypeError(
        'The value from the "new-race-starting-build" element was not a string.',
      );
    }
    const oldBuild = parseIntSafe(oldBuildString);
    let randomBuild: number;
    do {
      // The build at index 0 is intentionally blank.
      randomBuild = getRandomInt(1, BUILDS.length - 1);
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

  // Add the options to the character dropdown.
  for (const character of CHARACTERS) {
    const characterElement = $("<option></option>")
      .val(character)
      .html(character);
    $("#new-race-character").append(characterElement);
  }

  $("#new-race-character").change(newRaceCharacterChange);

  $("#new-race-goal").change(newRaceGoalChange);

  // Add the options to the starting build dropdown.
  for (let i = 0; i < BUILDS.length; i++) {
    const build = BUILDS[i];
    if (build === undefined) {
      continue;
    }

    // Add the option for this build.
    $("#new-race-starting-build").append(
      $("<option></option>").val(i).html(build.name),
    );

    const lastItem = build.collectibles.at(-1);
    if (lastItem === undefined) {
      throw new Error(
        `Failed to get the final collectible for build: ${build.name}`,
      );
    }

    // Insert spacing in between each build category. We also want spacing between the last build
    // and the "Random" selection.
    const nextBuild = BUILDS[i + 1];
    if (nextBuild === undefined || build.category !== nextBuild.category) {
      const spacing = new Option("─────────────────────────");
      spacing.disabled = true;
      $("#new-race-starting-build").append($(spacing));
    }
  }

  $("#new-race-starting-build").change(newRaceStartingBuildChange);

  $("#new-race-difficulty-normal").change(newRaceDifficultyChange);
  $("#new-race-difficulty-hard").change(newRaceDifficultyChange);

  $("#new-race-form").submit(submit);
}

function submit(event: JQuery.SubmitEvent) {
  // By default, the form will reload the page, so stop this from happening.
  event.preventDefault();

  // Don't do anything if we are not on the right screen.
  if (g.currentScreen !== Screen.LOBBY) {
    return false;
  }

  // Get values from the form and update the stored defaults in the "settings.json" file if
  // necessary.

  const titleValue = $("#new-race-title").val();
  if (typeof titleValue !== "string") {
    throw new TypeError(
      'The value from the "new-race-title" element was not a string.',
    );
  }
  let title = titleValue.trim();
  if (title !== g.lastRaceTitle) {
    settings.set("newRaceTitle", title); // An empty string means to use the random name generator
  }

  const passwordValue = $("#new-race-password").val();
  if (typeof passwordValue !== "string") {
    throw new TypeError(
      'The value from the "new-race-password" element was not a string.',
    );
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
    throw new TypeError(
      'The value from the "new-race-ranked" element was not a string.',
    );
  }
  if (rankedString !== settings.get("newRaceRanked")) {
    settings.set("newRaceRanked", rankedString);
  }

  let format = $("#new-race-format").val();
  if (format !== settings.get("newRaceFormat")) {
    settings.set("newRaceFormat", format);
  }

  let character = $("#new-race-character").val();
  if (character !== settings.get("newRaceCharacter")) {
    settings.set("newRaceCharacter", character);
  }

  // If we selected "Random" for the character, we must select a random character before sending it
  // to the server.
  if (character === "Random") {
    const exceptions = format === "seeded" ? ["Tainted Lazarus"] : [];
    character = getRandomArrayElement(CHARACTERS, exceptions);
  }

  const goal = $("#new-race-goal").val();
  if (goal !== settings.get("newRaceGoal")) {
    settings.set("newRaceGoal", goal);
  }

  // The server expects "solo" and "ranked" as booleans.

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

  let startingBuildIndex: number;
  if (format === "seeded") {
    const startingBuildVal = $("#new-race-starting-build").val();
    if (typeof startingBuildVal !== "string") {
      throw new TypeError(
        'The value from the "new-race-starting-build" element was not a string.',
      );
    }
    if (startingBuildVal !== settings.get("newRaceBuild")) {
      settings.set("newRaceBuild", startingBuildVal);
    }

    // The server expects this to be a number.
    startingBuildIndex = parseIntSafe(startingBuildVal) ?? -1;
    if (startingBuildIndex === -1) {
      throw new Error(
        `Failed to parse the starting build value of: ${startingBuildVal}`,
      );
    }

    // If we selected "Random" for the build, we must select a random build before sending it to the
    // server.
    if (startingBuildIndex === RANDOM_BUILD) {
      startingBuildIndex = getRandomArrayIndex(BUILDS);
    }
  } else {
    startingBuildIndex = -1;
  }

  let difficulty = $("input[name=new-race-difficulty]:checked").val();
  if (typeof difficulty !== "string") {
    throw new TypeError(
      'The value from the "new-race-difficulty" element was not a string.',
    );
  }
  if (difficulty !== settings.get("newRaceDifficulty")) {
    settings.set("newRaceDifficulty", difficulty);
  }

  // Validate that they are not creating a race with the same title as an existing race.
  for (const race of g.raceList.values()) {
    if (race.name === title) {
      $("#new-race-title").tooltipster("open");
      return false;
    }
  }
  $("#new-race-title").tooltipster("close");

  // Truncate names longer than 100 characters (this is also enforced server-side).
  const maximumLength = 100;
  if (title.length > maximumLength) {
    title = title.slice(0, Math.max(0, maximumLength));
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

  // Handle multiplayer specific settings.
  if (!solo) {
    ranked = true;
  }

  // Handle ranked solo specific settings.
  if (ranked && solo) {
    format = "seeded";
    startingBuildIndex = -1;
    difficulty = "normal";
  }

  // Close the tooltip (and all error tooltips, if present).
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
    startingBuildIndex,
    difficulty,
  };
  g.currentScreen = Screen.WAITING_FOR_SERVER;
  g.conn.send("raceCreate", {
    name: title,
    password,
    ruleset: rulesetObject,
  });

  // Return false or else the form will submit and reload the page.
  return false;
}

function newRaceSizeChange(_event: JQuery.ChangeEvent | null, fast = false) {
  // Change the displayed icon.
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
      // Unlike the fade in above, the fade out needs to complete before the tooltip is redrawn.
      $("#header-new-race").tooltipster("reposition"); // Redraw the tooltip
    });
    $("#new-race-password-row").fadeIn(fast ? 0 : FADE_TIME);
    $("#new-race-password-row-padding").fadeIn(fast ? 0 : FADE_TIME);

    // Multiplayer races must be unranked.
    $("#new-race-ranked-no").prop("checked", true);
    newRaceRankedChange(null, true);
  }
}

function newRaceRankedChange(_event: JQuery.ChangeEvent | null, fast = false) {
  // Change the displayed icon.
  const newRanked = $("input[name=new-race-ranked]:checked").val();
  setElementBackgroundImage(
    "new-race-ranked-icon",
    `img/ranked/${newRanked}.png`,
  );

  // Make the format border flash to signify that there are new options there. (This is no longer
  // needed since the format is hidden in solo ranked.)
  /*
  if (newRanked === "no" && !fast) {
    const oldColor = $("#new-race-format").css("border-color");
    $("#new-race-format").css("border-color", "green");
    setTimeout(() => {
      $("#new-race-format").css("border-color", oldColor);
    }, 350); // The CSS is set to 0.3 seconds, so we need some leeway
  }
  */

  // Change the subsequent options accordingly.
  const format = $("#new-race-format").val();
  if (newRanked === "no") {
    // Show the non-standard formats.
    /*
    $("#new-race-format-diversity").fadeIn(0);
    $("#new-race-format-custom").fadeIn(0);
    */

    // Show extra new race options.
    setTimeout(
      () => {
        $("#new-race-format-container").fadeIn(fast ? 0 : FADE_TIME);
        $("#new-race-character-container").fadeIn(fast ? 0 : FADE_TIME);
        $("#new-race-goal-container").fadeIn(fast ? 0 : FADE_TIME);
        if (format === "seeded") {
          $("#new-race-starting-build-container").fadeIn(fast ? 0 : FADE_TIME);
        }
        $("#new-race-difficulty-container").fadeIn(fast ? 0 : FADE_TIME);
        $("#header-new-race").tooltipster("reposition"); // Redraw the tooltip
      },
      fast ? 0 : FADE_TIME,
    );
  } else if (newRanked === "yes") {
    // Hide the non-standard formats.
    /*
    $("#new-race-format-diversity").fadeOut(0);
    $("#new-race-format-custom").fadeOut(0);
    */

    // Hide extra new race options.
    $("#new-race-format-container").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-character-container").fadeOut(fast ? 0 : FADE_TIME);
    // We hide the "starting-build" container before the "goal" container because it may already be
    // hidden and would mess up the callback.
    $("#new-race-starting-build-container").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-goal-container").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-difficulty-container").fadeOut(fast ? 0 : FADE_TIME, () => {
      $("#header-new-race").tooltipster("reposition"); // Redraw the tooltip
    });

    // There are only unseeded and seeded formats in ranked races.
    if (format !== "unseeded" && format !== "seeded") {
      $("#new-race-format").val("unseeded");
      newRaceFormatChange(null, fast);
    }

    // Set default values for the character, goal, and build drop-downs.
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
  if (password === undefined || password === "") {
    $("#new-race-password-no-password-icon").fadeIn(fast ? 0 : FADE_TIME);
    $("#new-race-password-has-password-icon").fadeOut(fast ? 0 : FADE_TIME);
  } else {
    $("#new-race-password-no-password-icon").fadeOut(fast ? 0 : FADE_TIME);
    $("#new-race-password-has-password-icon").fadeIn(fast ? 0 : FADE_TIME);
  }
}

function newRaceFormatChange(_event: JQuery.ChangeEvent | null, fast = false) {
  // Change the displayed icon.
  const newFormat = $("#new-race-format").val();
  setElementBackgroundImage(
    "new-race-format-icon",
    `img/formats/${newFormat}.png`,
  );

  // Show or hide the starting build row.
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
  // Change the displayed icon.
  const newCharacter = $("#new-race-character").val();
  setElementBackgroundImage(
    "new-race-character-icon",
    `${IMG_URL_PREFIX}/characters/${newCharacter}.png`,
  );
}

function newRaceGoalChange(_event: JQuery.ChangeEvent | null) {
  // Change the displayed icon.
  const newGoal = $("#new-race-goal").val();
  setElementBackgroundImage(
    "new-race-goal-icon",
    `${IMG_URL_PREFIX}/goals/${newGoal}.png`,
  );
}

function newRaceStartingBuildChange(_event: JQuery.ChangeEvent | null) {
  // Change the displayed icon.
  const newBuildString = $("#new-race-starting-build").val();
  if (typeof newBuildString !== "string") {
    throw new TypeError(
      'The value of the "new-race-starting-build" element was not a string.',
    );
  }

  const newBuild = parseIntSafe(newBuildString);
  if (newBuild === undefined) {
    throw new TypeError(
      `Failed to convert the build of "${newBuildString}" to a number.`,
    );
  }

  if (newBuild === RANDOM_BUILD) {
    setElementBackgroundImage(
      "new-race-starting-build-icon",
      `${IMG_URL_PREFIX}/builds/random.png`,
    );
  } else {
    setElementBuildIcon("new-race-starting-build-icon", newBuild);
  }
}

function newRaceDifficultyChange(_event: JQuery.ChangeEvent | null) {
  // Change the displayed icon.
  const newDifficulty = $("input[name=new-race-difficulty]:checked").val();
  if (newDifficulty === "normal") {
    $("#new-race-difficulty-icon-i").css("color", "green");
  } else {
    $("#new-race-difficulty-icon-i").css("color", "red");
  }
}

/** This is the "functionBefore" function for Tooltipster. */
export function tooltipFunctionBefore(): boolean {
  if (g.currentScreen !== Screen.LOBBY) {
    return false;
  }

  $("#gui").fadeTo(FADE_TIME, 0.1);
  return true;
}

/** This is the "functionReady" function for Tooltipster. */
export function tooltipFunctionReady(): void {
  // Load the default settings from the settings.json file and hide or show some rows based on the
  // race type and format. (The first argument is "event", the second argument is "fast".)
  const newRaceTitle = settings.get("newRaceTitle") as string;
  if (newRaceTitle === "") {
    // Randomize the race title.
    $("#new-race-title-randomize").click();
  } else {
    $("#new-race-title").val(newRaceTitle);
    g.lastRaceTitle = newRaceTitle;
  }

  const newRacePassword = settings.get("newRacePassword");
  if (typeof newRacePassword === "string") {
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
  // (The change functions have to be interspersed here, otherwise the format change would overwrite
  // the character change.)

  // Focus the race title box. (We have to wait 1 millisecond because the above code that changes
  // rows will wrest focus away.)
  setTimeout(() => {
    $("#new-race-title").focus();
  }, 1);

  // Tooltips within tooltips seem to be buggy and can sometimes be uninitialized. So, check for
  // this every time the tooltip is opened and reinitialize them if necessary.
  if (!$("#new-race-title").hasClass("tooltipstered")) {
    $("#new-race-title").tooltipster({
      theme: "tooltipster-shadow",
      delay: 0,
      trigger: "custom",
    });
  }
}
