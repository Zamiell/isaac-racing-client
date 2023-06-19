// This is the configuration file for ESLint, the TypeScript linter:
// https://eslint.org/docs/latest/use/configure/

/** @type {import("eslint").Linter.Config} */
const config = {
  extends: [
    // The linter base is the shared IsaacScript config:
    // https://github.com/IsaacScript/isaacscript/blob/main/packages/eslint-config-isaacscript/base.js
    "eslint-config-isaacscript/base",
  ],

  // The ".prettierrc.cjs" file is ignored by default, so we have to un-ignore it. Additionally, we
  // don't bother linting the compiled output.
  // @template-ignore-next-line
  ignorePatterns: ["!.prettierrc.cjs", "**/dist/**", "*.min.js"],

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

    // @template-customization-end
  },
};

module.exports = config;
