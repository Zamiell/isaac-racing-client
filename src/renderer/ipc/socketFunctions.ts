import log from "electron-log";
import { parseIntSafe } from "../../common/util";
import g from "../globals";
import { errorShow } from "../misc";
import * as modSocket from "../modSocket";
import { SocketCommandOut } from "../types/SocketCommand";
import * as raceScreen from "../ui/race";
import { inOngoingRace } from "./socketSubroutines";

const functionMap = new Map<SocketCommandOut, (data: string) => void>();
export default functionMap;

functionMap.set("connected", (_data: string) => {
  g.gameState.modConnected = true;
  log.info(`Set modConnected to: ${g.gameState.modConnected}`);
  modSocket.sendAll();
  raceScreen.checkReadyValid();
});

functionMap.set("disconnected", (_data: string) => {
  g.gameState.modConnected = false;
  log.info(`Set modConnected to: ${g.gameState.modConnected}`);
  raceScreen.checkReadyValid();
});

functionMap.set("error", (data: string) => {
  log.error(data);
});

functionMap.set("exited", (_data: string) => {
  errorShow("The localhost socket server exited unexpectedly.");
});

functionMap.set("finish", (data: string) => {
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

functionMap.set("item", (data: string) => {
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

functionMap.set("info", (data: string) => {
  log.info(data);
});

functionMap.set("level", (data: string) => {
  if (!inOngoingRace()) {
    return;
  }

  const match = /(\d+)-(\d+)/.exec(data); // This does not work with a global flag
  if (match === null) {
    errorShow(`Failed to parse the level: ${data}`);
    return;
  }

  const floorNum = parseIntSafe(match[1]); // The server expects this to be an integer
  if (Number.isNaN(floorNum)) {
    errorShow(
      `Failed to parse the floor number of "${match[1]}" from "${data}".`,
    );
    return;
  }

  const stageType = parseIntSafe(match[2]); // The server expects this to be an integer
  if (Number.isNaN(stageType)) {
    errorShow(
      `Failed to parse the stage type of "${match[2]}" from "${data}".`,
    );
    return;
  }

  if (g.conn !== null) {
    g.conn.send("raceFloor", {
      id: g.currentRaceID,
      floorNum,
      stageType,
    });
  }
});

functionMap.set("mainMenu", (_data: string) => {
  g.gameState.inGame = false;
  g.gameState.runMatchesRuleset = false;
  raceScreen.checkReadyValid();
});

functionMap.set("seed", (data: string) => {
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

functionMap.set("room", (data: string) => {
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

functionMap.set("runMatchesRuleset", (_data: string) => {
  g.gameState.runMatchesRuleset = true;
  raceScreen.checkReadyValid();
});
