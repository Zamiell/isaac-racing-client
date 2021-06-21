// This cannot be part of the "constants.ts" file because the "electron" module cannot be imported
// in the child processes

import * as electron from "electron";

const IS_DEV = !electron.app.isPackaged;
export default IS_DEV;
