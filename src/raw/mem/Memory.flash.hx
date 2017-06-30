package raw.mem;


// https://github.com/HaxeFoundation/haxe/commit/5b8bc7dd3dfb8999df8d86ccfdb9273dcc933d36
extern class Memory {

	public static inline function select( b : RawData): Void
		flash.system.ApplicationDomain.currentDomain.domainMemory = b.getData();

	public static inline function setByte(addr: Ptr, v: Int): Void
		untyped __vmem_set__(0, addr, v);

	public static inline function setI16(addr: Ptr, v: Int): Void
		untyped __vmem_set__(1, addr, v);

	public static inline function setI32(addr: Ptr, v: Int): Void
		untyped __vmem_set__(2, addr, v);

	public static inline function setFloat(addr: Ptr, v: Float): Void
		untyped __vmem_set__(3, addr, v);

	public static inline function setDouble(addr: Ptr, v: Float): Void
		untyped __vmem_set__(4, addr, v);

	public static inline function getByte(addr: Ptr): Int
		return untyped __vmem_get__(0, addr);

	public static inline function getUI16(addr: Ptr): Int
		return untyped __vmem_get__(1, addr);

	public static inline function getI32(addr: Ptr): Int
		return untyped __vmem_get__(2, addr);

	public static inline function getFloat(addr: Ptr): Float
		return untyped __vmem_get__(3, addr);

	public static inline function getDouble(addr: Ptr): Float
		return untyped __vmem_get__(4, addr);

	//public static inline function signExtend1(v: Int): Int
	//	return untyped __vmem_sign__(0, v);

	public static inline function signExtend8(v: Int): Int
		return untyped __vmem_sign__(1, v);

	public static inline function signExtend16(v: Int): Int
		return untyped __vmem_sign__(2, v);
}