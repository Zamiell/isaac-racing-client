import log from "electron-log";
import path from "path";

// Preload some sounds by playing all of them
// We do this at the beginning of a race so that the user is forced to interact with the document
// first (otherwise, Chrome prevents audio from playing)
export function preloadSounds(): void {
  const soundFiles = [
    "1",
    "2",
    "3",
    "finished",
    "go",
    "lets-go",
    "quit",
    "race-completed",
  ];
  for (const file of soundFiles) {
    const filePath = path.join("sounds", `${file}.mp3`);
    playMuted(filePath);
  }

  for (let i = 1; i <= 16; i++) {
    const filePath = path.join("sounds", "place", `${i}.mp3`);
    playMuted(filePath);
  }
}

function playMuted(filePath: string) {
  const audio = new Audio(filePath);
  audio.volume = 0;
  audio.play().catch((err) => {
    log.error(`Failed to preload audio "${filePath}": ${err}`);
  });
}
