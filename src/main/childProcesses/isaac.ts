/* eslint-disable import/no-unused-modules */

// When the Racing+ client starts, we need to perform several checks:

// 1) Racing+ mod integrity
// After the mod is updated on the Steam Workshop,
// the game can fail to download it and/or integrate it, which seems to happen pretty commonly
// We computed the SHA1 hash of every file during the build process and wrote it to "sha1.json";
// compare all files in the mod directory to this JSON

// 2) "--luadebug" launch options for the game in Steam
// This is required for the Racing+ mod to talk to the Racing+ client
// However, it cannot be set until Steam is completely closed
// (because it caches the value in memory)

// 3) Sandbox Lua files in place
// Since we are turning on --luadebug,
// we provide a sandbox so that only certain functions can be called

import { execSync } from "child_process";
import path from "path";
import ps from "ps-node";
import Registry, { RegistryItem } from "winreg";
import * as file from "../../common/file";
import { parseIntSafe } from "../../common/util";
import getGamePath from "./isaacGetGamePath";
import isSandboxValid from "./isaacIsSandboxValid";
import {
  hasLaunchOption,
  LAUNCH_OPTION,
  setLaunchOption,
} from "./isaacLaunchOptions";
import * as racingPlusMod from "./isaacRacingPlusMod";
import { childError, handleErrors, processExit } from "./subroutines";

const ISAAC_PROCESS_NAME = "isaac-ng.exe";
const STEAM_PROCESS_NAME = "steam.exe";

let steamPath: string;
let steamActiveUserID: number;
let gamePath: string;
let shouldRestartIsaac = false;
let shouldRestartSteam = false;

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
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send("Checking for the Steam path...");

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

  if (err !== undefined && err !== null) {
    throw new Error(
      `Failed to read the Windows registry when trying to figure out what the Steam path is: ${err}`,
    );
  }

  steamPath = item.value;
  process.send(`Steam path found: ${steamPath}`);

  getSteamActiveUser();
}

function getSteamActiveUser() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send("Checking for the Steam active user...");

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

  if (err !== undefined && err !== null) {
    throw new Error(
      `Failed to read the Windows registry when trying to figure out what the active Steam user is: ${err}`,
    );
  }

  // The active user is stored in the registry as a hexadecimal value,
  // so we have to convert it to base 10
  steamActiveUserID = parseInt(item.value, 16);

  if (Number.isNaN(steamActiveUserID)) {
    throw new Error(
      `Failed to parse the Steam ID from the Windows registry: ${item.value}`,
    );
  }

  process.send(`Steam active user found: ${steamActiveUserID}`);

  checkModExists();
}

function checkModExists() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  gamePath = getGamePath(steamPath);
  process.send(`Detected the game directory at: ${gamePath}`);

  const modsPath = path.join(gamePath, "mods");
  if (!file.exists(modsPath) || !file.isDir(modsPath)) {
    throw new Error(`Failed to find the "mods" directory at: ${modsPath}`);
  }

  const devModExists = racingPlusMod.devExists(modsPath);
  if (devModExists) {
    // Skip checking mod integrity if we are in development
    process.send(
      "File system validation passed. (Skipped mod checking since we are in development.)",
    );
    process.send("isaacChecksComplete", processExit);
    return;
  }

  const modExists = racingPlusMod.exists(modsPath);
  if (!modExists) {
    // The mod not being found is an ordinary error;
    // the end-user probably has not yet subscribed to the mod on the Steam Workshop
    process.send("modNotFound", processExit);
    return;
  }

  checkModIntegrity(modsPath).catch(childError);
}

async function checkModIntegrity(modsPath: string) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send("Checking to see if the Racing+ mod is corrupted...");

  // Mod checks are performed in a separate file
  const modValid = await racingPlusMod.isValid(modsPath);
  if (modValid) {
    process.send("The mod perfectly matched!");
  } else {
    process.send("modCorrupt", processExit);
    return;
  }

  checkLaunchOption();
}

function checkLaunchOption() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send(`Checking for the "${LAUNCH_OPTION}" launch option...`);

  // Launch option checking is performed in a separate file
  const launchOptionSet = hasLaunchOption(steamPath, steamActiveUserID);
  if (launchOptionSet) {
    process.send("The launch option is already set.");
  } else {
    process.send("The launch option is not set.");
    shouldRestartIsaac = true;
    shouldRestartSteam = true;
  }

  checkLuaSandbox();
}

function checkLuaSandbox() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send("Checking to see if the Lua sandbox is in place...");

  // Sandbox checks are performed in a separate file
  const sandboxValid = isSandboxValid(gamePath);
  if (sandboxValid) {
    process.send("The sandbox is in place.");
  } else {
    process.send("The sandbox was corrupted or missing.");
    shouldRestartIsaac = true;
  }

  checkCloseIsaac();
}

function checkCloseIsaac() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  if (!shouldRestartIsaac) {
    process.send(
      "File system validation passed. (No changes needed to be made.)",
    );
    process.send("isaacChecksComplete", processExit);
    return;
  }

  const [isaacOpen, isaacPID] = isProcessRunning(ISAAC_PROCESS_NAME);
  if (isaacOpen) {
    closeIsaac(isaacPID);
  } else if (shouldRestartSteam) {
    checkCloseSteam();
  } else {
    // Don't automatically open Isaac for them, since that might be annoying
    process.send(
      "File system repair complete. (Isaac was not open.)",
      processExit,
    );
  }
}

function closeIsaac(pid: number) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send("Closing Isaac...");
  ps.kill(pid, postKillIsaac);
}

function postKillIsaac(err?: Error) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  if (err !== null) {
    throw new Error(`Failed to close Isaac: ${err}`);
  }

  process.send("Closed Isaac.");

  if (shouldRestartSteam) {
    checkCloseSteam();
    return;
  }

  // After a short delay, start Isaac again
  setTimeout(() => {
    startIsaac();
  }, 1000); // 1 second
}

function checkCloseSteam() {
  const [steamOpen, steamPID] = isProcessRunning(STEAM_PROCESS_NAME);
  if (steamOpen) {
    closeSteam(steamPID);
  } else {
    postKillSteam();
  }
}

function closeSteam(pid: number) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send("Closing Steam...");
  ps.kill(pid, postKillSteam);
}

function postKillSteam() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  setLaunchOption(steamPath, steamActiveUserID);
  process.send(`Set the launch option of "${LAUNCH_OPTION}".`);

  // We don't have to manually start Steam, because we can instead just launch Isaac,
  // which will in turn automatically start Steam for us
  startIsaac();
}

function startIsaac() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  // We have to start Isaac from the main process because we don't have access to "electron.shell"
  // from here
  process.send("startIsaac");
  process.send("isaacChecksComplete", processExit);
}

function isProcessRunning(processName: string): [boolean, number] {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  // The "tasklist" module has problems on different languages
  // The "ps-node" module is very slow
  // The "process-list" module will not compile for some reason
  // So, just manually run the "tasklist" command and parse the output without using any module
  const command = "tasklist";
  let output;
  try {
    output = execSync(command).toString().split("\r\n");
  } catch (err) {
    throw new Error(`Failed to execute the "${command}" command: ${err}`);
  }

  for (const line of output) {
    if (!line.startsWith(`${processName} `)) {
      continue;
    }

    const lineWithoutPrefix = line.slice(processName.length + 1);

    // eslint-disable-next-line
    const match = lineWithoutPrefix.match(/^\s*(\d+) /); // Cannot use the g flag here
    if (match === null) {
      throw new Error(
        `Failed to parse the output of the "${command}" command.`,
      );
    }

    const pidString = match[1];
    const pid = parseIntSafe(pidString);
    if (Number.isNaN(pid)) {
      throw new Error(
        `Failed to convert "${pid}" to a number from the "${command}" command.`,
      );
    }

    return [true, pid];
  }

  return [false, -1];
}
