import klawSync from "klaw-sync";
import fetch from "node-fetch";
import path from "path";
import * as file from "../../common/file";

// This is the name of the folder for the Racing+ Lua mod after it is downloaded through Steam
const STEAM_WORKSHOP_MOD_NAME = "racing+_857628390";
const DEV_MOD_NAME = "racing-plus";
const SHA1_HASHES_URL =
  "https://raw.githubusercontent.com/Zamiell/racing-plus/main/sha1.json";

export function devExists(modsPath: string): boolean {
  const racingPlusModDevPath = path.join(modsPath, DEV_MOD_NAME);
  return file.exists(racingPlusModDevPath) && file.isDir(racingPlusModDevPath);
}

export function exists(modsPath: string): boolean {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  const racingPlusModPath = path.join(modsPath, STEAM_WORKSHOP_MOD_NAME);
  if (file.exists(racingPlusModPath) && file.isDir(racingPlusModPath)) {
    return true;
  }

  process.send(`Failed to find the Racing+ mod at: ${racingPlusModPath}`);
  return false;
}

export async function isValid(modsPath: string): Promise<boolean> {
  const racingPlusModPath = path.join(modsPath, STEAM_WORKSHOP_MOD_NAME);
  const checksums = await getModChecksums();

  if (checkCorruptOrMissingFiles(racingPlusModPath, checksums)) {
    return false;
  }

  if (checkExtraneousFiles(racingPlusModPath, checksums)) {
    return false;
  }

  return true;
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

  let modIsCorrupt = false;

  // Each key of the JSON is the relative path to the file
  for (const [relativePath, backupFileHash] of Object.entries(checksums)) {
    const filePath = path.join(modPath, relativePath);

    if (file.exists(filePath)) {
      // Make an exception for the "sha1.json" file
      // (this will not have a valid checksum)
      if (path.basename(filePath) === "sha1.json") {
        continue;
      }

      const fileHash = file.getHash(filePath);
      if (fileHash !== backupFileHash) {
        process.send(`File is corrupt: ${filePath}`);
        process.send(
          `The hash of "${fileHash}" does not match the hash of "${backupFileHash}" from the "sha1.json" file.`,
        );
        modIsCorrupt = true;
      }
    } else {
      process.send(`File is missing: ${filePath}`);
      modIsCorrupt = true;
    }
  }

  return modIsCorrupt;
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

  let hasExtraneousFiles = false;

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
      hasExtraneousFiles = true;
      file.deleteFile(filePath);
    }
  }

  return hasExtraneousFiles;
}
