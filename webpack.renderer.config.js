/* eslint-disable @typescript-eslint/no-var-requires */

const getBaseConfig = require("./webpack.base.config");

const ELECTRON_TYPE = "renderer";

const webpackConfig = getBaseConfig(ELECTRON_TYPE);

module.exports = webpackConfig;
