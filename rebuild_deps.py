#! C:\Python34\python.exe

# Imports
import os
import sys
import subprocess

# Configuration
repository_name = 'isaac-racing-client'
repository_dir = os.path.join('C:\\Repositories\\', repository_name)

try:
    # Change directory
    os.chdir(repository_dir)

    # Delete all of the existing node_modules
    print('Removing the "node_modules" folder...')
    subprocess.call(['rm', '-rf', 'node_modules'])

    # Remove Greenworks from the "package.json" file since we don't want to install it yet
    subprocess.call(['sed', '-i.bak', '/"greenworks": "git/d', 'package.json'])
    subprocess.call(['rm', 'package.json.bak'])

    # Download and install all of the modules except for Greenworks
    print('Installing packages...')
    subprocess.call(['C:\\Program Files\\nodejs\\npm.cmd', 'install'])

    # Install Greenworks
    print('Installing Greenworks...')
    subprocess.call(['C:\\Program Files\\nodejs\\npm.cmd', 'install', '--save', '--ignore-scripts', 'git+https://github.com/greenheartgames/greenworks.git'])
    subprocess.call(['cp', '-R', 'D:\\Backup\\greenworks\\steamworks_sdk_141\\steamworks_sdk', 'C:\\Repositories\\isaac-racing-client\\node_modules\\greenworks\\deps\\steamworks_sdk'])
    subprocess.call(['C:\\Program Files\\nodejs\\npm.cmd', 'install'])
    subprocess.call([os.path.join(repository_dir, 'node_modules', '.bin', 'electron-rebuild.cmd')])

    print('Completed!')

except Exception as e:
    print('Failed:', e)
    sys.exit(1)