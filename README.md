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
* Install [Yarn](https://yarnpkg.com/en/docs/install).
* Install [Git](https://git-scm.com/download/win).
* `git clone https://github.com/Zamiell/isaac-racing-client.git`
* `cd isaac-racing-client`
* `yarn install`
* `npm start`

<br />



Run (on macOS)
--------------

* Install [node.js](https://nodejs.org/en/) (using [nvm](https://github.com/creationix/nvm) to do this is recommended):
  * `touch ~/.bash_profile`
  * `curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash`
  * Close and reopen Terminal.
  * `nvm install node`
* Install [Yarn](https://yarnpkg.com/en/docs/install):
  * `brew install yarn --without-node`
* `git clone https://github.com/Zamiell/isaac-racing-client.git`
* `cd isaac-racing-client`
* `yarn install`
* `npm start`

<br />



Run (on Ubuntu 16.04)
---------------------

* `sudo apt install curl git -y`
* Follow the instructions for macOS above.

If you are on Ubuntu 17.04:

* You might have to do a `apt --fix-broken install` after installing NodeJS.
* You might have to create a symbolic link for nodejs: `ln -s /usr/bin/nodejs /usr/bin/node`

<br />
