import log from "electron-log";
import { errorShow } from "./misc";

export default function debugFunction(): void {
  log.info("Entering debug function.");

  errorShow("", "isaac-path-modal");

  log.info("Exiting debug function.");
}
