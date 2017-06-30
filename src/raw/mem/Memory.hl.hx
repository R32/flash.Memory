package raw.mem;

class Memory {
	static var b(default, null): hl.Bytes;
	public static inline function select(o: RawData): Void b = @:privateAccess o.b;

	public static inline function setByte( addr : Ptr, v : Int ): Void b.setUI8(addr.toInt(), v);
	public static inline function setI16 ( addr : Ptr, v : Int ): Void b.setUI16(addr.toInt(), v);
	public static inline function setI32 ( addr : Ptr, v : Int ): Void b.setI32(addr.toInt(), v);
	public static inline function setFloat ( addr : Ptr, v : Float ): Void b.setF32(addr.toInt(), v);
	public static inline function setDouble( addr : Ptr, v : Float ): Void b.setF64(addr.toInt(), v);

	public static inline function getByte( addr : Ptr ): Int return b.getUI8(addr.toInt());
	public static inline function getUI16( addr : Ptr ): Int return b.getUI16(addr.toInt());
	public static inline function getI32 ( addr : Ptr ): Int return b.getI32(addr.toInt());
	public static inline function getFloat ( addr : Ptr ): Float return b.getF32(addr.toInt());
	public static inline function getDouble( addr : Ptr ): Float return b.getF64(addr.toInt());

	public static inline function signExtend8(v: Int): Int
		return v & 0x80 == 0x80 ? v | 0xffffff00: v;
	public static inline function signExtend16(v: Int): Int
		return v & 0x8000 == 0x8000 ? v | 0xffff0000: v;
}