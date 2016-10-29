/*
	Login screen
*/

'use strict';

// Imports
const globals = nodeRequire('./assets/js/globals');

// Button handlers
$(document).ready(function() {
	$('#title-register-button').click(function() {
		if (globals.currentScreen !== 'title') {
			return;
		}
		globals.currentScreen = 'transition';
		$('#title').fadeOut(globals.fadeTime, function() {
			$('#register').fadeIn(globals.fadeTime, function() {
				globals.currentScreen = 'register';
			});
			$('#register-username').focus();
		});
	});
});
