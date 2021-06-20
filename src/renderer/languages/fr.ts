// cspell:disable

const languagePack = {
  token: {
    // Title screen
    "A racing mod for The Binding of Isaac: Repentance":
      "Un mod pour participer à des courses sur The Binding of Isaac: Repentance",

    // Register screen
    Register: "S'inscrire",
    "Choose your username.": "Choisissez votre nom d'utilisateur.",
    "This is what other players will see when you race them.":
      "C'est le nom que les autres joueurs verront pendant les courses.",
    "You won't be able to change this later.":
      "Vous ne pourrez pas le changer plus tard.",
    "Only use letters, numbers, and underscores.":
      "Utilisez seulement des lettres et des chiffres.",
    Username: "Utilisateur",
    Submit: "Soumettre",
    "Username can only contain alphanumeric characters and '_'. Username should have between 2 and 15 characters.":
      "Le nom d'utilisateur doit se composer de lettres, chiffres et '_' seulement. Le nom d'utilisateur doit contenir entre 2 et 15 caractères.",
    "The username provided is in use already.":
      "Ce nom d'utilisateur est déjà utilisé.",

    // Updating screen
    Updating: "Mise à jour en cours",
    "A new version of the client is being downloaded. The program will automatically restart once it is complete.":
      "Une nouvelle version du client est en train d'être téléchargée. Le programme va redémarrer automatiquement une fois l'opération terminée.",
    "The staff is working hard to continually fix bugs and add new features. Sorry for the inconvenience!":
      "L'équipe travaille continuellement pour corriger les bugs et rajouter de nouvelles fonctionnalités. Désolé du désagrément.",

    // Header
    Profile: "Profil",
    Leaderboards: "Classements",
    Help: "Aide",
    Lobby: "Accueil",
    "You must finish or quit the current race before returning to the lobby.":
      "Vous devez finir ou quitter la course avant de revenir dans le lobby.",
    "New Race": "Nouvelle Course",
    Settings: "Paramètres",

    // Lobby screen (current races table)
    "No current races.": "Pas de courses en cours.",
    Title: "Titre",
    Status: "Statut", // Open, Starting, In Progress
    Type: "Catégorie", // Unranked, Ranked
    Format: "Format", // Unseeded, Seeeded, Diversity, Custom
    Size: "Nb", // The number of players currently in the race
    Entrants: "Participants",
    Race: "Course",

    // The kinds of race "Status"
    Open: "Ouverte",
    Starting: "Départ",
    "In Progress": "En Cours",

    // The kinds of race "Type"
    Unranked: "Non Classée",
    Ranked: "Classée",

    // The kinds of race "Format"
    Unseeded: "Non Seeded",
    Seeded: "Seeded",
    Diversity: "Diversity",
    Custom: "Personnalisée",

    // The kinds of race "Difficulty"
    Difficulty: "Difficulté",
    Normal: "Normal",
    Hard: "Difficile",

    // Lobby screen (other)
    Chat: "Chat",
    "Online Users": "Utilisateurs en ligne",
    "Private Message": "Message privé",

    // Race screen (race table)
    Character: "Personnage",
    Goal: "Objectif",
    Seed: "Seed",
    Build: "Build",

    // Race screen (race controls)
    Ready: "Prêt",
    "Race starting in 10 seconds!": "La course commence dans 10 secondes!",
    Go: "Partez",
    "Finish Race": "Terminer la course",
    "Quit Race": "Quitter la Course",
    left: "restant(s)",
    "Race completed": "Course terminée",

    // Race screen (racer table)
    Place: "Place",
    Racer: "Coureur",
    Floor: "Etage",
    Items: "Items",
    Time: "Temps",
    Offset: "Ecart",

    // The kinds of racer "Status"
    "Not Ready": "En Attente",
    Racing: "En Course",
    Finished: "Terminée",
    Quit: "Forfait",

    // Error modal
    Error: "Erreur",
    "Exit and relaunch Racing+": "Quittez et relancez le Racing+",

    // Warning modal
    Warning: "Attention",
    OK: "OK",

    // Password Modal
    "Password Required": "Mot de passe requis",
    "Please enter the race's password to join:":
      "Veuillez entrer le mot de passe de la course pour la joindre:",
    "Race's Password": "Mot de passe de la course",
    "That is not the correct password.": "Ce n'est pas le bon mot de passe.",
    Cancel: "Annuler",

    // Log file modal
    "Log File": "Fichier log",
    Success: "Réussi",
    'Isaac\'s "log.txt" file does not appear to be at the default location. Racing+ needs to read this file in order to work properly.':
      'Le fichier Isaac "log.txt" n\'apparaît pas dans la location habituelle. Racing+ nécessite la lecture de ce fichier pour fonctionner correctement.',
    "By default, this file is located at": "Par défaut, ce fichier est situé à",
    "For more information, please see":
      "Pour plus d'information, veuillez voir",
    'the "Known Issues" page by Simon from Nicalis':
      'la page "Known Issues" par Simon de Nicalis',
    "Please relaunch the program.": "Veuillez redémarrer le programme.",
    'Locate "log.txt"': 'Localiser "log.txt"',
    'Select your Isaac "log.txt" file':
      'Sélectionnez votre fichier Isaac "log.txt".',
    "Please try again and select your Repentance log file.":
      "Veuillez réessayer et sélectionner le fichier log de Repentance.",

    // Save file modal
    "Save File": "Sauvegarder le fichier",
    "Racing+ was not able to find a fully unlocked save file for The Binding of Isaac: Repentance. Racing is typically done on a fully unlocked file so that all players have the same possibilities.":
      "Le client Racing+ n'a pas été capable de trouver une sauvegarde où tout est débloqué sur The Binding of Isaac: Repentance. Les courses sont généralement réalisées sur des sauvegardes entièrement débloquées afin que tous les joueurs aient des possibilités égales.",
    "If you want, the Racing+ client can automatically install a fully unlocked save file for you. Be careful, as this will overwrite the existing save file. If you aren't sure, make sure to back up your save files before proceeding.":
      "Si vous le voulez, le client Racing+ peut de lui-même vous installer une sauvegarde entièrement débloquée. Faîtes attention, cela supplantera l'ancienne sauvegarde. Si vous n'êtes pas sûr, réalisez un backup de cette sauvegarde avant d'effectuer la manoeuvre.",
    "Replace save slot": "Remplacez le fichier de sauvegarde",
    "Do nothing and exit": "Ne faites rien et quittez",
    "The save file has been installed. Please close and reopen The Binding of Isaac, and then click the button below.":
      "Le fichier de sauvegarde a été installé. Nous vous prions de fermer et réouvrir The Binding of Isaac, puis cliquez le bouton ci-dessous.",
    "If it doesn't work, then you need to go into the game once on that slot, exit the game, and then redo this process.":
      "Si cela ne fonctionne pas, vous devez dans le jeu une fois sur cette même sauvegarde, quitter le jeu, et répéter la procédure indiquée.",

    // New race tooltip
    "Race title (optional)": "Nom de la course (facultatif)",
    "There is already a race with that title.":
      "Il existe déjà une course avec ce nom.",
    Randomize: "Aléatoire",
    Solo: "Solo",
    Multiplayer: "Multijoueur",
    Practice: "Entraînement",
    Password: "MdP",
    "Password (optional)": "Mot de passe (facultatif)",
    Casual: "Amical",
    Season: "Saison",
    Random: "Aléatoire",
    "Random (all, 1-31)": "Aléatoire (tous, 1-31)",
    "Random (single items only, 1-24)":
      "Aléatoire (items uniques seulement, 1-24)",
    "Random (Treasure Room only, 1-15)":
      "Aléatoire (Treasure Room seulement, 1-15)",
    Create: "Créer",

    // Settings tooltip
    "Logged in as": "Connecté en tant que",
    "Client version": "Version client",
    "Log file location": "Emplacement du fichier log",
    Change: "Changer",
    Language: "Langue",
    Volume: "Volume",
    Test: "Test",
    "Enable boss cutscenes (for people used to vanilla; requires game restart)":
      "Activer les animations de boss (pour les joueurs habitués au vanilla, requiert un relancement du jeu)",
    "Change stream URL": "Changer l'URL du stream",
    'Your stream URL must begin with "https://www.twitch.tv/".':
      'L\'URL de votre stream doit commencer par "https://www.twitch.tv/".',
    "Enable Twitch chat bot": "Activer le bot dans le chat Twitch",
    "Make the bot a moderator in your Twitch channel by typing":
      "Passez le bot modérateur sur votre chaine Twitch en tapant",
    "in your Twitch chat.": "dans votre chat Twitch.",
    "It won't work unless it is a moderator.":
      "Il ne fonctionnera pas tant qu'il n'est pas modérateur.",
    "Delay (in seconds)": "Délai (en secondes)",
    "The stream delay must be between 0 and 60.":
      "Le délai pour le stream doit être entre 0 et 60.",
    Save: "Sauvegarder",

    // Error messages (local)
    "An unknown error occurred.": "Une erreur inconnue s'est produite.",
    "Failed to talk to Steam. Please open or restart Steam and relaunch Racing+.":
      "Echec d'initialisation de l'API Steam. Veuillez ouvrir Steam et redémarrer Racing+.",
    "Failed to connect to the WebSocket server. The server might be down!":
      "Echec de connexion avec le serveur. Le serveur peut être hors service !",
    "Encountered a WebSocket error. The server might be down!":
      "Rencontré une erreur WebSocket. Le serveur est peut-être hors-service !",
    "Disconnected from the server. Either your Internet is having problems or the server went down!":
      "Vous avez été déconnecté du serveur. Votre connection internet a des problèmes ou le serveur est actuellement hors-service !",

    // Error messages (from the server)
    "Someone else has already claimed that stream URL. If you are the real owner of this stream, please contact an administrator.":
      "Cette URL de stream est déjà utilisée par quelqu'un d'autre. Si vous êtes le véritable propriétaire de ce stream, veuillez contacter un administrateur.",

    // chat.js
    "The format of a private message is": "Le format d'un message privé est",
    "The format of a notice is": "Le format d'une remarque est",
    "The format of a ban is": "Le format d'un bannissement est",
    "The format of an unban is": "Le format d'un débannissement est",

    // log-watcher.js
    'It appears that you have selected your Rebirth "log.txt" file, which is different than the Repentance "log.txt" file.':
      'Il semble que vous avez sélectionné le fichier "log.txt" de Rebirth, celui ci est différent du fichier "log.txt" de Repentance.',
    'It appears that you have selected your Afterbirth "log.txt" file, which is different than the Repentance "log.txt" file.':
      'Il semble que vous avez sélectionné le fichier "log.txt" d\'Afterbirth, celui ci est différent du fichier "log.txt" de Repentance.',
    'It appears that you have selected your Afterbirth+ "log.txt" file, which is different than the Repentance "log.txt" file.':
      'Il semble que vous avez sélectionné le fichier "log.txt" d\'Afterbirth+, celui ci est différent du fichier "log.txt" de Repentance.',

    // race.js
    "The random items are not revealed until the race begins!":
      "Les items randomisés ne seront révélés qu'au lancement de la course!",
    "This race will count towards the leaderboards.":
      "Cette course comptera pour le classement.",
    "This race will not count towards the leaderboards.":
      "Cette course ne comptera pas pour le classement.",
    "No-one else can join this race.":
      "Plus personne ne peut se joindre à cette course.",
    "Reset over and over until you find something good from a Treasure Room.":
      "Recommencez jusqu'à ce que vous trouviez un bon item dans une salle de trésor.",
    "You will be playing on an entirely different seed than your opponent(s).":
      'Vous allez jouer une "seed" différente de celles de vos adversaires.',
    "You will play on the same seed as your opponent and start with The Compass.":
      'Vous allez jouer la même "seed" que votre adversaire et commencer avec la boussole (The Compass).',
    'This is the same as the "Unseeded" format, but you will also start with five random items.':
      'C\'est identique au format "Unseeded", mais vous démarrerez avec cinq items aléatoires.',
    "All players will start with the same five items.":
      "Tous les joueurs démarreront avec les cinq mêmes items.",
    "Extra changes will also be in effect; see the Racing+ website for details.":
      "D'autres changements prendront aussi effet, référez-vous au site du Racing+ pour davantages de détails.",
    "You make the rules! Make sure that everyone in the race knows what to do before you start.":
      "Vous choisissez les règles ! Faites attention à ce que chaque joueur dans la course les ait intégrées avant qu'elle commence.",
    "Defeat Blue Baby (the boss of The Chest)":
      "Battez Blue Baby (le boss de The Chest)",
    "Defeat The Lamb (the boss of The Dark Room)":
      "Battez The Lamb (le boss de la Dark Room)",
    "Defeat Mega Satan (the boss behind the giant locked door)":
      "Battez Mega Satan (le boss derrière la géante porte fermée à clé)",
    "and touch the trophy that falls down afterward.":
      "et touchez le trophée qui tombe ensuite.",
    "This race is password protected.":
      "Un mot de passe est requis pour cette course.",

    // Race ready error messages
    "Since this is a multiplayer race, you must wait for someone else to join before marking yourself as ready.":
      "Étant donné qu'il s'agit d'une course en multijoueur, vous devez attendre qu'un autre joueur rejoigne avant de vous marquer en tant que prêt.",
    "You have to start a run before you can mark yourself as ready.":
      'Vous devez commencer une partie pour pouvoir cocher la case "prêt".',
    'You must be in a "Normal" mode run before you can mark yourself as ready.':
      'Vous devez être en mode "Normal" pour pouvoir cocher la case "prêt".',
    "You must have the Racing+ mod enabled in-game before you can mark yourself as ready.":
      "Vous devez avoir le mod Racing+ actif en jeu avant de pouvoir vous indiquer en tant que prêt.",

    // register.js
    "The username field is required.": "Le nom d'utilisateur est requis.",
  },
};
export default languagePack;
