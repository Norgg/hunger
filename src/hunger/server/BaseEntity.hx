package hunger.server;

/**
 * ...
 * @author John Turner
 */
class BaseEntity {
	public var x: Float;
	public var y: Float;
	public var rotation: Float;
	
	//Unused on the server.
	var graphics: Dynamic;
	var scaleX = 0.;
	var stage: Dynamic;
	var main: Dynamic;

	public function new() {
		graphics = cast( { } );
	}
	
	public function add() {
	}
	
	public function remove() {
	}
	
	public function draw() {
	}
	
	public function texture(textureName, x=0., y=0.) {
	}
}