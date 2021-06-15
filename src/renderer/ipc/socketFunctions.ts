import log from "../../common/log";
import { parseIntSafe } from "../../common/util";
import g from "../globals";
import { errorShow } from "../misc";
import { SocketCommandOut } from "../types/SocketCommand";
import * as raceScreen from "../ui/race";
import { inOngoingRace } from "./socketSubroutines";

const functionMap = new Map<SocketCommandOut, (data: string) => void>();
export default functionMap;

functionMap.set("connected", (_data: string) => {
  g.gameState.modConnected = true;
  raceScreen.checkReadyValid();
});

functionMap.set("disconnected", (_data: string) => {
  g.gameState.modConnected = false;
  raceScreen.checkReadyValid();
});

functionMap.set("error", (data: string) => {
  errorShow(`Something went wrong with the socket server: ${data}`);
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

functionMap.set("level", (data: string) => {
  if (!inOngoingRace()) {
    return;
  }

  const match = data.match(/(\d+)-(\d+)/g);
  if (match === null) {
    errorShow(`Failed to parse the level: ${data}`);
    return;
  }

  const floorNum = parseIntSafe(match[1]); // The server expects this to be an integer
  if (Number.isNaN(floorNum)) {
    errorShow(`Failed to parse the floor number: ${match[1]}`);
    return;
  }

  const stageType = parseIntSafe(match[2]); // The server expects this to be an integer
  if (Number.isNaN(stageType)) {
    errorShow(`Failed to parse the stage type: ${match[1]}`);
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

functionMap.set("runMatchesRuleset", (data: string) => {
  let runMatchesRuleset: boolean;
  if (data === "true") {
    runMatchesRuleset = true;
  } else if (data === "false") {
    runMatchesRuleset = false;
  } else {
    log.error(`Failed to parse the "runMatchesRuleset" command: ${data}`);
    return;
  }

  g.gameState.runMatchesRuleset = runMatchesRuleset;
  raceScreen.checkReadyValid();
});
