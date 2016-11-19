#! C:\Python34\python.exe

# Imports
import os
import datetime
import tempfile
import time

IPC_file_path = os.path.join(tempfile.gettempdir(), 'Racing+_IPC.txt')

def error(message):
    print('Error:', message)
    sys.exit(1)

def write_file(message):
    try:
        with open(IPC_file_path, 'a') as f:
            f.write(message + '\n')
    except Exception as e:
        error('Failed to write to the IPC file at "' + IPC_file_path + '":' + e)

write_file(str(datetime.datetime.now().time()) + ' - TEST')

while True:
    time.sleep(1)
