import RaceItem from "./RaceItem";
import RacerStatus from "./RacerStatus";

/** Matches "RacerMessage" in "racer.go". */
export default interface Racer {
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
