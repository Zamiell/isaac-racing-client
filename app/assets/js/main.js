'use strict';

/*
	TODO

	- tab complete for chat
	- /r should work
	- test to see if multiple windows works in production
	- columns for race:
	  - seed
	  - floor
	  - starting item
	  - time offset
	  - automatic finish
	  - fill in items
*/

// Constants
const domain    = 'isaacracing.net';
const secure    = true; // "true" for HTTPS/WSS and "false" for HTTP/WS
const fadeTime  = 300;

// Imports
const ipcRenderer = nodeRequire('electron').ipcRenderer;
const remote      = nodeRequire('electron').remote;
const shell       = nodeRequire('electron').shell;
const clipboard   = nodeRequire('electron').clipboard;
const autoUpdater = nodeRequire('electron').autoUpdater;
const isDev       = nodeRequire('electron-is-dev');
const fs          = nodeRequire('fs');
const os          = nodeRequire('os');
const path        = nodeRequire('path');
const keytar      = nodeRequire('keytar');
const spawn       = nodeRequire('child_process').spawn;
const execFile    = nodeRequire('child_process').execFile;
const execSync    = nodeRequire('child_process').execSync;
const Tail        = nodeRequire('tail').Tail;

// Global variables
var currentScreen = 'title';
var currentRaceID = false; // Equal to false or the ID of the race
var conn;
var logMonitoringProgram;
var roomList = {};
var raceList = {};
var myUsername;
var timeOffset = 0;
var initiatedLogout = false;
var wordList;
var lang;
var settings = {
	'language': null,
	'volume': null,
	'logFilePath': null,
};

/*
	By default, we start on the title screen.
	currentScreen can be the following:
	- title
	- title-ajax
	- login
	- login-ajax
	- forgot
	- forgot-ajax
	- register
	- register-ajax
	- lobby
	- race
	- settings
	- error
	- warning
	- transition
*/

/*
	Debug functions
*/

function debug() {
	// The "/debug" command
	console.log('Entering debug function.');

	//errorShow('debug');
	//console.log(raceList);
	//console.log(currentRaceID);
}

/*
	Development-only stuff
*/

if (isDev) {
	// Importing this adds a right-click menu with 'Inspect Element' option
	let rightClickPosition = null;

	const menu = new remote.Menu();
	const menuItem = new remote.MenuItem({
		label: 'Inspect Element',
		click: () => {
			remote.getCurrentWindow().inspectElement(rightClickPosition.x, rightClickPosition.y);
		},
	});
	menu.append(menuItem);

	window.addEventListener('contextmenu', (e) => {
		e.preventDefault();
		rightClickPosition = {
			x: e.x,
			y: e.y,
		};
		menu.popup(remote.getCurrentWindow());
	}, false);
}

/*
	Initialize settings
*/

// Language localization
settings.language = localStorage.language;
if (typeof language === 'undefined') {
	// If this is the first run, default to English
	settings.language = 'en';
	localStorage.language = 'en';
}
lang = new Lang(); // Create a language switcher instance
lang.dynamic('fr', 'assets/languages/fr.json');
lang.init({
	defaultLang: 'en',
});

// Volume
settings.volume = localStorage.volume;
if (typeof settings.volume === 'undefined') {
	// If this is the first run, default to 10%
	settings.volume = 0.1;
	localStorage.volume = 0.1;
}

// Log file path
settings.logFilePath = localStorage.logFilePath;
if (typeof settings.logFilePath === 'undefined') {
	// If this is the first run, set it to the default location (which is in the user's Documents directory)
	let command = 'powershell.exe -command "[Environment]::GetFolderPath(\'mydocuments\')"';
	let documentsPath = execSync(command, {
		'encoding': 'utf8',
	});
	let defaultLogFilePath = path.join(documentsPath, 'My Games', 'Binding of Isaac Afterbirth', 'log.txt');
	localStorage.logFilePath = defaultLogFilePath;
}

/*
	Initialization (miscellaneous)
*/

// Read in the word list for later
let wordListLocation = (isDev ? 'app' : 'resources/app.asar') + '/assets/words/words.txt';
wordList = fs.readFileSync(wordListLocation).toString().split('\n');

/*
	Automatic updating
*/

function checkForUpdates() {
	autoUpdater.on('error', function(err) {
		console.err(`Update error: ${err.message}`);
	});

	autoUpdater.on('checking-for-update', function() {
		console.log('Checking for update.');
	});

	autoUpdater.on('update-available', function() {
		console.log('Update available.');
	});

	autoUpdater.on('update-not-available', function() {
		console.log('No update available.');
	});

	autoUpdater.on('update-downloaded', function(e, notes, name, date, url) {
		console.log(`Update downloaded: ${name}: ${url}`);
	});

	let url = 'http' + (secure ? 's' : '') + '://' + domain + '/update/win32';
	autoUpdater.setFeedURL(url);
	autoUpdater.checkForUpdates();
}

/*
	UI functionality
*/

$(document).ready(function() {
	// If the user is using a non-default language, change all the text on the page
	if (settings.language !== 'en') {
		localize(settings.language);
	}

	// Set the version number on the title screen
	let packageLocation = (isDev ? 'app' : 'resources/app.asar') + '/package.json';
	let version = JSON.parse(fs.readFileSync(packageLocation)).version;
	$('#title-version').html('v' + version);

	// Find out if the user has saved credentials
	let storedUsername = localStorage.username;
	if (typeof storedUsername !== 'undefined') {
		let storedPassword = keytar.getPassword('Racing+', storedUsername);
		if (storedPassword !== null) {
			// Show an AJAX circle
			currentScreen = 'title-ajax';
			$('#title-buttons').fadeOut(0);
			$('#title-languages').fadeOut(0);
			$('#title-version').fadeOut(0);
			$('#title-ajax').fadeIn(0);

			// Fill in the input fields in the login form in case there is an error later on
			$('#login-username').val(storedUsername);
			$('#login-password').val(storedPassword);
			$('#login-remember-checkbox').prop('checked', true);

			// We have a saved username and password, so attempt to log in automatically
			login1(storedUsername, storedPassword, false);
		}
	}

	/*
		Keyboard bindings
	*/

	$(document).keydown(function(event) {
		//console.log(event.which); // Find out the number that corresponds to the desired key

		if (event.which === 49) { // "1"
			if (currentScreen === 'title') {
				event.preventDefault();
				$('#title-login-button').click();
			}

		} else if (event.which === 50) { // "2"
			if (currentScreen === 'title') {
				event.preventDefault();
				$('#title-register-button').click();
			}

		} else if (event.which === 27) { // "Esc"
			if (currentScreen === 'login') {
				event.preventDefault();
				$('#login-back-button').click();
			} else if (currentScreen === 'forgot') {
				event.preventDefault();
				$('#forgot-back-button').click();
			} else if (currentScreen === 'register') {
				event.preventDefault();
				$('#register-back-button').click();
			} else if (currentScreen === 'lobby') {
				closeAllTooltips();
			}

		} else if (event.which === 38) { // Up arrow
			if (currentScreen === 'lobby' || currentScreen === 'race') {
				if ($('#' + currentScreen + '-chat-box-input').is(':focus')) {
					let room;
					if (currentScreen === 'lobby') {
						room = 'lobby';
					} else if (currentScreen === 'race') {
						room = '_race_' + currentRaceID;
					}

					event.preventDefault();
					roomList[room].historyIndex++;

					// Check to see if we have reached the end of the history list
					if (roomList[room].historyIndex > roomList[room].typedHistory.length - 1) {
						roomList[room].historyIndex--;
						return;
					}

					// Set the chat input box to what we last typed
					let retrievedHistory = roomList[room].typedHistory[roomList[room].historyIndex];
					$('#' + currentScreen + '-chat-box-input').val(retrievedHistory);
				}
			}

		} else if (event.which === 40) { // Down arrow
			if (currentScreen === 'lobby' || currentScreen === 'race') {
				if ($('#' + currentScreen + '-chat-box-input').is(':focus')) {
					let room;
					if (currentScreen === 'lobby') {
						room = 'lobby';
					} else if (currentScreen === 'race') {
						room = '_race_' + currentRaceID;
					}

					event.preventDefault();
					roomList[room].historyIndex--;

					// Check to see if we have reached the beginning of the history list
					if (roomList[room].historyIndex <= -2) { // -2 instead of -1 here because we want down arrow to clear the chat
						roomList[room].historyIndex = -1;
						return;
					}

					// Set the chat input box to what we last typed
					let retrievedHistory = roomList[room].typedHistory[roomList[room].historyIndex];
					$('#' + currentScreen + '-chat-box-input').val(retrievedHistory);
				}
			}

		} else if (event.altKey && event.which === 78) { // Alt + n
			if (currentScreen === 'lobby') {
				$('#header-new-race').click();
			}

		} else if (event.altKey && event.which === 83) { // Alt + s
			if (currentScreen === 'lobby') {
				$('#header-settings').click();
			}

		} else if (event.altKey && event.which === 76) { // Alt + l
			if (currentScreen === 'race') {
				$('#header-lobby').click();
			}

		} else if (event.altKey && event.which === 82) { // Alt + r
			if (currentScreen === 'race') {
				$('#race-ready-checkbox').click();
			}

		} else if (event.altKey && event.which === 81) { // Alt + q
			if (currentScreen === 'race') {
				$('#race-quit-button').click();
			}

		} else if (event.which === 13) { // Enter
			if (currentScreen === 'lobby' && $('#new-race-randomize').is(':focus')) {
				event.preventDefault();
				$('#new-race-form').submit();
			}
		}
	});

	/*
		Header buttons
	*/

	$('#header-minimize').click(function() {
		ipcRenderer.send('asynchronous-message', 'minimize');
	});

	$('#header-maximize').click(function() {
		ipcRenderer.send('asynchronous-message', 'maximize');
	});

	$('#header-close').click(function() {
		ipcRenderer.send('asynchronous-message', 'close');
	});

	/*
		Title screen
	*/

	$('#title-login-button').click(function() {
		if (currentScreen !== 'title') {
			return;
		}
		currentScreen = 'transition';
		$('#title').fadeOut(fadeTime, function() {
			$('#login').fadeIn(fadeTime, function() {
				currentScreen = 'login';
			});
			$('#login-username').focus();
		});
	});

	$('#title-register-button').click(function() {
		if (currentScreen !== 'title') {
			return;
		}
		currentScreen = 'transition';
		$('#title').fadeOut(fadeTime, function() {
			$('#register').fadeIn(fadeTime, function() {
				currentScreen = 'register';
			});
			$('#register-username').focus();
		});
	});

	$('#title-language-french').click(function() {
		localize('fr');
	});

	/*
		Login screen
	*/

	$('#login-form').submit(function(event) {
		// By default, the form will reload the page, so stop this from happening
		event.preventDefault();

		// Don't do anything if we are already logging in
		if (currentScreen !== 'login') {
			return;
		}

		// Get values from the form
		let username = document.getElementById('login-username').value.trim();
		let password = document.getElementById('login-password').value.trim();
		let remember = document.getElementById('login-remember-checkbox').checked;

		// Validate username/password
		if (username === '') {
			$('#login-error').fadeIn(fadeTime);
			$('#login-error').html('<span lang="en">The username field is required.</span>');
			return;
		} else if (password === '') {
			$('#login-error').fadeIn(fadeTime);
			$('#login-error').html('<span lang="en">The password field is required.</span>');
			return;
		}

		// Fade the form and show the AJAX circle
		currentScreen = 'login-ajax';
		if ($('#login-error').css('display') !== 'none') {
			$('#login-error').fadeTo(fadeTime, 0.25);
		}
		$('#login-form').fadeTo(fadeTime, 0.25);
		$('#login-username').prop('disabled', true);
		$('#login-password').prop('disabled', true);
		$('#login-remember-checkbox').prop('disabled', true);
		$('#login-remember-checkbox-label').css('cursor', 'default');
		$('#login-forgot-button').prop('disabled', true);
		$('#login-submit-button').prop('disabled', true);
		$('#login-back-button').prop('disabled', true);
		$('#login-ajax').fadeIn(fadeTime);

		// Begin the login process
		login1(username, password, remember);
	});

	$('#login-forgot-button').click(function() {
		if (currentScreen !== 'login') {
			return;
		}
		currentScreen = 'transition';
		$('#login').fadeOut(fadeTime, function() {
			// Clear out the login form
			$('#login-error').fadeOut(0);
			$('#login-username').val('');
			$('#login-password').val('');
			$('#login-remember-checkbox').prop('checked', false);

			// Show the forgot password screen
			$('#forgot').fadeIn(fadeTime, function() {
				currentScreen = 'forgot';
			});
			$('#forgot-email').focus();
		});
	});

	$('#login-back-button').click(function() {
		if (currentScreen !== 'login') {
			return;
		}
		currentScreen = 'transition';
		$('#login').fadeOut(fadeTime, function() {
			// Clear out the login form
			$('#login-error').fadeOut(0);
			$('#login-username').val('');
			$('#login-password').val('');
			$('#login-remember-checkbox').prop('checked', false);

			// Show the title screen
			$('#title').fadeIn(fadeTime, function() {
				currentScreen = 'title';
			});
		});
	});

	/*
		Forgot screen
	*/

	$('#forgot-form').submit(function(event) {
		// By default, the form will reload the page, so stop this from happening
		event.preventDefault();

		// Don't do anything if we are already requesting an email
		if (currentScreen !== 'forgot') {
			return;
		}

		// Get values from the form
		let email = document.getElementById('forgot-email').value.trim();

		// Validate email
		if (email === '') {
			$('#forgot-error').fadeIn(fadeTime);
			$('#forgot-error').html('<span lang="en">The email field is required.</span>');
			return;
		}

		// Fade the form and show the AJAX circle
		currentScreen = 'forgot-ajax';
		if ($('#forgot-success').css('display') !== 'none') {
			$('#forgot-success').fadeTo(fadeTime, 0.25);
		}
		if ($('#forgot-error').css('display') !== 'none') {
			$('#forgot-error').fadeTo(fadeTime, 0.25);
		}
		$('#forgot-form').fadeTo(fadeTime, 0.25);
		$('#forgot-email').prop('disabled', true);
		$('#forgot-submit-button').prop('disabled', true);
		$('#forgot-back-button').prop('disabled', true);
		$('#forgot-ajax').fadeIn(fadeTime);

		// Request an email from Auth0
		forgotPassword(email);
	});

	$('#forgot-back-button').click(function() {
		if (currentScreen !== 'forgot') {
			return;
		}
		currentScreen = 'transition';
		$('#forgot').fadeOut(fadeTime, function() {
			// Clear out the login form
			$('#forgot-error').fadeOut(0);
			$('#forgot-email').val('');

			// Show the login screen
			$('#login').fadeIn(fadeTime, function() {
				currentScreen = 'login';
			});
			$('#login-username').focus();
		});
	});

	/*
		Register screen
	*/

	$('#register-form').submit(function(event) {
		// By default, the form will reload the page, so stop this from happening
		event.preventDefault();

		// Don't do anything if we are already registering
		if (currentScreen !== 'register') {
			return;
		}

		// Validate username/password/email
		let username = document.getElementById('register-username').value.trim();
		let password = document.getElementById('register-password').value.trim();
		let email	 = document.getElementById('register-email').value.trim();
		if (username === '') {
			$('#register-error').fadeIn(fadeTime);
			$('#register-error').html('<span lang="en">The username field is required.</span>');
			return;
		} else if (password === '') {
			$('#register-error').fadeIn(fadeTime);
			$('#register-error').html('<span lang="en">The password field is required.</span>');
			return;
		} else if (email === '') {
			$('#register-error').fadeIn(fadeTime);
			$('#register-error').html('<span lang="en">The email field is required.</span>');
			return;
		}

		// Fade the form and show the AJAX circle
		currentScreen = 'register-ajax';
		if ($('#register-error').css('display') !== 'none') {
			$('#register-error').fadeTo(fadeTime, 0.25);
		}
		$('#register-form').fadeTo(fadeTime, 0.25);
		$('#register-username').prop('disabled', true);
		$('#register-password').prop('disabled', true);
		$('#register-email').prop('disabled', true);
		$('#register-submit-button').prop('disabled', true);
		$('#register-back-button').prop('disabled', true);
		$('#register-ajax').fadeIn(fadeTime);

		// Begin the login process
		register(username, password, email);
	});

	$('#register-back-button').click(function() {
		if (currentScreen !== 'register') {
			return;
		}
		currentScreen = 'transition';
		$('#register').fadeOut(fadeTime, function() {
			// Clear out the register form
			$('#register-error').fadeOut(0);
			$('#register-username').val('');
			$('#register-password').val('');
			$('#register-email').val('');

			// Show the title screen
			$('#title').fadeIn(fadeTime, function() {
				currentScreen = 'title';
			});
		});
	});

	/*
		Lobby links
	*/

	$('#header-profile').click(function() {
		let url = 'http' + (secure ? 's' : '') + '://' + domain + '/profiles/' + myUsername;
		shell.openExternal(url);
	});

	$('#header-leaderboards').click(function() {
		let url = 'http' + (secure ? 's' : '') + '://' + domain + '/leaderboards';
		shell.openExternal(url);
	});

	$('#header-help').click(function() {
		let url = 'http' + (secure ? 's' : '') + '://' + domain + '/info';
		shell.openExternal(url);
	});

	/*
		Lobby header buttons
	*/

	$('#header-lobby').click(function() {
		if (currentScreen !== 'race') {
			return;
		}

		// Check to see if we should leave the race
		if (raceList.hasOwnProperty(currentRaceID)) {
			if (raceList[currentRaceID].status === 'open') {
				conn.emit('raceLeave', {
					'id': currentRaceID,
				});
			}
		} else {
			lobbyShowFromRace();
		}

	});

	$('#header-lobby').tooltipster({
		theme: 'tooltipster-shadow',
		delay: 0,
		functionBefore: function() {
			if (currentScreen === 'race') {
				if (raceList.hasOwnProperty(currentRaceID)) {
					if (raceList[currentRaceID].status === 'starting' ||
						raceList[currentRaceID].status === 'in progress') {

						// The race has already started
						return true;
					} else {
						// The race has not started yet
						return false;
					}
				} else {
					// The race is finished
					return false;
				}
			} else {
				// Not on the race screen
				return false;
			}
		},
	});

	$('#header-new-race').tooltipster({
		theme: 'tooltipster-shadow',
		trigger: 'click',
		interactive: true,
		functionBefore: function() {
			if (currentScreen === 'lobby') {
				$('#gui').fadeTo(fadeTime, 0.1);
				return true;
			} else {
				return false;
			}
		},
	}).tooltipster('instance').on('close', function() {
		$('#gui').fadeTo(fadeTime, 1);
	});

	$('#header-new-race').click(function() {
		$('#new-race-name').focus();
	});

	$('#header-settings').tooltipster({
		theme: 'tooltipster-shadow',
		trigger: 'click',
		interactive: true,
		functionBefore: function() {
			if (currentScreen === 'lobby') {
				$('#gui').fadeTo(fadeTime, 0.1);
				return true;
			} else {
				return false;
			}
		},
	}).tooltipster('instance').on('close', function() {
		$('#gui').fadeTo(fadeTime, 1);
	});

	$('#header-settings').click(function() {
		// TODO focus something?
		//$('#senew-race-name').focus();

		// CHANGE LANGUAGES
	});

	$('#header-log-out').click(function() {
		// Delete their cached credentials, if any
		let storedUsername = localStorage.username;
		if (typeof storedUsername !== 'undefined') {
			let storedPassword = keytar.getPassword('Racing+', storedUsername);
			if (storedPassword !== null) {
				keytar.deletePassword('Racing+', storedUsername);
			}
			localStorage.removeItem('username');
		}

		// Kill the log monitoring program
		logMonitoringProgram.stdin.pause();
		logMonitoringProgram.kill();

		// Terminate the WebSocket connection (which will trigger the transition back to the title screen)
		initiatedLogout = true;
		conn.close();
	});

	/*
		Lobby screen
	*/

	$('#lobby-chat-form').submit(function(event) {
		// By default, the form will reload the page, so stop this from happening
		event.preventDefault();

		// Validate input and send the chat
		chatSend('lobby');
	});

	/*
		Start race tooltip
	*/

	$('#new-race-randomize').click(function() {
		let randomNumbers = [];
		for (let i = 0; i < 3; i++) {
			while (true) {
				let randomNumber = getRandomNumber(0, wordList.length - 1);
				if (randomNumbers.indexOf(randomNumber) === -1) {
					randomNumbers.push(randomNumber);
					break;
				}
			}
		}
		let randomlyGeneratedName = '';
		for (let i = 0; i < 3; i++) {
			randomlyGeneratedName += wordList[randomNumbers[i]] + ' ';
		}

		// Chop off the trailing space
		randomlyGeneratedName = randomlyGeneratedName.slice(0, -1);

		// Set it
		$('#new-race-name').val(randomlyGeneratedName);
	});

	$('#new-race-format').change(function() {
		// Change the displayed icon
		let newFormat = $(this).val();
		$('#new-race-format-icon').css('background-image', 'url("assets/img/formats/' + newFormat + '.png")');

		// Change to the default character for this ruleset
		let newCharacter;
		if ($(this).val() === 'unseeded') {
			newCharacter = 'Judas';
		} else if ($(this).val() === 'seeded') {
			newCharacter = 'Judas';
		} else if ($(this).val() === 'diversity') {
			newCharacter = 'Cain';
		}
		if ($('#new-race-character').val() !== newCharacter) {
			$('#new-race-character').val(newCharacter);
			$('#new-race-character-icon').css('background-image', 'url("assets/img/characters/' + newCharacter + '.png")');
		}

		// Show or hide the starting build row
		if ($(this).val() === 'seeded') {
			$('#new-race-starting-build-1').fadeIn(fadeTime);
			$('#new-race-starting-build-2').fadeIn(fadeTime);
			$('#new-race-starting-build-3').fadeIn(fadeTime);
		} else {
			$('#new-race-starting-build-1').fadeOut(fadeTime);
			$('#new-race-starting-build-2').fadeOut(fadeTime);
			$('#new-race-starting-build-3').fadeOut(fadeTime);
		}
	});

	$('#new-race-character').change(function() {
		// Change the displayed icon
		let newCharacter = $(this).val();
		$('#new-race-character-icon').css('background-image', 'url("assets/img/characters/' + newCharacter + '.png")');
	});

	$('#new-race-goal').change(function() {
		// Change the displayed icon
		let newGoal = $(this).val();
		$('#new-race-goal-icon').css('background-image', 'url("assets/img/goals/' + newGoal + '.png")');
	});

	$('#new-race-starting-build').change(function() {
		// Change the displayed icon
		let newBuild = $(this).val();
		$('#new-race-starting-build-icon').css('background-image', 'url("assets/img/builds/' + newBuild + '.png")');
	});

	$('#new-race-form').submit(function() {
		// By default, the form will reload the page, so stop this from happening
		event.preventDefault();

		// Don't do anything if we are already logging in
		if (currentScreen !== 'lobby') {
			return;
		}

		// Get values from the form
		let name = $('#new-race-name').val().trim();
		let format = $('#new-race-format').val();
		let character = $('#new-race-character').val();
		let goal = $('#new-race-goal').val();
		let startingBuild;
		if (format === 'seeded') {
			startingBuild = $('#new-race-starting-build').val();
		} else {
			startingBuild = -1;
		}

		// Truncate names longer than 71 characters (this is also enforced server-side)
		let maximumLength = (23 * 3) + 2; // Longest word is 23 characters, 3 word name, 2 spaces
		if (name.length > maximumLength) {
			name = name.substring(0, maximumLength);
		}

		// If necessary, get a random character
		if (character === 'Random') {
			let characterArray = [
				'Isaac',     // 0
				'Magdalene', // 1
				'Cain',      // 2
				'Judas',     // 3
				'Blue Baby', // 4
				'Eve',       // 5
				'Samson',    // 6
				'Azazel',    // 7
				'Lazarus',   // 8
				'Eden',      // 9
				'The Lost',  // 10
				'Lilith',    // 11
				'Keeper',    // 12
			];
			let randomNumber = getRandomNumber(0, 12);
			character = characterArray[randomNumber];
		}

		// If necessary, get a random starting build,
		if (startingBuild === 'Random') {
			// There are 31 builds in the Instant Start Mod
			startingBuild = getRandomNumber(1, 31);
		} else {
			// The value was read from the form as a string and needs to be sent to the server as an intenger
			startingBuild = parseInt(startingBuild);
		}

		// Close the tooltip
		$('#header-new-race').tooltipster('close'); // Close the tooltip

		// Create the race
		let rulesetObject = {
			'format': format,
			'character': character,
			'goal': goal,
			'startingBuild': startingBuild,
		};
		conn.emit('raceCreate', {
			'name': name,
			'ruleset': rulesetObject,
		});
	});

	/*
		Race screen
	*/

	$('#race-title-seed').tooltipster({
		theme: 'tooltipster-shadow',
		delay: 0,
		functionBefore: function() {
			if (currentScreen === 'race') {
				return true;
			} else {
				return false;
			}
		},
	});

	$('#race-ready-checkbox').change(function() {
		if (currentScreen !== 'race') {
			return;
		} else if (raceList.hasOwnProperty(currentRaceID) === false) {
			return;
		}

		if (this.checked) {
			conn.emit('raceReady', {
				'id': currentRaceID,
			});
		} else {
			conn.emit('raceUnready', {
				'id': currentRaceID,
			});
		}
	});

	$('#race-quit-button').click(function() {
		if (currentScreen !== 'race') {
			return;
		} else if (raceList.hasOwnProperty(currentRaceID) === false) {
			return;
		}

		conn.emit('raceQuit', {
			'id': currentRaceID,
		});
	});

	$('#race-chat-form').submit(function(event) {
		// By default, the form will reload the page, so stop this from happening
		event.preventDefault();

		// Validate input and send the chat
		chatSend('race');
	});

	/*
		Error modal
	*/

	$('#error-modal-button').click(function() {
		if (currentScreen === 'error') {
			ipcRenderer.send('asynchronous-message', 'restart');
		}
	});

	/*
		Log file modal
	*/

	$('#log-file-link').click(function() {
		let url = 'https://steamcommunity.com/app/250900/discussions/0/613941122558099449/';
		shell.openExternal(url);
	});

	$('#log-file-find').click(function() {
		let titleText = $('#select-your-log-file').html();
		let newLogFilePath = remote.dialog.showOpenDialog({
			title: titleText,
			filters: [
				{
					'name': 'Text',
					'extensions': ['txt'],
				}
			],
			properties: ['openFile'],
		});
		if (newLogFilePath === undefined) {
			return;
		} else {
			localStorage.logFilePath = newLogFilePath;
			$('#log-file-description-1').fadeOut(fadeTime);
			$('#log-file-description-2').fadeOut(fadeTime, function() {
				$('#log-file-description-3').fadeIn(fadeTime);
			});
			$('#log-file-find').fadeOut(fadeTime, function() {
				$('#log-file-exit').fadeIn(fadeTime);
			});
		}
	});

	$('#log-file-exit').click(function() {
		if (currentScreen === 'error') {
			ipcRenderer.send('asynchronous-message', 'restart');
		}
	});
});

/*
	Login functions
*/

// Step 1 - Get a login token from Auth0
function login1(username, password, remember) {
	let data = {
		'grant_type': 'password',
		'username':   username,
		'password':   password,
		'client_id':  'tqY8tYlobY4hc16ph5B61dpMJ1YzDaAR',
		'connection': 'Isaac-Server-DB-Connection',
	};
	let request = $.ajax({
		url:  'https://isaacserver.auth0.com/oauth/ro',
		type: 'POST',
		data: data,
	});
	request.done(function(data) {
		// We successfully got the token; move on to step 2
		login2(username, password, remember, data);
	});
	request.fail(loginFail);
}

// Step 2 - Login with the token to get a cookie
function login2(username, password, remember, data) {
	let url = 'http' + (secure ? 's' : '') + '://' + domain + '/login';
	let request = $.ajax({
		url:  url,
		type: 'POST',
		data: JSON.stringify(data),
		contentType: 'application/json',
	});
	request.done(function() {
		// We successfully got a cookie; attempt to establish a WebSocket connection
		websocket(username, password, remember);
	});
	request.fail(loginFail);
}

// When an AJAX call fails
function loginFail(jqXHR) {
	// Transition to the login screen if we are not already there
	if (currentScreen === 'title-ajax') {
		currentScreen = 'transition';
		$('#title').fadeOut(fadeTime, function() {
			// Reset the title screen back to normal
			$('#title-buttons').fadeIn(0);
			$('#title-languages').fadeIn(0);
			$('#title-version').fadeIn(0);
			$('#title-ajax').fadeOut(0);

			// Show the login screen
			$('#login').fadeIn(fadeTime);
			$('#login-username').focus();
		});
	} else if (currentScreen === 'login-ajax') {
		currentScreen = 'transition';
		loginReset();
	} else if (currentScreen === 'register-ajax') {
		currentScreen = 'transition';
		$('#register').fadeOut(fadeTime, function() {
			// Reset the register screen back to normal
			registerReset();
			$('#register-username').val('');
			$('#register-password').val('');
			$('#register-email').val('');

			// Show the login screen
			$('#login').fadeIn(fadeTime);
			$('#login-username').focus();
		});
	}

	// Show the error box
	let error = findAjaxError(jqXHR);
	$('#login-error').html('<span lang="en">' + error + '</span>');
	$('#login-error').fadeIn(fadeTime, function() {
		currentScreen = 'login';
	});
}

// A function to return the login form back to the way it was initially
function loginReset() {
	$('#login-error').fadeTo(fadeTime, 1);
	$('#login-form').fadeTo(fadeTime, 1);
	$('#login-username').prop('disabled', false);
	$('#login-password').prop('disabled', false);
	$('#login-remember-checkbox').prop('disabled', false);
	$('#login-remember-checkbox-label').css('cursor', 'pointer');
	$('#login-forgot-button').prop('disabled', false);
	$('#login-submit-button').prop('disabled', false);
	$('#login-back-button').prop('disabled', false);
	$('#login-ajax').fadeOut(fadeTime);
	$('#login-username').focus();
}

/*
	Forgot password functions
*/

function forgotPassword(email) {
	let data = {
		'client_id':  'tqY8tYlobY4hc16ph5B61dpMJ1YzDaAR',
		'connection': 'Isaac-Server-DB-Connection',
		'email':      email,
	};
	let request = $.ajax({
		url:  'https://isaacserver.auth0.com/dbconnections/change_password',
		type: 'POST',
		data: JSON.stringify(data),
		contentType: 'application/json',
	});
	request.done(function() {
		// The request was successful
		currentScreen = 'transition';
		forgotReset();
		$('#forgot-error').fadeOut(fadeTime);
		$('#forgot-success').fadeIn(fadeTime, function() {
			currentScreen = 'forgot';
		});
		$('#forgot-success').html('<span lang="en">Request successful. Please check your email.</span>');
	});
	request.fail(forgotFail);
}

// When an AJAX call fails
function forgotFail(jqXHR) {
	currentScreen = 'transition';
	forgotReset();

	// Show the error box
	let error = findAjaxError(jqXHR);
	$('#forgot-error').html('<span lang="en">' + error + '</span>');
	$('#forgot-success').fadeOut(fadeTime);
	$('#forgot-error').fadeIn(fadeTime, function() {
		currentScreen = 'forgot';
	});
}

// A function to return the forgot form back to the way it was initially
function forgotReset() {
	if ($('#forgot-success').css('display') !== 'none') {
		$('#forgot-success').fadeTo(fadeTime, 1);
	}
	if ($('#forgot-error').css('display') !== 'none') {
		$('#forgot-error').fadeTo(fadeTime, 1);
	}
	$('#forgot-form').fadeTo(fadeTime, 1);
	$('#forgot-email').prop('disabled', false);
	$('#forgot-submit-button').prop('disabled', false);
	$('#forgot-back-button').prop('disabled', false);
	$('#forgot-ajax').fadeOut(fadeTime);
	$('#forgot-email').focus();
}

/*
	Register functions
*/

// Register with Auth0
function register(username, password, email) {
	let data = {
		'client_id':  'tqY8tYlobY4hc16ph5B61dpMJ1YzDaAR',
		'connection': 'Isaac-Server-DB-Connection',
		'username':   username,
		'password':   password,
		'email':      email,
	};
	let request = $.ajax({
		url:  'https://isaacserver.auth0.com/dbconnections/signup',
		type: 'POST',
		data: JSON.stringify(data),
		contentType: 'application/json',
	});
	request.done(function(data) {
		// Fill in the input fields in the login form in case there is an error later on
		$('#login-username').val(username);
		$('#login-password').val(password);

		// The account was successfully created; now begin the log in process
		login1(username, password, false);
	});
	request.fail(registerFail);
}

// When an AJAX call fails
function registerFail(jqXHR) {
	currentScreen = 'transition';
	registerReset();

	// Show the error box
	let error = findAjaxError(jqXHR);
	$('#register-error').html('<span lang="en">' + error + '</span>');
	$('#register-error').fadeIn(fadeTime, function() {
		currentScreen = 'register';
	});
}

// A function to return the register form back to the way it was initially
function registerReset() {
	$('#register-form').fadeTo(fadeTime, 1);
	$('#register-username').prop('disabled', false);
	$('#register-password').prop('disabled', false);
	$('#register-email').prop('disabled', false);
	$('#register-submit-button').prop('disabled', false);
	$('#register-back-button').prop('disabled', false);
	$('#register-ajax').fadeOut(fadeTime);
	$('#register-username').focus();
}

/*
	Lobby functions
*/

// Called from the login screen or the register screen
function lobbyShow() {
	// Check to make sure the log file exists
	if (fs.existsSync(settings.logFilePath) === false) {
		settings.logFilePath = null;
	}

	// Check to ensure that we have a valid log file path
	if (settings.logFilePath === null ) {
		errorShow('', true); // Show the log file path modal
		return;
	}

	// Start the log monitoring program
	console.log('Starting the log monitoring program...');
	let command = (isDev ? 'app' : 'resources/app.asar') + '/assets/programs/watchLog/dist/watchLog.exe';
	logMonitoringProgram = spawn(command, [settings.logFilePath]);

	// Tail the IPC file
	let logWatcher = new Tail(path.join(os.tmpdir(), 'Racing+_IPC.txt'));
	logWatcher.on('line', function(line) {
		// Debug
		//console.log('- ' + line);

		// Don't do anything if we are not in a race
		if (currentRaceID === false) {
			return;
		}

		// Don't do anything if we have not started yet or we have quit
		for (let i = 0; i < raceList[currentRaceID].racerList.length; i++) {
			if (raceList[currentRaceID].racerList[i].name === myUsername) {
				if (raceList[currentRaceID].racerList[i].status !== 'racing') {
					return;
				}
				break;
			}
		}

		// Parse the line
		if (line.startsWith('New seed: ')) {
			let m = line.match(/New seed: (.... ....)/);
			if (m) {
				let seed = m[1];
				console.log('New seed:', seed);
				conn.emit('raceSeed', {
					'id':   currentRaceID,
					'seed': seed,
				});
			} else {
				errorShow('Failed to parse the new seed.');
			}
		} else if (line.startsWith('New floor: ')) {
			let m = line.match(/New floor: (\d+)-\d+/);
			if (m) {
				let floor = m[1];
				console.log('New floor:', floor);
				conn.emit('raceFloor', {
					'id':    currentRaceID,
					'floor': floor,
				});
			} else {
				errorShow('Failed to parse the new floor.');
			}
		} else if (line.startsWith('New room: ')) {
			let m = line.match(/New room: (\d+)/);
			if (m) {
				let room = m[1];
				console.log('New room:', room);
				conn.emit('raceFloor', {
					'id':   currentRaceID,
					'room': room,
				});
			} else {
				errorShow('Failed to parse the new room.');
			}
		} else if (line.startsWith('New item: ')) {
			let m = line.match(/New item: (\d+)/);
			if (m) {
				let itemID = m[1];
				console.log('New item:', itemID);
				conn.emit('raceItem', {
					'id':   currentRaceID,
					'itemID': itemID,
				});
			} else {
				errorShow('Failed to parse the new item.');
			}
		} else if (line === 'Finished run: Blue Baby') {
			if (raceList[currentRaceID].ruleset.goal === 'Blue Baby') {
				console.log('Killed Blue Baby!');
				conn.emit('raceFinish', {
					'id': currentRaceID,
				});
			}
		} else if (line === 'Finished run: The Lamb') {
			if (raceList[currentRaceID].ruleset.goal === 'The Lamb') {
				console.log('Killed The Lamb!');
				conn.emit('raceFinish', {
					'id': currentRaceID,
				});
			}
		} else if (line === 'Finished run: Mega Satan') {
			if (raceList[currentRaceID].ruleset.goal === 'Mega Satan') {
				console.log('Killed Mega Satan!');
				conn.emit('raceFinish', {
					'id': currentRaceID,
				});
			}
		}
	});
	logWatcher.on('error', function(error) {
		errorShow('Something went wrong with the log monitoring program: "' + error);
	});

	// Make sure that all of the forms are cleared out
	$('#login-username').val('');
	$('#login-password').val('');
	$('#login-remember-checkbox').prop('checked', false);
	$('#login-error').fadeOut(0);
	$('#register-username').val('');
	$('#register-password').val('');
	$('#register-email').val('');
	$('#register-error').fadeOut(0);

	// Show the links in the header
	$('#header-profile').fadeIn(fadeTime);
	$('#header-leaderboards').fadeIn(fadeTime);
	$('#header-help').fadeIn(fadeTime);

	// Show the buttons in the header
	$('#header-new-race').fadeIn(fadeTime);
	$('#header-settings').fadeIn(fadeTime);
	$('#header-log-out').fadeIn(fadeTime);

	// Show the lobby
	$('#page-wrapper').removeClass('vertical-center');
	$('#lobby').fadeIn(fadeTime, function() {
		currentScreen = 'lobby';
	});

	// Fix the indentation on lines that were drawn when the element was hidden
	lobbyChatIndent('lobby');

	// Automatically scroll to the bottom of the chat box
	let bottomPixel = $('#lobby-chat-text').prop('scrollHeight') - $('#lobby-chat-text').height();
	$('#lobby-chat-text').scrollTop(bottomPixel);

	// Focus the chat input
	$('#lobby-chat-box-input').focus();
}

function lobbyShowFromRace() {
	// We should be on the race screen unless there is severe lag
	if (currentScreen !== 'race') {
		errorShow('Failed to return to the lobby since currentScreen is equal to "' + currentScreen + '".');
		return;
	}
	currentScreen = 'transition';
	currentRaceID = false;

	// Show and hide some buttons in the header
	$('#header-profile').fadeOut(fadeTime);
	$('#header-leaderboards').fadeOut(fadeTime);
	$('#header-help').fadeOut(fadeTime);
	$('#header-lobby').fadeOut(fadeTime, function() {
		$('#header-profile').fadeIn(fadeTime);
		$('#header-leaderboards').fadeIn(fadeTime);
		$('#header-help').fadeIn(fadeTime);
		$('#header-new-race').fadeIn(fadeTime);
		$('#header-settings').fadeIn(fadeTime);
	});

	// Show the lobby
	$('#race').fadeOut(fadeTime, function() {
		$('#lobby').fadeIn(fadeTime, function() {
			currentScreen = 'lobby';
		});

		// Fix the indentation on lines that were drawn when the element was hidden
		lobbyChatIndent('lobby');

		// Automatically scroll to the bottom of the chat box
		let bottomPixel = $('#lobby-chat-text').prop('scrollHeight') - $('#lobby-chat-text').height();
		$('#lobby-chat-text').scrollTop(bottomPixel);

		// Focus the chat input
		$('#lobby-chat-box-input').focus();
	});
}

function lobbyRaceDraw(race) {
	// Create the new row
	let raceDiv = '<tr id="lobby-current-races-' + race.id + '" class="';
	if (race.status === 'open') {
		raceDiv += 'lobby-race-row-open ';
	}
	raceDiv += 'hidden"><td>Race ' + race.id;
	if (race.name !== '-') {
		raceDiv += ' &mdash; ' + race.name;
	}
	raceDiv += '</td><td>';
	let circleClass;
	if (race.status === 'open') {
		circleClass = 'open';
	} else if (race.status === 'starting') {
		circleClass = 'starting';
	} else if (race.status === 'in progress') {
		circleClass = 'in-progress';
	}
	raceDiv += '<span id="lobby-current-races-' + race.id + '-status-circle" class="circle lobby-current-races-' + circleClass + '"></span>';
	raceDiv += ' &nbsp; <span id="lobby-current-races-' + race.id + '-status">' + race.status.capitalize() + '</span>';
	raceDiv += '</td><td id="lobby-current-races-' + race.id + '-racers">' + race.racers.length + '</td>';
	raceDiv += '<td><span class="lobby-current-races-format-icon">';
	raceDiv += '<span class="lobby-current-races-' + race.ruleset.format + '"></span></span>';
	raceDiv += '<span class="lobby-current-races-spacing"></span>';
	raceDiv += '<span lang="en">' + race.ruleset.format.capitalize() + '</span></td>';
	raceDiv += '<td id="lobby-current-races-' + race.id + '-captain">' + race.captain + '</td></tr>';

	// Fade in the new row
	$('#lobby-current-races-table-body').append(raceDiv);
	if ($('#lobby-current-races-table-no').css('display') !== 'none') {
		$('#lobby-current-races-table-no').fadeOut(fadeTime, function() {
			$('#lobby-current-races-table').fadeIn(0);
			$('#lobby-current-races-' + race.id).fadeIn(fadeTime, function() {
				lobbyRaceRowClickable(race.id);
			});
		});
	} else {
		$('#lobby-current-races-' + race.id).fadeIn(fadeTime, function() {
			lobbyRaceRowClickable(race.id);
		});
	}

	// Make it clickable
	function lobbyRaceRowClickable(raceID) {
		if (raceList[raceID].status === 'open') {
			$('#lobby-current-races-' + raceID).click(function() {
				conn.emit('raceJoin', {
					'id': raceID,
				});
			});
		}
	}
}

function lobbyRaceUndraw(raceID) {
	$('#lobby-current-races-' + raceID).fadeOut(fadeTime, function() {
		$('#lobby-current-races-' + raceID).remove();

		if (Object.keys(raceList).length === 0) {
			$('#lobby-current-races-table').fadeOut(0);
			$('#lobby-current-races-table-no').fadeIn(fadeTime);
		}
	});
}

function chatSend(destination) {
	// Don't do anything if we are not on the screen corresponding to the chat input form
	if (destination === 'lobby' && currentScreen !== 'lobby') {
		return;
	} else if (destination === 'race' && currentScreen !== 'race') {
		return;
	}

	// Get values from the form
	let message = document.getElementById(destination + '-chat-box-input').value.trim();

	// Do nothing if the input field is empty
	if (message === '') {
		return;
	}

	// Truncate messages longer than 150 characters (this is also enforced server-side)
	if (message.length > 150) {
		message = message.substring(0, 150);
	}

	// Erase the contents of the input field
	$('#' + destination + '-chat-box-input').val('');

	// Get the room
	let room;
	if (destination === 'lobby') {
		room = 'lobby';
	} else if (destination === 'race') {
		room = '_race_' + currentRaceID;
	}

	// Add it to the history so that we can use up arrow later
	roomList[room].typedHistory.unshift(message);

	// Reset the history index
	roomList[room].historyIndex = -1;

	// Check for the presence of commands
	if (message === '/debug') {
		// /debug - Debug command
		debug();
	} else if (message === '/restart') {
		ipcRenderer.send('asynchronous-message', 'restart');
	} else if (message.match(/^\/msg .+? .+/)) {
		// /msg - Private message
		let m = message.match(/^\/msg (.+?) (.+)/);
		let name = m[1];
		message = m[2];
		conn.emit('privateMessage', {
			'name': name,
			'message': message,
		});

		// We won't get a message back from the server if the sending of the PM was successful, so manually call the draw function now
		chatDraw('PM-to', name, message);
	} else {
		conn.emit('roomMessage', {
			'room': room,
			'message':  message,
		});
	}
}

function chatDraw(room, name, message, datetime = null) {
	// Check for the existence of a PM
	let privateMessage = false;
	if (room === 'PM-to') {
		room = currentScreen;
		privateMessage = 'to';
	} else if (room === 'PM-from') {
		room = currentScreen;
		privateMessage = 'from';
	}

	// Keep track of how many lines of chat have been spoken in this room
	roomList[room].chatLine++;

	// Sanitize the input
	message = htmlEntities(message);

	// Check for emotes and insert them if present
	message = chatEmotes(message);

	// Get the hours and minutes from the time
	let date;
	if (datetime === null) {
		date = new Date();
	} else {
		date = new Date(datetime);
	}
	let hours = date.getHours();
	if (hours < 10) {
		hours = '0' + hours;
	}
	let minutes = date.getMinutes();
	if (minutes < 10) {
		minutes = '0' + minutes;
	}

	// Construct the chat line
	let chatLine = '<div id="' + room + '-chat-text-line-' + roomList[room].chatLine + '" class="hidden">';
	chatLine += '<span id="' + room + '-chat-text-line-' + roomList[room].chatLine + '-header">';
	chatLine += '[' + hours + ':' + minutes + '] &nbsp; ';
	if (privateMessage !== false) {
		chatLine += '<span class="chat-pm">[PM ' + privateMessage + ' <strong class="chat-pm">' + name + '</strong>]</span> &nbsp; ';
	} else {
		chatLine += '&lt;<strong>' + name + '</strong>&gt; &nbsp; ';
	}
	chatLine += '</span>';
	chatLine += message;
	chatLine += '</div>';

	// Find out if we should automatically scroll down after adding the new line of chat
	let autoScroll = false;
	let bottomPixel = $('#' + room + '-chat-text').prop('scrollHeight') - $('#' + room + '-chat-text').height();
	if ($('#' + room + '-chat-text').scrollTop() === bottomPixel) {
		// If we are already scrolled to the bottom, then it is ok to automatically scroll
		autoScroll = true;
	}

	// Add the new line
	let destination;
	if (room === 'lobby') {
		destination = 'lobby';
	} else if (room.startsWith('_race_')) {
		destination = 'race';
	} else {
		errorShow('Failed to parse the room in the "chatDraw" function.');
	}
	if (datetime === null) {
		$('#' + destination + '-chat-text').append(chatLine);
	} else {
		// We prepend instead of append because the chat history comes in order from most recent to least recent
		$('#' + destination + '-chat-text').prepend(chatLine);
	}
	$('#' + room + '-chat-text-line-' + roomList[room].chatLine).fadeIn(fadeTime);

	// Set indentation for long lines
	if (room === 'lobby') {
		let indentPixels = $('#' + room + '-chat-text-line-' + roomList[room].chatLine + '-header').css('width');
		$('#' + room + '-chat-text-line-' + roomList[room].chatLine).css('padding-left', indentPixels);
		$('#' + room + '-chat-text-line-' + roomList[room].chatLine).css('text-indent', '-' + indentPixels);
	}

	// Automatically scroll
	if (autoScroll) {
		bottomPixel = $('#' + room + '-chat-text').prop('scrollHeight') - $('#' + room + '-chat-text').height();
		$('#' + room + '-chat-text').scrollTop(bottomPixel);
	}
}

function chatEmotes(message) {
	// Get a list of all of the emotes
	let emoteList = _getAllFilesFromFolder(__dirname + '/assets/img/emotes');

	// Chop off the .png from the end of each element of the array
	for (let i = 0; i < emoteList.length; i++) {
		emoteList[i] = emoteList[i].slice(0, -4); // ".png" is 4 characters long
	}

	// Search through the text for each emote
	for (let i = 0; i < emoteList.length; i++) {
		if (message.indexOf(emoteList[i]) !== -1) {
			let emoteTag = '<img class="chat-emote" src="assets/img/emotes/' + emoteList[i] + '.png" alt="' + emoteList[i] + '" />';
			let re = new RegExp('\\b' + emoteList[i] + '\\b', 'g'); // "\b" is a word boundary in regex
			message = message.replace(re, emoteTag);
		}
	}

	return message;
}

function lobbyChatIndent(room) {
	if (typeof roomList[room] === 'undefined') {
		return;
	}

	for (let i = 1; i <= roomList[room].chatLine; i++) {
		let indentPixels = $('#' + room + '-chat-text-line-' + i + '-header').css('width');
		$('#' + room + '-chat-text-line-' + i).css('padding-left', indentPixels);
		$('#' + room + '-chat-text-line-' + i).css('text-indent', '-' + indentPixels);
	}
}

function lobbyUsersDraw(room) {
	// Update the header that shows shows the amount of people online or in the race
	$('#lobby-users-online').html(roomList[room].numUsers);

	// Make an array with the name of every user and alphabetize it
	let userList = [];
	for (let user in roomList[room].users) {
		if (!roomList[room].users.hasOwnProperty(user)) {
			continue;
		}

		userList.push(user);
	}
	userList.sort();

	// Empty the existing list
	$('#lobby-users-users').html('');

	// Add a div for each player
	for (let i = 0; i < userList.length; i++) {
		if (userList[i] === myUsername) {
			let userDiv = '<div>' + userList[i] + '</div>';
			$('#lobby-users-users').append(userDiv);
		} else {
			let userDiv = '<div id="lobby-users-' + userList[i] + '" class="users-user" data-tooltip-content="#user-click-tooltip">';
			userDiv += userList[i] + '</div>';
			$('#lobby-users-users').append(userDiv);

			// Add the tooltip
			$('#lobby-users-' + userList[i]).tooltipster({
				theme: 'tooltipster-shadow',
				trigger: 'click',
				interactive: true,
				side: 'left',
				functionBefore: userTooltipChange(userList[i]),
			});
		}
	}

	function userTooltipChange(username) {
		$('#user-click-profile').click(function() {
			let url = 'http' + (secure ? 's' : '') + '://' + domain + '/profiles/' + username;
			shell.openExternal(url);
		});
		$('#user-click-private-message').click(function() {
			if (currentScreen === 'lobby') {
				$('#lobby-chat-box-input').val('/msg ' + username + ' ');
				$('#lobby-chat-box-input').focus();
			} else if (currentScreen === 'race') {
				$('#race-chat-box-input').val('/msg ' + username + ' ');
				$('#race-chat-box-input').focus();
			} else {
				errorShow('Failed to fill in the chat box since currentScreen is "' + currentScreen + '".');
			}
			closeAllTooltips();
		});
	}
}

/*
	Race functions
*/

function raceShow(raceID) {
	// We should be on the lobby screen unless there is severe lag
	if (currentScreen === 'transition') {
		setTimeout(function() {
			raceShow(raceID);
		}, fadeTime + 10); // 10 milliseconds of leeway;
		return;
	} else if (currentScreen !== 'lobby') {
		errorShow('Failed to enter the race screen since currentScreen is equal to "' + currentScreen + '".');
		return;
	}
	currentScreen = 'transition';
	currentRaceID = raceID;

	// Put the seed in the clipboard
	if (raceList[currentRaceID].seed !== '-') {
		clipboard.writeText(raceList[currentRaceID].seed);
	}

	// Show and hide some buttons in the header
	$('#header-profile').fadeOut(fadeTime);
	$('#header-leaderboards').fadeOut(fadeTime);
	$('#header-help').fadeOut(fadeTime);
	$('#header-new-race').fadeOut(fadeTime);
	$('#header-settings').fadeOut(fadeTime, function() {
		$('#header-profile').fadeIn(fadeTime);
		$('#header-leaderboards').fadeIn(fadeTime);
		$('#header-help').fadeIn(fadeTime);
		$('#header-lobby').fadeIn(fadeTime);
	});

	// Close all tooltips
	closeAllTooltips();

	// Show the race screen
	$('#lobby').fadeOut(fadeTime, function() {
		$('#race').fadeIn(fadeTime, function() {
			currentScreen = 'race';
		});

		// Set the title
		let raceTitle = 'Race ' + currentRaceID;
		if (raceList[currentRaceID].name !== '-') {
			raceTitle += ' &mdash; ' + raceList[currentRaceID].name;
		}
		$('#race-title').html(raceTitle);

		// Adjust the font size so that it only takes up one line
		let emSize = 1.75; // In HTML5UP Alpha, h3's are 1.75
		while (true) {
			// Reset the font size (we could be coming from a previous race)
			$('#race-title').css('font-size', emSize + 'em');

			// One line is 45 pixels high
			if ($('#race-title').height() > 45) {
				// Reduce the font size by a little bit
				emSize -= 0.1;
			} else {
				break;
			}
		}

		// Set the status and format
		$('#race-title-status').html(raceList[currentRaceID].status.capitalize());
		$('#race-title-format').html(raceList[currentRaceID].ruleset.format.capitalize());
		$('#race-title-character').html(raceList[currentRaceID].ruleset.character);
		$('#race-title-goal').html(raceList[currentRaceID].ruleset.goal);
		$('#race-title-goal').html(raceList[currentRaceID].ruleset.goal);
		if (raceList[currentRaceID].ruleset.format === 'seeded' || raceList[currentRaceID].ruleset.format === 'diveristy') {
			$('#race-title-table-seed').fadeIn(0);
			$('#race-title-seed').fadeIn(0);
			$('#race-title-seed').html(raceList[currentRaceID].seed);
		} else {
			$('#race-title-table-seed').fadeOut(0);
			$('#race-title-seed').fadeOut(0);
		}
		if (raceList[currentRaceID].ruleset.format === 'seeded') {
			$('#race-title-table-build').fadeIn(0);
			$('#race-title-build').fadeIn(0);
			$('#race-title-build').html(raceList[currentRaceID].ruleset.startingBuild);
		} else {
			$('#race-title-table-build').fadeOut(0);
			$('#race-title-build').fadeOut(0);
		}

		// Show the pre-start race controls
		$('#race-ready-checkbox-container').fadeIn(0);
		$('#race-ready-checkbox').prop('checked', false);
		$('#race-countdown').fadeOut(0);
		$('#race-quit-button').fadeOut(0);

		// Set the race participants table to the pre-game state (with 2 columns)
		$('#race-participants-table-floor').fadeOut(0);
		$('#race-participants-table-item').fadeOut(0);
		$('#race-participants-table-time').fadeOut(0);
		$('#race-participants-table-offset').fadeOut(0);

		// Automatically scroll to the bottom of the chat box
		let bottomPixel = $('#race-chat-text').prop('scrollHeight') - $('#race-chat-text').height();
		$('#race-chat-text').scrollTop(bottomPixel);

		// Focus the chat input
		$('#race-chat-box-input').focus();

		// If we disconnected in the middle of the race, we need to update the race controls
		if (raceList[currentRaceID].status === 'starting') {
			errorShow('You rejoined the race during the countdown, which is not supported. Please relaunch the program.');
		} else if (raceList[currentRaceID].status === 'in progress') {
			raceStart();
		}
	});
}

// Add a row to the table with the race participants on the race screen
function raceParticipantAdd(i) {
	// Begin building the row
	let racerDiv = '<tr id="race-participants-table-' + raceList[currentRaceID].racerList[i].name + '">';

	// The racer's name
	racerDiv += '<td>' + raceList[currentRaceID].racerList[i].name + '</td>';

	// The racer's status
	racerDiv += '<td id="race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-status">';
	if (raceList[currentRaceID].racerList[i].status === 'ready') {
		racerDiv += '<i class="fa fa-check" aria-hidden="true"></i> &nbsp; ';
	} else if (raceList[currentRaceID].racerList[i].status === 'not ready') {
		racerDiv += '<i class="fa fa-times" aria-hidden="true"></i> &nbsp; ';
	} else if (raceList[currentRaceID].racerList[i].status === 'racing') {
		racerDiv += '<i class="mdi mdi-chevron-double-right"></i> &nbsp; ';
	} else if (raceList[currentRaceID].racerList[i].status === 'quit') {
		racerDiv += '<i class="mdi mdi-skull"></i> &nbsp; ';
	} else if (raceList[currentRaceID].racerList[i].status === 'finished') {
		racerDiv += '<i class="fa fa-check" aria-hidden="true"></i> &nbsp; ';
	}
	racerDiv += '<span lang="en">' + raceList[currentRaceID].racerList[i].status.capitalize() + '</span></td>';

	// The racer's floor
	racerDiv += '<td id="race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-floor" class="hidden">';
	racerDiv += raceList[currentRaceID].racerList[i].floor + '</td>';

	// The racer's starting item
	racerDiv += '<td id="race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-item" class="hidden">';
	if (raceList[currentRaceID].racerList[i].items !== null) {
		racerDiv += raceList[currentRaceID].racerList[i].items[0];
	} else {
		racerDiv += '-';
	}
	racerDiv += '</td>';

	// The racer's time
	racerDiv += '<td id="race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-time" class="hidden">';
	racerDiv += '</td>';

	// The racer's time offset
	racerDiv += '<td id="race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-offset" class="hidden">-</td>';

	// Append the row
	racerDiv += '</tr>';
	$('#race-participants-table-body').append(racerDiv);
	$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-status').attr('colspan', 5);
}

function raceMarkOnline() {

}

function raceCountdown() {
	// Change the functionality of the "Lobby" button in the header
	$('#header-lobby').addClass('disabled');

	// Show the countdown
	$('#race-ready-checkbox-container').fadeOut(fadeTime, function() {
		$('#race-countdown').css('font-size', '1.75em');
		$('#race-countdown').css('bottom', '0.25em');
		$('#race-countdown').css('color', '#e89980');
		$('#race-countdown').html('<span lang="en">Race starting in 10 seconds!</span>');
		$('#race-countdown').fadeIn(fadeTime);
	});
}

function raceCountdownTick(i) {
	if (i > 0) {
		$('#race-countdown').fadeOut(fadeTime, function() {
			$('#race-countdown').css('font-size', '2.5em');
			$('#race-countdown').css('bottom', '0.375em');
			$('#race-countdown').css('color', 'red');
			$('#race-countdown').html(i);
			$('#race-countdown').fadeIn(fadeTime);
			setTimeout(function() {
				if (i === 3 || i === 2 || i === 1) {
					let audio = new Audio('assets/sounds/' + i + '.wav');
					audio.volume = settings.volume;
					audio.play();
				}
			}, fadeTime / 2);
		});

		setTimeout(function() {
			raceCountdownTick(i - 1);
		}, 1000);
	}
}

function raceGo() {
	$('#race-countdown').html('<span lang="en">Go!</span>');
	$('#race-title-status').html('<span lang="en">In Progress</span>');

	// Press enter to start the race
	let command = (isDev ? 'app' : 'resources/app.asar') + '/assets/programs/raceGo.exe';
	execFile(command);

	// Play the "Go" sound effect
	let audio = new Audio('assets/sounds/go.wav');
	audio.volume = settings.volume;
	audio.play();

	// Wait 5 seconds, then start to change the controls
	setTimeout(raceStart, 5000);

	// Add default values to the columns to the race participants table
	for (let i = 0; i < raceList[currentRaceID].racerList.length; i++) {
		raceList[currentRaceID].racerList[i].status = 'racing';
		let statusDiv = '<i class="mdi mdi-chevron-double-right"></i> &nbsp; <span lang="en">Racing</span>';
		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-status').html(statusDiv);

		raceList[currentRaceID].racerList[i].status = 'racing';
		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-item').html('-');

		raceList[currentRaceID].racerList[i].status = 'racing';
		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-time').html('-');

		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-offset').html('-');
		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-offset').fadeIn(fadeTime);
	}
}

function raceStart() {
	// In case we coming back after a disconnect, redo all of the stuff that was done in the "raceCountdown" function
	$('#header-lobby').addClass('disabled');
	$('#race-ready-checkbox-container').fadeOut(0);

	// Start the race timer
	setTimeout(raceTimerTick, 0);

	// Change the controls on the race screen
	$('#race-countdown').fadeOut(fadeTime, function() {
		// Find out if we have quit this race already
		let alreadyQuit = false;
		for (let i = 0; i < raceList[currentRaceID].racerList.length; i++) {
			if (raceList[currentRaceID].racerList[i].name === myUsername &&
				raceList[currentRaceID].racerList[i].status === 'quit') {

				alreadyQuit = true;
			}
		}

		if (alreadyQuit === false) {
			$('#race-quit-button').fadeIn(fadeTime);
		}
	});

	// Change the table to have 6 columns instead of 2
	$('#race-participants-table-floor').fadeIn(fadeTime);
	$('#race-participants-table-item').fadeIn(fadeTime);
	$('#race-participants-table-time').fadeIn(fadeTime);
	$('#race-participants-table-offset').fadeIn(fadeTime);
	for (let i = 0; i < raceList[currentRaceID].racerList.length; i++) {
		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-status').attr('colspan', 1);
		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-floor').fadeIn(fadeTime);
		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-item').fadeIn(fadeTime);
		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-time').fadeIn(fadeTime);
		$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-offset').fadeIn(fadeTime);
	}
}

function raceTimerTick() {
	if (raceList.hasOwnProperty(currentRaceID) === false) {
		return;
	}

	// Get the elapsed time in the race
	let now = new Date().getTime();
	let raceMilliseconds = now - raceList[currentRaceID].datetimeStarted + timeOffset;
	let raceSeconds = Math.round(raceMilliseconds / 1000);
	let timeDiv = pad(parseInt(raceSeconds / 60, 10)) + ':' + pad(raceSeconds % 60);

	// Update all of the timers
	for (let i = 0; i < raceList[currentRaceID].racerList.length; i++) {
		if (raceList[currentRaceID].racerList[i].status === 'racing') {
			$('#race-participants-table-' + raceList[currentRaceID].racerList[i].name + '-time').html(timeDiv);
		}
	}

	// Schedule the next tick
	setTimeout(raceTimerTick, 1000);
}

/*
	Websocket handling
*/

function websocket(username, password, remember) {
	// Establish a WebSocket connection
	let url = 'ws' + (secure ? 's' : '') + '://' + domain + '/ws';
	conn = new golem.Connection(url, isDev); // It will automatically use the cookie that we recieved earlier
	// If the second argument is true, debugging is turned on

	/*
		Miscellaneous WebSocket handlers
	*/

	conn.on('open', function(event) {
		// Login success; join the lobby chat channel
		conn.emit('roomJoin', {
			'room': 'lobby',
		});

		// Save the credentials
		if (remember === true) {
			// Store the username (as a cookie)
			localStorage.username = username;

			// Store the password (in the OS vault)
			keytar.addPassword('Racing+', username, password);
		}

		// Do the proper transition to the lobby depending on where we logged in from
		if (currentScreen === 'title-ajax') {
			currentScreen = 'transition';
			$('#title').fadeOut(fadeTime, function() {
				$('#title-buttons').fadeIn(0);
				$('#title-languages').fadeIn(0);
				$('#title-version').fadeIn(0);
				$('#title-ajax').fadeOut(0);
				lobbyShow();
			});
		} else if (currentScreen === 'login-ajax') {
			currentScreen = 'transition';
			$('#login').fadeOut(fadeTime, function() {
				loginReset();
				lobbyShow();
			});
		} else if (currentScreen === 'register-ajax') {
			currentScreen = 'transition';
			$('#register').fadeOut(fadeTime, function() {
				registerReset();
				lobbyShow();
			});
		}
	});

	conn.on('close', connClose);

	function connClose(event) {
		// Check to see if this was intended
		if (currentScreen === 'error') {
			return;
		} else if (initiatedLogout === false) {
			errorShow('Disconnected from the server. Either your Internet is having problems or the server went down!');
			return;
		}

		// Reset some global variables
		roomList = {};
		raceList = {};
		myUsername = '';
		initiatedLogout = false;

		// Hide the links in the header
		$('#header-profile').fadeOut(fadeTime);
		$('#header-leaderboards').fadeOut(fadeTime);
		$('#header-help').fadeOut(fadeTime);

		// Hide the buttons in the header
		$('#header-lobby').fadeOut(fadeTime);
		$('#header-new-race').fadeOut(fadeTime);
		$('#header-settings').fadeOut(fadeTime);
		$('#header-log-out').fadeOut(fadeTime);

		// Transition to the title screen, depending on what screen we are currently on
		if (currentScreen === 'lobby') {
			// Show the title screen
			currentScreen = 'transition';
			$('#lobby').fadeOut(fadeTime, function() {
				$('#page-wrapper').addClass('vertical-center');
				$('#title').fadeIn(fadeTime, function() {
					currentScreen = 'title';
				});
			});
		} else if (currentScreen === 'race') {
			// Show the title screen
			currentScreen = 'transition';
			$('#race').fadeOut(fadeTime, function() {
				$('#page-wrapper').addClass('vertical-center');
				$('#title').fadeIn(fadeTime, function() {
					currentScreen = 'title';
				});
			});
		} else if (currentScreen === 'settings') {
			// Show the title screen
			currentScreen = 'transition';
			$('#settings').fadeOut(fadeTime, function() {
				$('#page-wrapper').addClass('vertical-center');
				$('#title').fadeIn(fadeTime, function() {
					currentScreen = 'title';
				});
			});
		} else if (currentScreen === 'transition') {
			// Come back when the current transition finishes
			setTimeout(function() {
				connClose(event);
			}, fadeTime + 10); // 10 milliseconds of leeway
		} else {
			errorShow('Unable to parse the "currentScreen" variable in the WebSocket close function.');
		}
	}

	conn.on('socketError', function(event) {
		if (currentScreen === 'title-ajax' ||
			currentScreen === 'login-ajax' ||
			currentScreen === 'register-ajax') {

			let error = 'Failed to connect to the WebSocket server. The server might be down!';
			loginFail(error);
		} else {
			let error = 'Encountered a WebSocket error. The server might be down!';
			errorShow(error);
		}
	});

	/*
		Miscellaneous command handlers
	*/

	// Sent upon a successful connection
	conn.on('username', function(data) {
		myUsername = data;
	});

	// Sent upon a successful connection
	conn.on('time', function(data) {
		let now = new Date().getTime();
		timeOffset = data - now;
	});

	conn.on('error', function(data) {
		errorShow(data.message);
	});

	/*
		Chat command handlers
	*/

	conn.on('roomList', function(data) {
		// We entered a new room, so keep track of all users in this room
		roomList[data.room] = {
			users: {},
			numUsers: 0,
			chatLine: 0,
			typedHistory: [],
			historyIndex: -1,
		};
		for (let i = 0; i < data.users.length; i++) {
			roomList[data.room].users[data.users[i].name] = data.users[i];
		}
		roomList[data.room].numUsers = data.users.length;

		if (data.room === 'lobby') {
			// Redraw the users list in the lobby
			lobbyUsersDraw(data.room);
		} else if (data.room.startsWith('_race_')) {
			let raceID = data.room.match(/_race_(\d+)/)[1];
			if (raceID === currentRaceID) {
				// Update the online/offline markers
				for (let i = 0; i < data.users.length; i++) {
					raceMarkOnline(data.users[i]);
				}
			}
		}
	});

	conn.on('roomHistory', function(data) {
		// Figure out what kind of chat room this is
		let destination;
		if (data.room === 'lobby') {
			destination = 'lobby';
		} else {
			destination = 'race';
		}

		// Empty the existing chat room, since there might still be some chat in there from a previous race or session
		$('#' + destination + '-chat-text').html('');

		// Add all of the chat
		for (let i = 0; i < data.history.length; i++) {
			chatDraw(data.room, data.history[i].name, data.history[i].message, data.history[i].datetime);
		}
	});

	conn.on('roomJoined', function(data) {
		// Keep track of the person who just joined
		roomList[data.room].users[data.user.name] = data.user;
		roomList[data.room].numUsers++;

		// Redraw the users list in the lobby
		if (data.room === 'lobby') {
			lobbyUsersDraw(data.room);
		}
	});

	conn.on('roomLeft', function(data) {
		// Remove them from the room list
		delete roomList[data.room].users[data.name];
		roomList[data.room].numUsers--;

		// Redraw the users list in the lobby
		if (data.room === 'lobby') {
			lobbyUsersDraw(data.room);
		}
	});

	conn.on('roomMessage', function(data) {
		chatDraw(data.room, data.name, data.message);
	});

	conn.on('privateMessage', function(data) {
		chatDraw('PM-from', data.name, data.message);
	});

	/*
		Race command handlers
	*/

	// On initial connection, we get a list of all of the races that are currently open or ongoing
	conn.on('raceList', function(data) {
		// Check for empty races
		if (data.length === 0) {
			$('#lobby-current-races-table-body').html('');
			$('#lobby-current-races-table').fadeOut(0);
			$('#lobby-current-races-table-no').fadeIn(0);
		}

		// Go through the list of races that were sent
		let mostCurrentRaceID = false;
		for (let i = 0; i < data.length; i++) {
			// Keep track of what races are currently going
			raceList[data[i].id] = data[i];
			raceList[data[i].id].racerList = {};

			// Update the "Current races" area
			lobbyRaceDraw(data[i]);

			// Check to see if we are in any races
			for (let j = 0; j < data[i].racers.length; j++) {
				if (data[i].racers[j] === myUsername) {
					mostCurrentRaceID = data[i].id;
					break;
				}
			}
		}
		if (mostCurrentRaceID !== false) {
			currentRaceID = mostCurrentRaceID; // This is normally set at the top of the raceShow function, but we need to set it now since we have to delay
			setTimeout(function() {
				raceShow(mostCurrentRaceID);
			}, fadeTime * 2 + 10); // 10 milliseconds of leeway
		}
	});

	// Sent when we reconnect in the middle of a race
	conn.on('racerList', function(data) {
		raceList[data.id].racerList = data.racers;

		// Build the table with the race participants on the race screen
		$('#race-participants-table-body').html('');
		for (let i = 0; i < raceList[currentRaceID].racerList.length; i++) {
			raceParticipantAdd(i);
		}
	});

	conn.on('raceCreated', function(data) {
		// Keep track of what races are currently going
		raceList[data.id] = data;

		// Update the "Current races" area
		lobbyRaceDraw(data);

		// Check to see if we created this race
		if (data.captain === myUsername) {
			raceShow(data.id);
		}
	});

	conn.on('raceJoined', function(data) {
		// Keep track of the people in each race
		raceList[data.id].racers.push(data.name);

		// Update the "# of Entrants" column in the lobby
		$('#lobby-current-races-' + data.id + '-racers').html(raceList[data.id].racers.length);

		if (data.name === myUsername) {
			// If we joined this race
			raceShow(data.id);
		} else {
			// Update the race screen
			if (data.id === currentRaceID) {
				// We are in this race
				let datetime = new Date().getTime();
				raceList[data.id].racerList.push({
					'name':   data.name,
					'status': 'not ready',
					'datetimeJoined': datetime,
					'datetimeFinished': 0,
					'place': 0,
				});
				raceParticipantAdd(raceList[data.id].racerList.length - 1);
			}
		}
	});

	conn.on('raceLeft', function(data) {
		// Delete this person from the race list
		if (raceList[data.id].racers.indexOf(data.name) !== -1) {
			raceList[data.id].racers.splice(raceList[data.id].racers.indexOf(data.name), 1);
		} else {
			errorShow('"' + data.name + '" left race #' + data.id + ', but they were not in the entrant list.');
			return;
		}

		// Update the "Current races" area
		if (raceList[data.id].racers.length === 0) {
			// Delete the race since the last person in the race left
			delete raceList[data.id];
			lobbyRaceUndraw(data.id);
		} else {
			// Check to see if this person was the captain, and if so, make the next person in line the captain
			if (raceList[data.id].captain === data.name) {
				raceList[data.id].captain = raceList[data.id].racers[0];
				$('#lobby-current-races-' + data.id + '-captain').html(raceList[data.id].captain);
			}

			// Update the "# of Entrants" column
			$('#lobby-current-races-' + data.id + '-racers').html(raceList[data.id].racers.length);

		}

		// If we left the race
		if (data.name === myUsername) {
			// Show the lobby
			lobbyShowFromRace();
			return;
		}

		// If we are in this race
		if (data.id === currentRaceID) {
			// Remove the row for this player
			$('#race-participants-table-' + data.name).remove();

			if (raceList[currentRaceID].status === 'open') {
				// Update the captian
				// Not implemented
			}
		}
	});

	conn.on('raceSetStatus', function(data) {
		// Update the status
		raceList[data.id].status = data.status;

		// Update the "Status" column in the lobby
		let circleClass;
		if (data.status === 'open') {
			circleClass = 'open';
		} else if (data.status === 'starting') {
			circleClass = 'starting';
			$('#lobby-current-races-' + data.id).removeClass('lobby-race-row-open');
			$('#lobby-current-races-' + data.id).unbind();
		} else if (data.status === 'in progress') {
			circleClass = 'in-progress';
		} else if (data.status === 'finished') {
			// Delete the race
			delete raceList[data.id];
			lobbyRaceUndraw(data.id);
		} else {
			errorShow('Unable to parse the race status from the raceSetStatus command.');
		}
		$('#lobby-current-races-' + data.id + '-status-circle').removeClass();
		$('#lobby-current-races-' + data.id + '-status-circle').addClass('circle lobby-current-races-' + circleClass);
		$('#lobby-current-races-' + data.id + '-status').html(data.status.capitalize());

		// Check to see if we are in this race
		if (data.id === currentRaceID) {
			if (data.status === 'starting') {
				// Update the status column in the race title
				$('#race-title-status').html('<span lang="en">' + data.status.capitalize() + '</span>');

				// Start the countdown
				raceCountdown();
			} else if (data.status === 'in progress') {
				// Do nothing special; after the countdown is finished, the race controls will fade in
			} else if (data.status === 'finished') {
				// Update the status column in the race title
				$('#race-title-status').html('<span lang="en">' + data.status.capitalize() + '</span>');

				// Remove the race controls
				$('#header-lobby').removeClass('disabled');
				$('#race-quit-button').fadeOut(fadeTime, function() {
					$('#race-countdown').css('font-size', '1.75em');
					$('#race-countdown').css('bottom', '0.25em');
					$('#race-countdown').css('color', '#e89980');
					$('#race-countdown').html('<span lang="en">Race completed</span>!');
					$('#race-countdown').fadeIn(fadeTime);
				});
			} else {
				errorShow('Failed to parse the status of race #' + data.id + ': ' + raceList[data.id].status);
			}
		}

		// Remove the race if it is finished
		if (data.status === 'finished') {
			delete raceList[data.id];
		}
	});

	conn.on('racerSetStatus', function(data) {
		if (data.id !== currentRaceID) {
			return;
		}

		// Find the player in the racerList
		for (let i = 0; i < raceList[data.id].racerList.length; i++) {
			if (data.name === raceList[data.id].racerList[i].name) {
				// Update their status locally
				raceList[data.id].racerList[i].status = data.status;

				// Update the race screen
				if (currentScreen === 'race' && data.id === currentRaceID) {
					let statusDiv;
					if (data.status === 'ready') {
						statusDiv = '<i class="fa fa-check" aria-hidden="true"></i> &nbsp; ';
					} else if (data.status === 'not ready') {
						statusDiv = '<i class="fa fa-times" aria-hidden="true"></i> &nbsp; ';
					} else if (data.status === 'racing') {
						statusDiv = '<i class="mdi mdi-chevron-double-right"></i> &nbsp; ';
					} else if (data.status === 'quit') {
						statusDiv = '<i class="mdi mdi-skull"></i> &nbsp; ';
					} else if (data.status === 'finished') {
						statusDiv = '<i class="fa fa-check" aria-hidden="true"></i> &nbsp; ';
					}
					statusDiv += '<span lang="en">' + data.status.capitalize() + '</span>';
					$('#race-participants-table-' + data.name + '-status').html(statusDiv);
				}

				break;
			}
		}

		// If we quit
		if (data.name === myUsername && data.status === 'quit') {
			$('#race-quit-button').fadeOut(fadeTime);
		}
	});

	conn.on('raceSetRuleset', function(data) {
		// Not implemented
	});

	conn.on('raceStart', function(data) {
		if (data.id !== currentRaceID) {
			errorShow('Got a "raceStart" command for a race that is not the current race.');
		}

		// Keep track of when the race starts
		raceList[currentRaceID].datetimeStarted = data.time;

		// Schedule the countdown and race (in two separate callbacks for more accuracy)
		let now = new Date().getTime();
		let timeToStartCountdown = data.time - now - timeOffset - 5000 - fadeTime;
		setTimeout(function() {
			raceCountdownTick(5);
		}, timeToStartCountdown);
		let timeToStartRace = data.time - now - timeOffset;
		setTimeout(raceGo, timeToStartRace);
	});
}

/*
	Localization
*/

function localize(new_language) {
	// Validate function arguments
	if (new_language !== 'en' &&
		new_language !== 'fr' &&
		new_language !== 'es') {

		console.error('Unsupported language.');
		return;
	}

	// Set the new language
	settings.language = new_language;
	localStorage.language = settings.language;

	if (settings.language === 'en') {
		// English
		$('#title-language-english').html('English');
		$('#title-language-english').removeClass('unselected-language');
		$('#title-language-english').addClass('selected-language');
		$('#title-language-english').unbind();
		$('#title-language-french').html('<a>Français</a>');
		$('#title-language-french').removeClass('selected-language');
		$('#title-language-french').addClass('unselected-language');
		$('#title-language-french').click(function() {
			localize('fr');
		});

		lang.change('en');

	} else if (settings.language === 'fr') {
		// French (Français)
		$('#title-language-english').html('<a>English</a>');
		$('#title-language-english').removeClass('selected-language');
		$('#title-language-english').addClass('unselected-language');
		$('#title-language-english').click(function() {
			localize('en');
		});
		$('#title-language-french').html('Français');
		$('#title-language-french').removeClass('unselected-language');
		$('#title-language-french').addClass('selected-language');
		$('#title-language-french').unbind();

		lang.change('fr');
	}
}

/*
	Error functions
*/

function errorShow(message, alternateScreen = false) {
	// Come back in a second if we are still in a transition
	if (currentScreen === 'transition') {
		setTimeout(function() {
			errorShow(message, alternateScreen);
		}, fadeTime + 10); // 10 milliseconds of leeway;
		return;
	}

	// Log the message
	console.error('Error:', message);

	// Don't do anything if we are already showing an error
	if (currentScreen === 'error') {
		return;
	}
	currentScreen = 'error';

	// Disconnect from the server, if connected
	conn.close();

	// Hide the links in the header
	$('#header-profile').fadeOut(fadeTime);
	$('#header-leaderboards').fadeOut(fadeTime);
	$('#header-help').fadeOut(fadeTime);

	// Hide the buttons in the header
	$('#header-lobby').fadeOut(fadeTime);
	$('#header-new-race').fadeOut(fadeTime);
	$('#header-settings').fadeOut(fadeTime);
	$('#header-log-out').fadeOut(fadeTime);

	// Close all tooltips
	closeAllTooltips();

	$('#gui').fadeTo(fadeTime, 0.1, function() {
		if (alternateScreen === true) {
			// Show the log file selector screen
			$('#log-file-modal').fadeIn(fadeTime);
		} else {
			// Show the error modal
			$('#error-modal').fadeIn(fadeTime);
			$('#error-modal-description').html(message);
		}
	});
}

function warningShow(message) {
	// Come back in a second if we are still in a transition
	if (currentScreen === 'transition') {
		setTimeout(function() {
			warningShow(message);
		}, fadeTime + 10); // 10 milliseconds of leeway;
		return;
	}

	// Log the message
	console.error('Warning:', message);

	// Don't do anything if we are already showing a warning
	if (currentScreen === 'warning') {
		return;
	}
	currentScreen = 'warning';

	$('#gui').fadeTo(fadeTime, 0.1, function() {
		// Show the error modal
		$('#warning-modal').fadeIn(fadeTime);
		$('#warning-modal-description').html(message);
	});
}

/*
	Miscellaneous functions
*/

function findAjaxError(jqXHR) {
	// Find out what error it was
	let error;
	if (jqXHR.hasOwnProperty('readyState')) {
		if (jqXHR.readyState === 4) {
			// HTTP error
			if (tryParseJSON(jqXHR.responseText) !== false) {
				error = JSON.parse(jqXHR.responseText); // jqXHR.response doesn't work for some reason
				if (error.hasOwnProperty('error_description')) { // Some errors have the plain text description in the "error_description" field
					error = error.error_description;
				} else if (error.hasOwnProperty('description')) { // Some errors have the plain text description in the "description" field
					error = error.description;
				} else if (error.hasOwnProperty('error')) { // Some errors have the plain text description in the "error" field
					error = error.error;
				} else {
					error = 'An unknown HTTP error occured.';
				}
			} else {
				error = jqXHR.responseText;
			}
		} else if (jqXHR.readyState === 0) {
			// Network error (connection refused, access denied, etc.)
			error = 'A network error occured. The server might be down!';
		} else {
			// Unknown error
			error = 'An unknown error occured.';
		}
	} else {
		// Unknown error
		error = 'An unknown error occured.';
	}

	// Auth0 has some crappy error messages, so rewrite them to be more clear
	if (error === 'Wrong email or password.') {
		error = 'Wrong username or password.';
	} else if (error === 'The user already exists.') { // Auth0 has a crappy error message for this, so rewrite it
		error = 'Someone has already registered with that email address.';
	} else if (error === 'invalid email address') {
		error = 'Invalid email address.';
	}

	return error;
}

function closeAllTooltips() {
	let instances = $.tooltipster.instances();
	$.each(instances, function(i, instance){
		instance.close();
	});
}

// From: https://css-tricks.com/snippets/javascript/htmlentities-for-javascript/
function htmlEntities(str) {
	return String(str)
		.replace(/&/g, '&amp;')
		.replace(/</g, '&lt;')
		.replace(/>/g, '&gt;')
		.replace(/"/g, '&quot;');
}

// From: https://stackoverflow.com/questions/20822273/best-way-to-get-folder-and-file-list-in-javascript
function _getAllFilesFromFolder(dir) {
	let results = [];
	fs.readdirSync(dir).forEach(function(file) {
		// Commenting this out because we don't need the full path
		//file = dir + '/' + file;

		// Commenting this out because we don't need recursion
		/*let stat = fs.statSync(file);
		if (stat && stat.isDirectory()) {
			results = results.concat(_getAllFilesFromFolder(file));
		} else {
			results.push(file);
		}*/
		results.push(file);
	});

	return results;
}

// From: https://stackoverflow.com/questions/3710204/how-to-check-if-a-string-is-a-valid-json-string-in-javascript-without-using-try
function tryParseJSON(jsonString){
	try {
		let o = JSON.parse(jsonString);

		// Handle non-exception-throwing cases:
		// Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
		// but... JSON.parse(null) returns null, and typeof null === 'object',
		// so we must check for that, too. Thankfully, null is falsey, so this suffices:
		if (o && typeof o === 'object') {
			return o;
		}
	}
	catch (e) { }

	return false;
}

function getRandomNumber(minNumber, maxNumber) {
	// Get a random number between minNumber and maxNumber
	return Math.floor(Math.random() * (parseInt(maxNumber) - parseInt(minNumber) + 1) + parseInt(minNumber));
}

// From: https://stackoverflow.com/questions/2332811/capitalize-words-in-string
String.prototype.capitalize = function() {
	return this.replace(/(?:^|\s)\S/g, function(a) {
		return a.toUpperCase();
	});
};

// From: https://stackoverflow.com/questions/5517597/plain-count-up-timer-in-javascript
function pad(val) {
	return val > 9 ? val : '0' + val;
}
