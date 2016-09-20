package mem;


abstract Ptr(Int) to Int {

	@:arrayAccess inline function get(i: Int):Int return Memory.getByte(this + i);
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setByte(this + i, v);

	@:op(A + B) private inline function addInt(b : Int ): Ptr
		return cast ((this:Int) + b);

	@:op(A - B) private inline function sub(b : Int ): Ptr
		return cast ((this:Int) - b);

	@:op(A < B) private static inline function lt( a : Ptr, b : Ptr ) : Bool
		return (a:Int) < (b:Int);

	@:op(A <= B) private static inline function lte( a : Ptr, b : Ptr ) : Bool
		return (a:Int) <= (b:Int);

	@:op(A > B) private static inline function gt( a : Ptr, b : Ptr ) : Bool
		return (a:Int) > (b:Int);

	@:op(A >= B) private static inline function gte( a : Ptr, b : Ptr ) : Bool
		return (a:Int) >= (b:Int);

	@:op(A == B) private static inline function eqInt( a : Ptr, b : Ptr ) : Bool
		return (a:Int) == (b:Int);
}

/**
 Array<Unsigned Char>
*/
abstract AU8(Ptr) to Ptr from Ptr {
	@:arrayAccess inline function get(k:Int):Int return Memory.getByte(this + k);
	@:arrayAccess inline function set(k:Int, v:Int):Void Memory.setByte(this + k, v);
}

abstract AU16(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Int return Memory.getUI16(this + (k + k));
	@:arrayAccess inline function set(k:Int, v:Int):Void Memory.setI16(this + (k + k), v);
}

abstract AI32(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Int return Memory.getI32(this + (k << 2));
	@:arrayAccess inline function set(k:Int, v:Int):Void Memory.setI32(this + (k << 2), v);
}

abstract AF4(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Float return Memory.getFloat(this + (k << 2));
	@:arrayAccess inline function set(k:Int, v:Float):Void Memory.setFloat(this + (k << 2), v);
}

abstract AF8(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Float return Memory.getDouble(this + (k << 3));
	@:arrayAccess inline function set(k:Int, v:Float):Void Memory.setDouble(this + (k << 3), v);
}

#if flash
typedef ByteArray = flash.utils.ByteArray;
typedef Memory = mem.FlashMemory;

#elseif (cpp && !keep_bytes)
typedef ByteArray = mem.cpp.BytesData;
class Memory {
	public static var b(default, null): cpp.Star<ByteArray>;
	public static inline function select( o : cpp.Star<ByteArray> ): Void b  = o;
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

#else // Too Many Local Varialbes, so no inline
class Memory {
	public static var b(default, null): haxe.io.Bytes;
	public static function select( o : haxe.io.Bytes ): Void b = o;
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
#end