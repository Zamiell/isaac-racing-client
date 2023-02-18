import path from "node:path";
import { copyFile, fileExists, getFileHash, isFile } from "../../common/file";

const SANDBOX_PATH = path.join(
  __dirname,
  "..",
  "..",
  "..",
  "..",
  "app.asar.unpacked",
  "static",
  "data",
  "sandbox",
);

export function isSandboxValid(gamePath: string): boolean {
  const mainLuaValid = isMainLuaValid(gamePath);
  const sandboxLuaValid = isSandboxLuaValid(gamePath);

  return mainLuaValid && sandboxLuaValid;
}

function isMainLuaValid(gamePath: string) {
  const mainLuaSrcFilename = "main-combined.lua";
  const mainLuaSrcPath = path.join(SANDBOX_PATH, mainLuaSrcFilename);
  if (!fileExists(mainLuaSrcPath) || !isFile(mainLuaSrcPath)) {
    throw new Error(
      `Failed to find "${mainLuaSrcFilename}" at: ${mainLuaSrcPath}`,
    );
  }
  const mainLuaSrcHash = getFileHash(mainLuaSrcPath);

  const scriptsPath = getScriptsPath(gamePath);
  const mainLuaDstFilename = "main.lua";
  const mainLuaDstPath = path.join(scriptsPath, mainLuaDstFilename);
  if (!fileExists(mainLuaDstPath)) {
    // This file should always exist in the Binding of Isaac "scripts" directory.
    throw new Error(
      `Failed to find your "${mainLuaDstFilename}" file at: ${mainLuaDstPath}`,
    );
  }

  const mainLuaDstHash = getFileHash(mainLuaDstPath);
  const mainLuaValid = mainLuaSrcHash === mainLuaDstHash;

  if (!mainLuaValid) {
    copyFile(mainLuaSrcPath, mainLuaDstPath);
  }

  return mainLuaValid;
}

function isSandboxLuaValid(gamePath: string) {
  const sandboxFilename = "sandbox.lua";
  const sandboxLuaSrcPath = path.join(SANDBOX_PATH, sandboxFilename);
  if (!fileExists(sandboxLuaSrcPath) || !isFile(sandboxLuaSrcPath)) {
    throw new Error(
      `Failed to find "${sandboxFilename}" at: ${sandboxLuaSrcPath}`,
    );
  }
  const sandboxLuaSrcHash = getFileHash(sandboxLuaSrcPath);

  const scriptsPath = getScriptsPath(gamePath);
  const sandboxLuaDstPath = path.join(scriptsPath, sandboxFilename);

  let sandboxLuaValid: boolean;
  if (fileExists(sandboxLuaDstPath) && isFile(sandboxLuaDstPath)) {
    const sandboxLuaDstHash = getFileHash(sandboxLuaDstPath);
    sandboxLuaValid = sandboxLuaSrcHash === sandboxLuaDstHash;
  } else {
    sandboxLuaValid = false;
  }

  if (!sandboxLuaValid) {
    copyFile(sandboxLuaSrcPath, sandboxLuaDstPath);
  }

  return sandboxLuaValid;
}

function getScriptsPath(gamePath: string) {
  return path.join(gamePath, "resources", "scripts");
}
