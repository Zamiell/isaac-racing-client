import * as electron from "electron";
import log from "electron-log";
import { parseIntSafe } from "../common/util";
import * as chat from "./chat";
import { FADE_TIME, IS_DEV, WEBSOCKET_URL } from "./constants";
import discordEmotes from "./discordEmotes";
import g from "./globals";
import * as isaac from "./ipc/isaac";
import * as socket from "./ipc/socket";
import {
  amSecondTestAccount,
  capitalize,
  errorShow,
  playSound,
  warningShow,
} from "./misc";
import * as modSocket from "./modSocket";
import ChatMessage from "./types/ChatMessage";
import Connection from "./types/Connection";
import Race from "./types/Race";
import RaceItem from "./types/RaceItem";
import Racer from "./types/Racer";
import RacerStatus from "./types/RacerStatus";
import RaceStatus from "./types/RaceStatus";
import User from "./types/User";
import * as lobbyScreen from "./ui/lobby";
import * as raceScreen from "./ui/race";
import * as registerScreen from "./ui/register";

export function connect(): void {
  log.info(
    "Successfully received a cookie from the server. Establishing a WebSocket connection to:",
    WEBSOCKET_URL,
  );

  // We have successfully authenticated with the server, so we no longer need the Greenworks process open
  if (g.steam.accountID !== null && g.steam.accountID > 0) {
    electron.ipcRenderer.send("asynchronous-message", "steamExit");
  }

  // Establish a WebSocket connection
  // It will automatically use the cookie that we received earlier
  // If the second argument is true, debugging is turned on
  const conn = new Connection(WEBSOCKET_URL, IS_DEV);
  g.conn = conn;

  initMiscHandlers(conn);
  initMiscCommandHandlers(conn);
  initChatCommandHandlers(conn);
  initRaceCommandHandlers(conn);
}

function initMiscHandlers(conn: Connection) {
  conn.on("open", () => {
    log.info("WebSocket connection established.");

    conn.send("roomJoin", {
      room: "lobby",
    });

    // If we are in development, skip Isaac checks and go directly to the lobby
    if (IS_DEV) {
      $("#title").fadeOut(FADE_TIME, () => {
        lobbyScreen.show();
      });
      return;
    }

    // Launch the process that will perform Isaac-related checks
    isaac.start();

    // Do the proper transition to the "File Checking" depending on where we logged in from
    if (g.currentScreen === "title-ajax") {
      g.currentScreen = "transition";
      $("#title").fadeOut(FADE_TIME, () => {
        showIsaacChecking();
      });
    } else if (g.currentScreen === "register-ajax") {
      g.currentScreen = "transition";
      $("#register").fadeOut(FADE_TIME, () => {
        registerScreen.reset();
        showIsaacChecking();
      });
    } else if (g.currentScreen === "error") {
      // If we are showing an error screen already, then don't bother going to the lobby
    } else {
      errorShow(
        `Can't transition to the lobby from screen: ${g.currentScreen}`,
      );
    }
  });

  conn.on("close", () => {
    log.info("WebSocket connection closed.");

    if (g.currentScreen === "error") {
      // The client is programmed to close the connection when an error occurs, so if we are already on the error screen, then we don't have to do anything else
    } else {
      // The WebSocket connection dropped because of a bad network connection or similar issue, so show the error screen
      errorShow(
        "Disconnected from the server. Either your Internet is having problems or the server went down!",
      );
    }
  });

  conn.on("socketError", (event) => {
    log.info("WebSocket error:", event);
    if (g.currentScreen === "title-ajax") {
      const error =
        "Failed to connect to the WebSocket server. The server might be down!";
      errorShow(error);
    } else if (g.currentScreen === "register-ajax") {
      const error =
        "Failed to connect to the WebSocket server. The server might be down!";
      const jqXHR = {
        // Emulate a jQuery error because that is what the "registerFail" function expects
        responseText: error,
      };
      registerScreen.fail(jqXHR as JQuery.jqXHR);
    } else {
      const error = "Encountered a WebSocket error. The server might be down!";
      errorShow(error);
    }
  });
}

function showIsaacChecking() {
  $("#file-checking").fadeIn(FADE_TIME, () => {
    g.currentScreen = "file-checking";
  });
}

function initMiscCommandHandlers(conn: Connection) {
  interface ErrorData {
    message: string;
  }

  // Sent if the server rejects a command;
  // we should completely reload the client since something may be out of sync
  conn.on("error", (data: ErrorData) => {
    errorShow(data.message);
  });

  interface WarningData {
    message: string;
  }

  // Sent if the server rejects a command,
  // but in a normal way that does not indicate that anything is out of sync
  conn.on("warning", (data: WarningData) => {
    if (
      data.message ===
      "Someone else has already claimed that stream URL. If you are the real owner of this stream, please contact an administrator."
    ) {
      g.stream.URL = g.stream.URLBeforeSubmit;
    }
    if (data.message === "That is not the correct password.") {
      g.currentScreen = "lobby";
    }
    warningShow(data.message);
  });

  interface SettingsData {
    userID: number;
    username: string;
    streamURL: string;
    twitchBotEnabled: boolean;
    twitchBotDelay: number;
  }

  // Sent after a successful connection
  conn.on("settings", (data: SettingsData) => {
    g.myUserID = data.userID;
    g.myUsername = data.username;
    g.stream.URL = data.streamURL === "-" ? "" : data.streamURL;
    g.stream.twitchBotEnabled = data.twitchBotEnabled;
    g.stream.twitchBotDelay = data.twitchBotDelay;

    if (IS_DEV && !amSecondTestAccount()) {
      // Start the local socket server
      // (this is normally started after Isaac-related checks are complete,
      // but since we are in development, we won't be doing those)
      socket.start();
    }
  });
}

function initChatCommandHandlers(conn: Connection) {
  interface RoomListData {
    room: string;
    users: User[];
  }

  conn.on("roomList", (data: RoomListData) => {
    // We entered a new room, so keep track of all users in this room
    const room = {
      users: new Map(),
      numUsers: 0,
      chatLine: 0,
      typedHistory: [],
      historyIndex: -1,
    };
    g.roomList.set(data.room, room);

    for (const user of data.users) {
      room.users.set(user.name, user);
    }
    room.numUsers = data.users.length;

    if (data.room === "lobby") {
      // Redraw the users list in the lobby
      lobbyScreen.usersDraw();
    } else if (data.room.startsWith("_race_")) {
      const match = /_race_(\d+)/.exec(data.room);
      if (match === null) {
        throw new Error(`Failed to parse the room name: ${data.room}`);
      }
      const raceIDString = match[1];
      const raceID = parseIntSafe(raceIDString);
      if (Number.isNaN(raceID)) {
        throw new Error(`Failed to parse the race ID: ${raceIDString}`);
      }
      if (raceID === g.currentRaceID) {
        // Update the online/offline markers
        for (let i = 0; i < data.users.length; i++) {
          raceScreen.markOnline(data.users[i]);
        }
      }
    }
  });

  interface RoomHistoryData {
    room: string;
    history: ChatMessage[];
  }

  conn.on("roomHistory", (data: RoomHistoryData) => {
    // Figure out what kind of chat room this is
    let destination;
    if (data.room === "lobby") {
      destination = "lobby";
    } else {
      destination = "race";
    }

    // Empty the existing chat room, since there might still be some chat in there from a previous race or session
    $(`#${destination}-chat-text`).html("");

    // Add all of the chat
    for (const chatMessage of data.history) {
      chat.draw(
        data.room,
        chatMessage.name,
        chatMessage.message,
        chatMessage.datetime,
      );
    }
  });

  interface RoomJoinedData {
    room: string;
    user: User;
  }

  conn.on("roomJoined", (data: RoomJoinedData) => {
    const room = g.roomList.get(data.room);
    if (room === undefined) {
      throw new Error(`Failed to find room: ${data.room}`);
    }

    // Keep track of the person who just joined
    room.users.set(data.user.name, data.user);
    room.numUsers += 1;

    // Redraw the users list in the lobby
    if (data.room === "lobby") {
      lobbyScreen.usersDraw();
    }

    // Send a chat notification
    if (data.room === "lobby") {
      if (data.user.name.startsWith("TestAccount")) {
        return; // Don't send notifications for test accounts connecting
      }

      const message = `${data.user.name} has connected.`;
      chat.draw(data.room, "!server", message);
      if (g.currentRaceID !== -1) {
        chat.draw(`_race_${g.currentRaceID}`, "!server", message);
      }
    } else {
      chat.draw(data.room, "!server", `${data.user.name} has joined the race.`);
    }
  });

  interface RoomLeftData {
    room: string;
    name: string;
  }

  conn.on("roomLeft", (data: RoomLeftData) => {
    const room = g.roomList.get(data.room);
    if (room === undefined) {
      throw new Error(`Failed to find room: ${data.room}`);
    }

    room.users.delete(data.name);
    room.numUsers -= 1;

    // Redraw the users list in the lobby
    if (data.room === "lobby") {
      lobbyScreen.usersDraw();
    }

    // Send a chat notification
    if (data.room === "lobby") {
      if (data.name.startsWith("TestAccount")) {
        return; // Don't send notifications for test accounts disconnecting
      }

      const message = `${data.name} has disconnected.`;
      chat.draw(data.room, "!server", message);
      if (g.currentRaceID !== -1) {
        chat.draw(`_race_${g.currentRaceID}`, "!server", message);
      }
    } else {
      chat.draw(data.room, "!server", `${data.name} has left the race.`);
    }
  });

  interface RoomUpdateData {
    room: string;
    user: User;
  }

  conn.on("roomUpdate", (data: RoomUpdateData) => {
    const room = g.roomList.get(data.room);
    if (room === undefined) {
      throw new Error(`Failed to find room: ${data.room}`);
    }

    // Keep track of the person who just joined
    room.users.set(data.user.name, data.user);

    // Redraw the users list in the lobby
    if (data.room === "lobby") {
      lobbyScreen.usersDraw();
    }
  });

  interface RoomMessageData {
    room: string;
    name: string;
    message: string;
  }

  conn.on("roomMessage", (data: RoomMessageData) => {
    chat.draw(data.room, data.name, data.message);
  });

  interface PrivateMessageData {
    name: string;
    message: string;
  }

  conn.on("privateMessage", (data: PrivateMessageData) => {
    chat.draw("PM-from", data.name, data.message);
  });

  interface DiscordMessageData {
    name: string;
    message: string;
  }

  // Used when someone types in the Discord server
  conn.on("discordMessage", discordMessage);
  function discordMessage(data: DiscordMessageData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        discordMessage(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    // Convert discord style emotes to Racing+ style emotes
    const words = data.message.split(" ");
    for (let i = 0; i < words.length; i++) {
      const word = words[i];
      const plainEnglishEmote = discordEmotes.get(word);
      if (plainEnglishEmote !== undefined) {
        words[i] = plainEnglishEmote;
      }
    }
    const newMessage = words.join(" ");

    // Send it to the lobby
    chat.draw("lobby", data.name, newMessage, null, true);
  }

  interface AdminMessageData {
    message: string;
  }

  // Used in the message of the day and other server broadcasts
  conn.on("adminMessage", adminMessage);
  function adminMessage(data: AdminMessageData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        adminMessage(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    // Send it to the lobby
    chat.draw("lobby", "!server", data.message);

    if (g.currentRaceID !== -1) {
      chat.draw(`_race_${g.currentRaceID}`, "!server", data.message);
    }
  }
}

function initRaceCommandHandlers(conn: Connection) {
  // On initial connection, we get a list of all of the races that are currently open or ongoing
  conn.on("raceList", (data: Race[]) => {
    // Check for empty races
    if (data.length === 0) {
      $("#lobby-current-races-table-body").html("");
      $("#lobby-current-races-table").fadeOut(0);
      $("#lobby-current-races-table-no").fadeIn(0);
    }

    // Go through the list of races that were sent
    let mostCurrentRaceID = -1;
    for (let i = 0; i < data.length; i++) {
      // Keep track of what races are currently going
      const race = data[i];
      const raceID = race.id;
      g.raceList.set(raceID, race);
      race.racerList = [];

      // Update the "Current races" area
      lobbyScreen.raceDraw(data[i]);

      // Start the callback for the lobby timer
      lobbyScreen.statusTimer(raceID);

      // Check to see if we are in any races
      for (const racer of race.racers) {
        if (racer === g.myUsername) {
          mostCurrentRaceID = raceID;
          break;
        }
      }
    }

    if (mostCurrentRaceID !== -1) {
      // This is normally set at the top of the raceScreen.show function, but we need to set it now since we have to delay
      g.currentRaceID = mostCurrentRaceID;
      setTimeout(() => {
        raceScreen.show(mostCurrentRaceID);
      }, FADE_TIME * 3); // Account for fade out and fade in, then add account for some lag
    }
  });

  interface RacerListData {
    id: number;
    racers: Racer[];
  }

  // Sent when we create a race or reconnect in the middle of a race
  conn.on("racerList", (data: RacerListData) => {
    // Store the racer list
    const race = g.raceList.get(data.id);
    if (race === undefined) {
      throw new Error(`Failed to find race: ${data.id}`);
    }
    race.racerList = data.racers;

    // Build the table with the race participants on the race screen
    $("#race-participants-table-body").html("");
    for (let i = 0; i < race.racerList.length; i++) {
      raceScreen.participantAdd(i);
    }

    if (race.status === "in progress") {
      // If the race is in progress, we are coming back after a disconnect
      // Write this to the save.dat file so that it does not reset us in the middle of the run
      modSocket.send("set", `status ${race.status}`);
      log.info("Coming back after a disconnect.");
    }

    // Now that we know the places of the racers,
    // we can update the mod with some additional information
    modSocket.sendExtraValues();
  });

  conn.on("raceCreated", connRaceCreated);
  function connRaceCreated(data: Race) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRaceCreated(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    // Keep track of what races are currently going
    const race = data;
    g.raceList.set(race.id, race);

    // Update the "Current races" area
    lobbyScreen.raceDraw(race);

    // Send a chat notification if we did not create this race and this is not a solo race
    if (race.captain !== g.myUsername && !race.ruleset.solo) {
      const message = `${data.captain} has started a new race.`;
      chat.draw("lobby", "!server", message);
      if (g.currentRaceID !== -1) {
        chat.draw(`_race_${g.currentRaceID}`, "!server", message);
      }
    }

    // Play the "race created" sound effect if applicable
    let shouldPlaySound = false;
    if (g.currentScreen === "lobby") {
      shouldPlaySound = true;
    } else if (g.currentScreen === "race" && !g.raceList.has(g.currentRaceID)) {
      shouldPlaySound = true;
    }
    if (data.ruleset.solo || data.isPasswordProtected) {
      // Don't play sounds for solo races or password-protected races
      shouldPlaySound = false;
    }
    if (shouldPlaySound) {
      playSound("race-created");
    }
  }

  interface RaceJoinedData {
    id: number;
    name: string;
  }

  conn.on("raceJoined", connRaceJoined);
  function connRaceJoined(data: RaceJoinedData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRaceJoined(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      return;
    }

    // Keep track of the people in each race
    race.racers.push(data.name);

    // Update the row for this race in the lobby
    lobbyScreen.raceUpdatePlayers(data.id);

    if (data.name === g.myUsername) {
      // If we joined this race
      raceScreen.show(data.id);
    } else if (data.id === g.currentRaceID) {
      // We are in this race, so add this racer to the racerList with all default values (defaults)
      const datetime = new Date().getTime();
      race.racerList.push({
        name: data.name,
        datetimeJoined: datetime,
        status: "not ready",
        floorNum: 0,
        stageType: 0,
        datetimeArrivedFloor: 0,
        items: [],
        startingItem: 0,
        characterNum: 0,
        place: 0,
        placeMid: -1,
        datetimeFinished: 0,
        runTime: 0,
        comment: "",
      });

      // Update the race screen
      raceScreen.participantAdd(race.racerList.length - 1);

      g.modSocket.numReady = modSocket.getNumReady(race);
      modSocket.send("set", `numReady ${g.modSocket.numReady}`);
      g.modSocket.numEntrants = race.racerList.length;
      modSocket.send("set", `numEntrants ${g.modSocket.numEntrants}`);
    }
  }

  interface RaceLeftData {
    id: number;
    name: string;
  }

  conn.on("raceLeft", connRaceLeft);
  function connRaceLeft(data: RaceLeftData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRaceLeft(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      throw new Error(`Failed to find race: ${data.id}`);
    }

    // Find out if we are in this race
    let inThisRace = false;
    if (race.racers.includes(g.myUsername)) {
      inThisRace = true;
    }

    // Delete this person from the "racers" array
    if (race.racers.includes(data.name)) {
      race.racers.splice(race.racers.indexOf(data.name), 1);
    } else {
      errorShow(
        `"${data.name}" left race #${data.id}, but they were not in the "racers" array.`,
      );
      return;
    }

    // If we are in this race, we also need to delete this person them from the "racerList" array
    if (inThisRace) {
      let foundRacer = false;
      for (let i = 0; i < race.racerList.length; i++) {
        if (data.name === race.racerList[i].name) {
          foundRacer = true;
          race.racerList.splice(i, 1);
          break;
        }
      }
      if (!foundRacer) {
        errorShow(
          `"${data.name}" left race #${data.id}, but they were not in the "racerList" array.`,
        );
        return;
      }
    }

    // Update the "Current races" area on the lobby
    if (race.racers.length === 0) {
      // Delete the race since the last person in the race left
      g.raceList.delete(data.id);
      lobbyScreen.raceUndraw(data.id);
    } else {
      // Check to see if this person was the captain, and if so, make the next person in line the captain
      if (race.captain === data.name) {
        race.captain = race.racers[0];
      }

      // Update the row for this race in the lobby
      lobbyScreen.raceUpdatePlayers(data.id);
    }

    // If we left the race
    if (data.name === g.myUsername) {
      // Show the lobby
      lobbyScreen.showFromRace();
      return;
    }

    // If this is the current race
    if (data.id === g.currentRaceID) {
      // Remove the row for this player
      $(`#race-participants-table-${data.name}`).remove();

      // Fix the bug where the "vertical-center" class causes things to be hidden if there is overflow
      if (race.racerList.length > 6) {
        // More than 6 races causes the overflow
        $("#race-participants-table-wrapper").removeClass("vertical-center");
      } else {
        $("#race-participants-table-wrapper").addClass("vertical-center");
      }

      if (race.status === "open") {
        // Update the captain
        // [not implemented]
      }

      // Update the mod
      g.modSocket.numReady = modSocket.getNumReady(race);
      modSocket.send("set", `numReady ${g.modSocket.numReady}`);
      g.modSocket.numEntrants = race.racerList.length;
      modSocket.send("set", `numEntrants ${g.modSocket.numEntrants}`);
    }
  }

  interface RaceSetStatusData {
    id: number;
    status: RaceStatus;
  }

  conn.on("raceSetStatus", connRaceSetStatus);
  function connRaceSetStatus(data: RaceSetStatusData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRaceSetStatus(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      return;
    }

    // Update the status
    race.status = data.status;

    // Check to see if we are in this race
    if (data.id === g.currentRaceID) {
      // Update the status of the race in the Lua mod
      // (we will update the status to "in progress" manually when the countdown reaches 0)
      // (and we don't care if the race finishes because we will set the "save#.dat" file to
      // defaults once we personally finish or quit the race)
      if (data.status !== "in progress" && data.status !== "finished") {
        g.modSocket.status = data.status;
        modSocket.send("set", `status ${g.modSocket.status}`);
      }

      // Do different things depending on the status
      if (data.status === "starting") {
        // Update the status column in the race title
        $("#race-title-status").html(
          '<span class="circle lobby-current-races-starting"></span> &nbsp; <span lang="en">Starting</span>',
        );

        // Start the countdown
        raceScreen.startCountdown();
      } else if (data.status === "in progress") {
        // Do nothing; after the countdown is finished, the race controls will automatically fade in
      } else if (data.status === "finished") {
        // Update the status column in the race title
        $("#race-title-status").html(
          '<span class="circle lobby-current-races-finished"></span> &nbsp; <span lang="en">Finished</span>',
        );

        // Remove the race controls
        $("#race-quit-button-container").fadeOut(FADE_TIME);
        $("#race-controls-padding").fadeOut(FADE_TIME);
        $("#race-num-left-container").fadeOut(FADE_TIME, () => {
          $("#race-countdown").css("font-size", "1.75em");
          $("#race-countdown").css("bottom", "0.25em");
          $("#race-countdown").css("color", "#e89980");
          $("#race-countdown").html('<span lang="en">Race completed</span>!');
          $("#race-countdown").fadeIn(FADE_TIME);
        });

        // Play the "race completed!" sound effect (for multiplayer races)
        if (!race.ruleset.solo) {
          playSound("race-completed", 1300);
        }
      } else {
        errorShow(
          `Failed to parse the status of race #${data.id}: ${data.status}`,
        );
      }
    }

    // Update the "Status" column in the lobby
    let circleClass;
    if (data.status === "open") {
      circleClass = "open";
    } else if (data.status === "starting") {
      circleClass = "starting";
      $(`#lobby-current-races-${data.id}`).removeClass("lobby-race-row-open");
      $(`#lobby-current-races-${data.id}`).unbind();
    } else if (data.status === "in progress") {
      circleClass = "in-progress";
    } else if (data.status === "finished") {
      // Delete the race
      g.raceList.delete(data.id);
      lobbyScreen.raceUndraw(data.id);
    } else {
      errorShow(
        "Unable to parse the race status from the raceSetStatus command.",
      );
    }
    $(`#lobby-current-races-${data.id}-status-circle`).removeClass();
    $(`#lobby-current-races-${data.id}-status-circle`).addClass(
      `circle lobby-current-races-${circleClass}`,
    );
    $(`#lobby-current-races-${data.id}-status`).html(
      `<span lang="en">${capitalize(data.status)}</span>`,
    );

    if (data.status === "in progress") {
      // Keep track of when the race starts
      const now = new Date().getTime();
      race.datetimeStarted = now;

      // Start the callback for timers
      lobbyScreen.statusTimer(data.id);
    }

    // Remove the race if it is finished
    if (data.status === "finished") {
      g.raceList.delete(data.id);
    }
  }

  interface RacerSetStatusData {
    id: number;
    name: string;
    status: RacerStatus;
    place: number;
    runTime: number;
  }

  conn.on("racerSetStatus", connRacerSetStatus);
  function connRacerSetStatus(data: RacerSetStatusData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRacerSetStatus(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    // We don't care about racer updates for a race that is not showing on the current screen
    if (data.id !== g.currentRaceID) {
      return;
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      return;
    }

    // Find the player in the racerList
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];
      if (data.name === racer.name) {
        // Update their status and place locally
        racer.status = data.status;
        racer.place = data.place;
        racer.runTime = data.runTime;

        // Update the race screen
        if (g.currentScreen === "race") {
          raceScreen.participantsSetStatus(i);
        }

        break;
      }
    }

    if (data.name === g.myUsername) {
      g.modSocket.myStatus = data.status;
      modSocket.send("set", `myStatus ${g.modSocket.myStatus}`);
      g.modSocket.place = data.place;
      modSocket.send("set", `place ${g.modSocket.place}`);
    }

    if (race.status === "open") {
      g.modSocket.numReady = modSocket.getNumReady(race);
      modSocket.send("set", `numReady ${g.modSocket.numReady}`);
    }
  }

  interface RaceStartData {
    id: number;
    secondsToWait: number;
  }

  conn.on("raceStart", connRaceStart);
  function connRaceStart(data: RaceStartData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRaceStart(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    // Check to see if this message actually applies to the race that is showing on the screen
    if (data.id !== g.currentRaceID) {
      errorShow(
        'Got a "raceStart" command for a race that is not the current race.',
      );
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      return;
    }

    // Keep track of when the race starts
    const now = new Date().getTime();
    const millisecondsToWait = data.secondsToWait * 1000;
    race.datetimeStarted = now + millisecondsToWait;

    // Schedule the countdown
    if (race.ruleset.solo) {
      // Solo races start in 3 seconds, so schedule a countdown that starts with 3 immediately
      setTimeout(() => {
        raceScreen.countdownTick(3);
      }, 0);
    } else {
      // Multiplayer races start in 10 seconds, so schedule a countdown that starts with 5 in 5 seconds
      const timeToStartCountdown = millisecondsToWait - 5000 - FADE_TIME;
      setTimeout(() => {
        raceScreen.countdownTick(5);
      }, timeToStartCountdown);
    }
  }

  interface RacerSetFloorData {
    id: number;
    name: string;
    floorNum: number;
    stageType: number;
    datetimeArrivedFloor: number;
  }

  conn.on("racerSetFloor", connRacerSetFloor);
  function connRacerSetFloor(data: RacerSetFloorData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRacerSetFloor(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    if (data.id !== g.currentRaceID) {
      return;
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      return;
    }

    // Find the player in the racerList
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];
      if (data.name === racer.name) {
        // Update their place and floor locally
        racer.floorNum = data.floorNum;
        racer.stageType = data.stageType;
        racer.datetimeArrivedFloor = data.datetimeArrivedFloor;

        const isAltStage = data.stageType === 4 || data.stageType === 5;
        if (data.floorNum === 1 && !isAltStage) {
          // Delete their items, since they reset
          racer.items = [];
          racer.startingItem = 0;

          // Update the race screen
          if (g.currentScreen === "race") {
            raceScreen.participantsSetStartingItem(i);
          }
        }

        // Update the race screen
        if (g.currentScreen === "race") {
          raceScreen.participantsSetFloor(i);
        }

        break;
      }
    }
  }

  interface RacerSetPlaceMidData {
    id: number;
    name: string;
    placeMid: number;
  }

  conn.on("racerSetPlaceMid", connRacerSetPlaceMid);
  function connRacerSetPlaceMid(data: RacerSetPlaceMidData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRacerSetPlaceMid(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    if (data.id !== g.currentRaceID) {
      return;
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      return;
    }

    // Find the player in the racerList
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];
      if (data.name === racer.name) {
        // Update their placeMid locally
        racer.placeMid = data.placeMid;

        // Update the race screen
        if (g.currentScreen === "race") {
          raceScreen.participantsSetPlaceMid(i);
        }

        break;
      }
    }

    if (data.name === g.myUsername) {
      modSocket.send("set", `placeMid ${data.placeMid}`);
    }
  }

  interface RacerAddItemData {
    id: number;
    name: string;
    item: RaceItem;
  }

  conn.on("racerAddItem", connRacerAddItem);
  function connRacerAddItem(data: RacerAddItemData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRacerAddItem(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    if (data.id !== g.currentRaceID) {
      return;
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      return;
    }

    // Find the player in the racerList
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];
      if (data.name === racer.name) {
        racer.items.push(data.item);
        break;
      }
    }
  }

  interface RacerSetStartingItemData {
    id: number;
    name: string;
    item: RaceItem;
  }

  conn.on("racerSetStartingItem", connRacerSetStartingItem);
  function connRacerSetStartingItem(data: RacerSetStartingItemData) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRacerSetStartingItem(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    if (data.id !== g.currentRaceID) {
      return;
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      return;
    }

    // Find the player in the racerList
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];
      if (data.name === racer.name) {
        racer.startingItem = data.item.id;

        // Update the race screen
        if (g.currentScreen === "race") {
          raceScreen.participantsSetStartingItem(i);
        }

        break;
      }
    }
  }

  interface RacerCharacter {
    id: number;
    name: string;
    characterNum: number;
  }

  conn.on("racerCharacter", connRacerCharacter);
  function connRacerCharacter(data: RacerCharacter) {
    if (g.currentScreen === "transition") {
      // Come back when the current transition finishes
      setTimeout(() => {
        connRacerCharacter(data);
      }, FADE_TIME + 5); // 5 milliseconds of leeway
      return;
    }

    if (data.id !== g.currentRaceID) {
      return;
    }

    const race = g.raceList.get(data.id);
    if (race === undefined) {
      return;
    }

    // Find the player in the racerList
    for (let i = 0; i < race.racerList.length; i++) {
      const racer = race.racerList[i];
      if (data.name === racer.name) {
        racer.characterNum = data.characterNum;
        break;
      }
    }
  }

  conn.on("achievement", connAchievement);
  function connAchievement(_data: unknown) {}
}
