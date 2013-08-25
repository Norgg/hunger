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

		var shape = new Polygon(Polygon.box(3, 26));
		
		#if !flash
		shape = new Polygon(Polygon.box(5, 28));
		shape.sensorEnabled = true;
		#end
		
		shape.material.dynamicFriction = 0;
		shape.material.staticFriction = 0;

		body.shapes.add(shape);
		//this.x = body.position.x = player.x + 9.5;
		//this.y = body.position.y = player.y + 5;
		
		if (player != null && player.local) {
			body.group = player.group;
			joint = new PivotJoint(body, player.body, Vec2.weak(0, 13), Vec2.weak(0, -6));
			player.sword = this;
		}
		
		this.body.rotation = Math.PI / 2;
		
	}
	
	override public function draw() {
		graphics.clear();
		
		texture("img/sword.png", -3.5, -13);
		graphics.drawRect( -3.5, -13, 7, 26);
	}
	
	override public function add() {
		super.add();
		
		if (joint != null) joint.space = body.space;
	}
	
	override public function getType() {
		return EntityType.SWORD;
	}
}