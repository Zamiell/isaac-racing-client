import log from "../../common/log";

interface WebSocketCallbackCommands {
  [command: string]: (data: unknown) => void;
}

type WebSocketCallbacks = WebSocketCallbackCommands & {
  open?: (evt: Event) => void;
  close?: (evt: Event) => void;
  socketError?: (evt: Event) => void;
};

/**
 * Connection is a class that manages a WebSocket connection to the server.
 * On top of the WebSocket protocol, the client and the server communicate using a specific format
 * based on the protocol that the Golem WebSocket framework uses.
 * For more information, see "websocketMessage.go".
 * Based on: https://github.com/trevex/golem_client/blob/master/golem.js
 */
export default class Connection {
  ws: WebSocket;
  callbacks: WebSocketCallbacks = {};
  debug: boolean;

  constructor(addr: string, debug: boolean) {
    this.ws = new WebSocket(addr);
    this.debug = debug;

    this.ws.onclose = this.onClose.bind(this);
    this.ws.onopen = this.onOpen.bind(this);
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
    const data = unpack(evt.data);
    const command = data[0];
    if (this.callbacks[command] !== undefined) {
      const obj = unmarshal(data[1]);
      this.callbacks[command](obj);
    } else {
      log.error(
        "Received WebSocket message with no callback:",
        command,
        JSON.parse(data[1]),
      );
    }
  }

  onError(evt: Event): void {
    if (this.callbacks.socketError !== undefined) {
      this.callbacks.socketError(evt);
    }
  }

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

    // Don't log some commands to reduce spam
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

const separator = " ";
const unpack = (data: string) => {
  const name = data.split(separator)[0];
  return [name, data.substring(name.length + 1, data.length)];
};
const unmarshal = (data: string) => JSON.parse(data) as unknown;
const marshalAndPack = (name: string, data: unknown) =>
  name + separator + JSON.stringify(data);
