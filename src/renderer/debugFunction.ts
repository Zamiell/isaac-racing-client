import log from "electron-log";

export default function debugFunction(): void {
  log.info("Entering debug function.");

  log.info("Exiting debug function.");
}
