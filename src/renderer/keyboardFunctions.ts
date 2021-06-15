import * as electron from "electron";
import { IS_DEV } from "./constants";
import g from "./globals";
import { textUpdated } from "./keyboardSubroutines";
import { closeAllTooltips } from "./misc";

const functionMap = new Map<number, (event: JQuery.KeyDownEvent) => void>();
export default functionMap;

// `
functionMap.set(192, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === "title-ajax" && IS_DEV) {
    event.preventDefault();
    $("#title-choose-steam").click();
  }
});

// 1
functionMap.set(49, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === "title-ajax" && IS_DEV) {
    event.preventDefault();
    $("#title-choose-1").click();
  }
});

// 2
functionMap.set(50, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === "title-ajax" && IS_DEV) {
    event.preventDefault();
    $("#title-choose-2").click();
  }
});

// 3
functionMap.set(51, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === "title-ajax" && IS_DEV) {
    event.preventDefault();
    $("#title-choose-3").click();
  }
});

// "r"
functionMap.set(82, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === "title-ajax" && IS_DEV) {
    event.preventDefault();
    $("#title-restart").click();
  }
});

// F12
functionMap.set(123, (_event: JQuery.KeyDownEvent) => {
  electron.ipcRenderer.send("asynchronous-message", "devTools");
});

// Tab
functionMap.set(9, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen !== "lobby" && g.currentScreen !== "race") {
    return;
  }

  if (!$(`#${g.currentScreen}-chat-box-input`).is(":focus")) {
    return;
  }

  event.preventDefault();

  let tabList: string[] = [];

  // Add the current list of connected users
  const lobbyUsers = g.roomList.get("lobby");
  if (lobbyUsers === undefined) {
    throw new Error("Failed to get the lobby room.");
  }
  for (const user of lobbyUsers.users.values()) {
    tabList.push(user.name);
  }

  // Add emotes
  tabList = tabList.concat(g.emoteList);
  tabList.push(":thinking:"); // Also add some custom emotes to the tab completion list
  tabList.sort();

  // Prioritize the more commonly used NotLikeThis over NootLikeThis
  const notLikeThisIndex = tabList.indexOf("NotLikeThis");
  const nootLikeThisIndex = tabList.indexOf("NootLikeThis");
  tabList[notLikeThisIndex] = "NootLikeThis";
  tabList[nootLikeThisIndex] = "NotLikeThis";

  // Prioritize the more commonly used Kappa over Kadda
  const kappaIndex = tabList.indexOf("Kappa");
  const kaddaIndex = tabList.indexOf("Kadda");
  tabList[kaddaIndex] = "Kappa";
  tabList[kappaIndex] = "Kadda";

  // Prioritize the more commonly used FrankerZ over all other Franker emotes
  const frankerZIndex = tabList.indexOf("FrankerZ");
  const frankerBIndex = tabList.indexOf("FrankerB");
  let tempEmote1 = tabList[frankerBIndex];
  tabList[frankerBIndex] = "FrankerZ";
  for (let i = frankerBIndex; i < frankerZIndex; i++) {
    const tempEmote2 = tabList[i + 1];
    tabList[i + 1] = tempEmote1;
    tempEmote1 = tempEmote2;
  }

  if (g.tabCompleteCounter === 0) {
    firstTimePressingTab(tabList);
  } else {
    tabCycle(tabList);
  }
});

function firstTimePressingTab(tabList: string[]) {
  // This is the first time we are pressing tab
  const element = $(`#${g.currentScreen}-chat-box-input`);
  let message = element.val();
  if (typeof message !== "string") {
    return;
  }
  message = message.trim();
  g.tabCompleteWordList = message.split(" ");
  const messageEnd = g.tabCompleteWordList[g.tabCompleteWordList.length - 1];
  for (let i = 0; i < tabList.length; i++) {
    const tabWord = tabList[i];
    const temp = tabWord.slice(0, messageEnd.length).toLowerCase();
    if (temp === messageEnd.toLowerCase()) {
      g.tabCompleteIndex = i;
      g.tabCompleteCounter += 1;
      let newMessage = "";
      for (let j = 0; j < g.tabCompleteWordList.length - 1; j++) {
        newMessage += g.tabCompleteWordList[j];
        newMessage += " ";
      }
      newMessage += tabWord;
      $(`#${g.currentScreen}-chat-box-input`).val(newMessage);
      break;
    }
  }
}

function tabCycle(tabList: string[]) {
  if (g.tabCompleteWordList === null) {
    return;
  }

  // We have already pressed tab once and we need to cycle through the rest of the autocompletion words
  let index = g.tabCompleteCounter + g.tabCompleteIndex;
  const messageEnd = g.tabCompleteWordList[g.tabCompleteWordList.length - 1];
  if (g.tabCompleteCounter >= tabList.length) {
    g.tabCompleteCounter = 0;
    $(`#${g.currentScreen}-chat-box-input`).val(messageEnd);
    index = g.tabCompleteCounter + g.tabCompleteIndex;
  }
  const tempSlice = tabList[index].slice(0, messageEnd.length).toLowerCase();
  if (tempSlice === messageEnd.toLowerCase()) {
    g.tabCompleteCounter += 1;
    let newMessage = "";
    for (let i = 0; i < g.tabCompleteWordList.length - 1; i++) {
      newMessage += g.tabCompleteWordList[i];
      newMessage += " ";
    }
    newMessage += tabList[index];
    $(`#${g.currentScreen}-chat-box-input`).val(newMessage);
  } else {
    g.tabCompleteCounter = 0;
    let newMessage = "";
    for (let i = 0; i < g.tabCompleteWordList.length - 1; i++) {
      newMessage += g.tabCompleteWordList[i];
      newMessage += " ";
    }
    newMessage += messageEnd;
    $(`#${g.currentScreen}-chat-box-input`).val(newMessage);
  }
}

// Backspace
functionMap.set(8, (_event: JQuery.KeyDownEvent) => {
  textUpdated();
});

// Enter
functionMap.set(13, (event: JQuery.KeyDownEvent) => {
  textUpdated();

  if (
    g.currentScreen === "lobby" &&
    $("#header-new-race").tooltipster("status").open
  ) {
    event.preventDefault();
    $("#new-race-form").submit();
  }
});

// Space
functionMap.set(32, (_event: JQuery.KeyDownEvent) => {
  textUpdated();
});

// Esc
functionMap.set(27, (_event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === "lobby") {
    closeAllTooltips();
  } else if (g.currentScreen === "race") {
    $("#header-lobby").click();
  }
});

// Up arrow
functionMap.set(38, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen !== "lobby" && g.currentScreen !== "race") {
    return;
  }

  if (!$(`#${g.currentScreen}-chat-box-input`).is(":focus")) {
    return;
  }

  event.preventDefault();

  let room;
  if (g.currentScreen === "lobby") {
    room = "lobby";
  } else if (g.currentScreen === "race") {
    room = `_race_${g.currentRaceID}`;
  } else {
    throw new Error("Failed to get the room.");
  }

  const storedRoom = g.roomList.get(room);
  if (storedRoom === undefined) {
    throw new Error(`Failed to get the room: ${room}`);
  }

  storedRoom.historyIndex += 1;

  // Check to see if we have reached the end of the history list
  if (storedRoom.historyIndex > storedRoom.typedHistory.length - 1) {
    storedRoom.historyIndex -= 1;
    return;
  }

  // Set the chat input box to what we last typed
  const retrievedHistory = storedRoom.typedHistory[storedRoom.historyIndex];
  $(`#${g.currentScreen}-chat-box-input`).val(retrievedHistory);
});

// Down arrow
functionMap.set(40, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen !== "lobby" && g.currentScreen !== "race") {
    return;
  }

  if (!$(`#${g.currentScreen}-chat-box-input`).is(":focus")) {
    return;
  }

  event.preventDefault();

  let room;
  if (g.currentScreen === "lobby") {
    room = "lobby";
  } else if (g.currentScreen === "race") {
    room = `_race_${g.currentRaceID}`;
  } else {
    throw new Error("Failed to get the room.");
  }

  const storedRoom = g.roomList.get(room);
  if (storedRoom === undefined) {
    throw new Error(`Failed to get the room: ${room}`);
  }

  storedRoom.historyIndex -= 1;

  // Check to see if we have reached the beginning of the history list
  if (storedRoom.historyIndex <= -2) {
    // -2 instead of -1 here because we want down arrow to clear the chat
    storedRoom.historyIndex = -1;
    return;
  }

  // Set the chat input box to what we last typed
  const retrievedHistory = storedRoom.typedHistory[storedRoom.historyIndex];
  $(`#${g.currentScreen}-chat-box-input`).val(retrievedHistory);
});

// e
functionMap.set(69, (event: JQuery.KeyDownEvent) => {
  if (event.altKey) {
    if (g.currentScreen === "lobby") {
      $("#header-new-race").click();
    }
  }
});

// s
functionMap.set(83, (event: JQuery.KeyDownEvent) => {
  if (event.altKey) {
    if (g.currentScreen === "lobby") {
      $("#header-settings").click();
    }
  }
});

// l
functionMap.set(76, (event: JQuery.KeyDownEvent) => {
  if (event.altKey) {
    if (g.currentScreen === "race") {
      $("#header-lobby").click();
    }
  }
});
