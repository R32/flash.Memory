package mem.struct;


import mem.Ptr;
import mem.Ut.padmul;

/**
Fixed Block
*/
@:build(mem.Struct.StructBuild.make())
@:dce abstract FBlock(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int; // OFFSET_FIRST == -4

	public var length(get, never): Int;
	private inline function get_length() return _len;

	public inline function new(size:Int, zero:Bool, pad:Int) {
		this = untyped mem.Malloc.make(size + CAPACITY, zero, pad) - OFFSET_FIRST;
		_len = size;
	}

	public inline function toBytes(): haxe.io.Bytes {
		var b = haxe.io.Bytes.alloc(length);
		#if flash
		Ram.readBytes(this, length, b.getData());
		#else
		Ram.readBytes(this, length, b);
		#end
		return b;
	}

	static public inline function fromBytes(b, align = 128):FBlock {
		return Ram.mallocFromBytes(b, align);
	}

	@:arrayAccess inline function get(i: Int):Int return Memory.getByte((this:Int) + i);
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setByte((this:Int) + i, v);
}