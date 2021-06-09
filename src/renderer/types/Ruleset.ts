/** Matches "Ruleset" in "race.go". */
export default interface Ruleset {
  ranked: boolean;
  solo: boolean;
  format: string;
  /** The full character name, e.g. "Judas" */
  character: string;
  characterRandom: boolean;
  goal: string;
  startingBuild: number;
  startingBuildRandom: boolean;
  startingItems: number[];
  seed: string;
  difficulty: string;
}
