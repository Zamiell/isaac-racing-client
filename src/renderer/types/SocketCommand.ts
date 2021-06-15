/** Commands sent to the Racing+ mod from the client. */
export type SocketCommandIn = "set" | "reset";

/** Commands sent to the Racing+ client from the mod. */
export type SocketCommandOut =
  | "connected"
  | "disconnected"
  | "ping"
  | "mainMenu"
  | "seed"
  | "runMatchesRuleset"
  | "level"
  | "room"
  | "item"
  | "finish"
  | "error";
