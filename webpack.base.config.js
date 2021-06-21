/* eslint-disable @typescript-eslint/no-var-requires */

// It is possible for the webpack configuration to be written in TypeScript,
// but this will not work with the full range of options in "tsconfig.json"
// Keep the config file written in JavaScript for simplicity

const path = require("path");

function getBaseConfig(electronType) {
  return {
    mode: "development",
    entry: path.join(__dirname, "src", electronType, "main.ts"),
    target: `electron-${electronType}`,

    module: {
      rules: [
        {
          test: /\.ts$/,
          include: [
            path.join(__dirname, "src", electronType),
            path.join(__dirname, "src", "common"),
          ],
          use: [{ loader: "ts-loader" }],
        },
        {
          test: /\.node$/,
          loader: "node-loader",
        },
      ],
    },

    output: {
      path: path.join(__dirname, "dist", electronType),
      filename: "main.js",
    },

    // .js is needed for libraries (Electron itself, winston, etc.)
    // .json is needed to import JSON files in the "data" directory
    resolve: {
      extensions: [".js", ".ts", ".json"],
    },

    // Enable source maps for debugging purposes
    // (this will show the line number of the real file in the browser console)
    devtool: "source-map",
  };
}

module.exports = getBaseConfig;
