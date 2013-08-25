package hunger.shared;
import hunger.proto.EntityType;
import nape.constraint.AngleJoint;
import nape.constraint.PivotJoint;
import nape.geom.Vec2;
import nape.shape.Polygon;

/**
 * ...
 * @author John Turner
 */
class Sword extends Entity {
	var joint: PivotJoint;
	
	public function new(player: Player) {
		var isLocal = false;
		var ownerId: Null<Int> = null;
		if (player != null) {
			isLocal = player.local;
			ownerId = player.ownerId;
		}
		
		super(isLocal, false, null, ownerId);
		var shape = new Polygon(Polygon.box(3, 22));
		shape.material.dynamicFriction = 0;
		shape.material.staticFriction = 0;
		#if !flash
		shape.sensorEnabled = true;
		#end
		body.shapes.add(shape);
		//this.x = body.position.x = player.x + 9.5;
		//this.y = body.position.y = player.y + 5;
		
		if (player != null && player.local) {
			body.group = player.group;
			joint = new PivotJoint(body, player.body, Vec2.weak(0, 11), Vec2.weak(0, -6));
		}
		
		this.body.rotation = Math.PI / 2;
		
		player.sword = this;
	}
	
	override public function draw() {
		graphics.clear();
		
		texture("img/sword.png", -3.5, -11);
		graphics.drawRect( -3.5, -9.5, 7, 22);
	}
	
	override public function add() {
		super.add();
		
		if (joint != null) joint.space = body.space;
	}
	
	override public function getType() {
		return EntityType.SWORD;
	}
}