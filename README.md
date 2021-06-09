# isaac-racing-client

<br />

## Download & Additional Information

Please visit [the website for Racing+](https://isaacracing.net/).

<br />

## Description

This is the client software for Racing+, a Binding of Isaac: Repentance racing platform. Normally a single player game, the Lua mod, client, and server allow players to be able to race each other in real time.

The client is written with [Electron](http://electron.atom.io/) and uses WebSockets to communicate with the server. The pretty elements are courtesy of [HTML5 UP](https://html5up.net/).

You may also be interested in [the Lua mod](https://github.com/Zamiell/isaac-racing-client/tree/master/mod) or [the server repository](https://github.com/Zamiell/isaac-racing-server).

<br />

## Settings

The location for the client settings file is: `C:\Users\[Username]\AppData\Local\Programs\settings.json`

<br />

## Run from Source (on Windows)

* Install [node.js](https://nodejs.org/en/download/).
* Install [Yarn](https://yarnpkg.com/en/docs/install).
* Install [Git](https://git-scm.com/download/win).
* `git clone https://github.com/Zamiell/isaac-racing-client.git`
* `cd isaac-racing-client`
* `yarn install`
* `npm start`

<br />

## Run from Source (on macOS)

* Install [node.js](https://nodejs.org/en/) (using [nvm](https://github.com/creationix/nvm) to do this is recommended):
  * `touch ~/.bash_profile`
  * `curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash`
  * Close and reopen Terminal.
  * `nvm install node`
* Install [Yarn](https://yarnpkg.com/en/docs/install):
  * `brew install yarn --without-node`
* `git clone https://github.com/Zamiell/isaac-racing-client.git`
* `cd isaac-racing-client`
* `yarn install`
* `npm start`

<br />

## Run from Source (on Ubuntu 18.04)

* Install [curl](https://curl.haxx.se/) and [Git](https://git-scm.com/):
  * `sudo apt install curl git -y`
* Install [node.js](https://nodejs.org/en/) (using [nvm](https://github.com/creationix/nvm) to do this is recommended):
  * `curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash`
  * Close and reopen Terminal.
  * `nvm install node`
* Install [Yarn](https://yarnpkg.com/en/docs/install):
  * `curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -`
  * `echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list`
  * `sudo apt-get update && sudo apt-get install yarn`
* `git clone https://github.com/Zamiell/isaac-racing-client.git`
* `cd isaac-racing-client`
* `yarn install`
* `npm start`

<br />

## Build (on Windows)

* `npm install --global --production windows-build-tools`
* `C:\Python34\python.exe release.py`
