// We have to handle the case of the user having Isaac installed to a separate drive
// This can be determined by parsing the following file:
// C:\Program Files (x86)\Steam\config\config.vdf
// If "BaseInstallFolder_1" does not exist, then they have Isaac installed in the standard location

import path from "path";
import * as vdfParser from "vdf-parser";
import * as file from "../../common/file";
import ConfigVDF from "../types/ConfigVDF";

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

  const baseInstallFolder =
    configVDF.InstallConfigStore.Software.Valve.Steam.BaseInstallFolder_1;
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
