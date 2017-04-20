package;

import mem.Ptr;
import haxe.unit.TestRunner;

enum NsfVer{
	Zero;
	One;
	Two;
	Three;
}

enum NsfSys{
	IsPAL;
	Dual;
}

/**
http://vgmrips.net/wiki/NSF_File_Format
*/
class Nsfhd implements mem.IStruct{
	@idx(5) var tag:String;
	@idx var ver:NsfVer;						// test Enum
	@idx var track_count:Int;
	@idx var track_intro_number:Int;
	@idx(2) var data_address:Int;
	@idx(2) var init_address:Int;
	@idx(2) var song_address:Int;
	@idx(32) var title:String;
	@idx(32) var author:String;
	@idx(32) var copyright:String;
	@idx(2) var ntsc:Int;
	@idx(8) var bank:AU8;
	@idx(2) var ntsc_loop_speed:Int;
	@idx(1) var sys:Int;
	@idx var spec:Int;
	@idx(4) var exra:AU8;
	public var addr(default, null):Ptr;
	inline public function new(len){
		addr = Ram.malloc(len, false);
	}
}

class EndianDetect implements mem.IStruct{
	@idx var littleEndian:Bool;		// 00
	@idx(2, -1) var i:Int;			// 00~01
	@idx(-1) var bigEndian:Bool;	// 01

	public inline function new(){
		addr = Ram.malloc(CAPACITY);
		i = 1;
	}
}

#if !macro
@:build(mem.Struct.make())
#end
abstract AbsEndianDetect(Ptr) from Ptr{
	@idx var littleEndian:Bool;		// 00
	@idx(2, -1) var i:Int;			// 00~01
	@idx(-1) var bigEndian:Bool;	// 01

	public inline function new(){
		this = Ram.malloc(CAPACITY);
		i = 1;
	}
}

class TestStruct extends haxe.unit.TestCase{

	function testNsfhd(){
		print("\n");
		var file = haxe.Resource.getBytes("supermario");

		var mario = new Nsfhd(file.length);
		Ram.writeBytes(mario.addr, file.length, #if flash file.getData() #else file #end);
		print(mario.__toOut() + "\n");

		var fake = new Nsfhd(Nsfhd.CAPACITY);
		// you can do: Ram.memcpy(fake.addr, mario.addr,  Nsfhd.CAPACITY);
		fake.tag = mario.tag;
		fake.ver = mario.ver;
		fake.track_count = mario.track_count;
		fake.track_intro_number = mario.track_intro_number;
		fake.init_address = mario.init_address;
		fake.data_address = mario.data_address;
		fake.song_address = mario.song_address;
		fake.title = mario.title;
		fake.author = mario.author;
		fake.copyright = mario.copyright;
		fake.ntsc = mario.ntsc;
		for (i in 0...Nsfhd.__BANK_LEN)
			fake.bank[i] = mario.bank[i];
		fake.ntsc_loop_speed = mario.ntsc_loop_speed;
		fake.sys = mario.sys;
		for (i in 0...Nsfhd.__EXRA_LEN)
			fake.exra[i] = mario.exra[i];

		assertTrue(mario.ntsc == 0x411A && Nsfhd.CAPACITY == 128 && Ram.memcmp(fake.addr, mario.addr, Nsfhd.CAPACITY) == 0);

		var endian = new EndianDetect();
		print(endian.__toOut() + "\n");
		assertTrue(endian.littleEndian == true && endian.bigEndian == false);

		var abs_endian:AbsEndianDetect = @:privateAccess endian.addr; // force cast
		abs_endian.i = 101;
		trace(endian.i);
		mario.free();
		fake.free();
		endian.free();
	}

	public static function main(){
	#if flash
		var stage = flash.Lib.current.stage;
		stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		stage.align = flash.display.StageAlign.TOP_LEFT;
	#end
		Ram.select(Ram.create());

		var runner = new TestRunner();
		runner.add(new TestStruct());
		runner.run();
	#if flash
		stage.color = 0;
		@:privateAccess{TestRunner.tf.textColor = 0xffffff; }
	#end
	}
}
