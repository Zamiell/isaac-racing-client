import { g } from "./globals";
import { Screen } from "./types/Screen";

export function textUpdated(): void {
  if (g.currentScreen !== Screen.LOBBY && g.currentScreen !== Screen.RACE) {
    return;
  }

  if (!$(`#${g.currentScreen}-chat-box-input`).is(":focus")) {
    return;
  }

  g.tabCompleteCounter = 0;
  g.tabCompleteIndex = 0;
  g.tabCompleteWordList = null;
}
