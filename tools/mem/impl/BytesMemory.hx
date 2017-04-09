package mem.impl;

import mem.RawData;

// No inline Since Too Many Local Varialbes
class BytesMemory {
	public static var b(default, null): RawData;
	public static inline function select( o : RawData ): Void b = o;
	public static function setByte( addr : Int, v : Int ): Void b.set(addr, v);
	public static function setI16 ( addr : Int, v : Int ): Void b.setUInt16(addr, v);
	public static function setI32 ( addr : Int, v : Int ): Void b.setInt32(addr, v);
	public static function setFloat ( addr : Int, v : Float ): Void b.setFloat(addr, v);
	public static function setDouble( addr : Int, v : Float ): Void b.setDouble(addr, v);
	public static function getByte( addr : Int ): Int return haxe.io.Bytes.fastGet(b.getData(), addr);
	public static function getUI16( addr : Int ): Int return b.getUInt16(addr);
	public static function getI32 ( addr : Int ): Int return b.getInt32(addr);
	public static function getFloat ( addr : Int ): Float return b.getFloat(addr);
	public static function getDouble( addr : Int ): Float return b.getDouble(addr);
}