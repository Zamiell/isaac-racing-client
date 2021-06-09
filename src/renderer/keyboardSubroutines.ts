import g from "./globals";

export function textUpdated(): void {
  if (g.currentScreen !== "lobby" && g.currentScreen !== "race") {
    return;
  }

  if (!$(`#${g.currentScreen}-chat-box-input`).is(":focus")) {
    return;
  }

  g.tabCompleteCounter = 0;
  g.tabCompleteIndex = 0;
  g.tabCompleteWordList = null;
}
