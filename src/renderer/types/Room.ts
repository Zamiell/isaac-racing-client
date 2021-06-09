import User from "./User";

export default interface Room {
  users: Map<string, User>;
  numUsers: number;
  chatLine: number;
  typedHistory: string[];
  historyIndex: number;
}
