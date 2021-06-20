import log from "electron-log";

export default function initLogging(): void {
  // Even though it looks like the level and text are squished together,
  // the "electron-log" library prepends a space to the text for some reason
  log.transports.console.format = "[{h}:{i}:{s}] [{level}]{text}";
}
