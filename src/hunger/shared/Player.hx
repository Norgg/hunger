package hunger.shared;
import nape.shape.Polygon;

class Player extends Entity{
	public var nick: String;
	
	public function new(local = false, x = 0., y = 0.) {
		super(local);
		body.shapes.add(new Polygon(Polygon.box(8, 16)));
		this.x = body.position.x = x;
		this.y = body.position.y = y;
	}
	
	override public function draw() {
		graphics.beginFill(0, 1);
		graphics.drawRect( -4, -8, 8, 16);
	}
}