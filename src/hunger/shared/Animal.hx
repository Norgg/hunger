package hunger.shared;

import hunger.proto.EntityType;
import nape.shape.Shape;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.geom.Vec2;

class Animal extends Entity {
	
	var runtick = 0;

	public function new(local = false, x = 0., y = 0.) {
		super(local);
		var shapes: Array<Shape> = [
			new Polygon(Polygon.rect(-3.5, 0, 7, 3.5)),
			new Circle(7, Vec2.weak(0, 0))
		];
			
		for (shape in shapes) {
			shape.material.dynamicFriction = 0;
			shape.material.staticFriction = 0;
			body.shapes.add(shape);
		}
		body.allowRotation = false;
		//body.group = group = new InteractionGroup(true);
		this.x = body.position.x = x;
		this.y = body.position.y = y;
	}
	
	override public function draw() {
		graphics.clear();
		
		var runFrame = Std.int(runtick / 10) % 2;
		var runOffset = -3.5 - runFrame * 7;
		
		if (right) {
			scaleX = 1;
			texture("img/animal-running.png", runOffset, -3.5);
		} else if (left) {
			scaleX = -1;
			texture("img/animal-running.png", runOffset, -3.5);
		} else {
			texture("img/animal.png", -3.5, -3.5);
		}
		graphics.drawRect( -3.5, -3.5, 7, 7);
	}
	
	override public function getType() {
		return EntityType.ANIMAL;
	}
	
	override public function update() {
		super.update();
		
		runtick++;
		
		if (local) {
			//TODO: AI here.
		}
	}
}