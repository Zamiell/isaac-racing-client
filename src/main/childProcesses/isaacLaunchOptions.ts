import path from "path";
import * as vdfParser from "vdf-parser";
import * as file from "../../common/file";
import { REBIRTH_STEAM_ID } from "../constants";
import LocalConfigVDF, {
  AppConfigVDF,
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

  // It is possible for no launch options to be set
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
    localConfigString = vdfParser.stringify(localConfigVDF);
  } catch (err) {
    throw new Error(`Failed to stringify the Steam local config: ${err}`);
  }

  const localConfigPath = getLocalConfigPath(steamPath, steamActiveUserID);
  file.write(localConfigPath, localConfigString);
}

function getLocalConfigVDF(steamPath: string, steamActiveUserID: number) {
  const localConfigPath = getLocalConfigPath(steamPath, steamActiveUserID);
  if (!file.exists(localConfigPath)) {
    throw new Error(
      `Failed to find the "localconfig.vdf" file at: ${localConfigPath}`,
    );
  }

  const localConfigString = file.read(localConfigPath);

  let localConfigVDF: LocalConfigVDF;
  try {
    localConfigVDF = vdfParser.parse(localConfigString) as LocalConfigVDF;
  } catch (err) {
    throw new Error(`Failed to parse the "${localConfigPath}" file: ${err}`);
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
  if (userLocalConfigStore === undefined) {
    throw new Error(
      'The "localconfig.vdf" file did not have a "UserLocalConfigStore" tag.',
    );
  }

  const software = userLocalConfigStore.Software;
  if (software === undefined) {
    throw new Error(
      'Failed to find the "Software" tag in the "localconfig.vdf" file.',
    );
  }

  // On some platforms, "valve" is lowercase for some reason
  let valve: ValveLocalConfigVDF | undefined;
  if (software.Valve !== undefined) {
    valve = software.Valve;
  } else if (software.valve !== undefined) {
    valve = software.valve;
  }

  if (valve === undefined) {
    throw new Error(
      'Failed to find the "Valve" or "valve" tag in the "localconfig.vdf" file.',
    );
  }

  // On some platforms, "steam" is lowercase for some reason
  let steam: SteamLocalConfigVDF | undefined;
  if (valve.Steam !== undefined) {
    steam = valve.Steam;
  } else if (valve.steam !== undefined) {
    steam = valve.steam;
  }

  if (steam === undefined) {
    throw new Error(
      'Failed to find the "Steam" or "steam" tag in the "localconfig.vdf" file.',
    );
  }

  // On some platforms, "apps" is lowercase for some reason
  let apps: Record<string, AppConfigVDF> | undefined;
  if (steam.Apps !== undefined) {
    apps = steam.Apps;
  } else if (steam.apps !== undefined) {
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
