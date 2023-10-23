#!/bin/bash

set -euo pipefail # Exit on errors and undefined variables.

# Get the directory of this script:
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Get the name of the repository:
# https://stackoverflow.com/questions/23162299/how-to-get-the-last-part-of-dirname-in-bash/23162553
REPO_NAME="$(basename "$DIR")"

SECONDS=0

cd "$DIR"

# Use Prettier to check formatting.
# "--log-level=warn" makes it only output errors.
npx prettier --log-level=warn --check .

# Use ESLint to lint the TypeScript.
# "--max-warnings 0" makes warnings fail in CI, since we set all ESLint errors to warnings.
npx eslint --max-warnings 0 .

# Check for unused files, dependencies, and exports.
# @template-ignore-next-line
# npx knip

# @template-customization-start

# Check for unused exports.
# "--error" makes it return an error code of 1 if unused exports are found.
npx ts-prune --error

# @template-customization-end

# Spell check every file using CSpell.
# "--no-progress" and "--no-summary" make it only output errors.
npx cspell --no-progress --no-summary .

# Check for unused CSpell words.
npx cspell-check-unused-words

# @template-customization-start

# Check for base file updates.
npx isaacscript check-ts --ignore "build.sh,cspell.json,publish.sh,run.sh"

# @template-customization-end

echo "Successfully linted $REPO_NAME in $SECONDS seconds."
