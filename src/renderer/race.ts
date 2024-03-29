import { g } from "./globals";
import type { Race } from "./types/Race";
import type { Racer } from "./types/Racer";
import { RacerStatus } from "./types/RacerStatus";

export function getMyRacer(race: Race): Racer | null {
  for (const racer of race.racerList) {
    if (racer.name === g.myUsername) {
      return racer;
    }
  }

  return null;
}

export function getMyStatus(race: Race): RacerStatus | null {
  const myRacer = getMyRacer(race);
  return myRacer === null ? null : myRacer.status;
}

export function getNumReady(race: Race): number {
  // Count how many people are ready.
  let numReady = 0;
  for (const racer of race.racerList) {
    if (racer.status === RacerStatus.READY) {
      numReady++;
    }
  }

  return numReady;
}

export function getNumLeft(race: Race): number {
  let numLeft = 0;
  for (const racer of race.racerList) {
    if (racer.status === RacerStatus.RACING) {
      numLeft++;
    }
  }

  return numLeft;
}
