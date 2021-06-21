export default interface Greenworks {
  getAuthSessionTicket(
    successCallback: (ticket: TicketObject) => void,
    errorCallback: (err: Error) => void,
  ): void;
  getCloudQuota(
    successCallback: (totalBytes: number, availableBytes: number) => void,
    errorCallback: (err: Error) => void,
  ): void;
  getSteamId(): SteamIDObject;
  init(): unknown;
}

export interface TicketObject {
  ticket: Buffer;
  // The ticket object also contains other stuff that we don't care about
}

export interface SteamIDObject {
  accountId: number;
  isValid: number;
  screenName: string;
  steamId: string;
}

/*
  The object returned by "getSteamId()" will look something like the following:
  {
      "flags":{
        "anonymous": false,
        "anonymousGameServer": false,
        "anonymousGameServerLogin": false,
        "anonymousUser": false,
        "chat": false,
        "clan": false,
        "consoleUser": false,
        "contentServer": false,
        "gameServer": false,
        "individual": true,
        "gameServerPersistent": false,
        "lobby": false
      },
      "type":{
        "name": "k_EAccountTypeIndividual",
        "value": 1
      },
      "accountId": 33000000,
      "steamId": "76561190000000000",
      "staticAccountId": "76561190000000000",
      "isValid": 1,
      "level": 7,
      "screenName": "Zamiel"
  }
*/
