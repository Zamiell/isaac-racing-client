import winston from "winston";
import "winston-daily-rotate-file";

const log = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json(),
  ),
  transports: [
    new winston.transports.Console(),

    // https://github.com/winstonjs/winston-daily-rotate-file
    new winston.transports.DailyRotateFile({
      filename: "RacingPlus-%DATE%.log",
      datePattern: "YYYY-MM-DD",
      zippedArchive: true,
      maxFiles: "14d",
    }),
  ],
});

export default log;

/*
let logRoot;
if (isDev) {
  // In development, "__dirname" is:
  // "C:\Repositories\isaac-racing-client\src"
  // We want the log file in the root of the repository
  logRoot = path.join(__dirname, '..');
} else if (process.platform === 'darwin') {
  // We want the log file in the macOS user's "Logs" directory
  logRoot = path.join(os.homedir(), 'Library', 'Logs');
} else {
  // On a bundled Windows app, "__dirname" is:
  // "C:\Users\[Username]\AppData\Local\Programs\RacingPlus\resources\app.asar\src"
  // We want the log file in the "Programs" directory
  logRoot = path.join(__dirname, '..', '..', '..', '..');
}
*/
