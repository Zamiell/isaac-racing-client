/* eslint-disable import/no-unused-modules */

const languagePack = {
  token: {
    // Title screen
    "A racing mod for The Binding of Isaac: Repentance.": "",

    // Register screen
    Register: "",
    "Choose your username.": "",
    "This is what other players will see when you race them.": "",
    "You won't be able to change this later.": "",
    "Only use letters, numbers, and underscores.": "",
    Username: "",
    Submit: "",
    "Username can only contain alphanumeric characters and '_'. Username should have between 2 and 15 characters.":
      "",
    "The username provided is in use already.": "",

    // Updating screen
    Updating: "",
    "A new version of the client is being downloaded. The program will automatically restart once it is complete.":
      "",
    "The staff is working hard to continually fix bugs and add new features. Sorry for the inconvenience!":
      "",

    // Header
    Profile: "",
    Leaderboards: "",
    Help: "",
    Lobby: "",
    "You must finish or quit the current race before returning to the lobby.":
      "",
    "New Race": "",
    Settings: "",

    // Lobby screen (current races table)
    "No current races.": "",
    Title: "",
    Status: "", // Open, Starting, In Progress
    Type: "", // Unranked, Ranked
    Format: "", // Unseeded, Seeded, Diversity, Custom
    Size: "", // The number of players currently in the race
    Entrants: "",
    Race: "",

    // The kinds of race "Status"
    Open: "",
    Starting: "",
    "In Progress": "",

    // The kinds of race "Type"
    Unranked: "",
    Ranked: "",

    // The kinds of race "Format"
    Unseeded: "",
    Seeded: "",
    Diversity: "",
    Custom: "",

    // The kinds of race "Difficulty"
    Difficulty: "",
    Normal: "",
    Hard: "",

    // Lobby screen (other)
    Chat: "",
    "Online Users": "",
    "Private Message": "",

    // Race screen (race table)
    Character: "",
    Goal: "",
    Seed: "",
    Build: "",

    // Race screen (race controls)
    Ready: "",
    "Race starting in 10 seconds!": "",
    Go: "",
    "Finish Race": "",
    "Quit Race": "",
    left: "",
    "Race completed": "",

    // Race screen (racer table)
    Place: "",
    Racer: "",
    Floor: "",
    Items: "",
    Time: "",
    Offset: "",

    // The kinds of racer "Status"
    "Not Ready": "",
    Racing: "",
    Finished: "",
    Quit: "",

    // Error modal
    Error: "",
    "Exit and relaunch Racing+": "",

    // Warning modal
    Warning: "",
    OK: "",

    // Password Modal
    "Password Required": "",
    "Please enter the race's password to join:": "",
    "Race's Password": "",
    "That is not the correct password.": "",
    Cancel: "",

    // Log file modal
    "Log File": "",
    Success: "",
    'Isaac\'s "log.txt" file does not appear to be at the default location. Racing+ needs to read this file in order to work properly.':
      "",
    "By default, this file is located at": "",
    "For more information, please see": "",
    'the "Known Issues" page by Simon from Nicalis': "",
    "Please relaunch the program.": "",
    'Locate "log.txt"': "",
    'Select your Isaac "log.txt" file': "",
    "Please try again and select your Repentance log file.": "",

    // Save file modal
    "Save File": "",
    "Racing+ was not able to find a fully unlocked save file for The Binding of Isaac: Repentance. Racing is typically done on a fully unlocked file so that all players have the same possibilities.":
      "",
    "If you want, the Racing+ client can automatically install a fully unlocked save file for you. Be careful, as this will overwrite the existing save file. If you aren't sure, make sure to back up your save files before proceeding.":
      "",
    "Replace save slot": "",
    "Do nothing and exit": "",
    "The save file has been installed. Please close and reopen The Binding of Isaac, and then click the button below.":
      "",
    "If it doesn't work, then you need to go into the game once on that slot, exit the game, and then redo this process.":
      "",

    // New race tooltip
    "Race title (optional)": "",
    "There is already a race with that title.": "",
    Randomize: "",
    Solo: "",
    Multiplayer: "",
    Practice: "",
    Password: "",
    "Password (optional)": "",
    Casual: "",
    Season: "",
    Random: "",
    "Random (all, 1-33)": "",
    "Random (single items only, 1-26)": "",
    "Random (Treasure Room only, 1-20)": "",
    Create: "",

    // Settings tooltip
    "Logged in as": "",
    "Client version": "",
    "Log file location": "",
    Change: "",
    Language: "",
    Volume: "",
    Test: "",
    "Enable boss cutscenes (for people used to vanilla; requires game restart)":
      "",
    "Change stream URL": "",
    'Your stream URL must begin with "https://www.twitch.tv/".': "",
    "Enable Twitch chat bot": "",
    "Make the bot a moderator in your Twitch channel by typing": "",
    "in your Twitch chat.": "",
    "It won't work unless it is a moderator.": "",
    "Delay (in seconds)": "",
    "The stream delay must be between 0 and 60.": "",
    Save: "",

    // Error messages (local)
    "An unknown error occurred.": "",
    "Failed to talk to Steam. Please open or restart Steam and relaunch Racing+.":
      "",
    "Failed to connect to the WebSocket server. The server might be down!": "",
    "Encountered a WebSocket error. The server might be down!": "",
    "Disconnected from the server. Either your Internet is having problems or the server went down!":
      "",

    // Error messages (from the server)
    "Someone else has already claimed that stream URL. If you are the real owner of this stream, please contact an administrator.":
      "",

    // chat.js
    "The format of a private message is": "",
    "The format of a notice is": "",
    "The format of a ban is": "",
    "The format of an unban is": "",

    // log-watcher.js
    'It appears that you have selected your Rebirth "log.txt" file, which is different than the Repentance "log.txt" file.':
      "",
    'It appears that you have selected your Afterbirth "log.txt" file, which is different than the Repentance "log.txt" file.':
      "",
    'It appears that you have selected your Afterbirth+ "log.txt" file, which is different than the Repentance "log.txt" file.':
      "",

    // race.js
    "The random items are not revealed until the race begins!": "",
    "This race will count towards the leaderboards.": "",
    "This race will not count towards the leaderboards.": "",
    "No-one else can join this race.": "",
    "Reset over and over until you find something good from a Treasure Room.":
      "",
    "You will be playing on an entirely different seed than your opponent(s).":
      "",
    "You will play on the same seed as your opponent and start with The Compass.":
      "",
    'This is the same as the "Unseeded" format, but you will also start with five random items.':
      "",
    "All players will start with the same five items.": "",
    "Extra changes will also be in effect; see the Racing+ website for details.":
      "",
    "You make the rules! Make sure that everyone in the race knows what to do before you start.":
      "",
    "Defeat Blue Baby (the boss of The Chest)": "",
    "Defeat The Lamb (the boss of The Dark Room)": "",
    "Defeat Mega Satan (the boss behind the giant locked door)": "",
    "and touch the trophy that falls down afterward.": "",
    "This race is password protected.": "",

    // Race ready error messages
    "Since this is a multiplayer race, you must wait for someone else to join before marking yourself as ready.":
      "",
    "You have to start a run before you can mark yourself as ready.": "",
    'You must be in a "Normal" mode run before you can mark yourself as ready.':
      "",
    "You must have the Racing+ mod enabled in-game before you can mark yourself as ready.":
      "",

    // register.js
    "The username field is required.": "",
  },
};
export default languagePack;
