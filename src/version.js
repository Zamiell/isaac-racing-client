// Imports
const fs = require('fs-extra');
const path = require('path');

// Get the version of the client (from the "package.json" file)
let basePath;
if (process.platform === 'darwin') {
    basePath = path.join(__dirname, 'Contents', 'Resources', 'app.asar');
} else {
    // In development, this is the root of the repository
    // On a bundled Windows app, this is:
    // "C:\Users\[Username]\AppData\Local\Programs\RacingPlus\resources\app.asar\"
    basePath = path.join(__dirname, '..', 'package.json');
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
