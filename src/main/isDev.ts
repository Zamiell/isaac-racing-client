import * as electron from "electron";

const IS_DEV = !electron.app.isPackaged;
export default IS_DEV;
