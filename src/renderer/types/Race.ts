import type { Racer } from "./Racer";
import type { RaceStatus } from "./RaceStatus";
import type { Ruleset } from "./Ruleset";

/** Matches "RaceCreatedMessage" in "websocketDataTypes.go". */
export interface Race {
  id: number;
  name: string;
  status: RaceStatus;
  ruleset: Ruleset;
  captain: string;
  isPasswordProtected: boolean;
  datetimeCreated: number;
  datetimeStarted: number;
  racers: string[];

  /**
   * This is only sent by the server in the "racerList" command (not the "raceList" command). We add
   * it to the race object manually at that point.
   */
  racerList: Racer[];
}
