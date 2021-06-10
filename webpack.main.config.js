/* eslint-disable @typescript-eslint/no-var-requires */

const path = require("path");
const getBaseConfig = require("./webpack.base.config");

const ELECTRON_TYPE = "main";
const BASE_PATH = path.join(__dirname, "src", ELECTRON_TYPE);
const CHILD_PROCESSES_PATH = path.join(BASE_PATH, "childProcesses");

const webpackConfig = getBaseConfig(ELECTRON_TYPE);

// Normally, webpack will bundle everything into a single JavaScript file
// Since we use subprocesses, we need to be able to invoke specific JavaScript files
// Thus, we use a name driven configuration
// https://stackoverflow.com/questions/40096470/get-webpack-not-to-bundle-files
webpackConfig.entry = {
  main: path.join(BASE_PATH, "main.ts"),
  steam: path.join(CHILD_PROCESSES_PATH, "steam.ts"),
  steamWatcher: path.join(CHILD_PROCESSES_PATH, "steamWatcher.ts"),
  isaac: path.join(CHILD_PROCESSES_PATH, "isaac.ts"),
};
webpackConfig.output = {
  path: path.join(__dirname, "dist", "main"),
  filename: "[name].js",
  sourceMapFilename: "[name].js.map",
};

// By default, "__dirname" will resolve to "/" in the main process,
// so we use this hack to restore it to what it is supposed to be
// https://github.com/webpack/webpack/issues/1599
webpackConfig.node = {
  __dirname: false,
};

module.exports = webpackConfig;
