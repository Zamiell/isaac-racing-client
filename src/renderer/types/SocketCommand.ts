/** Commands sent to the Racing+ mod from the client. */
export type SocketCommandIn = "set" | "reset";

/** Commands sent to the Racing+ client from the mod. */
export type SocketCommandOut =
  | "connected"
  | "disconnected"
  | "ping"
  | "info"
  | "mainMenu"
  | "seed"
  | "runMatchesRuleset"
  | "level"
  | "room"
  | "item"
  | "finish"
  | "error"
  | "exited"; // Not a real command; sent when the subprocess exits
