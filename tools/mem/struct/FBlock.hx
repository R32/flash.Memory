package mem.struct;


import mem.Ptr;
import mem.Ut.padmul;

/**
Fixed Block
*/
#if !macro
@:build(mem.Struct.StructBuild.make())
#end
@:dce abstract FBlock(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int; // OFFSET_FIRST == -4

	public var length(get, never): Int;
	private inline function get_length() return _len;

	public inline function new(size:Int, pad:Int) {
		this = untyped Ram.malloc(padmul(size + CAPACITY, pad), false) - OFFSET_FIRST;
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

	static public inline function fromBytes(b):FBlock {
		return Ram.mallocFromBytes(b);
	}
}