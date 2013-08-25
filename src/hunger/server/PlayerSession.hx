package hunger.server;

import hunger.shared.MsgQueue;
import hunger.shared.Player;
import hunger.shared.Sword;
import sys.net.Socket;
import protohx.Message;
import haxe.io.BytesOutput;

class PlayerSession {
	public static var nextId = 1;
	public var id: Int;
	public var player: Player;
	public var sword: Sword;
    public var socket: Socket;
	public var msgQ: MsgQueue;
	public var disconnected = false;
	
    public function new(socket:Socket) {
        this.socket = socket;
		id = nextId++;
        socket.setFastSend(true);
        socket.output.bigEndian = false;
        socket.input.bigEndian = false;
		msgQ = new MsgQueue();
    }

    public function close():Void {
        try { socket.close(); } catch (e: Dynamic) { }
		disconnected = true;
    }

    public function writeMsg(msg: Message):Void {
		if (disconnected) return;
        try{
            var bytes = msgToBytes(msg);
            socket.output.writeUInt16(bytes.length);
            socket.output.write(bytes);
            //socket.output.flush();
        }catch(e:Dynamic){
            trace(e);
            #if haxe3
            trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            #else
            trace(haxe.Stack.toString(haxe.Stack.exceptionStack()));
            #end
			//close();
        }
    }

    public static function msgToBytes(msg:Message):haxe.io.Bytes {
        var b = new BytesOutput();
        msg.writeTo(b);
        return b.getBytes();
    }

}