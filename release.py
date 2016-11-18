#! C:\Python34\python.exe

# Imports
import sys
import json
import subprocess
import requests
import github3
import certifi
import urllib3

# Configuration
repository_owner = 'Zamiell'
repository_name = 'isaac-racing-client'

# Subroutines
def error(message):
    print(message)
    sys.exit(1)

# Get the version
with open('app/package.json') as packageJSON:
    data = json.load(packageJSON)
number_version = data['version']
version = 'v' + data['version']

# Build/package
print('Building:', repository_name, version)
return_code = subprocess.call(['npm', 'run', 'dist', '--python="C:/Python27/python.exe"'], shell=True)
if return_code != 0:
    error('Failed to build.')

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

# Get the access token
with open('.secrets') as f:
    access_token = f.read().strip()

# Make a new release for this version
print('Making a new release.')
github = github3.login(token=access_token)
repository = github.repository(repository_owner, repository_name)
release = repository.create_release(version)

# Ignore "InsecureRequestWarning" when uploading files
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# Upload assets
files = [
    'Racing+ Setup ' + number_version + '.exe',
    'RacingPlus-' + number_version + '-full.nupkg',
    'RELEASES',
]
for file_name in files:
    asset = release.upload_asset(content_type='application/binary', name=file_name, asset=open('dist/win/' + file_name, 'rb'))
