#!/bin/bash

set -e # Exit on any errors

# Get the directory of this script
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "$DIR"

if [ ! "$1" == "renderer" ]; then
  rm -rf "$DIR/dist"

  echo "Building the main JavaScript..."
  npx webpack --config ./webpack.main.config.js
fi

echo "Building the renderer JavaScript..."
npx webpack --config ./webpack.renderer.config.js
