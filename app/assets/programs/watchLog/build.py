#! C:\Python34\python.exe

# Notes:
# - This file will "freeze" the Python code into an EXE and then package it into a ZIP file.

# Imports
import os
import subprocess
import shutil

# Configuration
program_name = 'watchLog'
pyinstaller_path = 'C:\Python34\Scripts\pyinstaller.exe'

# Clean up build-related directories before we start to do anything
if os.path.exists('build'):
    shutil.rmtree('build')
if os.path.exists('dist'):
    shutil.rmtree('dist')
if os.path.exists('__pycache__'):
    shutil.rmtree('__pycache__')
if os.path.exists('program/__pycache__'):
    shutil.rmtree('program/__pycache__')

# Check if pyinstaller is installed
if not os.path.isfile(pyinstaller_path):
    print('Error: Edit this file and specify the path to your pyinstaller.exe file.')
    exit(1)

# Freeze the updater into an exe
return_code = subprocess.call([pyinstaller_path, '--onefile', '--clean', '--log-level=ERROR', program_name + '.py'])
if return_code != 0:
    error('Failed to freeze "' + mod_name + '.py".')

# Clean up
shutil.rmtree('build')
shutil.rmtree('__pycache__')
os.unlink(program_name + '.spec')

# Finished
print('Built ' + program_name + '.exe successfully.')
