import type { User } from "./User";

export interface Room {
  users: Map<string, User>;
  numUsers: number;
  chatLine: number;
  typedHistory: string[];
  historyIndex: number;
}
