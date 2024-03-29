// Settings related to the program are stored in the following file:
// C:\Users\[Username]\AppData\Roaming\Racing+\config.json

// For the "Settings" part of the UI, see the "ui/settings-tooltip.ts" file. We use the
// "electron-store" library instead of using localstorage (cookies) because the main Electron
// process is not able to natively access cookies.

import Store from "electron-store";

export const settings = new Store();

export function initDefaults(): void {
  if (settings.get("window") === undefined) {
    settings.set("window", {});
  }

  if (settings.get("isaacPath") === undefined) {
    settings.set(
      "isaacPath",
      "C:\\Program Files (x86)\\Steam\\steamapps\\common\\The Binding of Isaac Rebirth\\isaac-ng.exe",
    );
  }

  if (settings.get("language") === undefined) {
    settings.set("language", "en"); // English
  }

  if (settings.get("volume") === undefined) {
    settings.set("volume", 0.5); // 50%
  }

  if (settings.get("newRaceTitle") === undefined) {
    settings.set("newRaceTitle", ""); // An empty string means to use the random name generator
  }

  if (settings.get("newRaceSize") === undefined) {
    settings.set("newRaceSize", "solo");
  }

  if (settings.get("newRaceRanked") === undefined) {
    settings.set("newRaceRanked", "no");
  }

  if (settings.get("newRaceFormat") === undefined) {
    settings.set("newRaceFormat", "unseeded");
  }

  if (settings.get("newRaceCharacter") === undefined) {
    settings.set("newRaceCharacter", "Judas");
  }

  if (settings.get("newRaceGoal") === undefined) {
    settings.set("newRaceGoal", "Blue Baby");
  }

  if (settings.get("newRaceBuild") === undefined) {
    settings.set("newRaceBuild", "1"); // 20/20
  }

  if (settings.get("newRaceDifficulty") === undefined) {
    settings.set("newRaceDifficulty", "normal");
  }
}
