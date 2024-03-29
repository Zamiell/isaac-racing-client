import path from "node:path";
import * as simpleVDF from "simple-vdf";
import { fileExists, readFile, writeFile } from "../../common/file";
import { REBIRTH_STEAM_ID } from "../constants";
import type {
  AppConfigVDF,
  LocalConfigVDF,
  SteamLocalConfigVDF,
  ValveLocalConfigVDF,
} from "../types/LocalConfigVDF";

export const LAUNCH_OPTION = "--luadebug";

export function hasLaunchOption(
  steamPath: string,
  steamActiveUserID: number,
): boolean {
  const localConfigVDF = getLocalConfigVDF(steamPath, steamActiveUserID);
  const rebirthEntry = getRebirthLocalConfigVDFEntry(localConfigVDF);

  const launchOptions = rebirthEntry.LaunchOptions;

  // It is possible for no launch options to be set.
  if (launchOptions === undefined) {
    return false;
  }

  return launchOptions === LAUNCH_OPTION;
}

export function setLaunchOption(
  steamPath: string,
  steamActiveUserID: number,
): void {
  const localConfigVDF = getLocalConfigVDF(steamPath, steamActiveUserID);
  const rebirthEntry = getRebirthLocalConfigVDFEntry(localConfigVDF);
  rebirthEntry.LaunchOptions = LAUNCH_OPTION;

  let localConfigString: string;
  try {
    localConfigString = simpleVDF.stringify(localConfigVDF);
  } catch (error) {
    throw new Error(`Failed to stringify the Steam local config: ${error}`);
  }

  const localConfigPath = getLocalConfigPath(steamPath, steamActiveUserID);
  writeFile(localConfigPath, localConfigString);
}

function getLocalConfigVDF(steamPath: string, steamActiveUserID: number) {
  const localConfigPath = getLocalConfigPath(steamPath, steamActiveUserID);
  if (!fileExists(localConfigPath)) {
    throw new Error(
      `Failed to find the "localconfig.vdf" file at: ${localConfigPath}`,
    );
  }

  const localConfigString = readFile(localConfigPath);

  let localConfigVDF: LocalConfigVDF;
  try {
    localConfigVDF = simpleVDF.parse(localConfigString) as LocalConfigVDF;
  } catch (error) {
    throw new Error(`Failed to parse the "${localConfigPath}" file: ${error}`);
  }

  return localConfigVDF;
}

function getLocalConfigPath(steamPath: string, steamActiveUserID: number) {
  return path.join(
    steamPath,
    "userdata",
    steamActiveUserID.toString(),
    "config",
    "localconfig.vdf",
  );
}

function getRebirthLocalConfigVDFEntry(localConfigVDF: LocalConfigVDF) {
  const userLocalConfigStore = localConfigVDF.UserLocalConfigStore;
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  if (userLocalConfigStore === undefined) {
    throw new Error(
      'The "localconfig.vdf" file did not have a "UserLocalConfigStore" tag.',
    );
  }

  const software = userLocalConfigStore.Software;
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  if (software === undefined) {
    throw new Error(
      'Failed to find the "Software" tag in the "localconfig.vdf" file.',
    );
  }

  // On some platforms, "valve" is lowercase for some reason.
  let valve: ValveLocalConfigVDF | undefined;
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  if (software.Valve !== undefined) {
    valve = software.Valve;
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  } else if (software.valve !== undefined) {
    // eslint-disable-next-line @typescript-eslint/prefer-destructuring
    valve = software.valve;
  }

  if (valve === undefined) {
    throw new Error(
      'Failed to find the "Valve" or "valve" tag in the "localconfig.vdf" file.',
    );
  }

  // On some platforms, "steam" is lowercase for some reason.
  let steam: SteamLocalConfigVDF | undefined;
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  if (valve.Steam !== undefined) {
    steam = valve.Steam;
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  } else if (valve.steam !== undefined) {
    // eslint-disable-next-line @typescript-eslint/prefer-destructuring
    steam = valve.steam;
  }

  if (steam === undefined) {
    throw new Error(
      'Failed to find the "Steam" or "steam" tag in the "localconfig.vdf" file.',
    );
  }

  // On some platforms, "apps" is lowercase for some reason.
  let apps: Record<string, AppConfigVDF> | undefined;
  if (steam.Apps !== undefined) {
    apps = steam.Apps;
  } else if (steam.apps !== undefined) {
    // eslint-disable-next-line @typescript-eslint/prefer-destructuring
    apps = steam.apps;
  }

  if (apps === undefined) {
    throw new Error(
      'Failed to find the "Apps" or "apps" tag in the "localconfig.vdf" file.',
    );
  }

  const rebirthEntry = apps[REBIRTH_STEAM_ID.toString()];
  if (rebirthEntry === undefined) {
    throw new Error(
      `Failed to find the entry for "${REBIRTH_STEAM_ID}" in the "localconfig.vdf" file.`,
    );
  }

  return rebirthEntry;
}
