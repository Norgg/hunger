package hunger.shared;
import nape.phys.Body;


#if flash
import hunger.client.BaseEntity;
#else
import hunger.server.BaseEntity;
#end

class Entity extends BaseEntity {
	public var body: Body;
	public var id: Int;
	
	public function new() {
		super();
	}
	
	public function update() {
		x = body.position.x;
		y = body.position.y;
		rotation = body.rotation * 180/Math.PI;
	}
}