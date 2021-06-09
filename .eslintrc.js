// This is the configuration file for ESLint, the TypeScript linter
// https://eslint.org/docs/user-guide/configuring
module.exports = {
  extends: [
    // The linter base is the shared IsaacScript config
    // https://github.com/IsaacScript/eslint-config-isaacscript/blob/main/base.js
    "eslint-config-isaacscript/base",
  ],

  /*
  env: {
    browser: true,
    node: true,
    es6: true,
    jquery: true,
  },
  */

  globals: {
    // Lang: true,
    // nodeRequire: true,
  },

  // Don't bother linting the compiled output
  ignorePatterns: ["./dist/**"],

  parserOptions: {
    // ESLint needs to know about the project's TypeScript settings in order for TypeScript-specific
    // things to lint correctly
    // We do not point this at "./tsconfig.json" because certain files (such at this file) should be
    // linted but not included in the actual project output
    project: "./tsconfig.eslint.json",
  },

  settings: {
    // This is needed in Electron projects to stop the following error:
    // 'electron' should be listed in the project's dependencies, not devDependencies
    "import/core-modules": ["electron"],
  },

  // We modify the base for some specific things
  rules: {
    "import/no-cycle": "off",
  },
};
