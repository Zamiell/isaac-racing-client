type RaceGoal =
  | "Blue Baby"
  | "The Lamb"
  | "Mega Satan"
  | "Hush"
  | "Delirium"
  | "Boss Rush"
  | "custom";

type RaceFormat = "unseeded" | "seeded" | "diversity" | "custom";
type RaceDifficulty = "normal" | "hard";

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
