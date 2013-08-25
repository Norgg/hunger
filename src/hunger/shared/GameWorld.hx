package hunger.shared;
import haxe.ds.IntMap;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Polygon;
import nape.space.Space;

/**
 * ...
 * @author John Turner
 */
class GameWorld {
	public var space: Space;
	public var entities: IntMap<Entity>;
	public var terrain: Terrain;
	
	public function new() {
		entities = new IntMap<Entity>();
		space = new Space(new Vec2(0, 500));
	}
	
	public function update() {
		space.step(1 / 60.);
		for (entity in entities) {
			entity.update();
		}
	}
	
	public function add(entity: Entity) {
		entities.set(entity.id, entity);
		entity.body.space = space;
		entity.add();
	}
	
	public function remove(entity: Entity) {
		if (entity == null) return;
		entities.remove(entity.id);
		for (joint in entity.body.constraints) {
			joint.space = null;
		}
		entity.body.space = null;
		entity.remove();
	}
}