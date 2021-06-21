import path from "path";
import * as file from "../../common/file";

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

export default function isSandboxValid(gamePath: string): boolean {
  const mainLuaValid = isMainLuaValid(gamePath);
  const sandboxLuaValid = isSandboxLuaValid(gamePath);

  return mainLuaValid && sandboxLuaValid;
}

function isMainLuaValid(gamePath: string) {
  const mainLuaSrcFilename = "main-combined.lua";
  const mainLuaSrcPath = path.join(SANDBOX_PATH, mainLuaSrcFilename);
  if (!file.exists(mainLuaSrcPath) || !file.isFile(mainLuaSrcPath)) {
    throw new Error(
      `Failed to find "${mainLuaSrcFilename}" at: ${mainLuaSrcPath}`,
    );
  }
  const mainLuaSrcHash = file.getHash(mainLuaSrcPath);

  const scriptsPath = getScriptsPath(gamePath);
  const mainLuaDstFilename = "main.lua";
  const mainLuaDstPath = path.join(scriptsPath, mainLuaDstFilename);
  if (!file.exists(mainLuaDstPath)) {
    // This file should always exist in the Binding of Isaac "scripts" directory
    throw new Error(
      `Failed to find your "${mainLuaDstFilename}" file at: ${mainLuaDstPath}`,
    );
  }

  const mainLuaDstHash = file.getHash(mainLuaDstPath);
  const mainLuaValid = mainLuaSrcHash === mainLuaDstHash;

  if (!mainLuaValid) {
    file.copy(mainLuaSrcPath, mainLuaDstPath);
  }

  return mainLuaValid;
}

function isSandboxLuaValid(gamePath: string) {
  const sandboxFilename = "sandbox.lua";
  const sandboxLuaSrcPath = path.join(SANDBOX_PATH, sandboxFilename);
  if (!file.exists(sandboxLuaSrcPath) || !file.isFile(sandboxLuaSrcPath)) {
    throw new Error(
      `Failed to find "${sandboxFilename}" at: ${sandboxLuaSrcPath}`,
    );
  }
  const sandboxLuaSrcHash = file.getHash(sandboxLuaSrcPath);

  const scriptsPath = getScriptsPath(gamePath);
  const sandboxLuaDstPath = path.join(scriptsPath, sandboxFilename);

  let sandboxLuaValid: boolean;
  if (file.exists(sandboxLuaDstPath) && file.isFile(sandboxLuaDstPath)) {
    const sandboxLuaDstHash = file.getHash(sandboxLuaDstPath);
    sandboxLuaValid = sandboxLuaSrcHash === sandboxLuaDstHash;
  } else {
    sandboxLuaValid = false;
  }

  if (!sandboxLuaValid) {
    file.copy(sandboxLuaSrcPath, sandboxLuaDstPath);
  }

  return sandboxLuaValid;
}

function getScriptsPath(gamePath: string) {
  return path.join(gamePath, "resources", "scripts");
}
