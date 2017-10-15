isaac-racing-client
===================

Download & Additional Information
---------------------------------

Please visit [the website for Racing+](https://isaacracing.net/).

<br />



Description
-----------

This is the client software for Racing+, a Binding of Isaac: Afterbirth+ racing platform. Normally a single player game, the Lua mod, client, and server allow players to be able to race each other in real time.

The client is written with [Electron](http://electron.atom.io/) and uses WebSockets to communicate with the server. The pretty elements are courtesy of [HTML5 UP](https://html5up.net/).

You may also be interested in [the Lua mod](https://github.com/Zamiell/isaac-racing-client/tree/master/mod) or [the server repository](https://github.com/Zamiell/isaac-racing-server).

<br />



Run (on Windows)
----------------

* Install [node.js](https://nodejs.org/en/download/).
* Install [Git](https://git-scm.com/download/win).
* `npm install --global windows-build-tools`
* `git clone https://github.com/Zamiell/isaac-racing-client.git`
* `cd isaac-racing-client`
* `npm install --ignore-scripts git+https://github.com/greenheartgames/greenworks.git` (We don't want to build this yet because we have to copy over the Steam SDK.)
* Download [the Steamworks SDK v1.41](https://partner.steamgames.com/downloads/list). (You will need to login with your Steam account first in order to access the downloads list.)
* Extract the contents of the zip file. The extracted contents will contain one subdirectory, `sdk`. Rename this to `steamworks_sdk`.
* Copy this directory to `node_modules\greenworks\deps`.
* `npm install`
* `node_modules\.bin\electron-rebuild`
* `npm start`

<br />



Run (on macOS)
--------------

* Install [node.js](https://nodejs.org/en/) (using [nvm](https://github.com/creationix/nvm) to do this is recommended):
  * `touch ~/.bash_profile`
  * `curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash`
  * Close and reopen Terminal.
  * `nvm install node`
* `git clone https://github.com/Zamiell/isaac-racing-client.git`
* `cd isaac-racing-client`
* `npm install --ignore-scripts git+https://github.com/greenheartgames/greenworks.git` (We don't want to build this yet because we have to copy over the Steam SDK.)
* Download [the Steamworks SDK v1.41](https://partner.steamgames.com/downloads/list). (You will need to login with your Steam account first in order to access the downloads list.)
* Extract the contents of the zip file. The extracted contents will contain one subdirectory, `sdk`. Rename this to `steamworks_sdk`.
* Copy this directory to `node_modules/greenworks/deps`.
* `npm install`
* `node_modules/.bin/electron-rebuild`
* `npm start`

<br />

Run (on Ubuntu 16.04)
---------------------

* `sudo apt install curl git -y`
* Follow the instructions for macOS above.

If you are on Ubuntu 17.04:

* You might have to do a `apt --fix-broken install` after installing NodeJS.
* `electron-rebuild` might not run due to a missing token for a dependency check. Instead, use electron-builder to build the initial electron modules.
* You might have to create a symbolic link for nodejs: `ln -s /usr/bin/nodejs /usr/bin/node`

<br />
