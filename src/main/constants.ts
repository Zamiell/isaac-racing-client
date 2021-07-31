import * as electron from "electron";
import path from "path";

export const IS_DEV = !electron.app.isPackaged;
export const REBIRTH_STEAM_ID = 250900;
export const STATIC_PATH = path.join(__dirname, "..", "..", "static");
