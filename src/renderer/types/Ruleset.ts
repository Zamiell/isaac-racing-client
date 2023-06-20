import { RaceDifficulty } from "./RaceDifficulty";
import { RaceFormat } from "./RaceFormat";
import { RaceGoal } from "./RaceGoal";

/** Matches "Ruleset" in "race.go". */
export interface Ruleset {
  ranked: boolean;
  solo: boolean;
  format: RaceFormat;
  /** The full character name, e.g. "Judas" */
  character: string;
  goal: RaceGoal;
  startingBuildIndex: number;
  startingItems: number[];
  seed: string;
  difficulty: RaceDifficulty;
}
