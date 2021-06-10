// If something goes wrong in a child process, the main process will never know unless we explicitly
// send the error backwards
export function handleErrors(): void {
  process.on("uncaughtException", childError);
}

export function childError(err: Error): void {
  if (process.send !== undefined) {
    // We have to exit the process in a callback because "process.send()" is asynchronous
    // Otherwise, the program would be exited before the send was completed
    process.send(`error: ${err}`, processExit);
  }
}

export function processExit(): void {
  process.exit();
}
