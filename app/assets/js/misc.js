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
