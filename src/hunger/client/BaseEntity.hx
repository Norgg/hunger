package hunger.client;
import flash.display.Sprite;

/**
 * ...
 * @author John Turner
 */
class BaseEntity extends Sprite {

	public function new() {
		super();
	}
	
	public function add() {
		Main.m.addChild(this);
		draw();
	}
	
	public function remove() {
		Main.m.removeChild(this);
	}
	
	public function draw() {
	}
}