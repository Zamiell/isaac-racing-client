const { execSync } = require('child_process');

const processName = 'isaac-ng.exe';
const command = 'tasklist';

// The "tasklist" module has problems on different languages
// The "ps-node" module is very slow
// The "process-list" module will not compile for some reason (missing "atlbase.h")
// So, just manually run the "tasklist" command parse the output without using any module
let output;
try {
    output = execSync(command).toString().split('\r\n');
} catch (err) {
    // process.send(`error: Failed to detect if Isaac is open when running the "${command}" command: ${err}`, processExit);
}
for (let i = 0; i < output.length; i++) {
    const line = output[i];
    if (line.startsWith(processName + " ")) {
        console.log('FOUND!!!!');
    }
}
