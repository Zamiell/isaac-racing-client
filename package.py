#! C:\Python34\python.exe

# Imports
import sys
import json
import subprocess
import requests

# Configuration
program_name = 'isaac-racing-client'

# Subroutines
def error(message):
    print(message)
    sys.exit(1)

# Get the version
with open('app/package.json') as packageJSON:
    data = json.load(packageJSON)
version = 'v' + data['version']

# Build/package
'''
print('Building:', program_name, version)
return_code = subprocess.call(['npm', 'run', 'dist', '--python="C:/Python27/python.exe"'], shell=True)
if return_code != 0:
    error('Failed to build.')
'''

# Commit to the repository
return_code = subprocess.call(['git', 'add', '-A'])
if return_code != 0:
    error('Failed to git add.')
return_code = subprocess.call(['git', 'commit', '-a', '-m', version])
if return_code != 0:
    error('Failed to git commit.')
return_code = subprocess.call(['git', 'push'])
if return_code != 0:
    error('Failed to git push.')

# Make a new release for this version
r = requests.post('https://github.com/repos/Zamiell/isaac-racing-client/releases', data={'tag_name': version})
