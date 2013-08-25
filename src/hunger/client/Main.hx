package hunger.client;

import flash.events.KeyboardEvent;
import flash.external.ExternalInterface;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import hunger.proto.Connect;
import hunger.proto.EntityType;
import hunger.proto.Packet;
import hunger.shared.Animal;
import hunger.shared.Entity;
import hunger.shared.Food;
import hunger.shared.MsgQueue;
import hunger.shared.Player;
import hunger.shared.SocketConnection;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import haxe.ds.IntMap.IntMap;
import haxe.io.Bytes;
import hunger.shared.GameWorld;
import hunger.shared.Sword;
import hunger.shared.Terrain;
import nape.geom.Vec2;
import protohx.Message;

class Main extends Sprite {
	public static var m: Main;
	
	var inited:Bool;
	var world: GameWorld;
	var player: Player;
	var sword: Sword;
	var socket: SocketConnection;
	var msgQ: MsgQueue;
	var connected = false;
	var nick = "player";
	public var tick = 0;
	var terrain: Terrain;
	var finished = false;
	var deathTimer = 60;
	var dead = false;
	var text: TextField;
	
	function resize(e) {
		if (!inited) init();
		// else (resize or orientation change)
	}
	
	function init() {
		if (inited) return;
		inited = true;
		m = this;
		
        //players = new IntMap<PlayerNode>();
		player = new Player(true, 500 * Math.random(), 200);
		sword = new Sword(player);
        msgQ = new MsgQueue();
        socket = new SocketConnection();
		world = new GameWorld();
		
		var host = "localhost:42424";
		
		try { host = ExternalInterface.call("host"); } catch (e: Dynamic) { }

		var hostname = host.split(":")[0];
		var port = Std.parseInt(host.split(":")[1]);
		
        socket.connect(hostname, port, onConnect, addBytes, onClose);
		
		text = new TextField();
		text.defaultTextFormat = new TextFormat("_sans", 10, 0);
		text.autoSize = TextFieldAutoSize.LEFT;
		text.x = 0;
		text.y = 0;
		text.text = "Connecting...";
		stage.addChild(text);
	}
	
	private function onConnect():Void { 
		//trace("Connected");
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
		if (finished) return;
		tick++;
		
		if (dead) deathTimer--;
		if (deathTimer <= 0) {
			reset();
			finished = true;
		}
		
		//Check messages
		while (msgQ.hasMsg()) {
            var msg:Packet = msgQ.popMsg();
			if (msg.connectAck != null) {
				text.text = "";
				connected = true;
				player.id = msg.connectAck.playerId;
				sword.id = msg.connectAck.swordId;
				//trace("Adding player.");
				world.add(player);
				world.add(sword);
				
				terrain = new Terrain();
				terrain.fromUpdate(msg.connectAck.terrain);
				world.add(terrain);
			}
			
			if (msg.entityUpdate != null) {
				//trace("Got entity update");
				if (world.entities.exists(msg.entityUpdate.id)) {
					//trace("Updating existing entity.");
					var entity = world.entities.get(msg.entityUpdate.id);
					entity.setFromPacket(msg.entityUpdate.x, msg.entityUpdate.y, msg.entityUpdate.rotation);
				} else {
					var entity: Entity = null;
					switch (msg.entityUpdate.type) {
						case EntityType.PLAYER:
							entity = new Player(false);
						case EntityType.SWORD:
							entity = new Sword(null);
						case EntityType.FOOD:
							entity = new Food(false);
						case EntityType.ANIMAL:
							entity = new Animal(false);
						default:
							throw("Entity type not found: " + msg.entityUpdate.type);
					}
					entity.id = msg.entityUpdate.id;
					entity.setFromPacket(msg.entityUpdate.x, msg.entityUpdate.y, msg.entityUpdate.rotation);
					world.add(entity);
				}
			}
			
			if (msg.destroyEntity != null) {
				//trace("Removing an entity");
				if (!dead && msg.destroyEntity.id == player.id) {
					player = null;
					sword = null;
					dead = true;
				}
				world.remove(world.entities.get(msg.destroyEntity.id));
			}
			
			if (msg.hungerUpdate != null) {
				if (msg.hungerUpdate.hunger > 6000) {
					text.defaultTextFormat = new TextFormat("_sans", 50, 0xff0000);
					text.text = "HURRAH! STOMACH IS FULL!";
					stage.removeEventListener(Event.ENTER_FRAME, update);
					stage.removeEventListener(KeyboardEvent.KEY_DOWN, keydown);
					stage.removeEventListener(KeyboardEvent.KEY_UP,   keyup);
					try { socket.socket.close(); } catch (e: Dynamic) { };
				} else {
					text.text = "Food: " + (Std.int(msg.hungerUpdate.hunger / 6) / 10);
				}
			}
        }
		
		world.update();
		
		if (dead) return;
		
		x = -player.x + stage.stageWidth / 2;
		y = -player.y + stage.stageHeight / 2;
		
		if (terrain != null) {
			terrain.draw();
		}
		
		if (tick % 3 == 0) {
			//trace("Writing player update");
			socket.writeMsg(player.toPacket());
			socket.writeMsg(sword.toPacket());
		}
	}
	   
	private function addBytes(bytes:Bytes):Void {
        msgQ.addBytes(bytes);
    }
	
	private function onClose():Void { trace("Connection closed. :("); }
	
	function keydown(evt: KeyboardEvent) {
		if (dead) return;
		switch(evt.keyCode) {
			case Keyboard.W, Keyboard.UP: player.up = true;
			case Keyboard.A, Keyboard.LEFT: player.left = true;
			case Keyboard.SPACE: player.down = true;
			case Keyboard.D, Keyboard.RIGHT: player.right = true;
		}
	}
	
	function keyup(evt: KeyboardEvent) {
		if (dead) return;
		switch(evt.keyCode) {
			case Keyboard.W, Keyboard.UP: player.up = false;
			case Keyboard.A, Keyboard.LEFT: player.left = false;
			case Keyboard.SPACE: player.down = false;
			case Keyboard.D, Keyboard.RIGHT: player.right = false;
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
	
	public function reset() {
		stage.removeEventListener(Event.ENTER_FRAME, update);
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, keydown);
		stage.removeEventListener(KeyboardEvent.KEY_UP,   keyup);
		
		stage.removeChild(text);
		
		try { socket.socket.close(); } catch (e: Dynamic) { };
		
		parent.removeChild(Main.m);
		Lib.current.addChild(new Main());
	}
	
	public static function main() {
		// static entry point
		Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		Lib.current.addChild(new Main());
	}
}
