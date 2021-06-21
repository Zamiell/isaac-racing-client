/* eslint-disable import/no-unused-modules */

// Child process that initializes the Steamworks API and generates a login ticket

import path from "path";
import * as file from "../../common/file";
import SteamMessage from "../../common/types/SteamMessage";
import { REBIRTH_STEAM_ID } from "../constants";
import Greenworks, { SteamIDObject, TicketObject } from "../types/Greenworks";
import { childError, handleErrors, processExit } from "./subroutines";

handleErrors();
init();

function init() {
  process.on("message", onMessage);
  greenworksInit();
}

function onMessage(message: string) {
  // The child will stay alive even if the parent has closed,
  // so we depend on the parent telling us when to die
  // We need to stay alive until authentication is over,
  // but killed after that so we it will not interfere with launching Isaac
  // (Greenworks uses the same AppID as Isaac, so Steam gets confused)
  if (message === "exit") {
    process.exit();
  }
}

function greenworksInit() {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  // Create the "steam_appid.txt" that Greenworks expects to find in:
  //   C:\Users\[Username]\AppData\Local\Programs\RacingPlus\steam_appid.txt (in production)
  //   or
  //   C:\Repositories\isaac-racing-client\steam_appid.txt (in development)
  // 570660 is the Steam app ID for The Binding of Isaac: Rebirth
  const steamAppIDPath = "steam_appid.txt";
  file.write(steamAppIDPath, REBIRTH_STEAM_ID.toString());

  // In order for the Greenworks library to work, we have to exempt it from being packed inside of
  // the ASAR archive via the "asarUnpack" property of the "package.json" file
  // The library is located in the "static" directory
  // The current working directory in development is:
  // D:\Repositories\isaac-racing-client\dist\main\childProcesses
  // The current working directory in production is:
  // C:\Users\[Username]\AppData\Local\Programs\isaac-racing-client\resources\app.asar.unpacked\dist\main\childProcesses
  const greenworksPathComponents = [
    "..",
    "..",
    "..",
    "static",
    "js",
    "greenworks",
    "greenworks.js",
  ];
  const greenworksPath = path.join(__dirname, ...greenworksPathComponents);

  if (!file.exists(greenworksPath) || !file.isFile(greenworksPath)) {
    throw new Error(
      `Failed to find the Greenworks library at: ${greenworksPath}`,
    );
  }

  // We cannot use "path.join()" for the require statement since Node expects forward slashes
  const greenworksPathNode = greenworksPathComponents.join("/");

  // Enclose the following require in an eval to prevent webpack from resolving it
  // eslint-disable-next-line no-eval
  const greenworks = eval(`require("${greenworksPathNode}")`) as Greenworks;

  // Initialize Greenworks
  // (this cannot be written as "!greenworks.init()")
  if (greenworks.init() === false) {
    process.send("errorInit", processExit);
    return;
  }

  // Get the object that contains the computer's Steam ID and screen name
  const steamIDObject = greenworks.getSteamId();

  // Check to see if it is valid
  if (steamIDObject.isValid !== 1) {
    throw new Error("It appears that your Steam account is invalid.");
  }

  // Get a session ticket from Steam
  greenworks.getAuthSessionTicket((ticketObject: TicketObject) => {
    successCallback(steamIDObject, ticketObject);
  }, childError);
}

function successCallback(
  steamIDObject: SteamIDObject,
  ticketObject: TicketObject,
) {
  if (process.send === undefined) {
    throw new Error("process.send() does not exist.");
  }

  const steamMessage: SteamMessage = {
    id: steamIDObject.steamId,
    accountID: steamIDObject.accountId,
    screenName: steamIDObject.screenName,
    ticket: ticketObject.ticket.toString("hex"),
  };
  process.send(steamMessage);

  // The ticket will become invalid if the process ends
  // Thus, we need to keep the process alive doing nothing until we get a message that the authentication is over
}
