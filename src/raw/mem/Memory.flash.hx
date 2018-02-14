package raw.mem;

extern class Memory {

	public static inline function select( b : RawData): Void
		flash.system.ApplicationDomain.currentDomain.domainMemory = b.getData();

	public static inline function setByte(addr: Ptr, v: Int): Void
		flash.Memory.setByte(addr.toInt(), v);

	public static inline function setI16(addr: Ptr, v: Int): Void
		flash.Memory.setI16(addr.toInt(), v);

	public static inline function setI32(addr: Ptr, v: Int): Void
		flash.Memory.setI32(addr.toInt(), v);

	public static inline function setFloat(addr: Ptr, v: Float): Void
		flash.Memory.setFloat(addr.toInt(), v);

	public static inline function setDouble(addr: Ptr, v: Float): Void
		flash.Memory.setDouble(addr.toInt(), v);

	public static inline function getByte(addr: Ptr): Int
		return flash.Memory.getByte(addr.toInt());

	public static inline function getUI16(addr: Ptr): Int
		return flash.Memory.getUI16(addr.toInt());

	public static inline function getI32(addr: Ptr): Int
		return flash.Memory.getI32(addr.toInt());

	public static inline function getFloat(addr: Ptr): Float
		return flash.Memory.getFloat(addr.toInt());

	public static inline function getDouble(addr: Ptr): Float
		return flash.Memory.getDouble(addr.toInt());

	//public static inline function signExtend1(v: Int): Int
	//	return flash.Memory.signExtend1(v);

	public static inline function signExtend8(v: Int): Int
		return flash.Memory.signExtend8(v);

	public static inline function signExtend16(v: Int): Int
		return flash.Memory.signExtend16(v);
}