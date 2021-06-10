// When the Racing+ client starts, we need to perform several checks:

// 1) "--luadebug" launch options for the game in Steam
// This is required for the Racing+ mod to talk to the Racing+ client

// 2) Sandbox Lua files in place
// Since we are turning on luadebug, we provide a sandbox so that only certain functions can be
// called

// 3) Racing+ mod integrity
// After the mod is updated on the Steam Workshop,
// the game can fail to download it and/or integrate it, which seems to happen pretty commonly
// We computed the SHA1 hash of every file during the build process and wrote it to "sha1.json";
// compare all files in the mod directory to this JSON

import { execSync } from "child_process";
import crypto from "crypto";
import * as electron from "electron";
import fs from "fs";
import klawSync from "klaw-sync";
import mkdirp from "mkdirp";
import path from "path";
import ps from "ps-node";
import * as vdfParser from "vdf-parser";
import Registry, { RegistryItem } from "winreg";
import * as file from "../../common/file";
import { parseIntSafe } from "../../common/util";
import { STEAM_WORKSHOP_MOD_NAME } from "../constants";
import { handleErrors, processExit } from "./subroutines";

const BACKUP_MOD_PATH = path.join("app.asar", "mod");

let steamPath: string;

handleErrors();
init();

function init() {
  process.on("message", onMessage);
  getSteamPath();
}

function onMessage(message: string) {
  // The child will stay alive even if the parent has closed,
  // so we depend on the parent telling us when to die
  if (message === "exit") {
    process.exit();
  }
}

function getSteamPath() {
  // Get the path of where the user has Steam installed to
  // We can find this in the Windows registry
  const steamKey = new Registry({
    hive: Registry.HKCU,
    key: "\\Software\\Valve\\Steam",
  });

  steamKey.get("SteamPath", postGetSteamPath);
}

function postGetSteamPath(err: Error, item: RegistryItem) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  if (err) {
    process.send(
      "error: Failed to read the Windows registry when trying to figure out what the Steam path is.",
      processExit,
    );
    return;
  }

  steamPath = item.value;
  process.send(`Steam path found: ${steamPath}`);

  getSteamActiveUser();
}

function getSteamActiveUser() {
  // Get the Steam ID of the active user
  // We can also find this in the Windows registry
  const steamKey = new Registry({
    hive: Registry.HKCU,
    key: "\\Software\\Valve\\Steam\\ActiveProcess",
  });
  steamKey.get("ActiveUser", postGetSteamActiveUser);
}

function postGetSteamActiveUser(err: Error, item: RegistryItem) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  if (err) {
    process.send(
      "error: Failed to read the Windows registry when trying to figure out what the active Steam user is.",
      processExit,
    );
    return;
  }

  // The active user is stored in the registry as a hexadecimal value,
  // so we have to convert it to base 10
  const steamActiveUserID = parseInt(item.value, 16);

  if (Number.isNaN(steamActiveUserID)) {
    process.send(
      `error: Failed to parse the Steam ID from the Windows registry: ${steamActiveUserID}`,
      processExit,
    );
    return;
  }

  checkLuaDebug(steamActiveUserID);
}

function checkLuaDebug(steamActiveUserID: number) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  const localConfigPath = path.join(
    steamPath,
    "userdata",
    steamActiveUserID.toString(),
    "250900",
    "config",
    "localconfig.vdf",
  );

  if (!fs.existsSync(localConfigPath)) {
    process.send(
      `error: Failed to find the "localconfig.vdf" file at: ${localConfigPath}`,
      processExit,
    );
  }

  let localConfigString: string;
  try {
    localConfigString = fs.readFileSync(localConfigPath, "utf8");
  } catch (err) {
    process.send(
      `error: Failed to read the "${localConfigPath}" file: ${err}`,
      processExit,
    );
    return;
  }

  interface LocalConfigVDF {
    UserLocalConfigStore: {
      Software: {
        Value: {
          Steam: {
            Apps: Record<string, AppConfigVDF>;
          };
        };
      };
    };
  }

  interface AppConfigVDF {
    LaunchOptions: string;
  }

  let localConfig: LocalConfigVDF;
  try {
    localConfig = vdfParser.parse(localConfigString) as LocalConfigVDF;
  } catch (err) {
    process.send(
      `error: Failed to parse the "${localConfigPath}" file: ${err}`,
      processExit,
    );
    return;
  }

  console.log(localConfig);
  console.log(localConfig.UserLocalConfigStore);

  checkModIntegrity();
}

function checkModIntegrity() {
  if (1 === 1) { // eslint-disable-line
    return;
  }

  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send("Checking to see if the Racing+ mod is corrupted.");

  const modPath = getModPath();
  const checksums = getModChecksums();

  const fileSystemValid =
    !checkCorruptOrMissingFiles(modPath, checksums) &&
    !checkExtraneousFiles(modPath, checksums);

  if (fileSystemValid) {
    process.send("File system validation passed.", processExit);
    return;
  }

  const [isaacOpen, isaacPID] = isIsaacOpen();
  if (isaacOpen) {
    closeIsaac(isaacPID);
  } else {
    // Don't automatically open Isaac for them, since that might be annoying
    process.send(
      "File system repair complete. (Isaac was not open.)",
      processExit,
    );
  }
}

function getModPath() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  const modPath = path.join(
    steamPath,
    "steamapps",
    "common",
    "The Binding of Isaac Rebirth",
    "mods",
    STEAM_WORKSHOP_MOD_NAME,
  );

  if (!file.exists(modPath)) {
    process.send(
      `error: Failed to find the Racing+ mod at: ${modPath}`,
      processExit,
    );
    return "";
  }

  return modPath;
}

function getModChecksums() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  const checksumsPath = path.join(BACKUP_MOD_PATH, "sha1.json");
  let checksumsString: string;
  try {
    checksumsString = fs.readFileSync(checksumsPath, "utf8");
  } catch (err) {
    process.send(
      `error: Failed to read the "${checksumsPath}" file: ${err}`,
      processExit,
    );
    return {};
  }

  let checksums: Record<string, string>;
  try {
    checksums = JSON.parse(checksumsString) as Record<string, string>;
  } catch (err) {
    process.send(
      `error: Failed to parse the "${checksumsPath}" file: ${err}`,
      processExit,
    );
    return {};
  }

  return checksums;
}

function checkCorruptOrMissingFiles(
  modPath: string,
  checksums: Record<string, string>,
) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  let allFilesValid = true;

  // Each key of the JSON is the relative path to the file
  for (const [relativePath, backupFileHash] of Object.entries(checksums)) {
    const filePath = path.join(modPath, relativePath);
    const backupFilePath = path.join(BACKUP_MOD_PATH, relativePath);

    let copyFile = false; // If this gets set to true, the file is missing or corrupt
    if (fs.existsSync(filePath)) {
      // Make an exception for the "sha1.json" file
      // (this will not have a valid checksum)
      if (path.basename(filePath) === "sha1.json") {
        continue;
      }

      if (getFileHash(filePath) !== backupFileHash) {
        process.send(`File is corrupt: ${filePath}`);
        copyFile = true;
      }
    } else {
      process.send(`File is missing: ${filePath}`);
      copyFile = true;
    }

    // Copy it
    if (copyFile) {
      allFilesValid = false;
      copyModFile(backupFilePath, filePath);
    }
  }

  return allFilesValid;
}

function getFileHash(filePath: string) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  try {
    const fileBuffer = fs.readFileSync(filePath);
    const sum = crypto.createHash("sha1");
    sum.update(fileBuffer);
    return sum.digest("hex");
  } catch (err) {
    process.send(
      `error: Failed to create a hash for the "${filePath}" file: ${err}`,
      processExit,
    );
    return "";
  }
}

function copyModFile(backupFilePath: string, filePath: string) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  try {
    // Make sure the directory is there
    const filePathDir = path.dirname(filePath);
    if (!fs.existsSync(filePathDir)) {
      mkdirp.sync(filePathDir);
    }
    fs.copyFileSync(backupFilePath, filePath);
  } catch (err) {
    process.send(
      `error: Failed to copy over the "${backupFilePath}" file (since the original was corrupt): ${err}`,
      processExit,
    );
  }
}

function checkExtraneousFiles(
  modPath: string,
  checksums: Record<string, string>,
) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  // To be thorough, also go through the mod directory and check to see if there are any extraneous
  // files that are not on the hash list
  let modFiles;
  try {
    modFiles = klawSync(modPath);
  } catch (err) {
    process.send(
      `error: Failed to enumerate the files in the "${modPath}" directory: ${err}`,
      processExit,
    );
    return false;
  }

  let areExtraneousFiles = false;

  for (const fileObject of modFiles) {
    // Get the relative path by chopping off the left side
    // We add one to remove the trailing slash
    const modFile = fileObject.path.substring(modPath.length + 1);

    if (!fileObject.stats.isFile()) {
      // Ignore directories; even extraneous directories shouldn't cause any harm
      continue;
    } else if (
      // This file may not match the one distributed through Steam
      path.basename(modFile) === "metadata.xml" ||
      path.basename(modFile) === "disable.it" // They might have the mod disabled
    ) {
      continue;
    }

    // Delete all files that are not found within the JSON hashes
    if (!Object.keys(checksums).includes(modFile)) {
      const filePath = path.join(modPath, modFile);
      process.send(`Extraneous file found: ${filePath}`);
      areExtraneousFiles = true;
      deleteModFile(filePath);
    }
  }

  return areExtraneousFiles;
}

function deleteModFile(filePath: string) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  try {
    fs.unlinkSync(filePath);
  } catch (err) {
    process.send(
      `error: Failed to delete the extraneous "${filePath}" file: ${err}`,
      processExit,
    );
  }
}

// The Racing+ mod was corrupt, so we need to restart Isaac to ensure that everything is loaded correctly
// First, find out if Isaac is open
function isIsaacOpen(): [boolean, number] {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send("Checking to see if Isaac is open.");

  const command = "tasklist";
  const processName = "isaac-ng.exe";

  // The "tasklist" module has problems on different languages
  // The "ps-node" module is very slow
  // The "process-list" module will not compile for some reason (missing "atlbase.h")
  // So, just manually run the "tasklist" command and parse the output without using any module
  let output;
  try {
    output = execSync(command).toString().split("\r\n");
  } catch (err) {
    process.send(
      `error: Failed to detect if Isaac is open when running the "${command}" command: ${err}`,
      processExit,
    );
    return [false, -1];
  }

  for (const line of output) {
    if (!line.startsWith(`${processName} `)) {
      continue;
    }

    const match = line.match(/^.+?(\d+)/g);
    if (!match) {
      process.send(
        `error: Failed to parse the output of the "${command}" command.`,
        processExit,
      );
      return [false, -1];
    }

    const isaacPIDString = match[1];
    const isaacPID = parseIntSafe(isaacPIDString);
    if (Number.isNaN(isaacPID)) {
      process.send(
        `error: Failed to convert "${isaacPIDString}" to a number from the "${command}" command.`,
        processExit,
      );
      return [false, -1];
    }

    return [true, isaacPID];
  }

  return [false, -1];
}

function closeIsaac(pid: number) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send("We need to restart Isaac.");

  ps.kill(pid, postKillIsaac);
}

function postKillIsaac(err?: Error) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  // This expects the first argument to be in a string for some reason
  if (err) {
    process.send(`error: Failed to close Isaac: ${err}`, processExit);
    return;
  }

  // After a delay, start Isaac again
  setTimeout(() => {
    startIsaac();
  }, 1000); // 1 second
}

// Start Isaac
function startIsaac() {
  // The "correct" way to launch the game is through Steam
  // (rather than invoking the binary directly)
  electron.shell.openPath("steam://rungameid/250900").catch(startIsaacFailed);

  // The child will stay alive even if the parent has closed
  setTimeout(() => {
    process.exit();
  }, 30000); // Delay 30 seconds before exiting
  // We need to delay before exiting or else Isaac won't actually open
}

function startIsaacFailed(err: Error) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send(`error: Failed to start Isaac: ${err}`, processExit);
}
