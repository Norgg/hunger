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
	
	public function new() {
		entities = new IntMap<Entity>();
		space = new Space(new Vec2(0, 100));
		
		var testgnd = new Body(BodyType.STATIC);
		testgnd.shapes.add(new Polygon(Polygon.rect( -100, 300, 1000, 10)));
		testgnd.space = space;
	}
	
	public function update() {
		space.step(1 / 60);
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
		entities.remove(entity.id);
		entity.body.space = null;
		entity.remove();
	}
}