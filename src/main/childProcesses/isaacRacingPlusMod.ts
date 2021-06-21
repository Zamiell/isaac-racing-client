import klawSync from "klaw-sync";
import mkdirp from "mkdirp";
import fetch from "node-fetch";
import path from "path";
import * as file from "../../common/file";
import { getRebirthPath } from "./subroutines";

const BACKUP_MOD_PATH = path.join("app.asar", "mod");
// This is the name of the folder for the Racing+ Lua mod after it is downloaded through Steam
const STEAM_WORKSHOP_MOD_NAME = "racing+_857628390";
const SHA1_HASHES_URL =
  "https://raw.githubusercontent.com/Zamiell/racing-plus/main/sha1.json";

export function exists(steamPath: string): boolean {
  const modPath = getModPath(steamPath);
  return file.exists(modPath) && file.isDir(modPath);
}

export async function isValid(steamPath: string): Promise<boolean> {
  const modPath = getModPath(steamPath);
  const checksums = await getModChecksums();

  const modWasCorrupt = checkCorruptOrMissingFiles(modPath, checksums);
  const modHadExtraneousFiles = checkExtraneousFiles(modPath, checksums);

  return !modWasCorrupt && !modHadExtraneousFiles;
}

function getModPath(steamPath: string) {
  const rebirthPath = getRebirthPath(steamPath);
  return path.join(rebirthPath, "mods", STEAM_WORKSHOP_MOD_NAME);
}

async function getModChecksums() {
  const response = await fetch(SHA1_HASHES_URL);
  const checksums = (await response.json()) as Record<string, string>;

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
    if (file.exists(filePath)) {
      // Make an exception for the "sha1.json" file
      // (this will not have a valid checksum)
      if (path.basename(filePath) === "sha1.json") {
        continue;
      }

      if (file.getHash(filePath) !== backupFileHash) {
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

function copyModFile(backupFilePath: string, filePath: string) {
  const filePathDir = path.dirname(filePath);
  if (!file.exists(filePathDir)) {
    // Make sure the directory is there
    mkdirp.sync(filePathDir);
  }

  file.copy(backupFilePath, filePath);
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
  let modFiles: readonly klawSync.Item[];
  try {
    modFiles = klawSync(modPath);
  } catch (err) {
    throw new Error(
      `Failed to enumerate the files in the "${modPath}" directory: ${err}`,
    );
  }

  let areExtraneousFiles = false;

  for (const klawSyncItem of modFiles) {
    // Get the relative path by chopping off the left side
    // We add one to remove the trailing slash
    const modFile = klawSyncItem.path.substring(modPath.length + 1);

    if (!klawSyncItem.stats.isFile()) {
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
      file.deleteFile(filePath);
    }
  }

  return areExtraneousFiles;
}
