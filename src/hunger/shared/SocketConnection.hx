package hunger.shared;

//From https://github.com/nitrobin/protohx/blob/master/samples/03-network/src/common/SocketConnection.hx
/*
Copyright (c) 2010, NetEase.com,Inc.
Copyright (c) 2011, 杨博(Yang Bo)
Copyright (c) 2013, Евгений Веретенников(Eugene Veretennikov)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import haxe.io.BytesData;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.io.Eof;
import protohx.Message;

#if flash

import flash.events.Event;
import flash.events.ErrorEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ProgressEvent;
class SocketConnection {
    var socket:flash.net.Socket;

    public function connect(host, port, onConnect, addBytes, onClose) {
        socket.connect(host, port);
        this.onConnect = onConnect;
        this.onClose = onClose;
        this.addBytes = addBytes;
    }

    public dynamic function onConnect():Void {}
    public dynamic function onClose():Void {}
    public dynamic function addBytes(bytes:Bytes):Void {}

    public function new() {
        socket = new flash.net.Socket();
        socket.addEventListener(Event.CLOSE, closeHandler);
        socket.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        socket.addEventListener(IOErrorEvent.NETWORK_ERROR, errorHandler);
        socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
        socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
        socket.addEventListener(Event.CONNECT, connectHandler);
        socket.endian = flash.utils.Endian.LITTLE_ENDIAN ;
    }
	
    private function closeHandler(e:Event):Void {
        trace("closeHandler");
        detach();
        onClose();
    }

    private function errorHandler(e:ErrorEvent):Void {
        trace("errorHandler" + Std.string(e));
        detach();
        onClose();
    }

    private function connectHandler(e:Event):Void {
//        trace("connectHandler");
        onConnect();
    }

    public function writeMsg(msg:Message):Void {
        var b = new BytesOutput();
        msg.writeTo(b);
        var bytes = b.getBytes();
        socket.writeShort(bytes.length);
        socket.writeBytes(cast bytes.getData());
		socket.flush();
    }

    private function socketDataHandler(e:ProgressEvent):Void {
        try {
//            trace("socketDataHandler");
            var b = new flash.utils.ByteArray();
            socket.readBytes(b);
            var bs = Bytes.ofData(cast b);
            addBytes(bs);
        } catch (e:Dynamic) {
            trace('error: ' + e);
        }
    }

    public function detach():Void {
        socket.removeEventListener(Event.CLOSE, closeHandler);
        socket.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        socket.removeEventListener(IOErrorEvent.NETWORK_ERROR, errorHandler);
        socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
        socket.removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
        socket.removeEventListener(Event.CONNECT, connectHandler);
    }
}
#elseif (neko||cpp)
class SocketConnection {
    var socket:sys.net.Socket;

    public function connect(host, port, onConnect, addBytes, onClose) {
        this.onConnect = onConnect;
        this.addBytes = addBytes;
        this.onClose = onClose;
        try{
            socket.connect(new sys.net.Host(host), port);
        }catch(e:Dynamic){
            trace(e);
            #if haxe3
            trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            #else
            trace(haxe.Stack.toString(haxe.Stack.exceptionStack()));
            #end
            onClose();
            return;
        }
        trace("connected");
        onConnect();

        var buffer = Bytes.alloc(1024);
        var socks = [socket];
        var timer = new haxe.Timer(100);
        timer.run = function() {
            try {
                var r:Array<sys.net.Socket>;
                do {
                    r = sys.net.Socket.select(socks, null, null, 0.001).read;
                    for (s in r) {
                        var size = s.input.readBytes(buffer, 0, buffer.length);
                        addBytes(buffer.sub(0, size));
                    }
                } while (r.length > 0);
            } catch (e:haxe.io.Eof) {
                timer.stop();
                onClose();
                socket.close();
            } catch (e:Dynamic) {
                trace(e);
                #if haxe3
                trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
                #else
                trace(haxe.Stack.toString(haxe.Stack.exceptionStack()));
                #end
            }
        };
    }

    public dynamic function onConnect():Void {}
    public dynamic function onClose():Void {}
    public dynamic function addBytes(bytes:Bytes):Void {}

    public function new() {
        socket = new sys.net.Socket();
        socket.input.bigEndian = false;
        socket.output.bigEndian = false;
    }

    public function writeMsg(msg:Message):Void {
        var b = new BytesOutput();
        msg.writeTo(b);
        var bytes = b.getBytes();
        socket.output.writeUInt16(bytes.length);
        socket.output.writeBytes(bytes, 0, bytes.length);
    }
}
#elseif js
class SocketConnection {
    var socket:Dynamic;

    public dynamic function onConnect():Void {}
    public dynamic function onClose():Void {}
    public dynamic function addBytes(bytes:Bytes):Void {}

    public function new() {

    }

    public function handleMsg(msg:String):Void {
    }
    public function writeMsg(msg:Message):Void {
        socket.emit("message", Base64.encodeBase64(msgToFrameBytes(msg)));
    }

    public static function msgToFrameBytes(msg:Message):haxe.io.Bytes {
        var b = new BytesOutput();
        msg.writeTo(b);
        var data = b.getBytes();

        var res = new BytesOutput();
        res.writeUInt16(data.length);
        res.write(data);
        return res.getBytes();
    }

    public function connect(host, port, onConnect, addBytes, onClose) {
        this.onConnect = onConnect;
        this.addBytes = addBytes;
        this.onClose = onClose;
        var self = this;
        var decodeBytes = Base64.decodeBase64;
        untyped __js__("
        //self.socket = io.connect('http://'+host+':'+port);
        self.socket = io.connect();
        this.socket.on('connect', function () {
            onConnect();
            self.socket.on('message', function (msg) {
                addBytes(decodeBytes(msg));
            });
            self.socket.on('disconnect', function (msg) {
                onClose();
                self.socket.disconnect();
                onConnect = function(){}
                onClose = function(){}
                addBytes = function(b){}
            });
        });
        ");
    }
}
#end