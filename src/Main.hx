package;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;
import haxe.unit.TestRunner;

/**
* ...
* @author 匿名
*/

class Main {
	
	static function main() {
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		// entry point
		
		var runner = new TestRunner();
		runner.add(new test.Test());
		runner.run();
	}
	
}