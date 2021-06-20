import * as electron from "electron";
import log from "electron-log";
import { unpackSocketMsg } from "../../common/util";
import { amSecondTestAccount } from "../misc";
import socketFunctions from "./socketFunctions";

export function init(): void {
  electron.ipcRenderer.on("socket", IPCSocket);
}

export function start(): void {
  // Send a message to the main process to start up the socket server
  if (!amSecondTestAccount()) {
    electron.ipcRenderer.send("asynchronous-message", "socket", "start");
  }
}

function IPCSocket(_event: electron.IpcRendererEvent, rawData: string) {
  const [command, data] = unpackSocketMsg(rawData);

  // Don't log everything to reduce spam
  if (command !== "level" && command !== "room" && command !== "item") {
    log.info(`Renderer process received socket command: ${command} ${data}`);
  }

  const socketFunction = socketFunctions.get(command);
  if (socketFunction !== undefined) {
    socketFunction(data);
  } else {
    log.error(`Received an unknown socket command: ${command}`);
  }
}
