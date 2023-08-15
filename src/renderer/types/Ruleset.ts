import type { RaceDifficulty } from "./RaceDifficulty";
import type { RaceFormat } from "./RaceFormat";
import type { RaceGoal } from "./RaceGoal";

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
