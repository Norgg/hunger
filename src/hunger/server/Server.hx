package hunger.server;

import haxe.ds.IntMap;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import hunger.proto.DestroyEntity;
import hunger.proto.HungerUpdate;
import hunger.proto.Packet;
import hunger.proto.ConnectAck;
import hunger.shared.Animal;
import hunger.shared.Entity;
import hunger.shared.Food;
import hunger.shared.GameWorld;
import hunger.shared.Player;
import hunger.shared.Sword;
import hunger.shared.Terrain;
import nape.callbacks.InteractionType;
import sys.net.Socket;
import haxe.Timer;
import neko.net.ThreadServer;
import neko.Lib;
import neko.vm.Thread;
import protohx.Message;

class Server extends ThreadServer<PlayerSession, Bytes> {
	var world: GameWorld;
	var sessions: IntMap<PlayerSession>;
	static var ticktime: Float = { 1 / 60.0; };
	var tick = 0;
	
	var terrain: Terrain;
	
	var numAnimals = 0;
	var maxAnimals = 20;
    
	public function new() {
        super();
		world = new GameWorld();

		terrain = new Terrain();
		terrain.generateHeights();
		terrain.loadHeights();
		world.add(terrain);

		sessions = new IntMap<PlayerSession>();
		Thread.create(worldUpdate);
    }

// create a Client

    override function clientConnected(s:Socket):PlayerSession {
        var session = new PlayerSession(s);
		sessions.set(session.id, session);
        Lib.println("client: " + session.id + " / " + s.peer());
        return session;
    }

    override function clientDisconnected(session:PlayerSession) {
        Lib.println("client " + Std.string(session.id) + " disconnected");
		session.disconnected = true;
    }

    override function readClientMessage(session:PlayerSession, buf:Bytes, pos:Int, len:Int) {
        return {msg: buf.sub(pos, len), bytes: len};
    }

    override function clientMessage(session:PlayerSession, bytes:Bytes) {
		session.msgQ.addBytes(bytes);
    }
	
	function remove(entity: Entity) {
		world.remove(entity);
		var pkt = new Packet();
		pkt.destroyEntity = new DestroyEntity();
		pkt.destroyEntity.id = entity.id;
		for (session in sessions) {
			session.writeMsg(pkt);
		}
	}
	
	function worldUpdate() {
		while (true) {
			try {
				tick++;

				for (session in sessions) {
					if (session.player != null && session.player.isDead()) {
						remove(session.player);
						remove(session.sword);

						world.add(new Food(true, session.player.x, session.player.y));
						world.add(new Food(true, session.player.x, session.player.y));
						
						session.player = null;
						session.sword = null;
					}
					
					if (session.disconnected) {
						try {session.socket.close();} catch(e: Dynamic) {} //Make sure socket is closed, ignore errors.
						sessions.remove(session.id);
						if (session.player != null) {
							remove(session.player);
							remove(session.sword);
						}
					}
				}
				
				var t1 = Timer.stamp();
				
				//Update game world
				world.update();
				
				//Handle messages
				for (session in sessions) {
					while (session.msgQ.hasMsg()) {
						var msg:Packet = session.msgQ.popMsg();
						if (msg.connect != null) {
							trace(msg.connect.nick + " connected!");
							var newPlayer = new Player();
							newPlayer.nick = msg.connect.nick;
							newPlayer.ownerId = session.id;
							
							var newSword = new Sword(newPlayer);
							
							var ack = new Packet();
							ack.connectAck = new ConnectAck();
							ack.connectAck.playerId = newPlayer.id;
							ack.connectAck.swordId = newSword.id;
							ack.connectAck.terrain = terrain.message();
							session.writeMsg(ack);
							session.player = newPlayer;
							session.sword = newSword;
							
							world.add(newPlayer);
							world.add(newSword);
							
							for (entity in world.entities) entity.changed = true; //Make sure we send all entities when new player joins.
						}
						
						if (msg.entityUpdate != null) {
							if (world.entities.exists(msg.entityUpdate.id)) {
								var entity = world.entities.get(msg.entityUpdate.id);
								if (entity.ownerId == session.id) {
									entity.setFromPacket(msg.entityUpdate.x, msg.entityUpdate.y, msg.entityUpdate.rotation);
								}
							}
						}
					}
				}
				
				//Check and handle player collissions.
				for (session in sessions) {
					if (session.player != null) {
						//trace("Checking collisions");
						for (otherBody in session.player.body.interactingBodies(InteractionType.SENSOR, 1)) {
							//trace("Player touched another thing");
							if (
								(
									Std.is(otherBody.userData.entity, Sword) ||
									Std.is(otherBody.userData.entity, Animal)
								) && 
								otherBody.userData.entity.ownerId != session.id
							) {
								trace("Someone killed someone else!");
								session.player.dead = true;
							}
							
							if (Std.is(otherBody.userData.entity, Food)) {
								remove(otherBody.userData.entity);
								session.player.hunger += 300;
							}
						}
						
						for (otherBody in session.sword.body.interactingBodies(InteractionType.SENSOR, 1)) {
							if (Std.is(otherBody.userData.entity, Animal)) {
								numAnimals--;
								remove(otherBody.userData.entity);
								world.add(new Food(true, otherBody.userData.entity.x, otherBody.userData.entity.y));
								world.add(new Food(true, otherBody.userData.entity.x, otherBody.userData.entity.y));
							}
						}
					}
				}
				
				//Send world updates every 3 ticks (~50ms)
				if (tick % 3 == 0) {
					for (entity in world.entities) {
						for (session in sessions) {
							if (entity.ownerId != session.id && !Std.is(entity, Terrain) && entity.changed) {
								//trace("Sending an entity to client");
								session.writeMsg(entity.toPacket());
							}
						}
					}
					for (session in sessions) {
						if (session.player != null) {
							var pkt = new Packet();
							pkt.hungerUpdate = new HungerUpdate();
							pkt.hungerUpdate.hunger = session.player.hunger;
							session.writeMsg(pkt);
						}
					}
				}
				
				//Spawn animals
				if (numAnimals < maxAnimals) {
					numAnimals++;
					var animal = new Animal(true, (Math.random() - 0.5) * 2000, 200);
					world.add(animal);
				}
				
				var t2 = Timer.stamp();
				var delta = t2 - t1;
				if (delta < ticktime) {
					Sys.sleep(ticktime - delta);
				}
			} catch (e: Dynamic) {
				trace(e);
				trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			}
		}
	}

    public static function main() {
        var server = new Server();
        trace("Running...");
        server.run("0.0.0.0", 42424);
    }
}
