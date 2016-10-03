'use strict';

/*
	Isaac Racing Client stuff
*/

// Constants
const serverURL = 'isaacitemtracker.com';
const secure = true; // "true" for HTTPS/WSS and "false" for HTTP/WS
const fadeTime = 300;

// Imports
// const keytar = nodeRequire('keytar');

// Global variables
var currentScreen = 'title';
var roomList = {};
var raceList = {};
var myUsername;
var currentRaceID = false; // Can be false or the ID of the race

/*
	By default, we start on the title screen.
	currentScreen can be the following:
	- title
	- login
	- login-ajax
	- register
	- register-ajax
	- lobby
	- race-lobby
	- transition
*/

// Set up localization
var language = localStorage['language'];
if (typeof language === 'undefined') { // If this is the first run, default to English
	language = 'en';
	localStorage['language'] = 'en';
}
/* global Lang */ // Tell ESLint that this is a global variable
var lang = new Lang(); // Create a language switcher instance
lang.dynamic('fr', 'assets/js/langpack/fr.json');
lang.init({
	defaultLang: 'en',
});

/*
	UI functionality
*/

$(document).ready(function() {
	// DEBUG
	$('#title').fadeOut(0);
	enterLobby();

	// If the user is using a non-default language, change all the text on the page
	if (language !== 'en') {
		localize(language);
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
			} else if (currentScreen === 'register') {
				event.preventDefault();
				$('#register-back-button').click();
			}
		}

		// 37 // Left arrow
		// 38 // Up arrow
		// 39 // Right arrow
		// 40 // Down arrow

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

		// Validate username/password
		var username = document.getElementById('login-username').value.trim();
		var password = document.getElementById('login-password').value.trim();
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
		$('#login-error').fadeOut(fadeTime);
		$('#login-form').fadeTo(fadeTime, 0.25);
		$('#login-username').prop('disabled', true);
		$('#login-password').prop('disabled', true);
		$('#login-remember-checkbox').prop('disabled', true);
		$('#login-remember-checkbox-label').css('cursor', 'default');
		$('#login-submit-button').prop('disabled', true);
		$('#login-back-button').prop('disabled', true);
		$('#login-ajax').fadeIn(fadeTime);

		// A function to return the login form back to the way it was initially
		function loginReset() {
			$('#login-form').fadeTo(fadeTime, 1);
			$('#login-username').prop('disabled', false);
			$('#login-password').prop('disabled', false);
			$('#login-remember-checkbox').prop('disabled', false);
			$('#login-remember-checkbox-label').css('cursor', 'pointer');
			$('#login-submit-button').prop('disabled', false);
			$('#login-back-button').prop('disabled', false);
			$('#login-ajax').fadeOut(fadeTime);
			$('#login-username').focus();
		}

		// Step 1 - Get the login token from Auth0
		var data = {
			'grant_type': 'password',
			'username':   username,
			'password':   password,
			'client_id':  'tqY8tYlobY4hc16ph5B61dpMJ1YzDaAR',
			'connection': 'Isaac-Server-DB-Connection',
		};
		var request = $.ajax({
			url:  'https://isaacserver.auth0.com/oauth/ro',
			type: 'POST',
			data: data,
		});
		request.done(function(data) {
			// Step 2 - Login with the token
			var url = 'http' + (secure ? 's' : '') + '://' + serverURL + '/login';
			var request = $.ajax({
				url:  url,
				type: 'POST',
				data: JSON.stringify(data),
				contentType: 'application/json',
			});
			request.done(function() {
				// Step 3 - Connect to the WebSocket server
				if (websocket() === true) {
					// Login success
					currentScreen = 'transition';
					loginReset();
					myUsername = username;
					username = '';
					password = '';
					$('#login').fadeOut(fadeTime, function() {
						$('#login-username').val('');
						$('#login-password').val('');
						enterLobby();
					});
				} else {
					currentScreen = 'transition';
					loginReset();
					var error = '<span lang="en">Failed to connect to the WebSocket server. The server might be down!</span>';
					$('#login-error').html(error);
					$('#login-error').fadeIn(fadeTime, function() {
						currentScreen = 'login';
					});
				}
			});
			request.fail(function(jqXHR) {
				currentScreen = 'transition';
				loginReset();
				var error;
				if (jqXHR.readyState == 4) {
					// HTTP error
					if (jqXHR.responseText === '') {
						error = { error_description: '<span lang="en">An unknown HTTP error occured.</span>' };
					} else {
						error = JSON.parse(jqXHR.responseText); // jqXHR.response doesn't work for some reason
					}
				} else if (jqXHR.readyState == 0) {
					// Network error (connection refused, access denied, etc.)
					error = { error_description: '<span lang="en">A network error occured. The server might be down!</span>' };
				} else {
					// Unknown error
					error = { error_description: '<span lang="en">An unknown error occured.</span> (<code>jqXHR.readyState</code> = ' + jqXHR.readyState + '.)' };
				}
				$('#login-error').html(error.error_description);
				$('#login-error').fadeIn(fadeTime, function() {
					currentScreen = 'login';
				});
			});
		});
		request.fail(function(jqXHR) {
			currentScreen = 'transition';
			loginReset();
			var error;
			if (jqXHR.responseText === '') {
				error = { error_description: '<span lang="en">An unknown error occured.</span>' };
			} else {
				error = JSON.parse(jqXHR.responseText); // jqXHR.response doesn't work for some reason
			}
			$('#login-error').html(error.error_description);
			$('#login-error').fadeIn(fadeTime, function() {
				currentScreen = 'login';
			});
		});
	});

	$('#login-back-button').click(function() {
		if (currentScreen !== 'login') {
			return;
		}
		currentScreen = 'transition';
		$('#login').fadeOut(fadeTime, function() {
			$('#title').fadeIn(fadeTime, function() {
				currentScreen = 'title';
			});
		});
	});

	/*
		Register screen
	*/

	$('#register-form').submit(function(event) {
		// By default, the form will reload the page, so stop this from happening
		event.preventDefault();

		// Don't do anything if we are already logging in
		if (currentScreen !== 'register') {
			return;
		}

		// Validate username/password/email
		var username = document.getElementById('register-username').value.trim();
		var password = document.getElementById('register-password').value.trim();
		var email	= document.getElementById('register-email').value.trim();
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
		$('#register-error').fadeOut(fadeTime);
		$('#register-form').fadeTo(fadeTime, 0.25);
		$('#register-username').prop('disabled', true);
		$('#register-password').prop('disabled', true);
		$('#register-email').prop('disabled', true);
		$('#register-submit-button').prop('disabled', true);
		$('#register-back-button').prop('disabled', true);
		$('#register-ajax').fadeIn(fadeTime);

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

		// Step 1 - Register with Auth0
		var data = {
			'grant_type': 'password',
			'username':   username,
			'password':   password,
			'client_id':  'tqY8tYlobY4hc16ph5B61dpMJ1YzDaAR',
			'connection': 'Isaac-Server-DB-Connection',
		};
		var request = $.ajax({
			url:  'https://isaacserver.auth0.com/oauth/ro',
			type: 'POST',
			data: data,
		});
		request.done(function(data) {
			// Step 2 - Login with the token
			var url = 'http' + (secure ? 's' : '') + '://' + serverURL + '/login';
			var request = $.ajax({
				url:  url,
				type: 'POST',
				data: JSON.stringify(data),
				contentType: 'application/json',
			});
			request.done(function() {
				// Step 3 - Connect to the WebSocket server
				if (websocket() === true) {
					// Login success
					currentScreen = 'transition';
					registerReset();
					username = '';
					password = '';
					$('#login').fadeOut(fadeTime, function() {
						enterLobby();
					});
				} else {
					currentScreen = 'transition';
					registerReset();
					var error = '<span lang="en">Failed to connect to the WebSocket server. The server might be down!</span>';
					$('#login-error').html(error);
					$('#login-error').fadeIn(fadeTime, function() {
						currentScreen = 'login';
					});
				}
			});
			request.fail(function(jqXHR) {
				currentScreen = 'transition';
				registerReset();
				var error;
				if (jqXHR.responseText === '') {
					error = { error_description: '<span lang="en">An unknown error occured.</span>' };
				} else {
					error = JSON.parse(jqXHR.responseText); // jqXHR.response doesn't work for some reason
				}
				$('#login-error').html(error.error_description);
				$('#login-error').fadeIn(fadeTime, function() {
					currentScreen = 'login';
				});
			});
		});
		request.fail(function(jqXHR) {
			currentScreen = 'transition';
			registerReset();
			var error;
			if (jqXHR.responseText === '') {
				error = { error_description: '<span lang="en">An unknown error occured.</span>' };
			} else {
				error = JSON.parse(jqXHR.responseText); // jqXHR.response doesn't work for some reason
			}
			$('#login-error').html(error.error_description);
			$('#login-error').fadeIn(fadeTime, function() {
				currentScreen = 'login';
			});
		});
	});

	$('#register-back-button').click(function() {
		if (currentScreen !== 'register') {
			return;
		}
		currentScreen = 'transition';
		$('#register').fadeOut(fadeTime, function() {
			$('#title').fadeIn(fadeTime, function() {
				currentScreen = 'title';
			});
		});
	});

});

// Called from the login screen or the register screen
function enterLobby() {
	$('#lobby').fadeIn(fadeTime, function() {
		currentScreen = 'lobby';
	});

	// Autoscroll the lobby chat box
	$('#lobby-chat-text').scrollTop(fadeTime);
}

/*
	Websocket handling
*/

function websocket() {
	// Establish a WebSocket connection
	var socket;
	try {
		var url = 'ws' + (secure ? 's' : '') + '://' + serverURL + '/ws';
		socket = new WebSocket(url);
	} catch(err) {
		console.log('Failed to connect to the WebSocket server:', err);
		return false;
	}

	// Create event handlers for all incoming messages
	socket.onmessage = function(event) {
		// Log the incoming message
		var message = event.data;
		console.log('Recieved message:', message);

		// Parse the incoming message
		var m = message.match(/^(\w+) (.+)$/);
		var command;
		var data;
		if (m) {
			command = m[1];
			data = JSON.parse(m[2]);
		} else {
			console.error('Failed to parse message:', message);
		}

		/*
			Chat command handlers
		*/

		if (command === 'roomList') {
			// Keep track locally of who is in this channel
			for (let i = 0; i < data.users.length; i++) {
				roomList[data.room] = {};
				roomList[data.room][data.users[i].name] = data.users[i];
			}

		} else if (command === 'roomHistory') {
			for (let i = 0; i < data.history.length; i++) {
				if (data.room === 'global') {
					// Draw the global user user list
					// TODO
				} else {
					// Draw the race user list
					// TODO
				}
			}

		} else if (command === 'roomJoined') {
			// Keep track of who is in this channel
			roomList[data.room][data.user.name] = data.user;

			if (data.room === 'global') {
				// Add them to the global user list
				// TODO
			} else {
				// Add them to the race user list
				// TODO
			}

		} else if (command === 'roomLeft') {
			// Remove them from the room list
			delete roomList[data.room][data.name];

			if (data.room === 'global') {
				// Remove them to the global chat list
				// TODO
			} else {
				// Mark them as offline inside the race
				// TODO
			}

		/*
			Race command handlers
		*/

		} else if (command === 'raceList') { // On inital connection, we get a list of all of the races that are currently open or ongoing
			// Keep track of what races are currently going
			for (let i = 0; i < data.length; i++) {
				raceList[data[i].id] = data[i];
			}

			// Update the "Current races" area
			// TODO

			// Check to see if we are in any races
			for (let id in raceList) {
				if (!raceList.hasOwnProperty(id)) {
					continue;
				}

				for (let i = 0; i < raceList[id].players.length; i++) {
					if (raceList[id].players[i] === myUsername) {
						currentRaceID = id;
						break;
					}
				}
			}

			// "currentRaceID" is now equal to the last race that we joined, so join that race lobby
			if (currentRaceID !== false) {
				// TODO
			}

		} else if (command === 'raceCreated') { // When a new race is created
			// Keep track of what races are currently going
			raceList[data.id] = data;

			// Update the "Current races" area
			// TODO

			// Check to see if we created this race
			if (data.players[0] === myUsername) { // There will only be one player in this race because it was just created
				currentRaceID = data.id;

				// Join the race lobby
				// TODO
			}

		} else if (command === 'raceJoined') {
			// Keep track of the people in each race
			raceList[data.id].players.push(data.name);

			// Update the "Current races" area
			// TODO

			// Check to see if we joined this race
			if (data.name === myUsername) {
				currentRaceID = data.id;

				// Join the race lobby
				// TODO
			}

		} else if (command === 'raceLeft') {
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
				currentRaceID = false;

				// Show the lobby
				// TODO
			}

		} else if (command === 'raceSetStatus') {
			// Update the status
			raceList[data.id].status = data.status;

			// Check to see if we are in this race
			if (data.id === currentRaceID) {
				if (raceList[data.id].status === 'starting') {
					// Update the race lobby
					// TODO
				} else if (raceList[data.id].status === 'in progress') {
					// Update the race lobby
					// TODO
				} else if (raceList[data.id].status === 'finished') {
					currentRaceID = false;

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

		/*
			Miscellaneous handlers
		*/

		} else if (command === 'error') {
			errorShow(data.msg);

		} else {
			// Unknown command
			errorShow('Unrecognized message: ' + message);
		}

	};

	return true;
}

/*
	Miscellaneous functions
*/

function errorShow(message) {
	console.error('Error:', message);
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
	localStorage['language'] = language;

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
