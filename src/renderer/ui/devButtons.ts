import * as electron from "electron";
import { FADE_TIME, IS_DEV } from "../constants";
import g from "../globals";
import login from "../login";

export function init(): void {
  if (!IS_DEV) {
    return;
  }

  // Don't automatically log in with our Steam account
  // We want to choose from a list of login options
  $("#title-ajax").fadeOut(0);
  $("#title-choose").fadeIn(0);

  $("#title-choose-steam").click(() => {
    loginDebug(null);
  });

  for (let i = 1; i <= 10; i++) {
    $(`#title-choose-${i}`).click(() => {
      loginDebug(i);
    });
  }

  $("#title-restart").click(() => {
    // Restart the client
    electron.ipcRenderer.send("asynchronous-message", "restart");
  });
}

function loginDebug(account: number | null) {
  if (g.currentScreen !== "title-ajax") {
    return;
  }

  $("#title-choose").fadeOut(FADE_TIME, () => {
    $("#title-ajax").fadeIn(FADE_TIME);
  });

  if (account === null) {
    // A normal login
    electron.ipcRenderer.send("asynchronous-message", "steam");
  } else {
    // A manual login that does not rely on Steam authentication
    g.steam.id = `-${account}`;
    g.steam.accountID = 0;
    g.steam.screenName = `TestAccount${account}`;
    g.steam.ticket = "debug";
    login();
  }
}
