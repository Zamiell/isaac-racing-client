isaac-racing-client
===================

Download & Additional Information
---------------------------------

Please visit [the website for Racing+](https://isaacracing.net/).



Description
-----------

This is the client software for Racing+, a Binding of Isaac: Afterbirth+ racing mod. Normally a single player game, the mod and server allow players to be able to race each other in real time.

The client is written with [Electron](http://electron.atom.io/) and uses WebSockets to communicate with the server. The pretty elements are courtesy of [HTML5 UP](https://html5up.net/).



Run
---

* Install node/npm. (Using [nvm](https://github.com/creationix/nvm) to do this is recommended.)
* `git clone https://github.com/Zamiell/isaac-racing-client.git`
* `cd isaac-racing-client`
* `npm install --ignore-scripts git+https://github.com/greenheartgames/greenworks.git` (We don't want to build this yet because we have to copy over the Steam SDK.)
* Download [the Steamworks SDK v1.38a](https://partner.steamgames.com/downloads/list). (You will need to login with your Steam account first in order to access the downloads list.)
* Extract the contents of the zip file. The extracted contents will contain one subdirectory, `sdk`. Rename this to `steamworks_sdk`.
* Copy this directory to `node_modules/greenworks/deps`.
* `npm install`
* `node_modules/.bin/electron-rebuild`
* `npm start`

Compile / Package
-----------------

* Install Python 2 (you need to be able to run the `python` command).
* `npm run dist --python="C:\Python27\python27.exe"`
