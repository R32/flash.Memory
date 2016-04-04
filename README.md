flash.Memory
------

**WIP**

* 混淆数据类,及数据结构, 类实例及其成员变量在编译后只表现为内存地址和偏移量

Example:

```haxe
import mem.Ptr;
// just simple implement,  see: tools/mem/Struct.hx,
class EndianDetect implements mem.Struct{
	@idx var littleEndian:Bool;    // 00
	@idx(2, -1) var i:Int;         // 00~01
	@idx(-1) var bigEndian:Bool;   // 01
}

class Example{
	public static function main(){
		Ram.select(Ram.create());  // init
		var endian = new EndianDetect();
		endian.i = 1;
		trace(endian.__toOut());
		trace(endian.littleEndian == true && endian.bigEndian == false);
	}
}
```

**compile**: `haxe -cp tools -main Example -swf exa.swf`,

> it can also: `haxe -cp tools -main Example --interp`

run output:
```
Example.hx:17: --- EndianDetect.CAPACITY: 2, addr: 32
offset: 0x00 - 0x01, bytes: 1, littleEndian: true
offset: 0x00 - 0x02, bytes: 2, i: 1
offset: 0x01 - 0x02, bytes: 1, bigEndian: false

Example.hx:18: true
```

#### example: Directly read the file header:

```haxe
import mem.Ptr;

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

// http://vgmrips.net/wiki/NSF_File_Format
class Nsfhd implements mem.Struct{
	@idx(5) var tag:String;
	@idx var ver:NsfVer;
	@idx var track_count:Int;
	@idx var track_intro_number:Int;
	@idx(2) var data_address:Int;
	@idx(2) var init_address:Int;
	@idx(2) var song_address:Int;
	@idx(32) var title:String;
	@idx(32) var author:String;
	@idx(32) var copyright:String;
	@idx(2) var ntsc:Int;
	@idx(8) var bank:Array<Int>;
	@idx(2) var ntsc_loop_speed:Int;
	@idx var sys:haxe.EnumFlags<NsfSys>;
	@idx var spec:Int;
	@idx(4) var exra:Array<Int>;

	public var addr(default, null):Ptr;    // define "addr" if you want to access the private field
	public inline function new(len:Int){   // custom constructor
		addr = mem.Malloc.make(Nsfhd.CAPACITY + len, false);
	}
}

class Example{
	public static function main(){
		Ram.select(Ram.create());  // init
		var file = haxe.Resource.getBytes("supermario");
		var mario = new Nsfhd(file.length);
	#if flash
		Ram.writeBytes(mario.addr, file.length, file.getData());
	#else
		Ram.writeBytes(mario.addr, file.length, file);
	#end
		trace(mario.__toOut());
	}
}
```

**compile**: `haxe -cp tools -main Example --interp -resource ./res/super_mario.nsf@supermario`

```
Example.hx:52: --- Nsfhd.CAPACITY: 128, addr: 32
offset: 0x00 - 0x05, bytes: 5, tag: NESM
offset: 0x05 - 0x06, bytes: 1, ver: One
offset: 0x06 - 0x07, bytes: 1, track_count: 18
offset: 0x07 - 0x08, bytes: 1, track_intro_number: 1
offset: 0x08 - 0x0A, bytes: 2, data_address: 36292
offset: 0x0A - 0x0C, bytes: 2, init_address: 48692
offset: 0x0C - 0x0E, bytes: 2, song_address: 62160
offset: 0x0E - 0x2E, bytes: 32, title: Super Mario Bros.
offset: 0x2E - 0x4E, bytes: 32, author: Koji Kondo
offset: 0x4E - 0x6E, bytes: 32, copyright: 1985 Nintendo
offset: 0x6E - 0x70, bytes: 2, ntsc: 16666
offset: 0x70 - 0x78, bytes: 8, bank: [0,0,0,0,1,1,1,1]
offset: 0x78 - 0x7A, bytes: 2, ntsc_loop_speed: 0
offset: 0x7A - 0x7B, bytes: 1, sys: 0
offset: 0x7B - 0x7C, bytes: 1, spec: 0
offset: 0x7C - 0x80, bytes: 4, exra: [0,0,0,0]
```

Learn More, see: <./tools/mem/Malloc.hx> and  <./tools/mem/Struct.hx>


<br />