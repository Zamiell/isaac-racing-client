import * as electron from "electron";
import log from "electron-log";
import linkifyHtml from "linkifyjs/html";
import { parseIntSafe } from "../common/util";
import { FADE_TIME, IS_DEV } from "./constants";
import debugFunction from "./debugFunction";
import g from "./globals";
import { errorShow, escapeHTML, warningShow } from "./misc";

const CHAT_INDENT_SIZE = "3.2em";

export function send(destination: string): void {
  // Don't do anything if we are not on the screen corresponding to the chat input form
  if (destination === "lobby" && g.currentScreen !== "lobby") {
    return;
  }
  if (destination === "race" && g.currentScreen !== "race") {
    return;
  }

  // Get values from the form
  const element = document.getElementById(
    `${destination}-chat-box-input`,
  ) as HTMLInputElement | null;
  if (element === null) {
    throw new Error("Failed to find the chat element.");
  }
  let message = element.value.trim();

  // Do nothing if the input field is empty
  if (message === "") {
    return;
  }

  // If this is a command
  let isCommand = false;
  let isPM = false;
  let chatArg1;
  let chatArg2;
  if (message.startsWith("/")) {
    isCommand = true;

    // First, for any formatted command, validate that it is formatted correctly
    if (
      /^\/p\b/.exec(message) !== null ||
      /^\/pm\b/.exec(message) !== null ||
      /^\/m\b/.exec(message) !== null ||
      /^\/msg\b/.exec(message) !== null ||
      /^\/w\b/.exec(message) !== null ||
      /^\/whisper\b/.exec(message) !== null ||
      /^\/t\b/.exec(message) !== null ||
      /^\/tell\b/.exec(message) !== null
    ) {
      isPM = true;

      // Validate that private messages have a recipient
      const m = /^\/\w+ (.+?) (.+)/.exec(message);
      if (m !== null) {
        [, chatArg1, chatArg2] = m; // recipient, message
      } else {
        warningShow(
          '<span lang="en">The format of a private message is</span>: <code>/pm Alice hello</code>',
        );
        return;
      }

      // Get the current list of connected users
      const userList = [];
      const roomLobby = g.roomList.get("lobby");
      if (roomLobby === undefined) {
        throw new Error("Failed to get the lobby room.");
      }
      for (const user of roomLobby.users.keys()) {
        userList.push(user);
      }

      // Validate that the recipient is online
      let isConnected = false;
      for (let i = 0; i < userList.length; i++) {
        if (chatArg1.toLowerCase() === userList[i].toLowerCase()) {
          isConnected = true;
          chatArg1 = userList[i];
        }
      }
      if (!isConnected) {
        warningShow("That user is not currently online.");
        return;
      }
    } else if (/^\/notice\b/.exec(message) !== null) {
      // Validate that there is an attached message
      const m = /^\/\w+ (.+)/.exec(message);
      if (m !== null) {
        [, chatArg1] = m;
      } else {
        warningShow(
          '<span lang="en">The format of a notice is</span>: <code>/notice Hey guys!</code>',
        );
        return;
      }
    } else if (/^\/ban\b/.exec(message) !== null) {
      // Validate that ban commands have a recipient and a reason
      const m = /^\/ban (.+?) (.+)/.exec(message);
      if (m !== null) {
        [, chatArg1, chatArg2] = m; // recipient, reason
      } else {
        warningShow(
          '<span lang="en">The format of a ban is</span>: <code>/ban Krak being too Polish</code>',
        );
        return;
      }
    } else if (/^\/unban\b/.exec(message) !== null) {
      // Validate that unban commands have a recipient
      const m = /^\/unban (.+)/.exec(message);
      if (m !== null) {
        [, chatArg1] = m;
      } else {
        warningShow(
          '<span lang="en">The format of an unban is</span>: <code>/unban Krak</code>',
        );
        return;
      }
    } else if (/^\/r\b/.exec(message) !== null) {
      // Check if the user is replying to a message
      isPM = true;

      // Validate that a PM has been received already
      if (g.lastPM === null) {
        warningShow("No PMs have been received yet.");
        return;
      }

      const m = /^\/r (.+)/.exec(message);
      if (m !== null) {
        chatArg1 = g.lastPM;
        [, chatArg2] = m;
      } else {
        warningShow("The format of a reply is: <code>/r [message]</code>");
        return;
      }
    } else if (/^\/floor\b/.exec(message) !== null) {
      // Validate that unban commands have a recipient
      const m = /^\/floor (\d+) (\d+)/.exec(message);
      if (m !== null) {
        [, chatArg1, chatArg2] = m; // stage, stage type
      } else {
        warningShow(
          '<span lang="en">The format of a floor command is</span>: <code>/floor [stage] [stageType]</code>',
        );
        return;
      }
    }
  }

  // Erase the contents of the input field
  $(`#${destination}-chat-box-input`).val("");

  // Truncate messages longer than 150 characters (this is also enforced server-side)
  if (message.length > 150) {
    message = message.substring(0, 150);
  }

  // Get the room
  let room;
  if (destination === "lobby") {
    room = "lobby";
  } else if (destination === "race") {
    room = `_race_${g.currentRaceID}`;
  } else {
    throw new Error("Failed to parse the destination.");
  }

  if (g.conn === null) {
    throw new Error("The WebSocket connection was null.");
  }

  const storedRoom = g.roomList.get(room);
  if (storedRoom === undefined) {
    return;
  }

  // Add it to the history so that we can use up arrow later
  storedRoom.typedHistory.unshift(message);

  // Reset the history index
  storedRoom.historyIndex = -1;

  if (!isCommand) {
    // If this is a normal chat message
    g.conn.send("roomMessage", {
      room,
      message,
    });
  } else if (isPM) {
    if (chatArg1 === undefined) {
      throw new Error("Failed to parse chatArg1.");
    }

    if (chatArg2 === undefined) {
      throw new Error("Failed to parse chatArg2.");
    }

    // If this is a PM (which has many aliases)
    g.conn.send("privateMessage", {
      name: chatArg1,
      message: chatArg2,
    });

    // We won't get a message back from the server if the sending of the PM was successful,
    // so manually call the draw function now
    draw("PM-to", chatArg1, chatArg2);
  } else if (message === "/debug1") {
    // /debug1 - Debug command for the client
    debugFunction();
  } else if (message === "/debug2") {
    // /debug2 - Debug command for the server
    log.info("Sending debug command.");
    g.conn.send("debug", {});
  } else if (message === "/restart") {
    // /restart - Restart the client
    electron.ipcRenderer.send("asynchronous-message", "restart");
  } else if (message === "/finish") {
    // /finish - Debug finish
    if (IS_DEV) {
      g.conn.send("raceFinish", {
        id: g.currentRaceID,
      });
    }
  } else if (message === "/ready") {
    if (IS_DEV) {
      g.conn.send("raceReady", {
        id: g.currentRaceID,
      });
    }
  } else if (message === "/unready") {
    if (IS_DEV) {
      g.conn.send("raceUnready", {
        id: g.currentRaceID,
      });
    }
  } else if (message === "/shutdown") {
    // We want to automatically restart the server by default
    g.conn.send("adminShutdown", {
      comment: "restart",
    });
  } else if (message === "/shutdown2") {
    // This will not automatically restart the server
    g.conn.send("adminShutdown", {});
  } else if (message === "/unshutdown") {
    g.conn.send("adminUnshutdown", {});
  } else if (message.startsWith("/notice ")) {
    g.conn.send("adminMessage", {
      message: chatArg1,
    });
  } else if (message.startsWith("/ban ")) {
    g.conn.send("adminBan", {
      name: chatArg1,
      comment: chatArg2,
    });
  } else if (message.startsWith("/unban ")) {
    g.conn.send("adminUnban", {
      name: chatArg1,
    });
  } else if (message.startsWith("/floor ")) {
    if (chatArg1 === undefined) {
      throw new Error("Failed to parse chatArg1.");
    }

    if (chatArg2 === undefined) {
      throw new Error("Failed to parse chatArg2.");
    }

    g.conn.send("raceFloor", {
      id: g.currentRaceID,
      floorNum: parseIntSafe(chatArg1),
      stageType: parseIntSafe(chatArg2),
    });
  } else if (message.startsWith("/checkpoint")) {
    g.conn.send("raceItem", {
      id: g.currentRaceID,
      itemID: 560,
    });
  } else {
    // Manually call the draw function
    draw(room, "_error", "That is not a valid command.");
  }
}

export function draw(
  room: string,
  name: string,
  message: string,
  datetime: number | null = null,
  discord = false,
): void {
  // Check for errors
  let error = false;
  if (name === "_error") {
    error = true;
  }

  // Check for the existence of a PM
  let privateMessage: string | null = null;
  if (room === "PM-to") {
    privateMessage = "to";
  } else if (room === "PM-from") {
    privateMessage = "from";
    g.lastPM = name;
  }
  if (room === "PM-to" || room === "PM-from") {
    if (g.currentScreen === "lobby") {
      room = "lobby"; // eslint-disable-line no-param-reassign
    } else if (g.currentScreen === "race") {
      room = `_race_${g.currentRaceID}`; // eslint-disable-line no-param-reassign
    } else {
      setTimeout(() => {
        draw(room, name, message, datetime);
      }, FADE_TIME + 5);
    }
  }

  // Don't show messages that are not for the current race
  if (room.startsWith("_race_")) {
    const match = /_race_(\d+)/.exec(room);
    if (match === null) {
      throw new Error("Failed to parse the race ID from the room.");
    }
    const raceIDString = match[1];
    const raceID = parseIntSafe(raceIDString);
    if (raceID !== g.currentRaceID) {
      return;
    }
  }

  // Make sure that the room still exists in the roomList
  const storedRoom = g.roomList.get(room);
  if (storedRoom === undefined) {
    return;
  }

  // Keep track of how many lines of chat have been spoken in this room
  storedRoom.chatLine += 1;

  // Sanitize the input
  message = escapeHTML(message); // eslint-disable-line no-param-reassign

  // Check for links and insert them if present (using Linkify)
  // eslint-disable-next-line no-param-reassign
  message = linkifyHtml(message, {
    attributes: (href, _type) => ({
      onclick: `nodeRequire('electron').shell.openExternal('${href}');`,
    }),
    formatHref: (_href, _type) => "#",
    target: "_self",
  });

  // Check for emotes and insert them if present
  message = fillEmotes(message); // eslint-disable-line no-param-reassign

  // Get the hours and minutes from the time
  let date;
  if (datetime === null) {
    date = new Date();
  } else {
    date = new Date(datetime * 1000);
  }
  const hours = date.getHours();
  let hoursString = hours.toString();
  if (hours < 10) {
    hoursString = `0${hours}`;
  }
  const minutes = date.getMinutes();
  let minutesString = minutes.toString();
  if (minutes < 10) {
    minutesString = `0${minutes}`;
  }

  // Construct the chat line
  let chatLine = `<div id="${room}-chat-text-line-${storedRoom.chatLine}" class="hidden">`;
  chatLine += `<span id="${room}-chat-text-line-${storedRoom.chatLine}-header">`;
  chatLine += `[${hoursString}:${minutesString}] &nbsp; `;

  if (discord) {
    chatLine += '<span class="chat-discord">[Discord]</span> &nbsp; ';
  }

  if (error) {
    // The "chat-pm" class will make it red
    chatLine += '<span class="chat-pm">[ERROR]</span> ';
  } else if (privateMessage !== null) {
    chatLine += `<span class="chat-pm">[PM ${privateMessage} <strong class="chat-pm">${name}</strong>]</span> &nbsp; `;
  } else if (name !== "!server") {
    chatLine += `&lt;<strong>${name}</strong>&gt; &nbsp; `;
  }
  chatLine += "</span>";

  if (name === "!server") {
    chatLine += `<span class="chat-server">${message}</span>`;
  } else {
    chatLine += message;
  }
  chatLine += "</div>";

  // Find out whether this is going to "#race-chat-text" or "#lobby-chat-text"
  let destination;
  if (room === "lobby") {
    destination = "lobby";
  } else if (room.startsWith("_race_")) {
    destination = "race";
  } else {
    errorShow('Failed to parse the room in the "chat.draw" function.');
  }

  const destinationElement = $(`#${destination}-chat-text`);

  // Find out if we should automatically scroll down after adding the new line of chat
  let autoScroll = false;
  const destinationElementHeight = destinationElement.height();
  if (destinationElementHeight === undefined) {
    throw new Error("Failed to get the height of the destination element.");
  }
  let bottomPixel =
    destinationElement.prop("scrollHeight") - destinationElementHeight;
  if (destinationElement.scrollTop() === bottomPixel) {
    // If we are already scrolled to the bottom, then it is ok to automatically scroll
    autoScroll = true;
  }

  // Add the new line
  if (datetime === null) {
    destinationElement.append(chatLine);
  } else {
    // We prepend instead of append because the chat history comes in order from most recent to least recent
    destinationElement.prepend(chatLine);
  }
  $(`#${room}-chat-text-line-${storedRoom.chatLine}`).fadeIn(FADE_TIME);

  // Set indentation for long lines
  if (room === "lobby") {
    // Indent the text to the "<Username>" to signify that it is a continuation of the last line
    $(`#${room}-chat-text-line-${storedRoom.chatLine}`).css(
      "padding-left",
      CHAT_INDENT_SIZE,
    );
    $(`#${room}-chat-text-line-${storedRoom.chatLine}`).css(
      "text-indent",
      `-${CHAT_INDENT_SIZE}`,
    );
  }

  // Automatically scroll
  if (autoScroll) {
    const destinationElementHeight2 = destinationElement.height();
    if (destinationElementHeight2 === undefined) {
      throw new Error("Failed to get the height of the destination element.");
    }
    bottomPixel =
      destinationElement.prop("scrollHeight") - destinationElementHeight2;
    $(`#${destination}-chat-text`).scrollTop(bottomPixel);
  }
}

export function indentAll(room: string): void {
  const storedRoom = g.roomList.get(room);
  if (storedRoom === undefined) {
    return;
  }

  for (let i = 1; i <= storedRoom.chatLine; i++) {
    // If this line overflows, indent it to the "<Username>" to signify that it is a continuation of the last line
    $(`#${room}-chat-text-line-${i}`).css("padding-left", CHAT_INDENT_SIZE);
    $(`#${room}-chat-text-line-${i}`).css(
      "text-indent",
      `-${CHAT_INDENT_SIZE}`,
    );
  }
}

function fillEmotes(message: string): string {
  // Search through the text for each emote
  for (let i = 0; i < g.emoteList.length; i++) {
    if (message.indexOf(g.emoteList[i]) !== -1) {
      const emoteTag = `<img class="chat-emote" src="img/emotes/${g.emoteList[i]}.png" title="${g.emoteList[i]}" />`;
      const re = new RegExp(`\\b${g.emoteList[i]}\\b`, "g"); // "\b" is a word boundary in regex
      message = message.replace(re, emoteTag); // eslint-disable-line no-param-reassign
    }
  }

  // Special emotes that don't match the filenames
  if (message.indexOf("&lt;3") !== -1) {
    const emoteTag =
      '<img class="chat-emote" src="img/emotes2/3.png" title="&lt;3" />';
    const re = new RegExp("&lt;3", "g"); // "\b" is a word boundary in regex
    message = message.replace(re, emoteTag); // eslint-disable-line no-param-reassign
  }
  if (message.indexOf(":thinking:") !== -1) {
    const emoteTag =
      '<img class="chat-emote" src="img/emotes2/thinking.svg" title=":thinking:" />';
    const re = new RegExp(":thinking:", "g"); // "\b" is a word boundary in regex
    message = message.replace(re, emoteTag); // eslint-disable-line no-param-reassign
  }

  return message;
}
