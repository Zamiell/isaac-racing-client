import log from "electron-log";
import path from "node:path";
import { settings } from "../common/settings";
import { g } from "./globals";

const audioElements = new Map<string, HTMLAudioElement>();

export function play(soundFilename: string, lengthOfSound = -1): void {
  // First check to see if sound is disabled.
  const volume = settings.get("volume") as number;
  if (volume === 0) {
    return;
  }

  if (lengthOfSound !== -1) {
    // For some sound effects, we only want one of them playing at once to prevent confusion.
    if (g.playingSound) {
      return; // Do nothing if we are already playing a sound
    }

    g.playingSound = true;
    setTimeout(() => {
      g.playingSound = false;
    }, lengthOfSound);
  }

  const audioElement = getAudioElement(soundFilename);
  audioElement.volume = volume;
  audioElement.play().catch((err) => {
    log.info(`Failed to play "${soundFilename}": ${err}`);
  });
}

function getAudioElement(soundFilename: string) {
  let audioElement = audioElements.get(soundFilename);
  if (audioElement === undefined) {
    const audioPath = path.join("sounds", `${soundFilename}.mp3`);
    audioElement = new Audio(audioPath);
    audioElement.preload = "auto";
    audioElements.set(soundFilename, audioElement);
  }

  return audioElement;
}

// Preload some sounds. We do this at the beginning of a race so that the user is forced to interact
// with the document first. (Otherwise, Chrome prevents audio from playing.)
export function preload(): void {
  const soundFilenames = [
    "1",
    "2",
    "3",
    "finished",
    "go",
    "lets-go",
    "quit",
    "race-completed",
  ];
  for (const soundFilename of soundFilenames) {
    getAudioElement(soundFilename);
  }

  for (let i = 1; i <= 16; i++) {
    const soundFilename = `place/${i}`;
    getAudioElement(soundFilename);
  }
}
