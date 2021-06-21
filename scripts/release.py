#!/c/Python38/python.exe

""" This is the script that compiles and builds the Racing+ client. """

# Standard imports
import argparse
import sys
import json
import subprocess
import os
import re
import urllib.request

# Non-standard imports
import dotenv
import psutil
import paramiko

# This script is written for Python 3
if sys.version_info < (3, 0):
    print("This script requires Python 3.")
    sys.exit(1)

# Constants
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
REPOSITORY_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
REPOSITORY_NAME = os.path.basename(REPOSITORY_DIR)
VERSION_URL = (
    "https://raw.githubusercontent.com/Zamiell/racing-plus/main/mod/version.txt"
)


def main():
    os.chdir(REPOSITORY_DIR)

    # Load environment variables
    dotenv.load_dotenv(os.path.join(SCRIPT_DIR, ".env"))
    validate_environment_variables()

    # For the version, match the latest Racing+ mod version uploaded to GitHub
    with urllib.request.urlopen(VERSION_URL) as response:
        version = response.read().decode("utf-8").strip()

    write_version_to_package_json(version)
    ensure_localhost_false()
    git_commit(version)
    close_existing_electron()
    sys.exit(0)
    package_electron(version)
    set_latest_client_version_on_server(version)

    print("Released version {} successfully.".format(version))


def validate_environment_variables():
    if os.environ.get("GH_TOKEN") == "":
        error('error: GH_TOKEN is blank in the ".env" file')

    if os.environ.get("VPS_IP") == "":
        error('error: VPS_IP is blank in the ".env" file')

    if os.environ.get("VPS_USER") == "":
        error('error: VPS_USER is blank in the ".env" file')

    if os.environ.get("VPS_PASS") == "":
        error('error: VPS_PASS is blank in the ".env" file')


def write_version_to_package_json(version: str):
    match_regex = r'  "version": "\d+.\d+\.\d+",'
    replace = '  "version": "{}",'.format(version)
    find_and_replace_in_file(match_regex, replace, "package.json")


def ensure_localhost_false():
    # Make sure that the localhost version of the client is not activated
    constants_file = os.path.join(REPOSITORY_DIR, "src", "renderer", "constants.ts")
    find_and_replace_in_file(
        "const localhost = true;", "const localhost = false;", constants_file
    )


def git_commit(version: str):
    # Throw an error if this is not a git repository
    return_code = subprocess.call(["git", "status"])
    if return_code != 0:
        error("This is not a git repository.")

    # Check to see if there are any changes
    # https://stackoverflow.com/questions/3878624/how-do-i-programmatically-determine-if-there-are-uncommitted-changes
    return_code = subprocess.call(["git", "diff-index", "--quiet", "HEAD", "--"])
    if return_code == 0:
        # There are no changes
        print("There are no changes to commit.")
        return

    # Commit to the client repository
    return_code = subprocess.call(["git", "add", "-A"])
    if return_code != 0:
        error("Failed to git add.")
    return_code = subprocess.call(["git", "commit", "-m", version])
    if return_code != 0:
        error("Failed to git commit.")
    return_code = subprocess.call(["git", "pull", "--rebase"])
    if return_code != 0:
        error("Failed to git pull.")
    return_code = subprocess.call(["git", "push"])
    if return_code != 0:
        error("Failed to git push.")


def close_existing_electron():
    # Having Electron open can cause corrupted ASAR archives
    for process in psutil.process_iter():
        if process.name() == "electron.exe":
            process.kill()


def package_electron(version: str, github: bool):
    print("Building:", REPOSITORY_NAME, version)
    return_code = subprocess.call(["npm", "run", "publish"], shell=True)
    if return_code != 0:
        error("Failed to build.")


def set_latest_client_version_on_server(version: str):
    latest_client_version_file = "latest_client_version.txt"

    with open(latest_client_version_file, "w") as version_file:
        print(version, file=version_file)

    transport = paramiko.Transport((os.environ.get("VPS_IP"), 22))
    transport.connect(None, os.environ.get("VPS_USER"), os.environ.get("VPS_PASS"))
    sftp = paramiko.SFTPClient.from_transport(transport)
    remote_path = "isaac-racing-server/" + latest_client_version_file
    sftp.put(latest_client_version_file, remote_path)
    transport.close()

    os.remove(latest_client_version_file)


# From: http://stackoverflow.com/questions/17140886/how-to-search-and-replace-text-in-a-file-using-python
def find_and_replace_in_file(match_regex: str, replace: str, file_path: str):
    with open(file_path, "r") as file_handle:
        file_data = file_handle.read()

    new_file = ""
    for line in iter(file_data.splitlines()):
        match = re.search(match_regex, line)
        if match:
            new_file += replace + "\n"
        else:
            new_file += line + "\n"

    with open(file_path, "w", newline="\n") as file:
        file.write(new_file)


def error(message):
    print(message)
    sys.exit(1)


if __name__ == "__main__":
    main()
