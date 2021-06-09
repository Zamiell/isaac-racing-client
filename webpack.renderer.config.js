/* eslint-disable @typescript-eslint/no-var-requires */

const path = require("path");
const getBaseConfig = require("./webpack.base.config");

const ELECTRON_TYPE = "renderer";

const webpackConfig = getBaseConfig(ELECTRON_TYPE);

module.exports = webpackConfig;
