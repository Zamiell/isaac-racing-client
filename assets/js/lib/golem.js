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

// We need access to the globals here so that we can use the logger
const globals = nodeRequire('./assets/js/globals');

var separator = " ";
var DefaultJSONProtocol = {
    unpack: function(data) {
        var name = data.split(separator)[0];
        return [name, data.substring(name.length + 1, data.length)];
    },
    unmarshal: function(data) {
        return JSON.parse(data);
    },
    marshalAndPack: function(name, data) {
        return name + separator + JSON.stringify(data);
    },
};

var Connection = function(addr, debug) {
    this.ws = new WebSocket(addr);
    this.callbacks = {};
    this.debug = debug;
    this.ws.onclose = this.onClose.bind(this);
    this.ws.onopen = this.onOpen.bind(this);
    this.ws.onmessage = this.onMessage.bind(this);
    this.ws.onerror = this.onError.bind(this);
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
            globals.log.info("golem: Connection closed!");
        }
        if (this.callbacks.close) {
            this.callbacks.close(evt);
        }
    },
    onMessage: function(evt) {
        var data = this.protocol.unpack(evt.data);
        if (this.debug) {
            globals.log.info("golem: Received:", data[0], JSON.parse(data[1]));
        }
        if (this.callbacks[data[0]]) {
            var obj = this.protocol.unmarshal(data[1]);
            this.callbacks[data[0]](obj);
        }
    },
    onOpen: function(evt) {
        if (this.debug) {
            globals.log.info("golem: Connection established!");
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
exports.Connection = Connection;
