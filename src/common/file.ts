import fs from "fs";

export function exists(filePath: string): boolean {
  let pathExists: boolean;
  try {
    pathExists = fs.existsSync(filePath);
  } catch (err) {
    throw new Error(`Failed to check to see if "${filePath}" exists: ${err}`);
  }

  return pathExists;
}

export function getDirList(dirPath: string): string[] {
  let fileList: string[];
  try {
    fileList = fs.readdirSync(dirPath);
  } catch (err) {
    throw new Error(
      `Failed to get the files in the "${dirPath}" directory: ${err}`,
    );
  }

  return fileList;
}

function getFileStats(filePath: string): fs.Stats {
  let fileStats: fs.Stats;
  try {
    fileStats = fs.lstatSync(filePath);
  } catch (err) {
    throw new Error(`Failed to get the file stats for "${filePath}": ${err}`);
  }

  return fileStats;
}

export function isDir(filePath: string): boolean {
  const fileStats = getFileStats(filePath);
  return fileStats.isDirectory();
}

export function isFile(filePath: string): boolean {
  const fileStats = getFileStats(filePath);
  return fileStats.isFile();
}

export function read(filePath: string): string {
  let fileContents: string;
  try {
    fileContents = fs.readFileSync(filePath, "utf8");
  } catch (err) {
    throw new Error(`Failed to read the "${filePath}" file: ${err}`);
  }

  return fileContents;
}

export function write(filePath: string, data: string): void {
  try {
    fs.writeFileSync(filePath, data);
  } catch (err) {
    throw new Error(`Failed to write to the "${filePath}" file: ${err}`);
  }
}
