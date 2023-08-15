import * as electron from "electron";
import log from "electron-log";
import { REBIRTH_STEAM_ID } from "./constants";

export function launchIsaac(): void {
  electron.shell
    .openExternal(`steam://rungameid/${REBIRTH_STEAM_ID}`)
    .catch((error) => {
      log.error(`Failed to open Isaac: ${error}`);
    });
}
