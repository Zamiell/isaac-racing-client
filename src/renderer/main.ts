// Racing+ Client
// for The Binding of Isaac: Repentance
// (renderer process)

import * as electron from "electron";
import log from "electron-log";
import path from "path";
import pkg from "../../package.json";
import * as file from "../common/file";
import initLogging from "../common/initLogging";
import * as automaticUpdate from "./automaticUpdate";
import { IS_DEV } from "./constants";
import g from "./globals";
import * as isaac from "./ipc/isaac";
import * as socket from "./ipc/socket";
import * as steam from "./ipc/steam";
import * as steamWatcher from "./ipc/steamWatcher";
import * as keyboard from "./keyboard";
import * as localization from "./localization";
import Item from "./types/Item";
import * as devButtons from "./ui/devButtons";
import * as header from "./ui/header";
import * as lobbyScreen from "./ui/lobby";
import * as modals from "./ui/modals";
import * as newRaceTooltip from "./ui/newRaceTooltip";
import * as raceScreen from "./ui/race";
import * as registerScreen from "./ui/register";
import * as settingsTooltip from "./ui/settingsTooltip";

const DATA_PATH = path.join(__dirname, "data");

initLogging();

$(() => {
  printWelcomeMessage();

  // Version
  const versionString = `v${pkg.version}`;
  $("#title-version").html(versionString);
  $("#settings-version").html(versionString);

  initData();

  // Main
  automaticUpdate.init();
  keyboard.init();
  localization.init();

  // UI
  devButtons.init();
  header.init();
  lobbyScreen.init();
  modals.init();
  newRaceTooltip.init();
  raceScreen.init();
  registerScreen.init();
  settingsTooltip.init();

  // IPC
  isaac.init();
  socket.init();
  steam.init();
  steamWatcher.init();

  log.info("Renderer initialization completed.");

  if (IS_DEV) {
    // Automatically log in with account #1
    // $("#title-choose-1").click();
  } else {
    // Tell the main process to start the child process that will initialize Greenworks
    // That process will get our Steam ID, Steam screen name, and authentication ticket
    electron.ipcRenderer.send("asynchronous-message", "steam");
  }
});

function printWelcomeMessage() {
  const welcomeText = `Racing+ client ${pkg.version} started.`;
  const hyphens = "-".repeat(welcomeText.length);
  const welcomeTextBorder = `+-${hyphens}-+`;
  log.info(welcomeTextBorder);
  log.info(`| ${welcomeText} |`);
  log.info(welcomeTextBorder);
}

function initData() {
  // Word list
  const wordListPath = path.join(DATA_PATH, "word-list.txt");
  const wordListString = file.read(wordListPath);
  g.wordList = wordListString.split("\n");

  // Item list
  const itemListPath = path.join(DATA_PATH, "items.json");
  const itemListString = file.read(itemListPath);
  g.itemList = JSON.parse(itemListString) as Record<string, Item>;

  // Emote list
  const emotePath = path.join(__dirname, "img", "emotes");
  g.emoteList = file.getDirList(emotePath);
  for (let i = 0; i < g.emoteList.length; i++) {
    // Remove ".png" from each element of emoteList
    g.emoteList[i] = g.emoteList[i].slice(0, -4); // ".png" is 4 characters long
  }
}
