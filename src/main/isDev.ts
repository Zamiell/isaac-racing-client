import * as electron from "electron";

// This must be a separate file, otherwise the subprocesses will crash
export const IS_DEV = !electron.app.isPackaged;
