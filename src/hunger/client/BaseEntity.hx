package hunger.client;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Matrix;
import openfl.Assets;

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
	
	public function texture(textureName, xOff = 0, yOff = 0) {
		graphics.beginBitmapFill(Assets.getBitmapData(textureName), new Matrix(1, 0, 0, 1, xOff, yOff), false, false);
	}
}