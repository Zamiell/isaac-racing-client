// We have to handle the case of the user having Isaac installed to a separate drive
// This can be determined by parsing the following file:
// C:\Program Files (x86)\Steam\config\config.vdf
// If "BaseInstallFolder_1" does not exist, then they have Isaac installed in the standard location

import path from "path";
import * as vdfParser from "vdf-parser";
import * as file from "../../common/file";
import ConfigVDF, { SteamConfigVDF, ValveConfigVDF } from "../types/ConfigVDF";

export default function getRebirthPath(steamPath: string): string {
  const configVDFPath = path.join(steamPath, "config", "config.vdf");
  if (!file.exists(configVDFPath)) {
    throw new Error(
      `Failed to find the "config.vdf" file at: ${configVDFPath}`,
    );
  }

  const configVDFString = file.read(configVDFPath);

  let configVDF: ConfigVDF;
  try {
    configVDF = vdfParser.parse(configVDFString) as ConfigVDF;
  } catch (err) {
    throw new Error(`Failed to parse the "${configVDFPath}" file: ${err}`);
  }

  const installConfigStore = configVDF.InstallConfigStore;
  if (installConfigStore === undefined) {
    throw new Error(
      'Failed to find the "InstallConfigStore" tag in the "config.vdf" file.',
    );
  }

  const software = installConfigStore.Software;
  if (software === undefined) {
    throw new Error(
      'Failed to find the "Software" tag in the "config.vdf" file.',
    );
  }

  // On some platforms, "valve" is lowercase for some reason
  let valve: ValveConfigVDF | undefined;
  if (software.Valve !== undefined) {
    valve = software.Valve;
  } else if (software.valve !== undefined) {
    valve = software.valve;
  }

  if (valve === undefined) {
    throw new Error(
      'Failed to find the "Valve" or "valve" tag in the "config.vdf" file.',
    );
  }

  // On some platforms, "steam" is lowercase for some reason
  let steam: SteamConfigVDF | undefined;
  if (valve.Steam !== undefined) {
    steam = valve.Steam;
  } else if (valve.steam !== undefined) {
    steam = valve.steam;
  }

  if (steam === undefined) {
    throw new Error(
      'Failed to find the "Steam" or "steam" tag in the "config.vdf" file.',
    );
  }

  const baseInstallFolder = steam.BaseInstallFolder_1;
  // (the baseInstallFolder will not be present on systems that install Steam games into the
  // standard directory)

  const basePath =
    baseInstallFolder === undefined ? steamPath : baseInstallFolder;

  const gamePath = path.join(
    basePath,
    "steamapps",
    "common",
    "The Binding of Isaac Rebirth",
  );
  if (!file.exists(gamePath) || !file.isDir(gamePath)) {
    throw new Error(`Failed to find the game directory at: ${gamePath}`);
  }

  return gamePath;
}
