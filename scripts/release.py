#!/c/Python38/python.exe

""" This is the script that compiles and builds the Racing+ client. """

# Standard imports
import argparse
import sys
import json
import subprocess
import os
import re

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
os.chdir(REPOSITORY_DIR)


def main():
    args = get_command_line_args()

    # Load environment variables
    dotenv.load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

    if args.github:
        if (
            os.environ.get("GH_TOKEN") == ""
            or os.environ.get("VPS_IP") == ""
            or os.environ.get("VPS_USER") == ""
            or os.environ.get("VPS_PASS") == ""
        ):
            print('error: GH_TOKEN is blank in the ".env" file')
            sys.exit(1)

    # Get the version
    with open("package.json") as package_JSON:
        DATA = json.load(package_JSON)
    NUMBER_VERSION = DATA["version"]
    VERSION = "v" + DATA["version"]

    if args.github:
        ensure_localhost_false()
        git_commit()

    # Close the program if it is running
    # (having it open can cause corrupted ASAR archives)
    for process in psutil.process_iter():
        if process.name() == "electron.exe":
            process.kill()

    # Build/package
    print("Building:", REPOSITORY_NAME, VERSION)
    if args.github:
        RUN_COMMAND = "distPub"
    else:
        RUN_COMMAND = "dist"
    RETURN_CODE = subprocess.call(
        ["npm", "run", RUN_COMMAND, '--python="C:/Python27/python.exe"'], shell=True
    )
    if RETURN_CODE != 0:
        error("Failed to build.")

    # Set the latest client version number on the server
    if args.github:
        latest_client_version_file = "latest_client_version.txt"
        with open(latest_client_version_file, "w") as version_file:
            print(VERSION, file=version_file)

        transport = paramiko.Transport((os.environ.get("VPS_IP"), 22))
        transport.connect(None, os.environ.get("VPS_USER"), os.environ.get("VPS_PASS"))
        sftp = paramiko.SFTPClient.from_transport(transport)
        remote_path = "isaac-racing-server/" + latest_client_version_file
        sftp.put(latest_client_version_file, remote_path)
        transport.close()
        os.remove(latest_client_version_file)

    print("Released version", NUMBER_VERSION, "successfully.")


def get_command_line_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-gh",
        "--github",
        help="upload to GitHub in addition to building locally",
        action="store_true",
    )
    return parser.parse_args()


def ensure_localhost_false():
    # Make sure that the localhost version of the client is not activated
    # http://stackoverflow.com/questions/17140886/how-to-search-and-replace-text-in-a-file-using-python
    constants_file = os.path.join("src", "renderer", "constants.js")
    with open(constants_file, "r") as file_handle:
        file_data = file_handle.read()
    new_file = ""
    for line in iter(file_data.splitlines()):
        match = re.search(r"const localhost = true;", line)
        if match:
            new_file += "const localhost = false;" + "\n"
        else:
            new_file += line + "\n"
    with open(constants_file, "w", newline="\n") as file:
        file.write(new_file)


def git_commit(version: str):
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


# Subroutines
def error(message, exception=None):
    if exception is None:
        print(message)
    else:
        print(message, exception)
    sys.exit(1)


if __name__ == "__main__":
    main()
