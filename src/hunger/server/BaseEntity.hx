package hunger.server;

/**
 * ...
 * @author John Turner
 */
class BaseEntity {
	var x: Float;
	var y: Float;
	var rotation: Float;
	
	//Unused on the server.
	var graphics: Dynamic;
	var scaleX = 0.;

	public function new() {
		graphics = cast( { } );
	}
	
	public function add() {
	}
	
	public function remove() {
	}
	
	public function draw() {
	}
	
	public function texture(textureName, x, y) {
	}
}