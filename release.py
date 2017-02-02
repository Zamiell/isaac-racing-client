#! C:\Python34\python.exe

# Imports
import argparse
import sys
import json
import subprocess
import os
import dotenv
import fileinput
import re
from PIL import Image, ImageFont, ImageDraw

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
parser.add_argument('-l', '--logo', help="only udate the logo", action='store_true')
args = parser.parse_args()

# Get the version
with open('package.json') as package_JSON:
    data = json.load(package_JSON)
number_version = data['version']
version = 'v' + data['version']

# Update the version in the Lua mod "metadata.xml" file
XML_path = os.path.join('assets', 'mod', 'Racing+', 'metadata.xml')
with fileinput.FileInput(XML_path, inplace=True, backup='.bak') as file:
    for line in file:
        # Skip empty lines
        if line.strip() == '':
            continue

        match = re.search(r'<version>.+<\/version>', line)
        if match:
            print('\t<version>' + version + '</version>')
        else:
            print(line, end="")
os.unlink(XML_path + '.bak')

# Draw the version number on the title menu graphic
print('Drawing the version on the title screen...')
large_font = ImageFont.truetype(os.path.join('assets', 'fonts', 'magical-mystery-tour.outline-shadow.ttf'), 13)
title_img = Image.open(os.path.join('assets', 'mod', 'Racing+', 'resources', 'gfx', 'ui', 'main menu', 'titlemenu-orig.png'))
title_draw = ImageDraw.Draw(title_img)
w, h = title_draw.textsize(version, font=large_font)
title_draw.text((68 - w / 2, 195), version, (0, 0, 0), font=large_font)
title_img.save(os.path.join('assets', 'mod', 'Racing+', 'resources', 'gfx', 'ui', 'main menu', 'titlemenu.png'))

# We are done if all we need to do is update the title screen
if args.logo:
    sys.exit()

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
