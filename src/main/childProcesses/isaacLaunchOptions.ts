import path from "path";
import * as vdfParser from "vdf-parser";
import * as file from "../../common/file";
import { REBIRTH_STEAM_ID } from "../constants";
import LocalConfigVDF from "../types/LocalConfigVDF";

export const LAUNCH_OPTION = "--luadebug";

export function hasLaunchOption(
  steamPath: string,
  steamActiveUserID: number,
): boolean {
  const localConfigVDF = getSteamLocalConfig(steamPath, steamActiveUserID);
  if (localConfigVDF === undefined) {
    throw new Error(
      'The parsed result of the "localconfig.vdf" file was undefined.',
    );
  }

  // ---
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }
  process.send(`DEBUG1: ${localConfigVDF}`);
  process.send(`DEBUG2: ${typeof localConfigVDF}`);
  // ---

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

  const valve = software.Valve;
  if (valve === undefined) {
    throw new Error(
      'Failed to find the "Valve" tag in the "localconfig.vdf" file.',
    );
  }

  const steam = valve.Steam;
  if (steam === undefined) {
    throw new Error(
      'Failed to find the "Steam" tag in the "localconfig.vdf" file.',
    );
  }

  const apps = steam.Apps;
  if (apps === undefined) {
    throw new Error(
      'Failed to find the "Apps" tag in the "localconfig.vdf" file.',
    );
  }

  const rebirthEntry = apps[REBIRTH_STEAM_ID.toString()];
  if (rebirthEntry === undefined) {
    throw new Error(
      `Failed to find the entry for "${REBIRTH_STEAM_ID}" in the "localconfig.vdf" file.`,
    );
  }

  const launchOptions = rebirthEntry.LaunchOptions;
  if (launchOptions === undefined) {
    throw new Error(
      'Failed to find the "LaunchOptions" tag in the "localconfig.vdf" file.',
    );
  }

  return launchOptions === LAUNCH_OPTION;
}

export function setLaunchOption(
  steamPath: string,
  steamActiveUserID: number,
): void {
  const localConfig = getSteamLocalConfig(steamPath, steamActiveUserID);

  localConfig.UserLocalConfigStore.Software.Valve.Steam.Apps[
    REBIRTH_STEAM_ID.toString()
  ].LaunchOptions = LAUNCH_OPTION;

  let localConfigString: string;
  try {
    localConfigString = vdfParser.stringify(localConfig);
  } catch (err) {
    throw new Error(`Failed to stringify the Steam local config: ${err}`);
  }

  const localConfigPath = getSteamLocalConfigPath(steamPath, steamActiveUserID);
  file.write(localConfigPath, localConfigString);
}

function getSteamLocalConfig(steamPath: string, steamActiveUserID: number) {
  const localConfigPath = getSteamLocalConfigPath(steamPath, steamActiveUserID);
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

function getSteamLocalConfigPath(steamPath: string, steamActiveUserID: number) {
  return path.join(
    steamPath,
    "userdata",
    steamActiveUserID.toString(),
    "config",
    "localconfig.vdf",
  );
}
