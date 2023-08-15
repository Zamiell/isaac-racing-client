import log from "electron-log";
import { parseIntSafe } from "../../common/isaacScriptCommonTS";
import * as chat from "../chat";
import { g } from "../globals";
import * as modSocket from "../modSocket";
import type { SocketCommandOut } from "../types/SocketCommand";
import * as raceScreen from "../ui/race";
import { errorShow } from "../utils";
import { inOngoingRace } from "./socketSubroutines";

export const socketFunctionMap = new Map<
  SocketCommandOut,
  (data: string) => void
>();

socketFunctionMap.set("connected", (_data: string) => {
  g.gameState.modConnected = true;
  log.info(`Set modConnected to: ${g.gameState.modConnected}`);
  modSocket.sendAll();
  raceScreen.checkReadyValid();
});

socketFunctionMap.set("disconnected", (_data: string) => {
  g.gameState.modConnected = false;
  log.info(`Set modConnected to: ${g.gameState.modConnected}`);
  raceScreen.checkReadyValid();
});

socketFunctionMap.set("chat", (data: string) => {
  chat.send("race", data);
});

socketFunctionMap.set("error", (data: string) => {
  log.error(data);
});

socketFunctionMap.set("exited", (_data: string) => {
  errorShow("The localhost socket server exited unexpectedly.");
});

socketFunctionMap.set("finish", (data: string) => {
  if (!inOngoingRace()) {
    return;
  }

  const time = parseIntSafe(data); // The server expects this to be an integer
  if (Number.isNaN(time)) {
    errorShow(`Failed to parse the time: ${data}`);
    return;
  }

  if (g.conn !== null) {
    g.conn.send("raceFinish", {
      id: g.currentRaceID,
      time,
    });
  }
});

socketFunctionMap.set("item", (data: string) => {
  if (!inOngoingRace()) {
    return;
  }

  const itemID = parseIntSafe(data); // The server expects this to be an integer
  if (Number.isNaN(itemID)) {
    errorShow(`Failed to parse the item: ${data}`);
    return;
  }

  if (g.conn !== null) {
    g.conn.send("raceItem", {
      id: g.currentRaceID,
      itemID,
    });
  }
});

socketFunctionMap.set("info", (data: string) => {
  log.info(data);
});

socketFunctionMap.set("level", (data: string) => {
  if (!inOngoingRace()) {
    return;
  }

  const match = /(\d+)-(\d+)-(\w+)/.exec(data); // This does not work with a global flag.
  if (match === null) {
    errorShow(`Failed to parse the level: ${data}`);
    return;
  }

  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const floorNum = parseIntSafe(match[1]!); // The server expects this to be an integer.
  if (Number.isNaN(floorNum)) {
    errorShow(
      `Failed to parse the floor number of "${match[1]}" from "${data}".`,
    );
    return;
  }

  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const stageType = parseIntSafe(match[2]!); // The server expects this to be an integer.
  if (Number.isNaN(stageType)) {
    errorShow(
      `Failed to parse the stage type of "${match[2]}" from "${data}".`,
    );
    return;
  }

  const backwardsPath = match[3] === "true";

  if (g.conn !== null) {
    g.conn.send("raceFloor", {
      id: g.currentRaceID,
      floorNum,
      stageType,
      backwardsPath,
    });
  }
});

socketFunctionMap.set("mainMenu", (_data: string) => {
  g.gameState.inGame = false;
  g.gameState.runMatchesRuleset = false;
  raceScreen.checkReadyValid();
});

socketFunctionMap.set("seed", (data: string) => {
  g.gameState.inGame = true;
  raceScreen.checkReadyValid();

  if (!inOngoingRace()) {
    return;
  }

  if (g.conn !== null) {
    g.conn.send("raceSeed", {
      id: g.currentRaceID,
      seed: data,
    });
  }
});

socketFunctionMap.set("room", (data: string) => {
  if (!inOngoingRace()) {
    return;
  }

  if (g.conn !== null) {
    g.conn.send("raceRoom", {
      id: g.currentRaceID,
      roomID: data, // roomID is a string on the server, e.g. "13.12"
    });
  }
});

socketFunctionMap.set("runMatchesRuleset", (_data: string) => {
  g.gameState.runMatchesRuleset = true;
  raceScreen.checkReadyValid();
});
