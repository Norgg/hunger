package hunger.shared;
import hunger.proto.EntityType;
import hunger.proto.Packet;
import hunger.proto.EntityUpdate;
import nape.phys.Body;
import nape.phys.BodyType;
import haxe.Timer;

#if flash
import hunger.client.BaseEntity;
#else
import hunger.server.BaseEntity;
#end

class Entity extends BaseEntity {
	public var body: Body;
	public var id: Int;
	public var ownerId: Int;
	public static var nextId: Int = 1;
	var local = false;
	
	var lastX = 0.;
	var lastY = 0.;
	var lastR = 0.;
	
	var lastT = 0.;
	var nextT = 0.;
	
	public function new(local = false, isStatic = false, ?id, ?ownerId) {
		super();
		this.local = local;
		
		if (id == null) this.id = nextId++;
		else            this.id = id;

		if (ownerId == null) this.ownerId = id;
		else this.ownerId = ownerId;
		
		var bodyType = BodyType.STATIC;
		if (!isStatic) {
			if (local) {
				bodyType = BodyType.DYNAMIC;
			} else {
				bodyType = BodyType.KINEMATIC;
			}
		}
		body = new Body(bodyType);
	}
	
	public function update() {
		//trace("Updating entity: " + id + ": " + x + ", " + y);
		if (local) {
			x = body.position.x;
			y = body.position.y;
			rotation = body.rotation * 180 / Math.PI;
		} else {
			lerp();
		}
	}
	
	public function setFromPacket(x, y, rotation) {
		var t = Timer.stamp();
		nextT = t + (t - lastT);
		lastT = t;
		
		body.position.x = x;
		body.position.y = y;
		body.rotation = rotation;
	}
	
	public function toPacket(): Packet {
		var packet: Packet = new Packet();
		packet.entityUpdate = new EntityUpdate();
		packet.entityUpdate.id = id;
		packet.entityUpdate.x = body.position.x;
		packet.entityUpdate.y = body.position.y;
		packet.entityUpdate.rotation = body.rotation;
		packet.entityUpdate.type = getType();
		return packet;
	}
	
	public function getType() {
		return EntityType.UNKNOWN;
	}
	
	public function lerp() {
		var t = Timer.stamp();
		var nextX = body.position.x;
		var nextY = body.position.y;
		var nextR = body.rotation;

		var lerpBy = (t - nextT) / (nextT - lastT);
		if (lerpBy >= 1) lerpBy = 1;
		if (nextT == lastT || lerpBy < 0) lerpBy = 0;
		
		x = Std.int((lerpBy * nextX) + ((1 - lerpBy) * lastX));
		y = Std.int((lerpBy * nextY) + ((1 - lerpBy) * lastY));
		rotation = 180 * (lerpBy * nextR) + ((1 - lerpBy) * lastR)/ Math.PI;
	}
}