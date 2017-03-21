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

You may also be interested in [the Lua mod repository](https://github.com/Zamiell/isaac-racing-client/mod) or [the server repository](https://github.com/Zamiell/isaac-racing-server).

<br />



Run
---

* Install [node](https://nodejs.org/en/download/).
* If you are on Windows, install [Git](https://git-scm.com/download/win).
* If you are on Windows, `npm install --global windows-build-tools`
* `git clone https://github.com/Zamiell/isaac-racing-client.git`
* `cd isaac-racing-client`
* `npm install --ignore-scripts git+https://github.com/greenheartgames/greenworks.git` (We don't want to build this yet because we have to copy over the Steam SDK.)
* Download [the Steamworks SDK v1.38a](https://partner.steamgames.com/downloads/list). (You will need to login with your Steam account first in order to access the downloads list.)
* Extract the contents of the zip file. The extracted contents will contain one subdirectory, `sdk`. Rename this to `steamworks_sdk`.
* Copy this directory to `node_modules/greenworks/deps`.
* `npm install`
* `node_modules\.bin\electron-rebuild`
* `npm start`

<br />



Compile / Package
-----------------

* Install Python 2 (you need to be able to run the `python` command).
* `npm run dist --python="C:\Python27\python27.exe"`

<br />
