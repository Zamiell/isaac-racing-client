import { RaceDifficulty } from "./RaceDifficulty";
import { RaceFormat } from "./RaceFormat";
import { RaceGoal } from "./RaceGoal";
import { RacerStatus } from "./RacerStatus";
import { RaceStatus } from "./RaceStatus";

/** This must match the "RaceData" class on the mod. */
export class ModSocket {
  raceID = -1;
  status = RaceStatus.NONE;
  myStatus = RacerStatus.NOT_READY;
  ranked = false;
  solo = false;
  format = RaceFormat.UNSEEDED;
  difficulty = RaceDifficulty.NORMAL;
  character = 3; // Judas
  goal = RaceGoal.BLUE_BABY;
  seed = "-";
  startingBuild = -1; // Converted to "startingItems" later on
  countdown = -1;
  placeMid = 0;
  place = -1;
  numReady = 0;
  numEntrants = 1;
}
