import { RaceItem } from "./RaceItem";
import { RacerStatus } from "./RacerStatus";

/** Matches "RacerMessage" in "racer.go". */
export interface Racer {
  name: string;
  datetimeJoined: number;
  status: RacerStatus;
  floorNum: number;
  stageType: number;
  datetimeArrivedFloor: number;
  items: RaceItem[];
  startingItem: number;
  characterNum: number;
  place: number;
  placeMid: number;
  datetimeFinished: number;
  runTime: number;
  comment: string;
}

export function getDefaultRacer(name: string): Racer {
  const datetime = new Date().getTime();

  return {
    name,
    datetimeJoined: datetime,
    status: RacerStatus.NOT_READY,
    floorNum: 1,
    stageType: 0,
    datetimeArrivedFloor: 0,
    items: [],
    startingItem: 0,
    characterNum: 0,
    place: 0,
    placeMid: -1,
    datetimeFinished: 0,
    runTime: 0,
    comment: "",
  };
}
