package hunger.shared;
import hunger.proto.Packet;
import hunger.proto.TerrainUpdate;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;

/**
 * ...
 * @author John Turner
 */
class Terrain extends Entity {
	public var heights: Array<Float>;
	var points = 2000;
	var resolution = 20;
	
	public function new() {
		super(true, true);
		body = new Body(BodyType.STATIC);
	}
	
	public function generateHeights() {
		heights = new Array<Float>();

		var height = 400.;
		var lastHeight = 400.;

		heights.push(height);
		for (i in 0...points) {
			var diff = (Math.random() - 0.5) * 20;
			var newHeight = (height + diff + lastHeight) / 2;
			if (height > 500) height = 500;
			heights.push(newHeight);
						
			lastHeight = height;
			height = newHeight;
		}
	}
	
	public function loadHeights() {
		//trace("Loading terrain");
		var lastHeight = 400.;
		var i = 0;
		for (height in heights) {
			var xOff = points * resolution / 2.;
			var x1 = i * resolution - xOff;
			var x2 = (i + 1) * resolution - xOff;
			var shape = new Polygon([
				Vec2.weak(x1, lastHeight),
				Vec2.weak(x2, height),
				Vec2.weak(x2, 1000),
				Vec2.weak(x1, 1000)
			]);
			
			shape.material.dynamicFriction = 0;
			shape.material.staticFriction = 0;
			
			body.shapes.add(shape);
			lastHeight = height;
			i++;
		}
	}
	
	override public function draw() {
		graphics.clear();
		for (shape in body.shapes) {
			var first = true;
			
			var verts = shape.castPolygon.worldVerts;
			if (verts.at(1).x < -main.x-resolution || verts.at(0).x > -main.x + stage.stageWidth + resolution) continue;

			graphics.beginFill(0, 1);
			for (vert in verts) {
				if (first) {
					first = false;
					graphics.moveTo(vert.x, vert.y);
				} else {
					graphics.lineTo(vert.x, vert.y);
				}
			}
			graphics.endFill();
		}
	}
	
	override public function toPacket():Packet {
		var packet = new Packet();
		packet.terrainUpdate = message();
		return packet;
	}
	
	public function message() {
		var msg = new TerrainUpdate();
		msg.id = this.id;
		msg.heights = this.heights;
		return msg;
	}
	
	public function fromUpdate(terrainUpdate: TerrainUpdate) {
		heights = terrainUpdate.heights;
		id = terrainUpdate.id;
		loadHeights();
	}
}