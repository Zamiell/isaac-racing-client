function preloadSounds() {
  // Preload some sounds by playing all of them
  // (commented out because in the new version of Chrome we get an error:
  // "play() failed because the user didn't interact with the document first.")
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
    const audioPath = path.join("sounds", `${file}.mp3`);
    const audio = new Audio(audioPath);
    audio.volume = 0;
    audio.play();
  }
  for (let i = 1; i <= 16; i++) {
    const audioPath = path.join("sounds", "place", `${i}.mp3`);
    const audio = new Audio(audioPath);
    audio.volume = 0;
    audio.play();
  }
}
