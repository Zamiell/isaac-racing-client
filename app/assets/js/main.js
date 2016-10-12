'use strict';

/*
	TODO

	- tab complete for chat
	- change lobby-users-user to agnostic
	- raceEnter
*/

/*
	Isaac Racing Client stuff
*/

// Constants
const serverURL = 'isaacitemtracker.com';
const secure = true; // "true" for HTTPS/WSS and "false" for HTTP/WS
const fadeTime = 300;

// Imports
const {ipcRenderer} = nodeRequire('electron');
const {remote} = nodeRequire('electron');
const {Menu, MenuItem} = remote;
const {shell} = nodeRequire('electron');
const keytar = nodeRequire('keytar');
const fs = nodeRequire('fs');

// Global variables
var currentScreen = 'title';
var conn;
var roomList = {};
var raceList = {};
var myUsername;
var initiatedLogout = false;
var runningInDev = false;
var wordList;
var language;
var lang;

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
	- _race_##### (corresponding to the current race ID)
	- settings
	- error
	- transition
*/

/*
	Debug functions
*/

function debug() {
	console.log('Entering debug function.');
	//errorShow('fuck');
}

/*
	Program initialization
*/

// Check to see if we are running in development by checking for the existance of the "assets" directory
try {
	fs.accessSync('assets', fs.F_OK);
} catch (e) {
	runningInDev = true;
}
if (runningInDev === true) {
	// Importing this adds a right-click menu with 'Inspect Element' option
	let rightClickPosition = null;

	const menu = new Menu();
	const menuItem = new MenuItem({
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

// Set up localization
language = localStorage.language;
if (typeof language === 'undefined') { // If this is the first run, default to English
	language = 'en';
	localStorage.language = 'en';
}
lang = new Lang(); // Create a language switcher instance
lang.dynamic('fr', 'assets/js/langpack/fr.json');
lang.init({
	defaultLang: 'en',
});

// Read in the word list for later
let wordListLocation = (runningInDev === true ? 'app/' : '') + 'assets/words/words.txt';
wordList = fs.readFileSync(wordListLocation).toString().split('\n');

/*
	UI functionality
*/

$(document).ready(function() {
	// If the user is using a non-default language, change all the text on the page
	if (language !== 'en') {
		localize(language);
	}

	// Find out if the user has saved credentials
	let storedUsername = localStorage.username;
	if (typeof storedUsername !== 'undefined') {
		let storedPassword = keytar.getPassword('Racing+', storedUsername);
		if (storedPassword !== null) {
			// Show an AJAX circle
			currentScreen = 'title-ajax';
			$('#title-buttons').fadeOut(0);
			$('#title-languages').fadeOut(0);
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
			if (currentScreen === 'lobby') {
				if ($('#lobby-chat-box-input').is(':focus')) {
					event.preventDefault();
					roomList.lobby.historyIndex++;

					// Check to see if we have reached the end of the history list
					if (roomList.lobby.historyIndex > roomList.lobby.typedHistory.length - 1) {
						roomList.lobby.historyIndex--;
						return;
					}

					// Set the chat input box to what we last typed
					let retrievedHistory = roomList.lobby.typedHistory[roomList.lobby.historyIndex];
					$('#lobby-chat-box-input').val(retrievedHistory);
				}
			}
		} else if (event.which === 40) { // Down arrow
			if (currentScreen === 'lobby') {
				if ($('#lobby-chat-box-input').is(':focus')) {
					event.preventDefault();
					roomList.lobby.historyIndex--;

					// Check to see if we have reached the beginning of the history list
					if (roomList.lobby.historyIndex <= -2) { // -2 instead of -1 here because we want down arrow to clear the chat
						roomList.lobby.historyIndex = -1;
						return;
					}

					// Set the chat input box to what we last typed
					let retrievedHistory = roomList.lobby.typedHistory[roomList.lobby.historyIndex];
					$('#lobby-chat-box-input').val(retrievedHistory);
				}
			}
		}

		// 37 // Left arrow
		// 39 // Right arrow

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
		Lobby header buttons
	*/

	$('#header-lobby').click(function() {
		if ($('#header-lobby').hasClass('disabled') === false) {
			// TODO go back to lobby
		}
	});

	$('#header-start-race').tooltipster({
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

	$('#header-start-race').click(function() {
		$('#start-race-name').focus();
	});

	$('#header-settings').click(function() {
		if ($('#header-settings').hasClass('disabled') === false) {

		}
	});

	$('#header-profile').click(function() {
		let url = 'http' + (secure === true ? 's' : '') + '://' + serverURL + '/profiles/' + myUsername;
		shell.openExternal(url);
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

		// Terminate the WebSocket connection
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

	$('#start-race-randomize').click(function() {
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

		// Set it and focus it
		$('#start-race-name').val(randomlyGeneratedName);
		$('#start-race-name').focus();
	});

	$('#start-race-format').change(function() {
		$('#select-race-format-icon').css('background-image', 'url("assets/img/formats/' + $(this).val() + '.png")');

		if ($(this).val() === 'unseeded') {
			$('#start-race-character').val('Judas');
		} else if ($(this).val() === 'seeded') {
			$('#start-race-character').val('Judas');
		} else if ($(this).val() === 'diversity') {
			$('#start-race-character').val('Cain');
		}

		if ($(this).val() === 'seeded') {
			$('#select-race-starting-build-1').fadeIn(fadeTime);
			$('#select-race-starting-build-2').fadeIn(fadeTime);
			$('#select-race-starting-build-3').fadeIn(fadeTime);
		} else {
			$('#select-race-starting-build-1').fadeOut(fadeTime);
			$('#select-race-starting-build-2').fadeOut(fadeTime);
			$('#select-race-starting-build-3').fadeOut(fadeTime);
		}
	});

	$('#start-race-character').change(function() {
		let newCharacter = $(this).val();
		$('#select-race-character-icon').fadeOut(fadeTime / 2, function() {
			$('#select-race-character-icon').css('background-image', 'url("assets/img/characters/' + newCharacter + '.png")');
			$('#select-race-character-icon').fadeIn(fadeTime / 2);
		});
	});

	$('#start-race-goal').change(function() {
		$('#select-race-goal-icon').css('background-image', 'url("assets/img/goals/' + $(this).val() + '.png")');
	});

	$('#start-race-starting-build').change(function() {
		$('#select-race-starting-build-icon').css('background-image', 'url("assets/img/builds/' + $(this).val() + '.png")');
	});

	$('#start-race-form').submit(function() {
		// By default, the form will reload the page, so stop this from happening
		event.preventDefault();

		// Don't do anything if we are already logging in
		if (currentScreen !== 'lobby') {
			return;
		}

		// Get values from the form
		let name = $('#start-race-name').val().trim();
		let format = $('#start-race-format').val();
		let character = $('#start-race-character').val();
		let goal = $('#start-race-goal').val();
		let startingBuild;
		if (format === 'seeded') {
			startingBuild = $('#start-race-starting-build').val();
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
			startingBuild = getRandomNumber(1, 31); // There are 31 builds in the Instant Start Mod
		}

		// Close the tooltip
		$('#header-start-race').tooltipster('close'); // Close the tooltip

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
	let url = 'http' + (secure ? 's' : '') + '://' + serverURL + '/login';
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
function lobbyEnter() {
	// Make sure that all of the forms are cleared out
	$('#login-username').val('');
	$('#login-password').val('');
	$('#login-remember-checkbox').prop('checked', false);
	$('#login-error').fadeOut(0);
	$('#register-username').val('');
	$('#register-password').val('');
	$('#register-email').val('');
	$('#register-error').fadeOut(0);

	// Show the buttons in the header
	$('#header-start-race').fadeIn(fadeTime);
	$('#header-settings').fadeIn(fadeTime);
	$('#header-profile').fadeIn(fadeTime);
	$('#header-log-out').fadeIn(fadeTime);

	// Show the lobby
	$('#page-wrapper').removeClass('vertical-center');
	$('#lobby').fadeIn(fadeTime, function() {
		currentScreen = 'lobby';
	});

	// Fix the indentation on lines that were drawn when the element was hidden
	chatIndent('lobby');

	// Automatically scroll to the bottom of the chat box
	let bottomPixel = $('#lobby-chat-text').prop('scrollHeight') - $('#lobby-chat-text').height();
	$('#lobby-chat-text').scrollTop(bottomPixel);

	// Focus the chat input
	$('#lobby-chat-box-input').focus();
}

function lobbyRaceDraw(race) {
	console.log('entered lobbyracedraw:');
	console.log(race);
}

function chatSend(destination) {
	// Don't do anything if we are not on the screen corresponding to the chat input form
	if (destination === 'lobby' && currentScreen !== 'lobby') {
		return;
	} else if (destination === 'race' && currentScreen.startsWith('_race_') === false) {
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

	// Add it to the history so that we can use up arrow later
	roomList[currentScreen].typedHistory.unshift(message);

	// Reset the history index
	roomList[currentScreen].historyIndex = -1;

	// Check for the presence of commands
	if (message === '/debug') {
		debug();
	} else {
		conn.emit('roomMessage', {
			"room": currentScreen,
			"message":  message,
		});
	}
}

function chatDraw(room, name, message, datetime = null) {
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
		date = new Date(datetime * 1000); // Add 3 zeros because the server doesn't keep track of the nanoseconds
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
	chatLine += '&lt;<strong>' + name + '</strong>&gt; &nbsp; ';
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
	if (datetime === null) {
		$('#' + room + '-chat-text').append(chatLine);
	} else {
		// We prepend instead of append because the chat history comes in order from most recent to least recent
		$('#' + room + '-chat-text').prepend(chatLine);
	}
	$('#' + room + '-chat-text-line-' + roomList[room].chatLine).fadeIn(fadeTime);

	// Set indentation for long lines
	let indentPixels = $('#' + room + '-chat-text-line-' + roomList[room].chatLine + '-header').css('width');
	$('#' + room + '-chat-text-line-' + roomList[room].chatLine).css('padding-left', indentPixels);
	$('#' + room + '-chat-text-line-' + roomList[room].chatLine).css('text-indent', '-' + indentPixels);

	// Automatically scroll
	if (autoScroll === true) {
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
			let emoteTag = '<img class="chat-emote" src="assets/img/emotes/' + emoteList[i] + '.png" />';
			let re = new RegExp('\\b' + emoteList[i] + '\\b', 'g'); // "\b" is a word boundary in regex
			message = message.replace(re, emoteTag);
		}
	}

	return message;
}

function chatIndent(room) {
	if (typeof roomList[room] === 'undefined') {
		return;
	}

	for (let i = 1; i <= roomList[room].chatLine; i++) {
		let indentPixels = $('#' + room + '-chat-text-line-' + i + '-header').css('width');
		$('#' + room + '-chat-text-line-' + i).css('padding-left', indentPixels);
		$('#' + room + '-chat-text-line-' + i).css('text-indent', '-' + indentPixels);
	}
}

function usersDraw(room) {
	// Figure out what kind of chat room this is
	let destination;
	if (room === 'lobby') {
		destination = 'lobby';
	} else if (room.startsWith('_race_')) {
		destination = 'race';
	} else {
		errorShow('Unable to parse the room in the "usersDraw" function.');
	}

	// Update the header that shows shows the amount of people online or in the race
	$('#' + destination + '-users-online').html(roomList[room].numUsers);

	// Make an array with the name of every user and alphabetize it
	let userList = [];
	for (var user in roomList[room].users) {
		if (!roomList[room].users.hasOwnProperty(user)) {
			continue;
		}

		userList.push(user);
	}
	userList.sort();

	// Empty the existing list
	$('#' + destination + '-users-users').html('');

	// Add a div for each player
	for (let i = 0; i < userList.length; i++) {
		if (userList[i] === myUsername) {
			let userDiv = '<div>' + userList[i] + '</div>';
			$('#' + room + '-users-users').append(userDiv);
		} else {
			let userDiv = '<div id="' + destination + '-users-' + userList[i] + '" class="lobby-users-user" data-tooltip-content="#user-click-tooltip">';
			userDiv += userList[i];
			userDiv += '</div>';
			$('#' + room + '-users-users').append(userDiv);

			// Add the tooltip
			$('#' + room + '-users-' + userList[i]).tooltipster({
				theme: 'tooltipster-shadow',
				trigger: 'click',
				interactive: true,
				side: 'left',
			});
		}
	}
}

/*
	Race functions
*/

function raceEnter(raceID) { // TODO FILL THIS OUT
	// We should be on the lobby screen unless there is severe lag
	if (currentScreen !== 'lobby') {
		errorShow('Failed to enter the race screen since currentScreen is equal to "' + currentScreen + '".');
		return;
	}

	// Show and hide some buttons in the header
	$('#header-lobby').fadeIn(fadeTime);
	$('#header-start-race').fadeOut(fadeTime);
	$('#header-settings').fadeOut(fadeTime);

	// Close all tooltips
	closeAllTooltips();

	// Show the lobby
	$('#page-wrapper').removeClass('vertical-center');
	$('#lobby').fadeIn(fadeTime, function() {
		currentScreen = 'lobby';
	});

	// Fix the indentation on lines that were drawn when the element was hidden
	chatIndent(raceID);

	// Automatically scroll to the bottom of the chat box
	let bottomPixel = $('#lobby-chat-text').prop('scrollHeight') - $('#lobby-chat-text').height();
	$('#lobby-chat-text').scrollTop(bottomPixel);

	// Focus the chat input
	$('#lobby-chat-box-input').focus();
}

/*
	Websocket handling
*/

function websocket(username, password, remember) {
	// Establish a WebSocket connection
	let url = 'ws' + (secure ? 's' : '') + '://' + serverURL + '/ws';
	conn = new golem.Connection(url, true); // It will automatically use the cookie that we recieved earlier
	// "true" means that debugging is on

	/*
		Miscellaneous WebSocket handlers
	*/

	conn.on('open', function(event) {
		// Login success; join the lobby chat channel
		myUsername = username;
		conn.emit('roomJoin', {
			"room": "lobby",
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
				$('#title-ajax').fadeOut(0);
				lobbyEnter();
			});
		} else if (currentScreen === 'login-ajax') {
			currentScreen = 'transition';
			$('#login').fadeOut(fadeTime, function() {
				loginReset();
				lobbyEnter();
			});
		} else if (currentScreen === 'register-ajax') {
			currentScreen = 'transition';
			$('#register').fadeOut(fadeTime, function() {
				registerReset();
				lobbyEnter();
			});
		}
	});

	conn.on('close', connClose);

	function connClose(event) {
		// Check to see if this was intended
		if (initiatedLogout === false) {
			errorShow('Disconnected from the server. Either your Internet is having problems or the server went down!');
			return;
		}

		// Reset some global variables
		roomList = {};
		raceList = {};
		myUsername = '';
		initiatedLogout = false;

		// Hide the buttons in the header
		$('#header-lobby').fadeOut(fadeTime);
		$('#header-start-race').fadeOut(fadeTime);
		$('#header-profile').fadeOut(fadeTime);
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
		} else if (currentScreen.startsWith('_race_')) {
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
		Chat command handlers
	*/

	conn.on('roomList', function(data) {
		// Keep track of all of the rooms that we are in
		roomList[data.room] = {
			users: {},
			numUsers: 0,
			chatLine: 0,
			typedHistory: [],
			historyIndex: -1,
		};

		// Keep track of all of the users in the room
		for (let i = 0; i < data.users.length; i++) {
			roomList[data.room].users[data.users[i].name] = data.users[i];
		}
		roomList[data.room].numUsers = data.users.length;

		// Redraw the users list
		usersDraw(data.room);
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

		// Redraw the users list
		usersDraw(data.room);
	});

	conn.on('roomLeft', function(data) {
		// Remove them from the room list
		delete roomList[data.room].users[data.name];
		roomList[data.room].numUsers--;

		// Redraw the users list
		usersDraw(data.room);
	});

	conn.on('roomMessage', function(data) {
		chatDraw(data.room, data.name, data.message);
	});

	/*
		Race command handlers
	*/

	// On initial connection, we get a list of all of the races that are currently open or ongoing
	conn.on('raceList', function(data) {
		// Go through the list of races that were sent
		for (let i = 0; i < data.length; i++) {
			// Keep track of what races are currently going
			raceList[data[i].id] = data[i];

			// Update the "Current races" area
			lobbyRaceDraw(data[i]);

			// Check to see if we are in this races
			for (let j = 0; j < data[i].players.length; j++) {
				// TODO
			}

		}
	});

	conn.on('raceCreated', function(data) {
		// Keep track of what races are currently going
		raceList[data.id] = data;

		// Update the "Current races" area
		lobbyRaceDraw(data);

		// Check to see if we created this race
		if (data.captain === myUsername) {
			raceEnter(data.id);
		}
	});

	conn.on('raceJoined', function(data) {
		// Keep track of the people in each race
		raceList[data.id].players.push(data.name);

		// Update the "Current races" area
		// TODO

		// Check to see if we joined this race
		if (data.name === myUsername) {
			//currentRaceID = data.id;

			// Join the race lobby
			// TODO
		}
	});

	conn.on('raceLeft', function(data) {
		// Delete this person from the race list
		if (raceList[data.id].players.indexOf(data.name) !== -1) {
			raceList[data.id].players.splice(raceList[data.id].players.indexOf(data.name), 1);
		} else {
			errorShow('"' + data.name + '" left race #' + data.id + ', but they were not in the entrant list.');
			return;
		}

		if (raceList[data.id].players.length === 0) {
			// Check to see if this was the last person in the race, and if so, delete the race
			delete raceList[data.id];
		} else {
			// Check to see if this person was the captain, and if so, make the next person in line the captain
			if (raceList[data.id].captain === data.name) {
				raceList[data.id].captain = raceList[data.id].players[0];
			}
		}

		// Update the "Current races" area
		// TODO

		if (data.name === myUsername) {
			//currentRaceID = false;

			// Show the lobby
			// TODO
		}
	});

	conn.on('raceSetStatus', function(data) {
		// Update the status
		raceList[data.id].status = data.status;

		// Check to see if we are in this race
		if (data.id === false) { //if (data.id === currentRaceID) {
			if (raceList[data.id].status === 'starting') {
				// Update the race lobby
				// TODO
			} else if (raceList[data.id].status === 'in progress') {
				// Update the race lobby
				// TODO
			} else if (raceList[data.id].status === 'finished') {
				//currentRaceID = false;

				// Update the race lobby
				// TODO
			} else {
				errorShow('Failed to parse the status of race #' + data.id + ': ' + raceList[data.id].status);
			}
		}

		// Remove the race if it is finished
		if (raceList[data.id] === 'finished') {
			delete raceList[data.id];
		}
	});

	/*
		Miscellaneous commands handlers
	*/

	conn.on('error', function(data) {
		errorShow(data.message);
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
	language = new_language;
	localStorage.language = language;

	if (language === 'en') {
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

	} else if (language === 'fr') {
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

function errorShow(message) {
	console.error('Error:', message);

	// Don't do anything if we are already showing an error
	if (currentScreen === 'error') {
		return;
	}
	currentScreen = 'error';

	// Disconnect from the server, if connected
	conn.close();

	// Hide the buttons in the header
	$('#header-lobby').fadeOut(fadeTime);
	$('#header-start-race').fadeOut(fadeTime);
	$('#header-profile').fadeOut(fadeTime);
	$('#header-settings').fadeOut(fadeTime);
	$('#header-log-out').fadeOut(fadeTime);

	// Close all tooltips
	closeAllTooltips();

	// Show the error modal
	$('#gui').fadeTo(fadeTime, 0.1, function() {
		$('#error-modal').fadeIn(fadeTime);
		$('#error-modal-description').html(message);
	});
}

/*
	Miscellaneous functions
*/

function findAjaxError(jqXHR) {
	// Find out what error it was
	let error;
	if (jqXHR.hasOwnProperty('readyState') === true) {
		if (jqXHR.readyState === 4) {
			// HTTP error
			if (tryParseJSON(jqXHR.responseText) !== false) {
				error = JSON.parse(jqXHR.responseText); // jqXHR.response doesn't work for some reason
				if (error.hasOwnProperty('error_description') === true) { // Some errors have the plain text description in the "error_description" field
					error = error.error_description;
				} else if (error.hasOwnProperty('description') === true) { // Some errors have the plain text description in the "description" field
					error = error.description;
				} else if (error.hasOwnProperty('error') === true) { // Some errors have the plain text description in the "error" field
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
		// but... JSON.parse(null) returns null, and typeof null === "object",
		// so we must check for that, too. Thankfully, null is falsey, so this suffices:
		if (o && typeof o === "object") {
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
