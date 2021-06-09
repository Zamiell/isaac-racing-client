import { ChildProcess, fork, ForkOptions } from "child_process";
import * as electron from "electron";
import path from "path";
import log from "../common/log";
import { IS_DEV } from "./constants";

interface ChildProcesses {
  steam: ChildProcess | null;
  steamWatcher: ChildProcess | null;
  isaac: ChildProcess | null;
}

const childProcesses: ChildProcesses = {
  steam: null,
  steamWatcher: null,
  isaac: null,
};

export function start(
  name: keyof ChildProcesses,
  window: electron.BrowserWindow,
): void {
  if (childProcesses[name] !== null) {
    // We already started this process
    return;
  }

  const childProcessPath = path.join(__dirname, name);
  const childProcessOptions: ForkOptions = {};
  if (!IS_DEV) {
    // There are problems when forking inside of an ASAR archive
    // See: https://github.com/electron/electron/issues/2708
    childProcessOptions.cwd = path.join(__dirname, "..", "..");
  }

  const childProcess = fork(childProcessPath, childProcessOptions);
  log.info(`Started the "${childProcessPath}" child process.`);

  childProcess.on("message", (message) => {
    // Pass the message to the renderer (browser) process
    // (we need to check to see if the window has been destroyed in the case where we get a message
    // from the child process after the window has already been destroyed)
    if (!window.isDestroyed()) {
      window.webContents.send(name, message);
    }
  });

  childProcess.on("error", (err) => {
    // Pass the error to the renderer (browser) process
    // (we need to check to see if the window has been destroyed in the case where we get a message
    // from the child process after the window has already been destroyed)
    if (!window.isDestroyed()) {
      window.webContents.send(name, `error: ${err}`);
    }
  });

  childProcess.on("exit", () => {
    // Pass the exit notification to the renderer (browser) process
    // (we need to check to see if the window has been destroyed in the case where we get a message
    // from the child process after the window has already been destroyed)
    if (!window.isDestroyed()) {
      window.webContents.send(name, "exited");
    }
  });

  childProcesses[name] = childProcess;
}

export function send(name: keyof ChildProcesses, msg: string): void {
  const childProcess = childProcesses[name];
  if (childProcess !== null) {
    childProcess.send(msg);
  }
}

export function exit(name: keyof ChildProcesses): void {
  const childProcess = childProcesses[name];
  if (childProcess !== null) {
    childProcess.send("exit");
  }
}

export function exitAll(): void {
  for (const childProcess of Object.values(childProcesses)) {
    if (childProcess !== null) {
      (childProcess as ChildProcess).send("exit");
    }
  }
}