/* eslint-disable @typescript-eslint/no-var-requires */

const path = require("path");
const getBaseConfig = require("./webpack.base.config");

const ELECTRON_TYPE = "main";

const webpackConfig = getBaseConfig(ELECTRON_TYPE);

// By default, "__dirname" will resolve to "/" in the main process,
// so we use this hack to restore it to what it is supposed to be
// https://github.com/webpack/webpack/issues/1599
webpackConfig.node = {
  __dirname: false,
};

module.exports = webpackConfig;
