import RaceDifficulty from "./RaceDifficulty";
import RaceFormat from "./RaceFormat";
import RaceGoal from "./RaceGoal";
import RacerStatus from "./RacerStatus";
import RaceStatus from "./RaceStatus";

/** This must match the "RaceData" class on the mod. */
export default class ModSocket {
  raceID = -1;
  status: RaceStatus = "none";
  myStatus: RacerStatus = "not ready";
  ranked = false;
  solo = false;
  format: RaceFormat = "unseeded";
  difficulty: RaceDifficulty = "normal";
  character = 3; // Judas
  goal: RaceGoal = "Blue Baby";
  seed = "-";
  startingBuild = -1; // Converted to "startingItems" later on
  countdown = -1;
  placeMid = 0;
  place = -1;
  numReady = 0;
  numEntrants = 1;
}
