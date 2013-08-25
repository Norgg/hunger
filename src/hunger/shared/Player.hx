package hunger.shared;
import hunger.proto.EntityType;
import nape.callbacks.InteractionType;
import nape.dynamics.InteractionGroup;
import nape.geom.Vec2;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.shape.Shape;

class Player extends Entity {
	var runtick = 0;
	
	public var nick: String;
	public var group: InteractionGroup;
	
	var jumpTimer = 0;
	
	var moveSpeed = 150;
	var moveForce = 100;
	var airMoveForce = 1;
	var jumpForce = 30;
	
	public function new(local = false, x = 0., y = 0.) {
		super(local);
		var shapes: Array<Shape> = [
			new Polygon(Polygon.rect(-3, -9, 6, 15)),
			new Circle(3, Vec2.weak(0, 6))
		];
			
		for (shape in shapes) {
			shape.material.dynamicFriction = 0;
			shape.material.staticFriction = 0;
			body.shapes.add(shape);
		}
		body.allowRotation = false;
		body.group = group = new InteractionGroup(true);
		this.x = body.position.x = x;
		this.y = body.position.y = y;
	}
	
	override public function draw() {
		graphics.clear();
		
		var runFrame = Std.int(runtick / 10) % 2;
		var runOffset = -3 - runFrame * 6;
		
		if (right) {
			scaleX = 1;
			texture("img/player-running.png", runOffset, -9);
		} else if (left) {
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
		
		if (jumpTimer > 0) jumpTimer--;

		if (body.interactingBodies(InteractionType.COLLISION).length > 0) {
			if (right) body.applyImpulse(Vec2.weak(moveForce,   0));
			if (left)  body.applyImpulse(Vec2.weak(-moveForce,  0));
			if (up && jumpTimer <= 0) {
				//trace("jump!");
				body.applyImpulse(Vec2.weak(0, -jumpForce));
				jumpTimer = 30;
			}
			if (!left && !right && !up) {
				body.velocity = body.velocity.mul(0.5);
			}
		} else {
			if (right) body.applyImpulse(Vec2.weak(airMoveForce,   0));
			if (left)  body.applyImpulse(Vec2.weak(-airMoveForce,  0));
		}
		if (body.velocity.x > moveSpeed) body.velocity.x = moveSpeed;
		if (body.velocity.x < -moveSpeed) body.velocity.x = -moveSpeed;
		
		#if flash
		draw();
		#end
	}
}