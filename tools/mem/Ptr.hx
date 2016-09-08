package mem;

typedef Ptr = Int;

/**
 Array<Unsigned Char>
*/
abstract AU8(Ptr) to Ptr {
	@:arrayAccess inline function get(k:Int):Int {
		return Memory.getByte(this + k);
	}

	@:arrayAccess inline function set(k:Int, v:Int):Void {
		return Memory.setByte(this + k, v);
	}
}

abstract AU16(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Int {
		return Memory.getUI16(this + (k + k));
	}

	@:arrayAccess inline function set(k:Int, v:Int):Void {
		return Memory.setI16(this + (k + k), v);
	}
}

abstract AI32(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Int {
		return Memory.getI32(this + (k << 2));
	}

	@:arrayAccess inline function set(k:Int, v:Int):Void {
		return Memory.setI32(this + (k << 2), v);
	}
}

abstract AF4(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Float {
		return Memory.getFloat(this + (k << 2));
	}

	@:arrayAccess inline function set(k:Int, v:Float):Void {
		return Memory.setFloat(this + (k << 2), v);
	}
}

abstract AF8(Ptr) to Ptr{
	@:arrayAccess inline function get(k:Int):Float {
		return Memory.getDouble(this + (k << 3));
	}

	@:arrayAccess inline function set(k:Int, v:Float):Void {
		return Memory.setDouble(this + (k << 3), v);
	}
}

#if flash
typedef Memory = flash.Memory;
typedef ByteArray = flash.utils.ByteArray;
#else
class Memory {

	public static var b(default, null): haxe.io.Bytes;

	public static inline function select( o : haxe.io.Bytes ) : Void {
		b = o;
	}

	public static inline function setByte( addr : Int, v : Int ) : Void {
		b.set(addr, v);
	}

	public static inline function setI16( addr : Int, v : Int ) : Void {
		b.setUInt16(addr, v);
	}

	public static inline function setI32( addr : Int, v : Int ) : Void {
		b.setInt32(addr, v);
	}

	public static inline function setFloat( addr : Int, v : Float ) : Void {
		b.setFloat(addr, v);
	}

	public static inline function setDouble( addr : Int, v : Float ) : Void {
		b.setDouble(addr, v);
	}

	public static inline function getByte( addr : Int ) : Int {
		return haxe.io.Bytes.fastGet(b.getData(), addr);
	}

	public static inline function getUI16( addr : Int ) : Int {
		return b.getUInt16(addr);
	}

	public static inline function getI32( addr : Int ) : Int {
		return b.getInt32(addr);
	}

	public static inline function getFloat( addr : Int ) : Float {
		return b.getFloat(addr);
	}

	public static inline function getDouble( addr : Int ) : Float {
		return b.getDouble(addr);
	}
}
#end