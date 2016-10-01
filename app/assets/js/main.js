/*
	Isaac Racing Client stuff
*/

// Constants
const serverURL = 'isaacitemtracker.com';
const secure = true; // "true" for HTTPS/WSS and "false" for HTTP/WS
const fadeTime = 300;

// Global variables
var currentScreen = 'title';
var roomList = {};
var raceList = {};

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

$(document).ready(function() {
	/*
		Keyboard bindings
	*/

	$(document).keydown(function(event) {
		//console.log(event.which); // Debug

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
			$('#login-error').html('The username field is required.');
			return;
		} else if (password === '') {
			$('#login-error').fadeIn(fadeTime);
			$('#login-error').html('The password field is required.');
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
			request.done(function(data) {
				// Step 3 - Connect to the WebSocket server
				if (websocket() === true) {
					// Login success
					currentScreen = 'transition';
					loginReset();
					$('#login').fadeOut(fadeTime, function() {
						enterLobby();
					});
				} else {
					currentScreen = 'transition';
					loginReset();
					var error = 'Failed to connect to the WebSocket server. This means the server might be down!';
					$('#login-error').html(error);
					$('#login-error').fadeIn(fadeTime, function() {
						currentScreen = 'login';
					});
				}
			});
			request.fail(function(jqXHR, textStatus, errorThrown) {
				currentScreen = 'transition';
				loginReset();
				var error;
				if (jqXHR.responseText === '') {
					error = { error_description: 'An unknown error occured.' }
				} else {
					error = JSON.parse(jqXHR.responseText); // jqXHR.response doesn't work for some reason
				}
				$('#login-error').html(error.error_description);
				$('#login-error').fadeIn(fadeTime, function() {
					currentScreen = 'login';
				});
			});
		});
		request.fail(function(jqXHR, textStatus, errorThrown) {
			currentScreen = 'transition';
			loginReset();
			var error;
			if (jqXHR.responseText === '') {
				error = { error_description: 'An unknown error occured.' }
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

	// DEBUG
	/*$('#title').fadeOut(0);
	enterLobby();*/

});

// Called from the login screen or the register screen
function enterLobby() {
	$('#lobby').fadeIn(fadeTime, function() {
		currentScreen = 'lobby';
	});

	// Autoscroll the lobby chat box
	$('#lobby-chat-box').scrollTop(fadeTime);
}

function websocket() {
	// Establish a WebSocket connection
	var socket;
	try {
		var url = 'ws' + (secure ? 's' : '') + '://' + serverURL + '/ws';
		socket = new WebSocket(url);
	} catch(err) {
		console.log('Failed to connect to the WebSocket server:', err)
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
			for (var i = 0; i < data.users.length; i++) {
				roomList[data.room] = {};
				roomList[data.room][data.users[i].name] = data.users[i];
			}

		} else if (command === 'roomHistory') {
			for (var i = 0; i < data.history.length; i++) {
				if (data.room === 'global') {
					// Draw the global chat
					// TODO
				} else {
					// Draw the game chat
					// TODO
				}
			}

		} else if (command === 'roomJoined') {
			// Keep track of who is in this channel
			roomList[data.room][data.user.name] = data.user;

			if (data.room === 'global') {
				// Add them to the global chat list
				// TODO
			} else {
				// Mark them as online inside the game
				// TODO
			}

		} else if (command === 'roomLeft') {
			// Remove them from the room list
			delete roomList[data.room][data.name];

			if (data.room === 'global') {
				// Remove them to the global chat list
				// TODO
			} else {
				// Mark them as offline inside the game
				// TODO
			}

		/*
			Race command handlers
		*/

		} else if (command === 'raceList') {
			// Keep track of what races are currently going
			for (var i = 0; i < data.length; i++) {
				raceList[data[i].id] = data[i];
			}

			// Update the "Current races" area
			// TODO

			// Check to see if we are in any games
			var inAGame = false;
			for (var id in currentGames) {
				if (!currentGames.hasOwnProperty(id)) {
					continue;
				}

				for (var i = 0; i < currentGames[id].players.length; i++) {
					if (currentGames[id].players[i] === username) {
						gameID = id;
						if (currentGames[id].status === 'open') {
							gameID = id;
							lobbyDrawPregame();
						} else if (currentGames[id].status === 'in progress') {
							gameID = id;
						} else {
							errorShow('Failed to parse the status of game #' + id + ': ' + currentGames[id].status);
						}
						break;
					}
				}
			}

		} else if (command === 'raceCreated') {
			// Keep track of what games are currently going
			currentGames[data.id] = data;

			// Update the "Current games" area
			lobbyDrawCurrentGames();

			// Check to see if we created this game
			if (data.players[0] === username) { // There will only be one player in this game because it was just created
				gameID = data.id;
				lobbyDrawPregame();
			}

		} else if (command === 'raceJoined') {
			// Keep track of the people in each game
			currentGames[data.id].players.push(data.name);

			// Update the "Current games" area
			lobbyDrawCurrentGames();

			// Check to see if we joined this game
			if (data.name === username) {
				gameID = data.id;
			}

			// Check to see if we are in this game
			if (data.id === gameID) {
				lobbyDrawPregame();
			}

		} else if (command === 'raceLeft') {
			// Get the status of the game before we potentially delete it
			var currentStatus = currentGames[data.id].status;

			// Delete this person from the currentGames list
			if (currentGames[data.id].players.indexOf(data.name) !== -1) {
				currentGames[data.id].players.splice(currentGames[data.id].players.indexOf(data.name), 1)
			} else {
				errorShow('"' + data.name + '" left race #' + data.id + ', but they were not in the entrant list.');
				return;
			}

			// Check to see if this was the last person in the game, and if so, delete the game
			if (currentGames[data.id].players.length === 0) {
				delete currentGames[data.id];

			// Check to see if this person was the captain, and if so, make the next person in line the captain
			} else {
				if (currentGames[data.id].captain === data.name) {
					currentGames[data.id].captain = currentGames[data.id].players[0];
				}
			}

			// Update the "Current games" area
			lobbyDrawCurrentGames();

			// Check to see if we left this game
			if (data.name === username) {
				gameID = false;
				if (currentStatus === 'open') {
					lobbyLeavePregame();
				} else if (currentStatus === 'in progress') {
					showLobby();
				} else {
					errorShow('Failed to parse the status of game #' + data.id + ': ' + currentStatus);
				}

			// Check to see if someone else left a game that we are in
			} else if (data.id === gameID) {
				if (currentStatus === 'open') {
					lobbyDrawPregame();
				} else if (currentStatus === 'in progress') {
					showLobby();
				} else {
					errorShow('Failed to parse the status of game #' + data.id + ': ' + currentStatus);
				}
			}

		} else if (command === 'raceSetStatus') {
			// Update the status
			currentGames[data.id].status = data.status;

			// Check to see if we are in this game
			if (data.id === gameID) {
				if (currentGames[data.id].status === 'in progress') {
					// Do nothing; gameState will be given next and we will act on that
				} else if (currentGames[data.id].status === 'finished') {
					gameID = false;
				} else {
					errorShow('Failed to parse the status of game #' + data.id + ': ' + currentGames[data.id].status);
				}
			}

			// Remove the game if it is finished
			if (currentGames[data.id] === 'finished') {
				delete currentGames[data.id];
			}

		} else if (command === 'raceState') {
			// We started a new game or disconnected, so reset/initialize the variable that represents the game state
			gameState = data;

			// Leave the lobby and show the Hanabi GUI
			hanabiShow();

		/*
			Miscellaneous handlers
		*/

		} else if (command === 'error') {
			errorShow(data.msg);

		} else {
			// Unknown command
			errorShow('Unrecognized message: ' + message);
		}

	}

	return true;
}

/*
	Alpha by HTML5 UP
	html5up.net | @ajlkn
	Free for personal and commercial use under the CCA 3.0 license (html5up.net/license)
*/

(function($) {

	skel.breakpoints({
		wide: '(max-width: 1680px)',
		normal: '(max-width: 1280px)',
		narrow: '(max-width: 980px)',
		narrower: '(max-width: 840px)',
		mobile: '(max-width: 736px)',
		mobilep: '(max-width: 480px)'
	});

	$(function() {

		var	$window = $(window),
			$body = $('body'),
			$header = $('#header'),
			$banner = $('#banner');

		// Fix: Placeholder polyfill.
			$('form').placeholder();

		// Prioritize "important" elements on narrower.
			skel.on('+narrower -narrower', function() {
				$.prioritize(
					'.important\\28 narrower\\29',
					skel.breakpoint('narrower').active
				);
			});

		// Dropdowns.
			$('#nav > ul').dropotron({
				alignment: 'right'
			});

	});

})(jQuery);
