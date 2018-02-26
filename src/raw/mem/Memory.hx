package raw.mem;

import raw.Ptr;

class Memory {
	static var b(get, never): RawData;
	static inline function get_b() return @:privateAccess Raw.current;
	public static inline function select( b : RawData): Void {}
	public static inline function setByte( addr : Ptr, v : Int ): Void b.set(addr.toInt(), v);
	public static inline function setI16 ( addr : Ptr, v : Int ): Void b.setUInt16(addr.toInt(), v);
	public static inline function setI32 ( addr : Ptr, v : Int ): Void b.setInt32(addr.toInt(), v);
	public static inline function setFloat ( addr : Ptr, v : Float ): Void b.setFloat(addr.toInt(), v);
	public static inline function setDouble( addr : Ptr, v : Float ): Void b.setDouble(addr.toInt(), v);
	public static inline function getByte( addr : Ptr ): Int return b.get(addr.toInt());
	public static inline function getUI16( addr : Ptr ): Int return b.getUInt16(addr.toInt());
	public static inline function getI32 ( addr : Ptr ): Int return b.getInt32(addr.toInt());
	public static inline function getFloat ( addr : Ptr ): Float return b.getFloat(addr.toInt());
	public static inline function getDouble( addr : Ptr ): Float return b.getDouble(addr.toInt());

	public static inline function signExtend1(v: Int): Int
		return v & 1 == 1 ? 0xffffffff : 0;
	public static inline function signExtend8(v: Int): Int
		return v & 0x80 == 0x80 ? v | 0xffffff00: v;
	public static inline function signExtend16(v: Int): Int
		return v & 0x8000 == 0x8000 ? v | 0xffff0000: v;
}