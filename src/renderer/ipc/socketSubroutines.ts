import { g } from "../globals";
import { RacerStatus } from "../types/RacerStatus";
import { Screen } from "../types/Screen";

export function inOngoingRace(): boolean {
  // Don't do anything if we are not in a race.
  if (g.currentScreen !== Screen.RACE || g.currentRaceID === -1) {
    return false;
  }

  // Don't do anything if the race is over.
  const race = g.raceList.get(g.currentRaceID);
  if (race === undefined) {
    return false;
  }

  // Don't do anything if we have not started yet or we have quit.
  for (const racer of race.racerList) {
    if (racer.name === g.myUsername) {
      return racer.status === RacerStatus.RACING;
    }
  }

  return false;
}
