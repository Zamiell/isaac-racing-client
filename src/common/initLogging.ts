import log from "electron-log";

export default function initLogging(): void {
  // The format is documented here:
  // https://github.com/megahertz/electron-log/blob/master/docs/format.md
  // Even though it looks like the level and text are squished together,
  // the "electron-log" library prepends a space to the text for some reason
  log.transports.console.format = "[{h}:{i}:{s}.{ms}] [{level}]{text}";
}
