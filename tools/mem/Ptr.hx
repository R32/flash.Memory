package mem;

import mem.RawData;

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
	public static inline var SIZEOF = 1;
}

abstract AU16(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Int return Memory.getUI16(this + (k + k));
	@:arrayAccess inline function set(k:Int, v:Int):Void Memory.setI16(this + (k + k), v);
	public static inline var SIZEOF = 2;
}

abstract AI32(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Int return Memory.getI32(this + (k << 2));
	@:arrayAccess inline function set(k:Int, v:Int):Void Memory.setI32(this + (k << 2), v);
	public static inline var SIZEOF = 4;
}

abstract AF4(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Float return Memory.getFloat(this + (k << 2));
	@:arrayAccess inline function set(k:Int, v:Float):Void Memory.setFloat(this + (k << 2), v);
	public static inline var SIZEOF = 4;
}

abstract AF8(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Float return Memory.getDouble(this + (k << 3));
	@:arrayAccess inline function set(k:Int, v:Float):Void Memory.setDouble(this + (k << 3), v);
	public static inline var SIZEOF = 8;
}

abstract ABit(Ptr) to Ptr {
	@:arrayAccess function get(k:Int):Int {
		var byte = Memory.getByte(this + (k >> 3));
		var p = k & (8 - 1);
		return (byte >> p) & 1;
	}
	@:arrayAccess function set(k:Int, v:Int):Void {
		var byte = Memory.getByte(this + (k >> 3));
		var p = k & (8 - 1);
		Memory.setByte(this + (k >> 3),
			v == 0
			? byte & (~(1 << p))
			: byte | (1 << p)
		);
	}
}

#if flash
typedef Memory = mem.impl.FlashMemory;
#elseif cpp
typedef Memory = mem.impl.CppMemory;
#elseif hl
typedef Memory = mem.impl.HLMemory;
#else
typedef Memory = mem.impl.BytesMemory;
#end