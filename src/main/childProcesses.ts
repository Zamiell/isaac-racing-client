import { ChildProcess, fork } from "child_process";
import * as electron from "electron";
import log from "electron-log";
import path from "path";
import * as file from "../common/file";
import IS_DEV from "./isDev";

// Any new child processes also have to be added to the webpack config in "webpack.main.config.js"
interface ChildProcesses {
  steam: ChildProcess | null;
  steamWatcher: ChildProcess | null;
  isaac: ChildProcess | null;
  socket: ChildProcess | null;
}

const childProcesses: ChildProcesses = {
  steam: null,
  steamWatcher: null,
  isaac: null,
  socket: null,
};

export function start(
  name: keyof ChildProcesses,
  window: electron.BrowserWindow,
): void {
  if (childProcesses[name] !== null) {
    // We already started this process
    return;
  }

  let childProcessPath;
  if (IS_DEV) {
    childProcessPath = path.join(__dirname, "childProcesses", `${name}.js`);
  } else {
    // Forking inside of an ASAR archive is broken as of 2021
    // https://github.com/electron/electron/issues/16382
    // To work around this, we specify the child process to not packed inside of the ASAR archive by
    // using the "asarUnpack" option in the "package.json" file
    // This places the files in the following directory:
    // C:\Users\[Username]\AppData\Local\Programs\isaac-racing-client\resources\app.asar.unpacked\dist\main\childProcesses
    // Our current working directory at this point is:
    // C:\Users\[Username]\AppData\Local\Programs\isaac-racing-client\resources\app.asar\dist\main
    childProcessPath = path.join(
      __dirname,
      "..",
      "..",
      "..",
      "app.asar.unpacked",
      "dist",
      "main",
      "childProcesses",
      `${name}.js`,
    );
  }

  if (!file.exists(childProcessPath) || !file.isFile(childProcessPath)) {
    log.error(
      `Failed to find the file for the child process of "${name}": ${childProcessPath}`,
    );
    return;
  }

  const childProcess = fork(childProcessPath);
  log.info(`Started the "${name}" child process: ${childProcessPath}`);

  childProcess.on("message", (message) => {
    // Don't print messages from the socket server to avoid spamming the log file
    if (name !== "socket") {
      log.info(
        `Main process received message from the "${name}" child process: ${message}`,
      );
    }

    // Pass the message to the renderer (browser) process
    // (we need to check to see if the window has been destroyed in the case where we get a message
    // from the child process after the window has already been destroyed)
    if (!window.isDestroyed()) {
      window.webContents.send(name, message);
    }
  });

  childProcess.on("error", (err) => {
    log.info(
      `Main process received error from the "${name}" child process: ${err}`,
    );

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
