#! C:\Python34\python.exe

# Imports
import argparse
import sys
import json
import subprocess
import os
import dotenv

# Configuration
repository_owner = 'Zamiell'
repository_name = 'isaac-racing-client'

# Subroutines
def error(message):
    print(message)
    sys.exit(1)

# Get command-line arguments
parser = argparse.ArgumentParser()
parser.add_argument('-gh', '--github', help="upload to GitHub in addition to building locally", action='store_true')
args = parser.parse_args()

# Get the version
with open('package.json') as packageJSON:
    data = json.load(packageJSON)
number_version = data['version']
version = 'v' + data['version']

# Commit to the repository
if args.github:
    # Commit to the repository
    return_code = subprocess.call(['git', 'add', '-A'])
    if return_code != 0:
        error('Failed to git add.')
    return_code = subprocess.call(['git', 'commit', '-m', version])
    if return_code != 0:
        error('Failed to git commit.')
    return_code = subprocess.call(['git', 'push'])
    if return_code != 0:
        error('Failed to git push.')

# Build/package
print('Building:', repository_name, version)
if args.github:
    dotenv.load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))
    run_command = 'dist2'
else:
    run_command = 'dist'
return_code = subprocess.call(['npm', 'run', run_command, '--python="C:/Python27/python.exe"'], shell=True)
if return_code != 0:
    error('Failed to build.')

# Done
print('Released version', number_version, 'successfully.')
