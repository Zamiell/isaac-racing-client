// This is the configuration file for ESLint, the TypeScript linter:
// https://eslint.org/docs/latest/use/configure/

/** @type {import("eslint").Linter.Config} */
const config = {
  extends: [
    // The linter base is the shared IsaacScript config:
    // https://github.com/IsaacScript/isaacscript/blob/main/packages/eslint-config-isaacscript/base.js
    "eslint-config-isaacscript/base",
  ],

  // Don't bother linting the compiled output.
  // @template-ignore-next-line
  ignorePatterns: ["**/dist/**", "*.min.js"],

  parserOptions: {
    // ESLint needs to know about the project's TypeScript settings in order for TypeScript-specific
    // things to lint correctly. We do not point this at "./tsconfig.json" because certain files
    // (such at this file) should be linted but not included in the actual project output.
    project: "./tsconfig.eslint.json",
  },

  rules: {
    // Insert changed or disabled rules here, if necessary.

    // @template-customization-start
    /**
     * Documentation:
     * https://github.com/benmosher/eslint-plugin-import/blob/master/docs/rules/no-cycle.md
     *
     * Defined at:
     * https://github.com/airbnb/javascript/blob/master/packages/eslint-config-airbnb-base/rules/imports.js
     *
     * This project has cyclical dependencies.
     */
    "import/no-cycle": "off",

    /**
     * Documentation:
     * https://github.com/mysticatea/eslint-plugin-node/blob/master/docs/rules/file-extension-in-import.md
     *
     * Defined in "base.js".
     *
     * Electron does not support ESM yet.
     */
    "n/file-extension-in-import": "off",

    // We use old JQuery methods.
    "deprecation/deprecation": "off",

    // Electron is supposed to be in "devDependencies".
    "import/no-extraneous-dependencies": "off",
    "n/no-unpublished-import": "off",

    // TEMP: new rules
    "prefer-destructuring": "off",
    "@typescript-eslint/no-empty-function": "off",
    "isaacscript/consistent-enum-values": "off",
    "unicorn/consistent-function-scoping": "off",
    "unicorn/no-null": "off",
    "unicorn/prefer-add-event-listener": "off",
    "unicorn/prefer-module": "off",
    "unicorn/prefer-string-slice": "off",
    "unicorn/prefer-ternary": "off",

    // @template-customization-end
  },
};

module.exports = config;
