package;

import flash.display.Shape;
import flash.Lib;
import flash.events.MouseEvent;
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.text.TextField;
import flash.system.ApplicationDomain;
import haxe.Log;
import haxe.Timer;

import mem.Ptr;
import mem.Malloc;

class TestInFlash{

	static inline var MC_H:Int = 8;
	static inline var MC_LEN:Int = 90;
	static var stageWidth = Lib.current.stage.stageWidth;
	public var mc:Shape;

	function new(){
		mc = new Shape();
		mc.y = (Lib.current.stage.stageHeight - MC_LEN * MC_H);
		Lib.current.addChild(mc);
		//Lib.current.stage.addEventListener(MouseEvent.CLICK, run);
	}

	function randAlloc():Ptr return Ram.malloc(Std.int(512 * Math.random() + 64));

	function run(?e:MouseEvent){
		mc.graphics.clear();
		Log.clear();

		var ar = new Array<Int>();
		var half = MC_LEN >> 1;

		for (i in 0...MC_LEN) ar.push(randAlloc());

		shuffle(ar, 2);

		for (i in 0...half) {
			Ram.free(cast ar[i]);
			draw(MC_H * i);
		}
		trace("**in process: ** - frag: " + Malloc.frag_count +", used: " +  Malloc.getUsed() + " bytes, --- block.length: " + Malloc.length  + " Malloc.check: " + Malloc.check() + "\n");

		ar.splice(0, half);

		for (i in 0...half) ar.push(randAlloc());

		shuffle(ar, 2);

		for (i in 0...ar.length) {
			Ram.free(cast ar[i]);
			draw(MC_H * i);
			if (i % 6 == 0)
				trace("index: "+ i +" **in process: ** - frag: " + Malloc.frag_count +", used: " +  Malloc.getUsed() + " bytes, --- block.length: " + Malloc.length  + " Malloc.check: " + Malloc.check() + "\n");

		}
		trace("**end** frag: " + Malloc.frag_count +", used: " +  Malloc.getUsed() + " bytes, --- block.length: " + Malloc.length + " Malloc.check: " + Malloc.check());
		if (Malloc.frag_count > 0) throw "xxxxxxxx";
	}


	@:access(mem.Malloc) function draw(h:Int = 0) {
		var w = stageWidth / MC_LEN;
		var i = 0;
		mc.graphics.lineStyle(1, 0);
		for (blk in mem.Malloc.iterator()){
			var x = i * w;
			mc.graphics.beginFill(blk.is_free ? 0xbd2c00 : 0x6cc644) ;
			mc.graphics.drawRect(x, h, w, MC_H);
			i++;
			if(0 != blk.next && ((blk:Int) + blk.size) != blk.next)
				throw "xxxxxxxxxxx";
		}
		var len = i;
		mc.graphics.lineStyle(1, 0);
		mc.graphics.beginFill(0xff9933);
		for(i in 0...(MC_LEN - len)){
			mc.graphics.drawRect( (MC_LEN - i - 1) * w  , h, w, MC_H);
		}
		mc.graphics.endFill();
	}

	function shuffle<T>(a:Array<T>, count = 1) {
		var len = a.length;
		var r:Int;
		var t:T;
		while (count > 0) {
			for (i in 0...len) {
				r = Std.int(Math.random() * len);
				t = a[r];
				a[r] = a[i];
				a[i] = t;
			}
			count -= 1;
		}
	}

	public static function main(){
		var stage = Lib.current.stage;
		stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		stage.align = flash.display.StageAlign.TOP_LEFT;
		stage.color = 0;
		Log.setColor(0xffffff);
		Ram.select(Ram.create());
		var f = new TestInFlash();
		var t = new Timer(2000);
		t.run = f.run.bind();
		t.run();
	}
}