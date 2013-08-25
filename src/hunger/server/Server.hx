package hunger.server;

import haxe.ds.IntMap;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import hunger.proto.Packet;
import hunger.proto.ConnectAck;
import hunger.shared.GameWorld;
import hunger.shared.Player;
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
    
	public function new() {
        super();
		world = new GameWorld();
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
	
	function worldUpdate() {
		while (true) {
			tick++;

			for (session in sessions) {
				if (session.disconnected) {
					sessions.remove(session.id);
					world.remove(session.player);
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
						var ack = new Packet();
						ack.connectAck = new ConnectAck();
						ack.connectAck.id = newPlayer.id;
						session.writeMsg(ack);
						session.player = newPlayer;
						
						world.add(newPlayer);
					}
					
					if (msg.entityUpdate != null) {
						if (world.entities.exists(msg.entityUpdate.id)) {
							var entity = world.entities.get(msg.entityUpdate.id);
							entity.setFromPacket(msg.entityUpdate.x, msg.entityUpdate.y, msg.entityUpdate.rotation);
						}
					}
				}
			}
			
			//Send world updates every 3 ticks (~50ms)
			if (tick % 3 == 0) {
				for (entity in world.entities) {
					for (session in sessions) {
						if (entity.ownerId != session.id) {
							trace("Sending an entity to client");
							session.writeMsg(entity.toPacket());
						}
					}
				}
			}
			
			var t2 = Timer.stamp();
			var delta = t2 - t1;
			if (delta < ticktime) {
				Sys.sleep(ticktime - delta);
			}
		}
	}

    public static function main() {
        var server = new Server();
        trace("Running...");
        server.run("0.0.0.0", 4242);
    }
}
