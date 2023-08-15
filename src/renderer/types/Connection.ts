import log from "electron-log";
import { ReadonlySet } from "../../common/isaacScriptCommonTS";

const SEPARATOR = " ";

const SPAMMY_COMMANDS = new ReadonlySet([
  "roomHistory",
  "roomMessage",
  "privateMessage",
  "discordMessage",
  "adminMessage",
  // - "racerSetFloor",
  // - "racerSetPlaceMid",
  // - "racerAddItem",
  // - "racerSetStartingItem",
  // - "racerCharacter",
]);

type WebSocketCallbackCommands = Record<string, (data: unknown) => void>;

type WebSocketCallbacks = WebSocketCallbackCommands & {
  open?: (evt: Event) => void;
  close?: (evt: Event) => void;
  socketError?: (evt: Event) => void;
};

/**
 * Connection is a class that manages a WebSocket connection to the server. On top of the WebSocket
 * protocol, the client and the server communicate using a specific format based on the protocol
 * that the Golem WebSocket framework uses. For more information, see "websocketMessage.go".
 *
 * Based on: https://github.com/trevex/golem_client/blob/master/golem.js
 */
export class Connection {
  ws: WebSocket;
  callbacks: WebSocketCallbacks = {};
  debug: boolean;

  constructor(addr: string, debug: boolean) {
    this.ws = new WebSocket(addr);
    this.debug = debug;

    this.ws.addEventListener("close", this.onClose.bind(this));
    this.ws.addEventListener("open", this.onOpen.bind(this));
    this.ws.onmessage = this.onMessage.bind(this);
    this.ws.onerror = this.onError.bind(this);
  }

  onOpen(evt: Event): void {
    if (this.callbacks.open !== undefined) {
      this.callbacks.open(evt);
    }
  }

  onClose(evt: CloseEvent): void {
    if (this.callbacks.close !== undefined) {
      this.callbacks.close(evt);
    }
  }

  onMessage(evt: MessageEvent): void {
    if (typeof evt.data !== "string") {
      throw new TypeError("WebSocket received data that was not a string.");
    }

    const [command, data] = unpack(evt.data);
    if (command === undefined || data === undefined) {
      return;
    }

    const callback = this.callbacks[command];
    if (callback === undefined) {
      log.error(`Received WebSocket message with no callback: ${evt.data}`);
      return;
    }

    if (!SPAMMY_COMMANDS.has(command)) {
      log.info(`WebSocket received: ${evt.data}`);
    }
    const dataObject = unmarshal(data);
    callback(dataObject);
  }

  onError(evt: Event): void {
    if (this.callbacks.socketError !== undefined) {
      this.callbacks.socketError(evt);
    }
  }

  // This must be "any" instead of "unknown".
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  on(name: string, callback: (evt: any) => void): void {
    this.callbacks[name] = callback;
  }

  emit(command: string, data?: unknown): void {
    if (this.ws.readyState !== WebSocket.OPEN) {
      return;
    }

    if (data === undefined) {
      data = {}; // eslint-disable-line no-param-reassign
    }
    const stringToSend = marshalAndPack(command, data);
    this.ws.send(stringToSend);
  }

  send(command: string, data?: unknown): void {
    this.emit(command, data);

    // Don't log some commands to reduce spam.
    if (
      command !== "raceFloor" &&
      command !== "raceRoom" &&
      command !== "raceItem"
    ) {
      log.info(`WebSocket sent: ${command} ${JSON.stringify(data)}`);
    }
  }

  close(): void {
    this.ws.close();
  }
}

function unpack(data: string) {
  const name = data.split(SEPARATOR)[0];
  if (name === undefined) {
    throw new Error('Failed to unpack data due to "name" being undefined.');
  }

  return [name, data.substring(name.length + 1, data.length)];
}

function unmarshal(data: string) {
  return JSON.parse(data) as unknown;
}

function marshalAndPack(name: string, data: unknown) {
  return name + SEPARATOR + JSON.stringify(data);
}
