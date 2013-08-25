package hunger.client;

import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import hunger.proto.Connect;
import hunger.proto.EntityType;
import hunger.proto.Packet;
import hunger.shared.MsgQueue;
import hunger.shared.Player;
import hunger.shared.SocketConnection;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import haxe.ds.IntMap.IntMap;
import haxe.io.Bytes;
import hunger.shared.GameWorld;
import nape.geom.Vec2;
import protohx.Message;

class Main extends Sprite {
	public static var m: Main;
	
	var inited:Bool;
	var world: GameWorld;
	var player: Player;
	var socket: SocketConnection;
	var msgQ: MsgQueue;
	var connected = false;
	var nick = "player";
	public var tick = 0;
	
	function resize(e) {
		if (!inited) init();
		// else (resize or orientation change)
	}
	
	function init() {
		if (inited) return;
		inited = true;
		m = this;
		
        //players = new IntMap<PlayerNode>();
		player = new Player(true, 500 * Math.random(), 25);
        msgQ = new MsgQueue();
        socket = new SocketConnection();
		world = new GameWorld();
        socket.connect("localhost", 4242, onConnect, addBytes, onClose);
	}
	
	private function onConnect():Void { 
		trace("Connected");
		var connectMsg: Connect = new Connect();
		connectMsg.nick = nick;
		player.nick = nick;
		
		var packet = new Packet();
		packet.connect = connectMsg;
		socket.writeMsg(packet);
		
		stage.addEventListener(Event.ENTER_FRAME, update);
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keydown);
		stage.addEventListener(KeyboardEvent.KEY_UP,   keyup);
	}
	
	function update(e: Event) {
		tick++;
		world.update();
		
		if (tick % 3 == 0) {
			//trace("Writing player update");
			socket.writeMsg(player.toPacket());
		}
	}
	   
	private function addBytes(bytes:Bytes):Void {
        msgQ.addBytes(bytes);
        while (msgQ.hasMsg()) {
            var msg:Packet = msgQ.popMsg();
			if (msg.connectAck != null) {
				connected = true;
				player.id = msg.connectAck.id;
				trace("Adding player.");
				world.add(player);
			}
			
			if (msg.entityUpdate != null) {
				//trace("Got entity update");
				if (world.entities.exists(msg.entityUpdate.id)) {
					trace("Updating existing entity.");
					var entity = world.entities.get(msg.entityUpdate.id);
					entity.setFromPacket(msg.entityUpdate.x, msg.entityUpdate.y, msg.entityUpdate.rotation);
				} else {
					switch (msg.entityUpdate.type) {
						case EntityType.PLAYER:
							trace("Creating new entity");
							var entity = new Player(false);
							entity.id = msg.entityUpdate.id;
							entity.setFromPacket(msg.entityUpdate.x, msg.entityUpdate.y, msg.entityUpdate.rotation);
							world.add(entity);
					}
				}
			}
        }
    }
	
	private function onClose():Void { trace("Connection closed. :("); }
	
	function keydown(evt: KeyboardEvent) {
		switch(evt.keyCode) {
			case Keyboard.W: player.up = true;
			case Keyboard.A: player.left = true;
			case Keyboard.S: player.down = true;
			case Keyboard.D: player.right = true;
		}
	}
	
	function keyup(evt: KeyboardEvent) {
		switch(evt.keyCode) {
			case Keyboard.W: player.up = false;
			case Keyboard.A: player.left = false;
			case Keyboard.S: player.down = false;
			case Keyboard.D: player.right = false;
		}
	}
	

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
