isaac-racing-client
===================

Description
-----------

This is the client software for the Binding of Isaac: Afterbirth+ racing mod. Normally a single player game, the mod and server allow players to be able to race each other in real time.

The client is written with [Electron](http://electron.atom.io/) and uses WebSockets to communicate with the server. The pretty elements are courtesy of [HTML5 UP](https://html5up.net/).



Run
---

* `git clone https://github.com/Zamiell/isaac-racing-server.git`
* `cd isaac-racing-server`
* `npm install`
* `npm start`



Compile / Package
-----------------

* Install Python 2 (you need to be able to run the `python` command).
* `npm run dist --python="C:\Python27\python27.exe`
