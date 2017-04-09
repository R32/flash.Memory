package mem.impl;

import mem.RawData;

class CppMemory {
	public static var b(default, null): RawData;
	public static inline function select( o : RawData ): Void b  = o;
	public static inline function setByte( addr : Int, v : Int ): Void b.set(addr, v);
	public static inline function setI16 ( addr : Int, v : Int ): Void b.setUInt16(addr, v);
	public static inline function setI32 ( addr : Int, v : Int ): Void b.setInt32(addr, v);
	public static inline function setFloat ( addr : Int, v : Float ): Void b.setFloat(addr, v);
	public static inline function setDouble( addr : Int, v : Float ): Void b.setDouble(addr, v);
	public static inline function getByte( addr : Int ): Int return b.get(addr);
	public static inline function getUI16( addr : Int ): Int return b.getUInt16(addr);
	public static inline function getI32 ( addr : Int ): Int return b.getInt32(addr);
	public static inline function getFloat ( addr : Int ): Float return b.getFloat(addr);
	public static inline function getDouble( addr : Int ): Float return b.getDouble(addr);
}