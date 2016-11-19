#! C:\Python34\python.exe

# Notes:
# - Run it:
#   "D:\Repositories\isaac-racing-client\app\assets\programs\watchLog\watchLog.py" "C:/Users/james/Documents/My Games/Binding of Isaac Afterbirth/log.txt"
#   "D:\Repositories\isaac-racing-client\app\assets\programs\watchLog\dist\watchLog.exe" "C:/Users/james/Documents/My Games/Binding of Isaac Afterbirth/log.txt"
# - Build with:
#   cd "D:\Repositories\isaac-racing-client\app\assets\programs\watchLog" && build.py

# Imports
import sys
import os
import re
import time
import psutil
import tempfile

# Global variables
IPC_file_path = os.path.join(tempfile.gettempdir(), 'Racing+_IPC.txt')
file_array_position = 0

# Subroutines
def error(message):
    print('Error:', message)
    sys.exit(1)

def write_file(message):
    try:
        with open(IPC_file_path, 'a') as f:
            f.write(message + '\n')
    except Exception as e:
        error('Failed to write to the IPC file at "' + IPC_file_path + '":' + e)

# Just in case, check to see if there is another copy already running
num_processes = False
for process in psutil.process_iter():
    if process.name() == 'watchLog.exe':
        num_processes += 1
if num_processes > 2:  # pyInstaller creates a "launcher" process with the same name
    error('watchLog.exe is already running. Exiting.')

# Validate command-line arguments
if len(sys.argv) < 2:
    error('Must provide an argument containing the path to Isaac\'s log file.')

# Check to see if the log file exists
log_file_path = sys.argv[1]
if not os.path.isfile(log_file_path):
    error('Log file "' + log_file_path + '" does not exist.')

# Check to see if we are running in development mode
parent_process_name = "Racing+.exe"
if len(sys.argv) == 3:
    parent_process_name = "electron.exe"

# Truncate the log file (so that we don't accidentally report to the server anything that we have already reported)
try:
    with open(log_file_path, 'w') as f:
        pass
except Exception as e:
    error('Failed to truncate the log file at "' + log_file_path + '":' + e)

# Truncate the IPC file (so that it doesn't grow too large)
try:
    with open(IPC_file_path, 'w') as f:
        pass
except Exception as e:
    error('Failed to truncate the IPC file at "' + IPC_file_path + '":' + e)

# Continuously read the log file
i = 1
while True:
    # Read the log into a variable
    try:
        with open(log_file_path, 'r') as f:
            fileContents = f.read()
    except Exception as e:
        error('Could not open the log file at "' + log_file_path + '":' + e)

    # Convert it to an array
    file_array = fileContents.splitlines()

    # Return to the start if we go past the end of the file (which occurs when the log file is truncated)
    if file_array_position > len(file_array):
        file_array_position = 0

    # Process the log's new output
    for line in file_array[file_array_position:]:
        # Debug
        #print("- " + line)

        # Check for the start of a run
        if line.startswith('RNG Start Seed: '):
            match = re.search(r'RNG Start Seed: (.... ....) \(\d+\)', line)
            if match:
                write_file('New seed: ' + match.group(1))
            else:
                error('Failed to parse the seed of the current run:\n' + line)

        # Check for a new floor
        elif line.startswith('Level::Init '):
            # Rebirth uses AltStage and Afterbirth uses StageType
            match = re.search(r'Level::Init m_Stage (\d+), m_(AltStage|StageType) (\d+) Seed \d+', line)
            if match:
                write_file('New floor: ' + match.group(1) + '-' + match.group(3))
            else:
                error('Failed to parse the floor of the current run:\n' + line)

        # Check for rooms entered
        elif line.startswith('Room '):
            match = re.search(r'Room (\d+\.\d+)\(', line)
            if match:
                write_file('Entered room: ' + match.group(1))
            else:
                error('Failed to parse the new room:\n' + line)

        # Check for a new item
        elif line.startswith('Adding collectible '):
            match = re.search(r'Adding collectible (\d+) ', line)
            if match:
                write_file('New item: ' + match.group(1))
            else:
                error('Failed to parse the new item:\n' + line)

        # Check for the end of the run
        elif line == 'playing cutscene 17 (Chest).':
            write_file('Finished run: Blue Baby')
        elif line == 'playing cutscene 18 (Dark Room).':
            write_file('Finished run: The Lamb')
        elif line == 'playing cutscene 19 (Mega Satan).':
            write_file('Finished run: Mega Satan')

        # Check for a kill signal
        elif line == '---RACING+ CLOSING---':
            write_file('Detected a kill signal in the Isaac log. Exiting.')
            sys.exit()

    # Set that we have read the log up to this point
    file_array_position = len(file_array)

    # Check to see if the parent died
    i += 1
    if (i == 5):
        i = 1
        parent_exists = False
        for process in psutil.process_iter():
            if process.name() == parent_process_name:
                parent_exists = True
                break
        if parent_exists == False:
            write_file('Detected that my parent exited (' + parent_process_name + '). Exiting.')
            sys.exit()

    # Sleep for a little while so that we don't overload the CPU too much
    time.sleep(0.1)
