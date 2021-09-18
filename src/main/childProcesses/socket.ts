/* eslint-disable import/no-unused-modules */

// Child process that runs a socket server
// We forward along socket messages to the parent process,
// which in turn sends them to the renderer process
// All messages to the parent must be in the form of "commandName rest of the data"

import dgram from "dgram";
import net from "net";
import { unpackSocketMsg } from "../../common/util";
import { processExit } from "./subroutines";

const LOCAL_HOSTNAME = "localhost";
const REMOTE_HOSTNAME = "isaacracing.net";
const TCP_PORT = 9112; // Arbitrarily chosen to not conflict with common IANA ports
const UDP_PORT = 9113; // The same port applies to both the localhost server and the remote server

const TCPSockets: net.Socket[] = [];

init();

function init() {
  // We use a different error message here than in the other child processes
  process.on("uncaughtException", onUncaughtException);
  process.on("message", onProcessMessage);

  initTCP();
  initUDP();
}

function initTCP() {
  const TCPServer = net.createServer(connectionListener);

  TCPServer.on("error", (err: Error) => {
    throw err;
  });

  TCPServer.listen(TCP_PORT, LOCAL_HOSTNAME, () => {
    if (process.send === undefined) {
      throw new Error("process.send() does not exist.");
    }
    process.send(`info TCP socket server started on port ${TCP_PORT}.`);
  });
}

function initUDP() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  const UDPServer = dgram.createSocket("udp4");
  const UDPClient = dgram.createSocket("udp4");

  UDPServer.on("error", (err: Error) => {
    throw err;
  });

  UDPServer.on("message", (msg: Buffer) => {
    // Forward messages from the mod --> the isaac racing server
    UDPClient.send(msg, UDP_PORT, REMOTE_HOSTNAME);
  });

  UDPServer.bind(UDP_PORT, LOCAL_HOSTNAME);
  process.send(`info UDP socket server started on port ${UDP_PORT}.`);

  UDPClient.on("error", (err: Error) => {
    throw err;
  });

  UDPClient.on("message", (msg: Buffer) => {
    // Forward messages from the isaac racing server --> the mod
    UDPServer.send(msg);
  });
}

function onUncaughtException(err: Error) {
  if (process.send !== undefined) {
    // We forward all errors back to the parent process like in the other child processes
    // But we use a prefix of "error" here instead of "error:"
    process.send(`error ${err}`, processExit);
  }
}

function onProcessMessage(message: string) {
  switch (message) {
    case "exit": {
      // The child will stay alive even if the parent has closed,
      // so we depend on the parent telling us when to die
      process.exit();
      break;
    }

    default: {
      // Forward all messages from the main process to the Racing+ mod
      for (const socket of TCPSockets) {
        socket.write(message);
      }
      break;
    }
  }
}

function connectionListener(socket: net.Socket) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  // Keep track of the newly connected client
  TCPSockets.push(socket);

  const clientAddress = `${socket.remoteAddress}:${socket.remotePort}`;
  process.send(
    `info Client "${clientAddress}" has connected to the socket server. (${TCPSockets.length} total clients)`,
  );
  process.send("connected");

  socket.on("data", TCPSocketData);

  socket.on("close", () => {
    TCPSocketClose(socket, clientAddress);
  });

  socket.on("error", (err) => {
    TCPSocketError(err, clientAddress);
  });
}

function TCPSocketData(buffer: Buffer) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  const lines = buffer.toString();
  for (const line of lines.split("\n")) {
    const trimmedLine = line.trim();
    if (trimmedLine === "") {
      continue;
    }

    const command = unpackSocketMsg(trimmedLine)[0];

    // The client will send a ping on every frame as a means of checking whether or not the socket
    // is closed
    // These can be ignored
    if (command === "ping") {
      return;
    }

    // Forward all messages received from the client to the parent process
    process.send(trimmedLine);
  }
}

function TCPSocketClose(socket: net.Socket, clientAddress: string) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  // Remove it from our list of sockets
  const index = TCPSockets.indexOf(socket);
  if (index > -1) {
    TCPSockets.splice(index, 1);
  }

  process.send(
    `info Client "${clientAddress} has disconnected from the socket server. (${TCPSockets.length} total clients)`,
  );

  if (TCPSockets.length === 0) {
    process.send("disconnected");
  }
}

function TCPSocketError(err: Error, clientAddress: string) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  process.send(
    `error The TCP socket server got an error for client "${clientAddress}": ${err}`,
  );
}
