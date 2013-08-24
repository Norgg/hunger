package hunger.server;

import haxe.ds.IntMap;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import hunger.proto.Packet;
import hunger.shared.GameWorld;
import sys.net.Socket;
import haxe.Timer;
import neko.net.ThreadServer;
import neko.Lib;
import neko.vm.Thread;
import protohx.Message;

class Server extends ThreadServer<PlayerSession, Bytes> {
	//var world: GameWorld;
	var sessions: IntMap<PlayerSession>;
	var ticktime = 0.15;
    
	public function new() {
        super();
		//world = new GameWorld();
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
    }

    override function readClientMessage(session:PlayerSession, buf:Bytes, pos:Int, len:Int) {
        return {msg: buf.sub(pos, len), bytes: len};
    }

    override function clientMessage(session:PlayerSession, bytes:Bytes) {
		session.msgQ.addBytes(bytes);
    }
	
	function worldUpdate() {
		while (true) {
			var t1 = Timer.stamp();
			
			//Update game world
			//world.update();
			
			//Handle messages
			for (session in sessions) {
				while (session.msgQ.hasMsg()) {
					var msg:Packet = session.msgQ.popMsg();
					if (msg.connect != null) {
						trace(msg.connect.nick + " connected!");
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
