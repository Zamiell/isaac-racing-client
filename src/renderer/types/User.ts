import type { Racer } from "./Racer";

export interface User {
  name: string;
  racerList: Map<string, Racer>;
}
