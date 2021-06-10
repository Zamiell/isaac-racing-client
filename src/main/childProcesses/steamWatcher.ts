// Child process that checks to see if the user logs out of Steam

import Registry from "winreg";
import { handleErrors, processExit } from "./subroutines";

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
  if (process.send === undefined) {
    return;
  }

  if (err) {
    process.send(
      `error: Failed to read the Windows registry when trying to figure out what the active Steam user is: ${err}`,
      processExit,
    );
    return;
  }

  // The active user is stored in the registry as a hexadecimal value,
  // so we have to convert it to base 10
  const registrySteamID = parseInt(item.value, 16);

  if (steamID !== registrySteamID) {
    process.send("error: It appears that you have logged out of Steam.");
  }
}
