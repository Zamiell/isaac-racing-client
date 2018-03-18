const { execSync } = require('child_process');

const command = 'tasklist';
const processName = 'isaac-ng.exe';

// The "tasklist" module has problems on different languages
// The "ps-node" module is very slow
// The "process-list" module will not compile for some reason (missing "atlbase.h")
// So, just manually run the "tasklist" command and parse the output without using any module
let output;
try {
    output = execSync(command).toString().split('\r\n');
} catch (err) {

}
let IsaacPID;
for (let i = 0; i < output.length; i++) {
    const line = output[i];
    if (line.startsWith(`${processName} `)) {
        // Example line:
        // isaac-ng.exe                 15220 Console                    1    187,520 K
        const match = line.match(/^.+?(\d+)/);
        if (match) {
            IsaacPID = parseInt(match[1], 10);
            console.log('DEBUG: ISAAC PID = ', IsaacPID);
            break;
        } else {

        }
    }
}
