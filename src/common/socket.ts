import { SocketCommandOut } from "../renderer/types/SocketCommand";

// e.g. "floor 1" or "finish"
export function unpackSocketMsg(rawData: string): [SocketCommandOut, string] {
  const separator = " ";
  const [command, ...dataArray] = rawData.trim().split(separator);
  const data = dataArray.join(separator);

  return [command as SocketCommandOut, data];
}
