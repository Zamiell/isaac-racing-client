import settings from "../../common/settings";
import { FADE_TIME } from "../constants";
import g from "../globals";

export function init(): void {
  const tutorial = settings.get("tutorial");
  if (tutorial === "true") {
    $("#title-buttons").fadeOut(0);
    $("#title-buttons-tutorial").fadeIn(0);
  }

  initEventHandlers();
}

function initEventHandlers() {
  $("#title-tutorial-button").click(() => {
    if (g.currentScreen !== "title-ajax") {
      return;
    }
    g.currentScreen = "transition";
    $("#title").fadeOut(FADE_TIME, () => {
      $("#tutorial1").fadeIn(FADE_TIME, () => {
        g.currentScreen = "tutorial1";
      });
    });
  });

  $("#tutorial1-next-button").click(() => {
    if (g.currentScreen !== "tutorial1") {
      return;
    }
    g.currentScreen = "transition";
    $("#tutorial1").fadeOut(FADE_TIME, () => {
      $("#tutorial2").fadeIn(FADE_TIME, () => {
        g.currentScreen = "tutorial2";
      });
    });
  });

  $("#tutorial2-next-button").click(() => {
    if (g.currentScreen !== "tutorial2") {
      return;
    }
    g.currentScreen = "transition";
    $("#tutorial2").fadeOut(FADE_TIME, () => {
      // Mark that we have completed the tutorial
      settings.set("tutorial", "false");

      // Change the title screen to the default
      $("#title-buttons-tutorial").fadeOut(0);
      $("#title-buttons").fadeIn(0);

      // Return to the title screen
      $("#title").fadeIn(FADE_TIME, () => {
        g.currentScreen = "title-ajax";
      });
    });
  });
}
