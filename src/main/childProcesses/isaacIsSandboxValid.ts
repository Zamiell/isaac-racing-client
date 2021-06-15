import path from "path";
import * as file from "../../common/file";
import { getRebirthPath } from "./subroutines";

const DATA_PATH = path.join(__dirname, "..", "..", "static", "data");

export default function isSandboxValid(steamPath: string): boolean {
  const mainLuaValid = isMainLuaValid(steamPath);
  const sandboxLuaValid = isSandboxLuaValid(steamPath);

  return mainLuaValid && sandboxLuaValid;
}

function isMainLuaValid(steamPath: string) {
  const mainLuaSrcPath = path.join(DATA_PATH, "main-combined.lua");
  const mainLuaSrcHash = file.getHash(mainLuaSrcPath);

  const scriptsPath = getScriptsPath(steamPath);
  const mainLuaDstPath = path.join(scriptsPath, "main.lua");

  let mainLuaValid: boolean;
  if (file.exists(mainLuaDstPath)) {
    const mainLuaDstHash = file.getHash(mainLuaDstPath);
    mainLuaValid = mainLuaSrcHash === mainLuaDstHash;
  } else {
    mainLuaValid = false;
  }

  if (!mainLuaValid) {
    file.copy(mainLuaSrcPath, mainLuaDstPath);
  }

  return mainLuaValid;
}

function isSandboxLuaValid(steamPath: string) {
  const sandboxFileName = "sandbox.lua";

  const sandboxLuaSrcPath = path.join(DATA_PATH, sandboxFileName);
  const sandboxLuaSrcHash = file.getHash(sandboxLuaSrcPath);

  const scriptsPath = getScriptsPath(steamPath);
  const sandboxLuaDstPath = path.join(scriptsPath, sandboxFileName);

  let sandboxLuaValid: boolean;
  if (file.exists(sandboxLuaDstPath)) {
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

function getScriptsPath(steamPath: string) {
  const rebirthPath = getRebirthPath(steamPath);
  return path.join(rebirthPath, "resources", "scripts");
}
