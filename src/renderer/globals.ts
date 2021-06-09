import Connection from "./types/Connection";
import Item from "./types/Item";
import Race from "./types/Race";
import Room from "./types/Room";

type Screen =
  | "title-ajax"
  | "tutorial1"
  | "tutorial2"
  | "login"
  | "login-ajax"
  | "forgot"
  | "forgot-ajax"
  | "register"
  | "register-ajax"
  | "updating"
  | "lobby"
  | "race"
  | "error"
  | "warning"
  | "waiting-for-server"
  | "transition"
  | "null";

// The object that contains all of the global variables
const globals = {
  autoUpdateStatus: null as string | null,
  conn: null as Connection | null, // The WebSocket connection (set in "websocket.ts")
  currentScreen: "title-ajax" as Screen,
  currentRaceID: -1,
  emoteList: [] as string[], // Filled in main.js

  gameState: {
    inGame: false, // The mod will tell us if we are in the menu or in a run
    hardMode: false, // The mod will tell us if a run is started on hard mode or Greed mode
    // The mod will tell us if race validation succeeded, which is an indicator that they have
    // successfully downloaded and are running the Racing+ Lua mod
    racingPlusModEnabled: false,
    fileChecksComplete: false, // This will be set to true when the "isaac.js" subprocess exits
  },

  itemList: {} as Record<string, Item>, // Filled in main.js
  lastPM: null as null | string,
  lastRaceTitle: "",
  lastFinishedTime: 0,

  modSocket: {
    // Race values are reset in the "mod-loader.js" file
    userID: 0,
    raceID: 0,
    status: "none",
    myStatus: "not ready",
    ranked: false,
    solo: false,
    rFormat: "unseeded",
    difficulty: "hard",
    character: 3, // Judas
    goal: "Blue Baby",
    seed: "-",
    startingBuild: -1, // Converted to "startingItems" later on
    countdown: -1,
    placeMid: 0,
    place: 1,
    numEntrants: 1,
  },

  myUserID: -1, // Set from the "settings" command
  myUsername: "", // Set from the "settings" command
  playingSound: false,
  roomList: new Map<string, Room>(),
  raceList: new Map<number, Race>(),
  spamTimer: new Date().getTime(),

  // Filled in steam.js
  steam: {
    id: null as string | null,
    accountID: null as number | null,
    screenName: null as string | null,
    ticket: null as string | null,
  },

  stream: {
    URL: "",
    URLBeforeTyping: "",
    URLBeforeSubmit: "",
    twitchBotEnabled: false,
    twitchBotDelay: 0,
  },

  tabCompleteCounter: 0,
  tabCompleteIndex: 0,
  tabCompleteWordList: null as string[] | null,
  timeLaunched: new Date().getTime(),
  wordList: [] as string[], // Filled in main.js
};
export default globals;

// Also make the globals available to the window
// (so that we can access them from the JavaScript console for debugging purposes)
declare global {
  interface Window {
    g: any; // eslint-disable-line @typescript-eslint/no-explicit-any
  }
}
if (window !== undefined) {
  window.g = globals;
}
