package hunger.shared;
import hunger.proto.EntityType;
import nape.geom.Vec2;
import nape.shape.Polygon;

class Player extends Entity {
	var runtick = 0;
	
	public var nick: String;
	
	public var left = false;
	public var right = false;
	public var up = false;
	public var down = false;
	
	public function new(local = false, x = 0., y = 0.) {
		super(local);
		body.shapes.add(new Polygon(Polygon.box(8, 16)));
		body.allowRotation = false;
		this.x = body.position.x = x;
		this.y = body.position.y = y;
	}
	
	override public function draw() {
		graphics.clear();
		
		var runFrame = Std.int(runtick / 10) % 2;
		var runOffset = -3 - runFrame * 6;
		
		if (body.velocity.x > 1) {
			scaleX = 1;
			texture("img/player-running.png", runOffset, -9);
		} else if (body.velocity.x < -1) {
			scaleX = -1;
			texture("img/player-running.png", runOffset, -9);
		} else {
			texture("img/player.png", -3, -9);
		}
		graphics.drawRect( -3, -9, 6, 18);
	}

	override public function getType() {
		return EntityType.PLAYER;
	}
	
	override public function update() {
		super.update();
		
		runtick++;

		if (right) body.applyImpulse(Vec2.weak(3, 0));
		if (left)  body.applyImpulse(Vec2.weak(-3, 0));
		
		draw();
	}
}