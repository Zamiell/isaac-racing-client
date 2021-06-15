import * as electron from "electron";
import builds from "../../../static/data/builds.json";
import log from "../../common/log";
import { parseIntSafe, unpackSocketMsg } from "../../common/util";
import g from "../globals";
import { SocketCommandIn } from "../types/SocketCommand";
import socketFunctions from "./socketFunctions";

export function init(): void {
  electron.ipcRenderer.on("socket", IPCSocket);
}

export function start(): void {
  // Send a message to the main process to start up the socket server
  electron.ipcRenderer.send("asynchronous-message", "socket", "start");
}

function IPCSocket(_event: electron.IpcRendererEvent, rawData: string) {
  const [command, data] = unpackSocketMsg(rawData);

  // Don't log everything to reduce spam
  if (command !== "level" && command !== "room" && command !== "item") {
    log.info(`Renderer process received socket command: ${command}`);
  }

  const socketFunction = socketFunctions.get(command);
  if (socketFunction !== undefined) {
    socketFunction(data);
  } else {
    log.error(`Received an unknown socket command: ${command}`);
  }
}

export function send(command: SocketCommandIn, data = ""): void {
  // Do nothing if we are on a test account > 1
  if (
    g.myUsername.startsWith("TestAccount") &&
    g.myUsername !== "TestAccount1"
  ) {
    return;
  }

  const packedMsg = packSocketMsg(command, data);
  electron.ipcRenderer.send("asynchronous-message", "socket", packedMsg);
}

function packSocketMsg(command: string, data: string) {
  if (data === "") {
    return command;
  }

  const separator = " ";
  return `${command}${separator}${data}`;
}

export function sendPlace(): void {
  // This sends an up-to-date myStatus, numEntrants, placeMid, and place to the mod
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return;
  }

  if (race.status === "in progress") {
    // Find our value of "placeMid"
    let numLeft = 0;
    let amRacing = false;
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];

      if (racer.status === "racing") {
        numLeft += 1;
      }

      if (racer.name === g.myUsername) {
        g.modSocket.myStatus = racer.status;
        g.modSocket.placeMid = racer.placeMid;
        g.modSocket.place = racer.place;
        if (racer.status === "racing") {
          amRacing = true;
        }
      }
    }
    if (numLeft === 1 && amRacing && race.racerList.length > 2) {
      g.modSocket.placeMid = -1; // This will show "last person left"
    }
  } else if (race.status === "starting") {
    // Count how many people are ready
    let numReady = 0;
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];

      if (racer.status === "ready") {
        numReady += 1;
      }

      if (racer.name === g.myUsername) {
        g.modSocket.myStatus = racer.status;
      }
    }
    g.modSocket.placeMid = numReady;
  }
  g.modSocket.numEntrants = race.racerList.length;

  if (race.ruleset.solo) {
    // We don't want to send our final place for solo races to avoid showing the "1st place" graphic at the end of the race
    g.modSocket.place = 0;
  }

  // send();
}

export function sendAll(): void {
  // Start to compile the list of starting items
  const startingItems: number[] = [];
  if (g.modSocket.format === "diversity") {
    const items = g.modSocket.seed.split(",");
    for (const itemString of items) {
      const itemID = parseIntSafe(itemString);
      if (!Number.isNaN(itemID)) {
        startingItems.push(); // The Lua mod expects this to be a number
      }
    }
  }

  // Parse the starting build
  if (g.modSocket.startingBuild !== -1) {
    for (const item of builds[g.modSocket.startingBuild]) {
      // The Lua mod just needs the item ID, not the name
      startingItems.push(item.id);
    }
  }

  // This is necessary because the 5 diversity items are communicated through the seed
  const seed = g.modSocket.format === "diversity" ? "-" : g.modSocket.seed;

  send("set", `raceID ${g.modSocket.raceID}`);
  send("set", `status ${g.modSocket.status}`);
  send("set", `myStatus ${g.modSocket.myStatus}`);
  send("set", `solo ${g.modSocket.solo}`);
  send("set", `format ${g.modSocket.format}`);
  send("set", `difficulty ${g.modSocket.difficulty}`);
  send("set", `character ${g.modSocket.character}`);
  send("set", `goal ${g.modSocket.goal}`);
  send("set", `seed ${seed}`);
  // "startingBuild" is converted to "startingItems"
  send("set", `startingItems ${startingItems}`);
  send("set", `countdown ${g.modSocket.countdown}`);
  send("set", `placeMid ${g.modSocket.placeMid}`);
  send("set", `place ${g.modSocket.place}`);
  send("set", `numEntrants ${g.modSocket.numEntrants}`);
}
