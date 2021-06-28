import * as electron from "electron";
import BUILDS from "../../static/data/builds.json";
import { parseIntSafe } from "../common/util";
import g from "./globals";
import { amSecondTestAccount } from "./misc";
import ModSocket from "./types/ModSocket";
import Race from "./types/Race";
import { SocketCommandIn } from "./types/SocketCommand";

const JUDAS_SHADOW_ID = 311;
const DARK_JUDAS_ID = 12;

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

// This sends an up-to-date myStatus, numReady, numEntrants, placeMid, and place to the mod
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

  if (race.status === "open" || race.status === "starting") {
    g.modSocket.numReady = getNumReady(race);
    send("set", `numReady ${g.modSocket.numReady}`);
  } else if (race.status === "in progress") {
    const numLeft = getNumLeft(race);

    // Find our value of "placeMid"
    let amRacing = false;
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];

      if (racer.name === g.myUsername) {
        g.modSocket.placeMid = racer.placeMid;
        g.modSocket.place = racer.place;

        if (racer.status === "racing") {
          amRacing = true;
        }
      }
    }

    if (numLeft === 1 && amRacing && race.racerList.length > 2) {
      g.modSocket.placeMid = 9999; // This will show "last person left"
    }

    if (race.ruleset.solo) {
      // We don't want to send our final place for solo races to avoid showing the "1st place"
      // graphic at the end of the race
      g.modSocket.place = 0;
    }

    send("set", `placeMid ${g.modSocket.placeMid}`);
    send("set", `place ${g.modSocket.place}`);
  }

  g.modSocket.numEntrants = race.racerList.length;
  send("set", `numEntrants ${g.modSocket.numEntrants}`);
}

function getMyStatus(race: Race) {
  for (const racer of race.racerList) {
    if (racer.name === g.myUsername) {
      return racer.status;
    }
  }

  return null;
}

export function getNumReady(race: Race): number {
  // Count how many people are ready
  let numReady = 0;
  for (let i = 0; i < race.racerList.length; i++) {
    const racer = race.racerList[i];

    if (racer.status === "ready") {
      numReady += 1;
    }
  }

  return numReady;
}

function getNumLeft(race: Race): number {
  let numLeft = 0;
  for (const racer of race.racerList) {
    if (racer.status === "racing") {
      numLeft += 1;
    }
  }

  return numLeft;
}

export function sendAll(): void {
  // Start to compile the list of starting items
  let startingItems: number[] = [];

  // Diversity races store the starting items in the seed
  if (g.modSocket.format === "diversity") {
    const items = g.modSocket.seed.split(",");
    for (const itemString of items) {
      const itemID = parseIntSafe(itemString);
      if (!Number.isNaN(itemID)) {
        startingItems.push(itemID);
      }
    }
  }

  // Seeded races store the starting items as the "startingBuild"
  if (g.modSocket.startingBuild !== -1) {
    for (const item of BUILDS[g.modSocket.startingBuild]) {
      startingItems.push(item.id);
    }
  }

  // Simplify seeded races that start with Judas' Shadow by changing the starting character
  let character = g.modSocket.character;
  if (startingItems.length === 1 && startingItems[0] === JUDAS_SHADOW_ID) {
    startingItems = [];
    character = DARK_JUDAS_ID;
  }

  // This is necessary because the 5 diversity items are communicated through the seed
  const seed = g.modSocket.format === "diversity" ? "-" : g.modSocket.seed;

  send("set", `raceID ${g.modSocket.raceID}`);
  send("set", `status ${g.modSocket.status}`);
  send("set", `myStatus ${g.modSocket.myStatus}`);
  send("set", `solo ${g.modSocket.solo}`);
  send("set", `format ${g.modSocket.format}`);
  send("set", `difficulty ${g.modSocket.difficulty}`);
  send("set", `character ${character}`);
  send("set", `goal ${g.modSocket.goal}`);
  send("set", `seed ${seed}`);
  // "startingBuild" is converted to "startingItems"
  send("set", `startingItems ${JSON.stringify(startingItems)}`);
  send("set", `countdown ${g.modSocket.countdown}`);
  send("set", `placeMid ${g.modSocket.placeMid}`);
  send("set", `place ${g.modSocket.place}`);
  send("set", `numReady ${g.modSocket.numReady}`);
  send("set", `numEntrants ${g.modSocket.numEntrants}`);
}

export function reset(): void {
  g.modSocket = new ModSocket();
  send("reset");
}
