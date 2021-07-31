import * as electron from "electron";

// This must be a separate file, otherwise the subprocesses will crash
const IS_DEV = !electron.app.isPackaged;
export default IS_DEV;
