package mem.obs;

import haxe.Int64;
import mem.Ptr;
import mem.obs.SXor;

#if !macro
@:build(mem.Struct.StructBuild.make())
#end
@:dce abstract SxKeys(Ptr) from Ptr{
	public inline function new(len:Int) {
		this = Malloc.make(len, false);
	}
	public var c_ptr(get, never):Ptr;
	inline function get_c_ptr():Ptr return this;
}


#if !macro
@:build(mem.Struct.StructBuild.make())
#end
abstract SxInt(Ptr) from Ptr{
	@idx(1) var v_0:Int;
	@idx(1) var v_1:Int;
	@idx(1) var v_2:Int;
	@idx(1) var v_3:Int;
	@idx(4, -4) var low:Int;
	@idx(1) var v_4:Int;
	@idx(1) var v_5:Int;
	@idx(1) var v_6:Int;
	@idx(1) var v_7:Int;
	@idx(4, -4) var high:Int;

	@:dce public inline  function calc_0():Int return v_5 ^ v_2 | (v_1 & v_2) ^ v_6 | (v_7 & v_6) ^ v_0 | (v_3 & v_0) ^ v_4;

	@:dce public inline  function calc_1():Int return v_7 ^ v_6 | (v_5 & v_6) ^ v_4 | (v_3 & v_4) ^ v_2 | (v_1 & v_2) ^ v_0;

	@:dce public inline  function calc_2():Int return v_4 ^ v_7 | (v_6 & v_7) ^ v_5 | (v_0 & v_5) ^ v_3 | (v_2 & v_3) ^ v_1;

	@:dce public inline  function calc_3():Int return v_1 ^ v_0 | (v_3 & v_0) ^ v_2 | (v_5 & v_2) ^ v_4 | (v_7 & v_4) ^ v_6;

	@:dce public static inline function fromInt64(v:Int64):SxInt{
		return fromInt2(v.low, v.high);
	}

	@:dce public static inline function fromInt2(l:Int, h:Int):SxInt{
		var x = new SxInt();
	#if !neko
		x.low = l;
		x.high = h;
	#else
		x.v_0 = l & 0xff;
		x.v_1 = (l >> 8) & 0xff;
		x.v_2 = (l >> 16) & 0xff;
		x.v_3 = (l >>> 24) & 0xff;
		x.v_4 = h & 0xff;
		x.v_5 = (h >> 8) & 0xff;
		x.v_6 = (h >> 16) & 0xff;
		x.v_7 = (h >>> 24) & 0xff;
	#end
		return x;
	}
}

// 0 --- 4~7,3~6,0~5,1~2
//// v_0 ^ v_1 | (v_2 & v_1) ^ v_3 | (v_4 & v_3) ^ v_5 | (v_6 & v_5) ^ v_7
//   v_5 ^ v_2 | (v_1 & v_2) ^ v_6 | (v_7 & v_6) ^ v_0 | (v_3 & v_0) ^ v_4;

// 1 --- 0~7,2~5,3~4,1~6
//// v_0 ^ v_1 | (v_2 & v_1) ^ v_3 | (v_4 & v_3) ^ v_5 | (v_6 & v_5) ^ v_7
//   v_7 ^ v_6 | (v_5 & v_6) ^ v_4 | (v_3 & v_4) ^ v_2 | (v_1 & v_2) ^ v_0;

// 2 --- 0~4, 1~7, 2~6, 3~5
//// v_0 ^ v_1 | (v_2 & v_1) ^ v_3 | (v_4 & v_3) ^ v_5 | (v_6 & v_5) ^ v_7
//   v_4 ^ v_7 | (v_6 & v_7) ^ v_5 | (v_0 & v_5) ^ v_3 | (v_2 & v_3) ^ v_1;

// 3 --- 4~5, 6~7, 0~1, 2~3
//// v_0 ^ v_1 | (v_2 & v_1) ^ v_3 | (v_4 & v_3) ^ v_5 | (v_6 & v_5) ^ v_7
//   v_1 ^ v_0 | (v_3 & v_0) ^ v_2 | (v_5 & v_2) ^ v_4 | (v_7 & v_4) ^ v_6;