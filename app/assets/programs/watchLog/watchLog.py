#! C:\Python34\python.exe

# Notes:
# - Default log file location:
#   'C:/Users/' + os.getenv('username') + '/Documents/My Games/Binding of Isaac Afterbirth/log.txt'
#   "C:/Users/james/Documents/My Games/Binding of Isaac Afterbirth/log.txt"

# Imports
import sys
import os
import re
import time
import psutil
import tempfile

# Global variables
IPCFile = os.path.join(tempfile.gettempdir(), 'Racing+_IPC.txt')
fileArrayPosition = 0

# Subroutines
def error(message):
    print('Error:', message)
    sys.exit(1)

def writeFile(message):
    try:
        with open(IPCFile, 'a') as f:
            f.write(message + '\n')
    except Exception:
        error('Failed to write to the IPC file at "' + logFilePath + '".')

# Validate command-line arguments
if len(sys.argv) != 2:
    error('Must provide an argument containing the path to Isaac\'s log file.')

# Check to see if the log file exists
logFilePath = sys.argv[1]
if not os.path.isfile(logFilePath):
    error('Log file "' + logFilePath + '" does not exist.')

# Truncate the log file (so that we don't accidentally report to the server anything that we have already reported)
try:
    with open(logFilePath, 'w') as f:
        pass
except Exception:
    error('Failed to truncate the log file at "' + logFilePath + '".')

# Truncate the IPC file (so that it doesn't grow too large)
try:
    with open(IPCFile, 'w') as f:
        pass
except Exception:
    error('Failed to truncate the IPC file at "' + IPCFile + '".')

# Continuously read the log file
while True:
    # Read the log into a variable
    try:
        with open(logFilePath, 'r') as f:
            fileContents = f.read()
    except Exception:
        error('Could not open the log file at "' + logFilePath + '".')

    # Convert it to an array
    fileArray = fileContents.splitlines()

    # Return to the start if we go past the end of the file (which occurs when the log file is truncated)
    if fileArrayPosition > len(fileArray):
        fileArrayPosition = 0

    # Process the log's new output
    for line in fileArray[fileArrayPosition:]:
        # Debug
        #print("- " + line)

        # Check for the start of a run
        if line.startswith('RNG Start Seed: '):
            match = re.search(r'RNG Start Seed: (.... ....) \(\d+\)', line)
            if match:
                writeFile('New seed: ' + match.group(1))
            else:
                error('Failed to parse the seed of the current run:\n' + line)

        # Check for a new floor
        elif line.startswith('Level::Init '):
            # Rebirth uses AltStage and Afterbirth uses StageType
            match = re.search(r'Level::Init m_Stage (\d+), m_(AltStage|StageType) (\d+) Seed \d+', line)
            if match:
                writeFile('New floor: ' + match.group(1) + '-' + match.group(3))
            else:
                error('Failed to parse the floor of the current run:\n' + line)

        # Check for rooms entered
        elif line.startswith('Room '):
            match = re.search(r'Room (\d+\.\d+)\(', line)
            if match:
                writeFile('Entered room: ' + match.group(1))
            else:
                error('Failed to parse the new room:\n' + line)

        # Check for a new item
        elif line.startswith('Adding collectible '):
            match = re.search(r'Adding collectible (\d+) ', line)
            if match:
                writeFile('New item: ' + match.group(1))
            else:
                error('Failed to parse the new item:\n' + line)

        # Check for the end of the run
        elif line == 'playing cutscene 17 (Chest).':
            writeFile('Finished run: Blue Baby')
        elif line == 'playing cutscene 18 (Dark Room).':
            writeFile('Finished run: The Lamb')
        elif line == 'playing cutscene 19 (Mega Satan).':
            writeFile('Finished run: Mega Satan')

    # Set that we have read the log up to this point
    fileArrayPosition = len(fileArray)

    # Sleep for a little while so that we don't overload the CPU too much
    time.sleep(0.1)
