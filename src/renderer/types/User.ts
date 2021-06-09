import Racer from "./Racer";

export default interface User {
  name: string;
  racerList: Map<string, Racer>;
}
