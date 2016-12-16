/*

   Copyright 2013 Niklas Voss

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

*/

(function(global) {

    // Add logging
    const fs    = nodeRequire('fs');
    const path  = nodeRequire('path');
    const isDev = nodeRequire('electron-is-dev');
    const log   = nodeRequire('tracer').console({
        format: "{{timestamp}} <{{title}}> {{file}}:{{line}}\r\n{{message}}",
        dateformat: "ddd mmm dd HH:MM:ss Z",
        transport: function(data) {
            // #1 - Log to the JavaScript console
            console.log(data.output);

            // #2 - Log to a file
            let logFile = (isDev ? 'Racing+.log' : path.resolve(process.execPath, '..', 'Racing+.log'));
            fs.appendFile(logFile, data.output + '\n', function(err) {
                if (err) {
                    throw err;
                }
            });
        }
    });

    function Connection(addr, debug) {

        this.ws = new WebSocket(addr);

        this.callbacks = {};

        this.debug = debug;

        this.ws.onclose = this.onClose.bind(this);
        this.ws.onopen = this.onOpen.bind(this);
        this.ws.onmessage = this.onMessage.bind(this);
        this.ws.onerror = this.onError.bind(this);
    }

    if (global.WebSocket) {
        var seperator = " ",
            DefaultJSONProtocol = {
                unpack: function(data) {
                    var name = data.split(seperator)[0];
                    return [name, data.substring(name.length+1, data.length)];
                },
                unmarshal: function(data) {
                    return JSON.parse(data);
                },
                marshalAndPack: function(name, data) {
                    return name + seperator + JSON.stringify(data);
                }
            };

        Connection.prototype = {
            constructor: Connection,
            protocol: DefaultJSONProtocol,
            setProtocol: function(protocol) {
                this.protocol = protocol;
            },
            enableBinary: function() {
                this.ws.binaryType = 'arraybuffer';
            },
            onClose: function(evt) {
                if (this.debug) {
                    log.info("golem: Connection closed!");
                }
                if (this.callbacks.close) {
                    this.callbacks.close(evt);
                }
            },
            onMessage: function(evt) {
                var data = this.protocol.unpack(evt.data);
                if (this.debug) {
                    log.info("golem: Received:", data[0], JSON.parse(data[1]));
                }
                if (this.callbacks[data[0]]) {
                    var obj = this.protocol.unmarshal(data[1]);
                    this.callbacks[data[0]](obj);
                }
            },
            onOpen: function(evt) {
                if (this.debug) {
                    log.info("golem: Connection established!");
                }
                if (this.callbacks.open) {
                    this.callbacks.open(evt);
                }
            },
            on: function(name, callback) {
                this.callbacks[name] = callback;
            },
            emit: function(name, data) {
                this.ws.send(this.protocol.marshalAndPack(name, data));
            },

            // Added stuff
            onError: function(evt) {
                if (this.callbacks.socketError) {
                    this.callbacks.socketError(evt);
                }
            },
            close: function() {
                this.ws.close();
            }

        };

        global.golem = {
            Connection: Connection
        };

    } else {
        log.warn('golem: WebSockets not supported!');
    }
})(this);
