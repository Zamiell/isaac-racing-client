import log from "electron-log";
import { execFile } from "node:child_process";
import path from "node:path";
import { STATIC_PATH } from "./constants";

export function isaacFocus(): void {
  if (process.platform !== "win32") {
    return;
  }

  const pathToFocusIsaac = path.join(
    STATIC_PATH,
    "programs",
    "focusIsaac",
    "focusIsaac.exe",
  );
  execFile(pathToFocusIsaac, (err) => {
    if (err !== null) {
      log.error(`Failed to focus Isaac: ${err.message}`);
    }
  });
}
