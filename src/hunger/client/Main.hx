package hunger.client;

import hunger.proto.Connect;
import hunger.proto.Packet;
import hunger.shared.MsgQueue;
import hunger.shared.SocketConnection;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import haxe.ds.IntMap.IntMap;
import haxe.io.Bytes;
import hunger.shared.GameWorld;
import protohx.Message;

class Main extends Sprite {
	var inited:Bool;
	var world: GameWorld;
	var socket: SocketConnection;
	var msgQ: MsgQueue;
	
	function resize(e) {
		if (!inited) init();
		// else (resize or orientation change)
	}
	
	function init() {
		if (inited) return;
		inited = true;
		
        //players = new IntMap<PlayerNode>();
        msgQ = new MsgQueue();
        socket = new SocketConnection();
        socket.connect("localhost", 4242, onConnect, addBytes, onClose);
	}
	
	private function onConnect():Void { 
		trace("Connected");
		var connectMsg: Connect = new Connect();
		connectMsg.nick = "hiya";
		
		var packet = new Packet();
		packet.connect = connectMsg;
		socket.writeMsg(packet);
	}
	   
	private function addBytes(bytes:Bytes):Void {
        msgQ.addBytes(bytes);
        while (msgQ.hasMsg()) {
            var msg:Message = msgQ.popMsg();
            trace('CLIENT MSG: ' + haxe.Json.stringify(msg));
        }
    }
	private function onClose():Void { }
	

	public function new() {
		super();	
		addEventListener(Event.ADDED_TO_STAGE, added);
	}

	function added(e) {
		removeEventListener(Event.ADDED_TO_STAGE, added);
		stage.addEventListener(Event.RESIZE, resize);
		#if ios
		haxe.Timer.delay(init, 100); // iOS 6
		#else
		init();
		#end
	}
	
	public static function main() {
		// static entry point
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}
}
