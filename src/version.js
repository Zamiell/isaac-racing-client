// Imports
let fs;
let path;
if (typeof nodeRequire === 'undefined') {
    // We are in the main process
    /* eslint-disable global-require */
    fs = require('fs');
    path = require('path');
} else {
    // We are in the renderer process
    fs = nodeRequire('fs');
    path = nodeRequire('path');
}

const isDev = process.mainModule.filename.indexOf('app.asar') === -1;

// Get the version of the client (from the "package.json" file)
let basePath;
if (isDev) {
    // In development, "__dirname" is:
    // "C:\Repositories\isaac-racing-client\src"
    // The package file is in the root of the repository
    basePath = path.join(__dirname, '..');
} else if (process.platform === 'darwin') {
    // On a bundled macOS app, "__dirname" is:
    // "/Applications/Racing+/Contents/Resources/app.asar/src"
    // The package file is in the root of the Asar archive
    basePath = path.join(__dirname, '..');
} else {
    // On a bundled Windows app, "__dirname" is:
    // "C:\Users\[Username]\AppData\Local\Programs\RacingPlus\resources\app.asar\src"
    // The package file is in the root of the Asar archive
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
