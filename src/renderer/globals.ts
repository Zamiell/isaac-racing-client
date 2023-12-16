import type { Connection } from "./types/Connection";
import { ModSocket } from "./types/ModSocket";
import type { Race } from "./types/Race";
import type { Room } from "./types/Room";
import { Screen } from "./types/Screen";

/** The object that contains all of the global variables. */
export const g = {
  autoUpdateStatus: null as string | null,

  /** The WebSocket connection (set in "websocket.ts"). */
  conn: null as Connection | null,
  currentScreen: Screen.TITLE_AJAX,
  currentRaceID: -1,
  emoteList: [] as readonly string[], // Filled in main.js

  gameState: {
    modConnected: false,

    /** The mod will tell us if we are in the menu or in a run. */
    inGame: false,

    /** The mod will tell us if the current run matches the race ruleset. */
    runMatchesRuleset: false,
  },

  lastPM: null as null | string,
  lastRaceTitle: "",
  lastFinishedTime: 0,

  modSocket: new ModSocket(),

  myUserID: -1, // Set from the "settings" command
  myUsername: "", // Set from the "settings" command
  playingSound: false,
  roomList: new Map<string, Room>(),
  raceList: new Map<number, Race>(),
  spamTimer: Date.now(),

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
  timeLaunched: Date.now(),
  wordList: [] as string[], // Filled in main.js
};

// We also make the globals available to the window (so that we can access them from the JavaScript
// console for debugging purposes).
window.g = g;
