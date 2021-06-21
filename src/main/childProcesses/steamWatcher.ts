/* eslint-disable import/no-unused-modules */

// Child process that checks to see if the user logs out of Steam

import Registry from "winreg";
import { handleErrors } from "./subroutines";

const CHECK_STEAM_INTERVAL = 5000; // 5 seconds

handleErrors();
init();

function init() {
  process.on("message", onMessage);
}

function onMessage(message: number | string) {
  // The child will stay alive even if the parent has closed,
  // so we depend on the parent telling us when to die
  if (message === "exit") {
    process.exit();
  }

  // After we have spawned, the parent will communicate with us, telling us the ID of the Steam user
  // If the message is a number, we can assume that it is the steam ID
  if (typeof message === "number") {
    // This child process will not be spawned if the Steam ID is 0 or a negative number
    // Thus, we can be sure that at this point, the Steam ID is a real, valid ID
    const steamID = message;

    setInterval(() => {
      checkActiveUser(steamID);
    }, CHECK_STEAM_INTERVAL);
  }
}

function checkActiveUser(steamID: number) {
  const steamKey = new Registry({
    hive: Registry.HKCU,
    key: "\\Software\\Valve\\Steam\\ActiveProcess",
  });

  steamKey.get("ActiveUser", (err, item) => {
    postGetActiveUser(err, item, steamID);
  });
}

function postGetActiveUser(
  err: Error,
  item: Registry.RegistryItem,
  steamID: number,
) {
  if (err !== undefined && err !== null) {
    throw new Error(
      `Failed to read the Windows registry when trying to figure out what the active Steam user is: ${err}`,
    );
  }

  // The active user is stored in the registry as a hexadecimal value,
  // so we have to convert it to base 10
  const registrySteamID = parseInt(item.value, 16);

  if (steamID !== registrySteamID) {
    throw new Error("It appears that you have logged out of Steam.");
  }
}
