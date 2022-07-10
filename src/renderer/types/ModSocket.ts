import { RaceDifficulty } from "./RaceDifficulty";
import { RaceFormat } from "./RaceFormat";
import { RaceGoal } from "./RaceGoal";
import { RacerStatus } from "./RacerStatus";
import { RaceStatus } from "./RaceStatus";

/** This must match the "RaceData" class on the mod (roughly). */
export class ModSocket {
  /** -1 if a race is not going on. */
  raceID = -1;

  status = RaceStatus.NONE;
  myStatus = RacerStatus.NOT_READY;
  ranked = false;
  solo = false;
  format = RaceFormat.UNSEEDED;
  difficulty = RaceDifficulty.NORMAL;
  character = 3; // Judas
  goal = RaceGoal.BLUE_BABY;

  /** Corresponds to the seed that is the race goal or "-". */
  seed = "-";

  /** Converted to "startingItems" later on. */
  startingBuild = -1;

  /** This corresponds to the graphic to draw on the screen. */
  countdown = -1;

  /**
   * This is either the number of people ready (in a pre-race) or the non-finished place (in a
   * race).
   */
  placeMid = 0;

  /** This is the final place. */
  place = -1;

  /** In a pre-race, the number of people who have readied up. */
  numReady = 0;

  /** The number of people in the race. */
  numEntrants = 1;

  millisecondsBehindLeader = 0;
  millisecondsAheadOfNextRacer = 0;
}
