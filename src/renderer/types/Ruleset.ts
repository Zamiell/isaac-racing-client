import RaceDifficulty from "./RaceDifficulty";
import RaceFormat from "./RaceFormat";
import RaceGoal from "./RaceGoal";

/** Matches "Ruleset" in "race.go". */
export default interface Ruleset {
  ranked: boolean;
  solo: boolean;
  format: RaceFormat;
  /** The full character name, e.g. "Judas" */
  character: string;
  characterRandom: boolean;
  goal: RaceGoal;
  startingBuild: number;
  startingBuildRandom: boolean;
  startingItems: number[];
  seed: string;
  difficulty: RaceDifficulty;
}
