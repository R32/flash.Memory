package test;

import haxe.unit.TestCase;
import mem.UnsafeIntMap;

/**
* ...
* @author 匿名
*/
class Test extends TestCase{

	function testMemcpy(){
		print("\nhello world");
		assertTrue(true);
	}
	
	function testUnsafeIntMap(){
		var map = new UnsafeIntMap<String>();
		for(i in 0...10){
			map.set(i, "---" + i + "---");
		}
		print("\n"+map.toString());
		assertTrue(true);
	}
	
}