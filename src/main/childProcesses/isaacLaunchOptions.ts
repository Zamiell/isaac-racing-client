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
  const apps = localConfigVDF.UserLocalConfigStore.Software.Valve.Steam.Apps;
  const rebirthEntry = apps[REBIRTH_STEAM_ID.toString()];
  if (rebirthEntry === undefined) {
    // ---
    if (process.send === undefined) {
      throw new Error("process.send() does not exist.");
    }
    const localConfigPath = getSteamLocalConfigPath(
      steamPath,
      steamActiveUserID,
    );
    const localConfigString = file.read(localConfigPath);
    process.send(`DEBUG: ${localConfigString}`);
    // ---

    throw new Error(
      `Failed to find the entry for "${REBIRTH_STEAM_ID}" in the "localconfig.vdf" file.`,
    );
  }
  const launchOptions = rebirthEntry.LaunchOptions;
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
