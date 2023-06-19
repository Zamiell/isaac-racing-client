import * as electron from "electron";
import { BUILDS } from "isaac-racing-common";
import { parseIntSafe } from "isaacscript-common-ts";
import { getHoursAndMinutes, isChatForThisRace } from "./chat";
import g from "./globals";
import { getMyStatus, getNumLeft, getNumReady } from "./race";
import { ModSocket } from "./types/ModSocket";
import { RaceFormat } from "./types/RaceFormat";
import { RacerStatus } from "./types/RacerStatus";
import { RaceStatus } from "./types/RaceStatus";
import { SocketCommandIn } from "./types/SocketCommand";
import { amSecondTestAccount } from "./utils";

export function send(command: SocketCommandIn, data = ""): void {
  if (amSecondTestAccount()) {
    return;
  }

  const packedMsg = packSocketMsg(command, data);
  electron.ipcRenderer.send("asynchronous-message", "socket", packedMsg);
}

function packSocketMsg(command: string, data: string) {
  if (data === "") {
    return `${command}\n`;
  }

  const separator = " ";
  return `${command}${separator}${data}\n`; // Socket messages must be terminated by a newline
}

// This sends an up-to-date myStatus, numReady, numEntrants, placeMid, and place to the mod.
export function sendExtraValues(): void {
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  const myStatus = getMyStatus(race);
  if (myStatus !== null) {
    g.modSocket.myStatus = myStatus;
    send("set", `myStatus ${g.modSocket.myStatus}`);
  }

  if (race.status === RaceStatus.OPEN || race.status === RaceStatus.STARTING) {
    g.modSocket.numReady = getNumReady(race);
    send("set", `numReady ${g.modSocket.numReady}`);
  } else if (race.status === RaceStatus.IN_PROGRESS) {
    const numLeft = getNumLeft(race);

    // Find our value of "placeMid".
    let amRacing = false;
    for (const racer of race.racerList) {
      if (racer.name === g.myUsername) {
        g.modSocket.placeMid = racer.placeMid;
        g.modSocket.place = racer.place;

        if (racer.status === RacerStatus.RACING) {
          amRacing = true;
        }
      }
    }

    if (numLeft === 1 && amRacing && race.racerList.length > 2) {
      g.modSocket.placeMid = 9999; // This will show "last person left".
    }

    if (race.ruleset.solo) {
      // We don't want to send our final place for solo races to avoid showing the "1st place"
      // graphic at the end of the race.
      g.modSocket.place = 0;
    }

    send("set", `placeMid ${g.modSocket.placeMid}`);
    send("set", `place ${g.modSocket.place}`);
  }

  g.modSocket.numEntrants = race.racerList.length;
  send("set", `numEntrants ${g.modSocket.numEntrants}`);
}

export function sendChat(room: string, username: string, msg: string): void {
  if (room === "lobby" || room === "PM-to" || room === "PM-from") {
    return;
  }

  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  if (!isChatForThisRace(room)) {
    return;
  }

  const [hoursString, minutesString] = getHoursAndMinutes(null);
  const time = `${hoursString}:${minutesString}`;
  const chatMessage = {
    time,
    username,
    msg,
  };
  send("chat", JSON.stringify(chatMessage));
}

export function sendAll(): void {
  // Start to compile the list of starting items.
  const startingItems: number[] = [];

  // Diversity races store the starting items in the seed.
  if (g.modSocket.format === RaceFormat.DIVERSITY) {
    const items = g.modSocket.seed.split(",");
    for (const itemString of items) {
      const itemID = parseIntSafe(itemString);
      if (!Number.isNaN(itemID)) {
        startingItems.push(itemID);
      }
    }
  }

  // Seeded races store the starting items as the "startingBuildIndex".
  if (g.modSocket.startingBuildIndex !== -1) {
    const build = BUILDS[g.modSocket.startingBuildIndex];
    if (build === undefined) {
      throw new Error(
        `Failed to get the build for starting build index of: ${g.modSocket.startingBuildIndex}`,
      );
    }

    for (const collectible of build.collectibles) {
      startingItems.push(collectible.id);
    }
  }

  // This is necessary because the 5 diversity items are communicated through the seed.
  const seed =
    g.modSocket.format === RaceFormat.DIVERSITY ? "-" : g.modSocket.seed;

  send("set", `userID ${g.myUserID}`);
  send("set", `username ${g.myUsername}`);
  send("set", `raceID ${g.modSocket.raceID}`);
  send("set", `status ${g.modSocket.status}`);
  send("set", `myStatus ${g.modSocket.myStatus}`);
  send("set", `ranked ${g.modSocket.ranked}`);
  send("set", `solo ${g.modSocket.solo}`);
  send("set", `format ${g.modSocket.format}`);
  send("set", `difficulty ${g.modSocket.difficulty}`);
  send("set", `character ${g.modSocket.character}`);
  send("set", `goal ${g.modSocket.goal}`);
  send("set", `seed ${seed}`);
  // "startingBuildIndex" is converted to "startingItems".
  send("set", `startingItems ${JSON.stringify(startingItems)}`);
  send("set", `countdown ${g.modSocket.countdown}`);
  send("set", `placeMid ${g.modSocket.placeMid}`);
  send("set", `place ${g.modSocket.place}`);
  send("set", `numReady ${g.modSocket.numReady}`);
  send("set", `numEntrants ${g.modSocket.numEntrants}`);
  send(
    "set",
    `millisecondsBehindLeader ${g.modSocket.millisecondsBehindLeader}`,
  );
}

export function sendMillisecondsBehindLeader(): void {
  send(
    "set",
    `millisecondsBehindLeader ${g.modSocket.millisecondsBehindLeader}`,
  );
}

export function sendMessage(): void {
  send("set", `message ${g.modSocket.message}`);
}

export function reset(): void {
  g.modSocket = new ModSocket();
  send("reset");
}
