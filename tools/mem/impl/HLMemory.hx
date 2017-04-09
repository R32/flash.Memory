package mem.impl;

import mem.RawData;

class HLMemory {
#if !macro
	public static var b(default, null): RawData;
	public static inline function select( o : RawData ): Void b = o;
#else
	static inline var bsetui8 = "$bsetui8"; // prevent "$" to escape.
	static inline var bsetui16 = "$bsetui16";
	static inline var bseti32 = "$bseti32";
	static inline var bsetf32 = "$bsetf32";
	static inline var bsetf64 = "$bsetf64";

	static inline var bgetui8 = "$bgetui8";
	static inline var bgetui16 = "$bgetui16";
	static inline var bgeti32 = "$bgeti32";
	static inline var bgetf32 = "$bgetf32";
	static inline var bgetf64 = "$bgetf64";
#end
	macro public static function setByte(  addr, v ) return macro untyped $i{bsetui8} (mem.Memory.b, ($addr: Int), ($v: Int));
	macro public static function setI16(   addr, v ) return macro untyped $i{bsetui16}(mem.Memory.b, ($addr: Int), ($v: Int));
	macro public static function setI32(   addr, v ) return macro untyped $i{bseti32} (mem.Memory.b, ($addr: Int), ($v: Int));
	macro public static function setFloat( addr, v ) return macro untyped $i{bsetf32} (mem.Memory.b, ($addr: Int), ($v: Float));
	macro public static function setDouble(addr, v ) return macro untyped $i{bsetf64} (mem.Memory.b, ($addr: Int), ($v: Float));

	macro public static function getByte(  addr ) return macro (untyped $i{bgetui8} (mem.Memory.b, ($addr: Int)): Int);
	macro public static function getUI16(  addr ) return macro (untyped $i{bgetui16}(mem.Memory.b, ($addr: Int)): Int);
	macro public static function getI32(   addr ) return macro (untyped $i{bgeti32} (mem.Memory.b, ($addr: Int)): Int);
	macro public static function getFloat( addr ) return macro (untyped $i{bgetf32} (mem.Memory.b, ($addr: Int)): Float);
	macro public static function getDouble(addr ) return macro (untyped $i{bgetf64} (mem.Memory.b, ($addr: Int)): Float);
}