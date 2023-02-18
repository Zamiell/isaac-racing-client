/* eslint-disable */

// Fix for 3rd-party scripts inside Electron:
// https://stackoverflow.com/questions/32621988/electron-jquery-is-not-defined
if (typeof module === "object") {
  window.module = module;
  module = undefined;
}
