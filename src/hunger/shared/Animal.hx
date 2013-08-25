package hunger.shared;

import hunger.proto.EntityType;
import nape.callbacks.InteractionType;
import nape.shape.Shape;
import nape.shape.Polygon;
import nape.shape.Circle;
import nape.geom.Vec2;

class Animal extends Entity {
	
	var runtick = 0;
	var moveSpeed = 50;
	var moveForce = 50;

	public function new(local = false, x = 0., y = 0.) {
		super(local);
		var shapes: Array<Shape> = [
			new Polygon(Polygon.rect(-4, 0, 8, 4)),
			new Circle(4, Vec2.weak(0, 0))
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
		var runOffset = -4 - runFrame * 8;
		
		if (right) {
			scaleX = -1;
			texture("img/animal-running.png", runOffset, -4, false);
		} else if (left) {
			scaleX = 1;
			texture("img/animal-running.png", runOffset, -4, false);
		} else {
			texture("img/animal.png", -4, -4, false);
		}
		graphics.drawRect( -4, -4, 8, 8);
	}
	
	override public function getType() {
		return EntityType.ANIMAL;
	}
	
	override public function update() {
		super.update();
		
		runtick++;
		
		if (local) {
			if (Math.random() < 0.01) right = true;
			if (Math.random() < 0.01) right = false;
			if (Math.random() < 0.01) left = true;
			if (Math.random() < 0.01) left = false;
			
			if (body.interactingBodies(InteractionType.COLLISION, 1).length > 0) {
				if (right) body.applyImpulse(Vec2.weak(moveForce,   0));
				if (left)  body.applyImpulse(Vec2.weak( -moveForce,  0));
			}
			if (body.velocity.x > moveSpeed) body.velocity.x = moveSpeed;
			if (body.velocity.x < -moveSpeed) body.velocity.x = -moveSpeed;
		}
		
		#if flash
		draw();
		#end
	}
}