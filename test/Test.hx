package test;

import flash.display.Shape;
import flash.Lib;
import flash.utils.ByteArray;
import haxe.unit.TestCase;
import haxe.Utf8;
import mem.UnsafeIntMap;
import mem.MemoryChunk;
import haxe.unit.TestRunner;
import flash.text.TextField;

class Test extends TestCase{
	static inline var MC_H:Int = 16;
	static var stageWidth = Lib.current.stage.stageWidth;
	
	public var mc:Shape;
	
	@:access(haxe.unit.TestRunner)
	public function new(){
		mc = new Shape();
		Lib.current.addChild(mc);
		mc.y = (Lib.current.stage.stageHeight - MC_H) >> 1;
		
		TestRunner.tf = new TextField();
		TestRunner.tf.textColor = 0xffffff;	
		TestRunner.tf.selectable = false;
		TestRunner.tf.width = flash.Lib.current.stage.stageWidth;
		TestRunner.tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		flash.Lib.current.addChild(TestRunner.tf);
		super();
	}
	

	
	@:access(mem.MemoryChunk)
	function testMergeFlagment() {
		
		var ar = new Array<Int>();
		var fragcount = MemoryChunk.fragCount;
		var len = 12;
		for(i in 0...len){
			ar[i] = Ram.malloc(1024);
		}

		// red => free but fragment, green => In Using space, yellow => free recycling space
		
		shuffle(ar, 2);
		print("testMergeFlagment:\n");
		for (i in 0...ar.length) {
			Ram.free(ar[i]);
			print("free order: " + Std.int(ar[i]/1024) + "\tptr: "+ ar[i] + "\ttotal frag:" + (MemoryChunk.fragCount - fragcount) +"\n");
			drawRam(18 * i, len);
		}
		
		assertTrue(fragcount == MemoryChunk.fragCount);
	}
	
	
	function testMemcpy() {
		// 由于目前还未实现 mallocFromString, 所以用 ByteArray
		var ba:ByteArray = new ByteArray();
		ba.writeMultiByte("0123456789abcdefABCDEFGHIJKLMNOPQRSTUVWXYZ中文012345679字符", "utf-8");
		ba.position = 0;
		var ptr = Ram.malloc(1024);
		
		print("testMemcpy:\n");
		var src = ptr;
		var dst = ptr;		
		var len = ba.length;
		Ram.writeBytes(src, len, ba);
		
		cp(dst, src, len, "dst == src:\t");
		
		dst = ptr + len * 10;
		cp(dst, src, len, "dst > src:\t");
		
		src = dst;
		dst = ptr + len;
		cp(dst, src, len, "dst < src:\t");
			
		Ram.free(ptr);
		assertTrue(true);
	}

	
	
	
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	
	

	
	function cp(dst:Int, src:Int, len:Int, desc:String){
		var out:ByteArray = new ByteArray();
		Ram.memcpy(dst, src, len);
		Ram.readBytes(dst, len, out);
		out.position = 0;
		print(desc + out.readMultiByte(len,"utf-8") + "\n");
	}
	
	function shuffle<T>(a:Array<T>, count = 1) {
		var len = a.length;
		var r:Int;
		var t:T;
		while (count-- > 0) {
			for (i in 0...len) {
				r = Std.int(Math.random() * len);
				t = a[r];
				a[r] = a[i];
				a[i] = t;
			}
		}		
	}
	
	@:access(mem.MemoryChunk)
	function drawRam(h:Int = 0, width:Int = 10) {
		var list = MemoryChunk.allPtr();	// sort by ptr
		var lines = new Array<Float>();
		var w = stageWidth / width;	
		mc.graphics.lineStyle(1, 0);
		
	
		for(i in 0...list.length){
			var ck = MemoryChunk.pool.get(list[i]);		
			var x = i * w;
			lines.push(x);
			mc.graphics.beginFill(ck.isFree ? 0xbd2c00 : 0x6cc644) ;
			mc.graphics.drawRect(x, h, w, MC_H);
		}
		
		mc.graphics.beginFill(0xff9933);	
		for(i in 0...(width - list.length)){
			mc.graphics.drawRect( (width - i - 1) * w  , h, w, MC_H);
		}
		
		lines.shift(); // 第一条线不要		
		for(p in lines){
			mc.graphics.moveTo(p, h);
			mc.graphics.lineTo(p, h + MC_H);
		}
		mc.graphics.endFill();
	}
	
}