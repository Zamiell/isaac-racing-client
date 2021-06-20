import { execFile } from "child_process";
import log from "electron-log";
import path from "path";
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
      log.error(`Failed to focus Isaac: ${err}`);
    }
  });
}
