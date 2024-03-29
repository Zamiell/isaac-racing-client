import * as electron from "electron";
import log from "electron-log";
import { unpackSocketMsg } from "../../common/socket";
import { amSecondTestAccount } from "../utils";
import { socketFunctionMap } from "./socketFunctionMap";

export function init(): void {
  electron.ipcRenderer.on("socket", IPCSocket);
}

export function start(): void {
  // Send a message to the main process to start up the socket server.
  if (!amSecondTestAccount()) {
    electron.ipcRenderer.send("asynchronous-message", "socket", "start");
  }
}

function IPCSocket(_event: electron.IpcRendererEvent, rawData: string) {
  const [command, data] = unpackSocketMsg(rawData);

  // Don't log everything to reduce spam.
  if (command !== "level" && command !== "room" && command !== "item") {
    log.info(`Renderer process received socket command: ${command} ${data}`);
  }

  const socketFunction = socketFunctionMap.get(command);
  if (socketFunction === undefined) {
    log.error(`Received an unknown socket command: ${command}`);
  } else {
    socketFunction(data);
  }
}
