import * as electron from "electron";
import { IS_DEV } from "./constants";
import { g } from "./globals";
import { textUpdated } from "./keyboardSubroutines";
import { Screen } from "./types/Screen";
import { closeAllTooltips } from "./utils";

export const keyboardFunctionMap = new Map<
  number,
  (event: JQuery.KeyDownEvent) => void
>();

// `
keyboardFunctionMap.set(192, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === Screen.TITLE_AJAX && IS_DEV) {
    event.preventDefault();
    $("#title-choose-steam").click();
  }
});

// 1
keyboardFunctionMap.set(49, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === Screen.TITLE_AJAX && IS_DEV) {
    event.preventDefault();
    $("#title-choose-1").click();
  }
});

// 2
keyboardFunctionMap.set(50, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === Screen.TITLE_AJAX && IS_DEV) {
    event.preventDefault();
    $("#title-choose-2").click();
  }
});

// 3
keyboardFunctionMap.set(51, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === Screen.TITLE_AJAX && IS_DEV) {
    event.preventDefault();
    $("#title-choose-3").click();
  }
});

// "r"
keyboardFunctionMap.set(82, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === Screen.TITLE_AJAX && IS_DEV) {
    event.preventDefault();
    $("#title-restart").click();
  }
});

// F12
keyboardFunctionMap.set(123, (_event: JQuery.KeyDownEvent) => {
  electron.ipcRenderer.send("asynchronous-message", "devTools");
});

// Tab
keyboardFunctionMap.set(9, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen !== Screen.LOBBY && g.currentScreen !== Screen.RACE) {
    return;
  }

  if (!$(`#${g.currentScreen}-chat-box-input`).is(":focus")) {
    return;
  }

  event.preventDefault();

  let tabList: string[] = [];

  // Add the current list of connected users.
  const lobbyUsers = g.roomList.get("lobby");
  if (lobbyUsers === undefined) {
    throw new Error("Failed to get the lobby room.");
  }
  for (const user of lobbyUsers.users.values()) {
    tabList.push(user.name);
  }

  // Add emotes
  tabList = [...tabList, ...g.emoteList];
  tabList.push(":thinking:"); // Also add some custom emotes to the tab completion list
  tabList.sort();

  // Prioritize the more commonly used NotLikeThis over NootLikeThis.
  const notLikeThisIndex = tabList.indexOf("NotLikeThis");
  const nootLikeThisIndex = tabList.indexOf("NootLikeThis");
  tabList[notLikeThisIndex] = "NootLikeThis";
  tabList[nootLikeThisIndex] = "NotLikeThis";

  // Prioritize the more commonly used Kappa over Kadda.
  const kappaIndex = tabList.indexOf("Kappa");
  const kaddaIndex = tabList.indexOf("Kadda");
  tabList[kaddaIndex] = "Kappa";
  tabList[kappaIndex] = "Kadda";

  // Prioritize the more commonly used FrankerZ over all other Franker emotes.
  const frankerZIndex = tabList.indexOf("FrankerZ");
  const frankerBIndex = tabList.indexOf("FrankerB");
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  let tempEmote1 = tabList[frankerBIndex]!;
  tabList[frankerBIndex] = "FrankerZ";
  for (let i = frankerBIndex; i < frankerZIndex; i++) {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    const tempEmote2 = tabList[i + 1]!;
    tabList[i + 1] = tempEmote1;
    tempEmote1 = tempEmote2;
  }

  if (g.tabCompleteCounter === 0) {
    firstTimePressingTab(tabList);
  } else {
    tabCycle(tabList);
  }
});

function firstTimePressingTab(tabList: readonly string[]) {
  // This is the first time we are pressing tab.
  const element = $(`#${g.currentScreen}-chat-box-input`);
  let message = element.val();
  if (typeof message !== "string") {
    return;
  }
  message = message.trim();
  g.tabCompleteWordList = message.split(" ");
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const messageEnd = g.tabCompleteWordList.at(-1)!;
  for (const [i, tabWord] of tabList.entries()) {
    const temp = tabWord.slice(0, messageEnd.length).toLowerCase();
    if (temp === messageEnd.toLowerCase()) {
      g.tabCompleteIndex = i;
      g.tabCompleteCounter++;
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

function tabCycle(tabList: readonly string[]) {
  if (g.tabCompleteWordList === null) {
    return;
  }

  // We have already pressed tab once and we need to cycle through the rest of the autocompletion
  // words.
  let index = g.tabCompleteCounter + g.tabCompleteIndex;
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const messageEnd = g.tabCompleteWordList.at(-1)!;
  if (g.tabCompleteCounter >= tabList.length) {
    g.tabCompleteCounter = 0;
    $(`#${g.currentScreen}-chat-box-input`).val(messageEnd);
    index = g.tabCompleteCounter + g.tabCompleteIndex;
  }
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const tempSlice = tabList[index]!.slice(0, messageEnd.length).toLowerCase();
  if (tempSlice === messageEnd.toLowerCase()) {
    g.tabCompleteCounter++;
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
keyboardFunctionMap.set(8, (_event: JQuery.KeyDownEvent) => {
  textUpdated();
});

// Enter
keyboardFunctionMap.set(13, (event: JQuery.KeyDownEvent) => {
  textUpdated();

  if (
    g.currentScreen === Screen.LOBBY &&
    $("#header-new-race").tooltipster("status").open
  ) {
    event.preventDefault();
    $("#new-race-form").submit();
  }
});

// Space
keyboardFunctionMap.set(32, (_event: JQuery.KeyDownEvent) => {
  textUpdated();
});

// Esc
keyboardFunctionMap.set(27, (_event: JQuery.KeyDownEvent) => {
  if (g.currentScreen === Screen.LOBBY) {
    closeAllTooltips();
  } else if (g.currentScreen === Screen.RACE) {
    $("#header-lobby").click();
  }
});

// Up arrow
keyboardFunctionMap.set(38, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen !== Screen.LOBBY && g.currentScreen !== Screen.RACE) {
    return;
  }

  if (!$(`#${g.currentScreen}-chat-box-input`).is(":focus")) {
    return;
  }

  event.preventDefault();

  const room =
    g.currentScreen === Screen.LOBBY ? "lobby" : `_race_${g.currentRaceID}`;

  const storedRoom = g.roomList.get(room);
  if (storedRoom === undefined) {
    throw new Error(`Failed to get the room: ${room}`);
  }

  storedRoom.historyIndex++;

  // Check to see if we have reached the end of the history list.
  if (storedRoom.historyIndex > storedRoom.typedHistory.length - 1) {
    storedRoom.historyIndex--;
    return;
  }

  // Set the chat input box to what we last typed.
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const retrievedHistory = storedRoom.typedHistory[storedRoom.historyIndex]!;
  $(`#${g.currentScreen}-chat-box-input`).val(retrievedHistory);
});

// Down arrow
keyboardFunctionMap.set(40, (event: JQuery.KeyDownEvent) => {
  if (g.currentScreen !== Screen.LOBBY && g.currentScreen !== Screen.RACE) {
    return;
  }

  if (!$(`#${g.currentScreen}-chat-box-input`).is(":focus")) {
    return;
  }

  event.preventDefault();

  const room =
    g.currentScreen === Screen.LOBBY ? "lobby" : `_race_${g.currentRaceID}`;

  const storedRoom = g.roomList.get(room);
  if (storedRoom === undefined) {
    throw new Error(`Failed to get the room: ${room}`);
  }

  storedRoom.historyIndex--;

  // Check to see if we have reached the beginning of the history list.
  if (storedRoom.historyIndex <= -2) {
    // -2 instead of -1 here because we want down arrow to clear the chat.
    storedRoom.historyIndex = -1;
    return;
  }

  // Set the chat input box to what we last typed.
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
  const retrievedHistory = storedRoom.typedHistory[storedRoom.historyIndex]!;
  $(`#${g.currentScreen}-chat-box-input`).val(retrievedHistory);
});

// e
keyboardFunctionMap.set(69, (event: JQuery.KeyDownEvent) => {
  if (event.altKey && g.currentScreen === Screen.LOBBY) {
    $("#header-new-race").click();
  }
});

// s
keyboardFunctionMap.set(83, (event: JQuery.KeyDownEvent) => {
  if (event.altKey && g.currentScreen === Screen.LOBBY) {
    $("#header-settings").click();
  }
});

// l
keyboardFunctionMap.set(76, (event: JQuery.KeyDownEvent) => {
  if (event.altKey && g.currentScreen === Screen.RACE) {
    $("#header-lobby").click();
  }
});
