// cspell:disable

const languagePack = {
  token: {
    // Title screen
    "A racing mod for The Binding of Isaac: Repentance.":
      "Un mod de carreras para The Binding of Isaac: Repentance.",

    // Register screen
    Register: "Regístrate",
    "Choose your username.": "Escoge tu nombre de usuario.",
    "This is what other players will see when you race them.":
      "Esto es lo que los demás jugadores verán cuando corras contra ellos.",
    "You won't be able to change this later.":
      "No podrás editar esto más tarde.",
    "Only use letters, numbers, and underscores.":
      "Usa sólo letras, números y guión bajo.",
    Username: "Usuario",
    Submit: "Enviar",
    "Username can only contain alphanumeric characters and '_'. Username should have between 2 and 15 characters.":
      "El nombre de usuario sólo puede contener carácteres alfanuméricos y '_'. El nombre de usuario debe tener entre 2 y 15 carácteres.",
    "The username provided is in use already.":
      "El nombre de usuario introducido está actualmente en uso.",

    // Updating screen
    Updating: "Actualizando",
    "A new version of the client is being downloaded. The program will automatically restart once it is complete.":
      "Se está descargando una nueva versión del cliente. El programa se reinciará automáticamente una vez se complete.",
    "The staff is working hard to continually fix bugs and add new features. Sorry for the inconvenience!":
      "El staff está trabajando para arreglar bugs y añadir nuevas características. ¡Perdón por las molestias!",

    // Header
    Profile: "Perfil",
    Leaderboards: "Clasificaciones",
    Help: "Ayuda",
    Lobby: "Vestíbulo",
    "You must finish or quit the current race before returning to the lobby.":
      "Debes terminar o salir de la carrera en curso antes de volver al vestíbulo.",
    "New Race": "Nueva carrera",
    Settings: "Opciones",

    // Lobby screen (current races table)
    "No current races.": "No hay carreras en curso",
    Title: "Nombre",
    Status: "Estado", // Open, Starting, In Progress
    Type: "Tipo", // Unranked, Ranked
    Format: "Formato", // Unseeded, Seeeded, Diversity, Custom
    Size: "Tamaño", // The number of players currently in the race
    Entrants: "Participantes",
    Race: "Carrera",

    // The kinds of race "Status"
    Open: "Abierta",
    Starting: "Iniciando",
    "In Progress": "En curso",

    // The kinds of race "Type"
    Unranked: "Casual",
    Ranked: "Igualada",

    // The kinds of race "Format"
    Unseeded: "Unseeded",
    Seeded: "Seeded",
    Diversity: "Diversity",
    Custom: "Personalizada",

    // The kinds of race "Difficulty"
    Difficulty: "Dificultad",
    Normal: "Normal",
    Hard: "Difícil",

    // Lobby screen (other)
    Chat: "Chat",
    "Online Users": "Usuarios en línea",
    "Private Message": "Mensaje privado",

    // Race screen (race table)
    Character: "Personaje",
    Goal: "Meta",
    Seed: "Seed",
    Build: "Build",

    // Race screen (race controls)
    Ready: "Listo",
    "Race starting in 10 seconds!": "La carrera comenzará en 10 segundos",
    Go: "¡Ya!",
    "Finish Race": "Acabar carrera",
    "Quit Race": "Salir de la carrera",
    left: "queda(n)",
    "Race completed": "Carrera completada",

    // Race screen (racer table)
    Place: "Posición",
    Racer: "Corredor",
    Floor: "Piso",
    Items: "Objetos",
    Time: "Tiempo",
    Offset: "Offset",

    // The kinds of racer "Status"
    "Not Ready": "No listo",
    Racing: "Corriendo",
    Finished: "Terminado",
    Quit: "Abandono",

    // Error modal
    Error: "Error",
    "Exit and relaunch Racing+": "Sal y relanza Racing+",

    // Warning modal
    Warning: "Aviso",
    OK: "OK",

    // Password Modal
    "Password Required": "Se requiere contraseña",
    "Please enter the race's password to join:":
      "Por favor, introduce la contraseña para entrar",
    "Race's Password": "Contraseña de la carrera",
    "That is not the correct password.": "La contraseña no es correcta",
    Cancel: "Cancelar",

    // Log file modal
    "Log File": "Fichero de log",
    Success: "Éxito",
    'Isaac\'s "log.txt" file does not appear to be at the default location. Racing+ needs to read this file in order to work properly.':
      'El "log.txt" del juego parece no estar en la ubicación por defecto. Racing+ necesita leerlo para funcionar correctamente.',
    "By default, this file is located at": "Por defecto, el fichero está en",
    "For more information, please see": "Para más información, ver",
    'the "Known Issues" page by Simon from Nicalis':
      'la página "Known Issues" de Simon de Nicalis',
    "Please relaunch the program.": "Por favor, relanza el programa.",
    'Locate "log.txt"': 'Localizar "log.txt"',
    'Select your Isaac "log.txt" file': 'Selecciona el "log.txt" del juego',
    "Please try again and select your Repentance log file.":
      "Por favor, intenta de nuevo y selecciona el fichero de log de tu Repentance.",

    // Save file modal
    "Save File": "Fichero de guardado",
    "Racing+ was not able to find a fully unlocked save file for The Binding of Isaac: Repentance. Racing is typically done on a fully unlocked file so that all players have the same possibilities.":
      "Racing+ no fue capaz de encontrar un fichero de guardado completo para The Binding of Isaac: Repentance. Las carreras se suelen hacer en un fichero de guardado completo para que así todos los jugadores tengan las mismas posibilidades.",
    "If you want, the Racing+ client can automatically install a fully unlocked save file for you. Be careful, as this will overwrite the existing save file. If you aren't sure, make sure to back up your save files before proceeding.":
      "Si lo deseas, el cliente de Racing+ puede instalarte automáticamente un fichero de guardado completo. Ten cuidado, esto sobreescribirá tu fichero de guardado actual. Asegúrate de hacer backups antes de proceder.",
    "Replace save slot": "Reemplaza el slot de guardado",
    "Do nothing and exit": "No hagas nada y sal",
    "The save file has been installed. Please close and reopen The Binding of Isaac, and then click the button below.":
      "El fichero de guardado se ha instalado. Por favor, cierra y abre d enuevo The Binding of Isaac y clicka en el botón de abajo.",
    "If it doesn't work, then you need to go into the game once on that slot, exit the game, and then redo this process.":
      "Si no funciona, tendrás que entrar al juego en ese slot, cerrar el juego y repetir el proceso.",

    // New race tooltip
    "Race title (optional)": "Nombre de la carrera (opcional)",
    "There is already a race with that title.":
      "Ya hay una carrera con ese nombre",
    Randomize: "Aleatorio",
    Solo: "Un jugador",
    Multiplayer: "Multijugador",
    Practice: "Práctica",
    Password: "Contraseña",
    "Password (optional)": "Contraseña (opcional)",
    Casual: "Casual",
    Season: "Temporada",
    Random: "Aleatorio",
    "Random (all, 1-31)": "Aleatorio (todos, 1-31)",
    "Random (single items only, 1-24)": "Aleatorio (sólo objetos únicos, 1-24)",
    "Random (Treasure Room only, 1-15)":
      "Aleatorio (sólo objetos de la Habitación del Tesoro)",
    Create: "Crear",

    // Settings tooltip
    "Logged in as": "Ingresado como",
    "Client version": "Versión del cliente",
    "Log file location": "Localización del fichero de log",
    Change: "Cambiar",
    Language: "Idioma",
    Volume: "Volumen",
    Test: "Test",
    "Enable boss cutscenes (for people used to vanilla; requires game restart)":
      "Habilita las escenas de los jefes (para gente acostumbrada a la versión Vanilla, requiere reinicio del juego)",
    "Change stream URL": "Cambia la URL de la retransmisión",
    'Your stream URL must begin with "https://www.twitch.tv/".':
      'La URL de la retransmisión debe empezar con "https://www.twitch.tv/".',
    "Enable Twitch chat bot": "Habilita el bot del chat de Twitch",
    "Make the bot a moderator in your Twitch channel by typing":
      "Haz moderador al bot en tu canal de Twitch escribiendo",
    "in your Twitch chat.": "En tu chat de Twitch.",
    "It won't work unless it is a moderator.":
      "No funcionará hasta que sea moderador.",
    "Delay (in seconds)": "Retraso (en segundos)",
    "The stream delay must be between 0 and 60.":
      "El retraso de la retransmisión debe ser entre 0 y 60.",
    Save: "Guardar",

    // Error messages (local)
    "An unknown error occurred.": "Ha ocurrido un error desconocido",
    "Failed to talk to Steam. Please open or restart Steam and relaunch Racing+.":
      "Fallo en la comunicación con Steam. Por favor, abre o reinicia Steam y relanza Racing+.",
    "Failed to connect to the WebSocket server. The server might be down!":
      "Fallo al conectar con el servidor WebSocket. ¡El servidor podría estar caído!",
    "Encountered a WebSocket error. The server might be down!":
      "Hallado un error de WebSocket. ¡El servidor podría estar caído!",
    "Disconnected from the server. Either your Internet is having problems or the server went down!":
      "Desconectado del servidor. ¡Puede que tu conexión esté teniendo problemas o el servidor haya caído!",

    // Error messages (from the server)
    "Someone else has already claimed that stream URL. If you are the real owner of this stream, please contact an administrator.":
      "Alguien más tiene esa URL de retransmisión. Si eres el propietario por favor, contacta con un administrador.",

    // chat.js
    "The format of a private message is": "El formato de un mensaje privado es",
    "The format of a notice is": "El formato de una notificación es",
    "The format of a ban is": "El formato de una expulsión es",
    "The format of an unban is": "El formato de un indulto es",

    // log-watcher.js
    'It appears that you have selected your Rebirth "log.txt" file, which is different than the Repentance "log.txt" file.':
      'Parece que has elegido un "log.txt" del Rebirth, el cual es diferente del "log.txt" del Repentance.',
    'It appears that you have selected your Afterbirth "log.txt" file, which is different than the Repentance "log.txt" file.':
      'Parece que has elegido un "log.txt" del Afterbirth, el cual es diferente del "log.txt" del Repentance.',
    'It appears that you have selected your Afterbirth+ "log.txt" file, which is different than the Repentance "log.txt" file.':
      'Parece que has elegido un "log.txt" del Afterbirth+, el cual es diferente del "log.txt" del Repentance.',

    // race.js
    "The random items are not revealed until the race begins!":
      "¡Los objetos aleatorios no serán revelados hasta que comience la carrera!",
    "This race will count towards the leaderboards.":
      "Esta carrera contará para la clasificación.",
    "This race will not count towards the leaderboards.":
      "Esta carrera no contará para la clasificación.",
    "No-one else can join this race.": "Nadie más puede unirse a esta carrera.",
    "Reset over and over until you find something good from a Treasure Room.":
      "Resetea una y otra vez hasta que encuentres algo bueno en una Habitación del Tesoro.",
    "You will be playing on an entirely different seed than your opponent(s).":
      "Jugarás en una seed completamente diferente a la de tu(s) rival(es).",
    "You will play on the same seed as your opponent and start with The Compass.":
      "Jugarás en la misma seed que tu rival y empezarás con The Compass.",
    'This is the same as the "Unseeded" format, but you will also start with five random items.':
      'Esto es lo mismo que el formato "Unseeded" pero además comenzarás con 5 objetos aleatorios.',
    "All players will start with the same five items.":
      "Todos los jugadores comenzarán con los mismos cinco objetos.",
    "Extra changes will also be in effect; see the Racing+ website for details.":
      "Otros cambios también tendrán efecto. Échale un ojo a la web del Racing+ para más detalles.",
    "You make the rules! Make sure that everyone in the race knows what to do before you start.":
      "¡Tu haces las reglas! Asegúrate de que todos los corredores sepan lo que hay que hacer antes de empezar.",
    "Defeat Blue Baby (the boss of The Chest)":
      "Derrota a Blue Baby (el jefe de The Chest)",
    "Defeat The Lamb (the boss of The Dark Room)":
      "Derrota a The Lamb (el jefe de The Dark Room)",
    "Defeat Mega Satan (the boss behind the giant locked door)":
      "Derrota a Mega Satan (el jefe tras la gigante puerta cerrada)",
    "and touch the trophy that falls down afterward.":
      "y toca el trofeo que caerá.",
    "This race is password protected.":
      "Esta carrera está protegida por contraseña",

    // Race ready error messages
    "Since this is a multiplayer race, you must wait for someone else to join before marking yourself as ready.":
      "Como esto es una carrera multijugador, debes esperar a que entre alguien más antes de empezar.",
    "You have to start a run before you can mark yourself as ready.":
      "Tienes que empezar una partida antes de darle a Listo.",
    'You must be in a "Normal" mode run before you can mark yourself as ready.':
      'Debes empezar una partida en modo "Normal" antes de darle a Listo.',
    "You must have the Racing+ mod enabled in-game before you can mark yourself as ready.":
      "Debes tener el mod Racing+ habilitado dentro del juego antes de darle a Listo.",

    // register.js
    "The username field is required.":
      "El campo de nombre de usuario es obligatorio.",
  },
};
export default languagePack;
