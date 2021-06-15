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
  const localConfig = getSteamLocalConfig(steamPath, steamActiveUserID);
  const launchOptions =
    localConfig.UserLocalConfigStore.Software.Valve.Steam.Apps[
      REBIRTH_STEAM_ID.toString()
    ].LaunchOptions;
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

  let localConfig: LocalConfigVDF;
  try {
    localConfig = vdfParser.parse(localConfigString) as LocalConfigVDF;
  } catch (err) {
    throw new Error(`Failed to parse the "${localConfigPath}" file: ${err}`);
  }

  return localConfig;
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
