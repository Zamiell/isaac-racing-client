import crypto from "node:crypto";
import fs from "node:fs";

export function copyFile(filePathSrc: string, filePathDst: string): void {
  try {
    fs.copyFileSync(filePathSrc, filePathDst);
  } catch (error) {
    throw new Error(
      `Failed to copy "${filePathSrc}" to "${filePathDst}": ${error}`,
    );
  }
}

export function deleteFile(filePath: string): void {
  try {
    fs.unlinkSync(filePath);
  } catch (error) {
    throw new Error(`Failed to delete "${filePath}": ${error}`);
  }
}

export function fileExists(filePath: string): boolean {
  let pathExists: boolean;
  try {
    pathExists = fs.existsSync(filePath);
  } catch (error) {
    throw new Error(`Failed to check to see if "${filePath}" exists: ${error}`);
  }

  return pathExists;
}

export function getDirList(dirPath: string): string[] {
  let fileList: string[];
  try {
    fileList = fs.readdirSync(dirPath);
  } catch (error) {
    throw new Error(
      `Failed to get the files in the "${dirPath}" directory: ${error}`,
    );
  }

  return fileList;
}

function getFileStats(filePath: string): fs.Stats {
  let fileStats: fs.Stats;
  try {
    fileStats = fs.lstatSync(filePath);
  } catch (error) {
    throw new Error(`Failed to get the file stats for "${filePath}": ${error}`);
  }

  return fileStats;
}

export function getFileHash(filePath: string): string {
  let hash: string;
  try {
    const fileBuffer = fs.readFileSync(filePath);
    const hashSum = crypto.createHash("sha1");
    hashSum.update(fileBuffer);
    hash = hashSum.digest("hex");
  } catch (error) {
    throw new Error(
      `Failed to create a hash for the "${filePath}" file: ${error}`,
    );
  }

  return hash;
}

export function isDir(filePath: string): boolean {
  const fileStats = getFileStats(filePath);
  return fileStats.isDirectory();
}

export function isFile(filePath: string): boolean {
  const fileStats = getFileStats(filePath);
  return fileStats.isFile();
}

export function readFile(filePath: string): string {
  let fileContents: string;
  try {
    fileContents = fs.readFileSync(filePath, "utf8");
  } catch (error) {
    throw new Error(`Failed to read the "${filePath}" file: ${error}`);
  }

  return fileContents;
}

export function writeFile(filePath: string, data: string): void {
  try {
    fs.writeFileSync(filePath, data);
  } catch (error) {
    throw new Error(`Failed to write to the "${filePath}" file: ${error}`);
  }
}
