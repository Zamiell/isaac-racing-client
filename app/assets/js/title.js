/*
	Title screen
*/

'use strict';

// Imports
const globals = nodeRequire('./assets/js/globals');

// Button handlers
$(document).ready(function() {
	$('#title-login-button').click(function() {
		if (globals.currentScreen !== 'title') {
			return;
		}
		globals.currentScreen = 'transition';
		$('#title').fadeOut(globals.fadeTime, function() {
			$('#login').fadeIn(globals.fadeTime, function() {
				globals.currentScreen = 'login';
			});
			$('#login-username').focus();
		});
	});

	// TODO TAKEN

	$('#title-language-french').click(function() {
		//localize('fr');
	});
});
