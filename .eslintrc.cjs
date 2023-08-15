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

    // We use old JQuery methods.
    "deprecation/deprecation": "off",

    // This project has cyclical dependencies.
    "import/no-cycle": "off",

    // Electron is supposed to be in "devDependencies".
    "import/no-extraneous-dependencies": "off",

    // This project uses IsaacScript-style enum members so that it can be consistent with the mod.
    "isaacscript/consistent-enum-values": "off",

    // Electron does not support ESM yet.
    "n/file-extension-in-import": "off",

    // Electron is supposed to be in "devDependencies".
    "n/no-unpublished-import": "off",

    // This project uses null.
    "unicorn/no-null": "off",

    // This project uses legacy methods for event listening.
    "unicorn/prefer-add-event-listener": "off",

    // This rule throws too many false positives.
    "prefer-destructuring": "off",

    // Electron does not support ESM yet.
    "unicorn/prefer-module": "off",

    // This rule throws too many false positives.
    "unicorn/prefer-ternary": "off",

    // @template-customization-end
  },
};

module.exports = config;
