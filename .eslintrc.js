// This is the configuration file for ESLint, the TypeScript linter
// https://eslint.org/docs/user-guide/configuring
module.exports = {
  extends: [
    // The linter base is the shared IsaacScript config
    // https://github.com/IsaacScript/eslint-config-isaacscript/blob/main/base.js
    "eslint-config-isaacscript/base",
  ],

  ignorePatterns: [
    "dist/**", // Don't bother linting the compiled output
    "src/main/lib/greenworks.js", // Don't bother linting the Greenworks library
  ],

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
    // Documentation:
    // https://github.com/benmosher/eslint-plugin-import/blob/master/docs/rules/no-cycle.md
    // Defined at:
    // https://github.com/airbnb/javascript/blob/master/packages/eslint-config-airbnb-base/rules/imports.js
    // Unfortunately, this project has cyclical dependencies
    "import/no-cycle": "off",

    // Documentation:
    // https://github.com/benmosher/eslint-plugin-import/blob/master/docs/rules/no-unused-modules.md
    // Not defined in parent configs
    // This helps to find dead code that should be deleted
    "import/no-unused-modules": [
      "error",
      {
        missingExports: true,
        unusedExports: true,
        ignoreExports: [
          "src/**/*.d.ts",
          ".eslintrc.js",
          "webpack.*.config.js",
          "src/main/main.ts",
          "src/renderer/main.ts",
        ],
      },
    ],
  },
};
