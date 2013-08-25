package hunger.shared;
import hunger.proto.EntityType;
import nape.geom.Vec2;
import nape.shape.Polygon;

/**
 * ...
 * @author John Turner
 */
class Food extends Entity {
	public var ttl = 120;
	
	public function new(local = false, x = 0., y = 0.) {
		super(local, false);
		var shape = new Polygon(Polygon.box(5, 3));
		body.shapes.add(shape);
		this.x = body.position.x = x;
		this.y = body.position.y = y;

		if (local) {
			body.applyImpulse(Vec2.weak(
					(Math.random() - 0.5) * 5,
					(Math.random() - 0.5) * 5
			));
		}
	}
	
	override public function draw() {
		texture("img/food.png", -2.5, -1.5);
		graphics.drawRect( -2.5, -1.5, 5, 3);
	}
	
	override public function getType() {
		return EntityType.FOOD;
	}
	
	override public function update() {
		super.update();
		if (ttl > 0) ttl--;
	}
}