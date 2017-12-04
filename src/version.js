// Imports
let fs;
let path;
let isDev;
if (typeof nodeRequire === 'undefined') {
    // We are in the main process
    fs = require('fs-extra');
    path = require('path');
    isDev = require('electron-is-dev');
} else {
    // We are in the renderer process
    fs = nodeRequire('fs-extra');
    path = nodeRequire('path');
    isDev = nodeRequire('electron-is-dev');
}

// Get the version of the client (from the "package.json" file)
let basePath;
if (isDev) {
    // In development, this is the root of the repository
    basePath = path.join(__dirname, '..');
} else if (process.platform === 'darwin') {
    // On a bundled macOS app, this is:
    // "/Applications/Racing+/Contents/Resources/app.asar/"
    basePath = path.join(__dirname, 'Contents', 'Resources', 'app.asar');
} else {
    // On a bundled Windows app, this is:
    // "C:\Users\[Username]\AppData\Local\Programs\RacingPlus\resources\app.asar\"
    basePath = path.join(__dirname, '..');
}
const packageJSONPath = path.join(basePath, 'package.json');
let version;
try {
    if (fs.existsSync(packageJSONPath)) {
        const packageJSON = fs.readFileSync(packageJSONPath, 'utf8');
        version = `v${JSON.parse(packageJSON).version}`;
    } else {
        version = 'Unknown';
    }
} catch (err) {
    version = 'Unknown';
}

// Export it
module.exports = version;
