package raw.struct;

import raw.Ptr;

@:build(raw.Struct.make())
abstract FBlock(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;

	public var length(get, never): Int;
	private inline function get_length() return _len;

	public inline function new(size: Int, zero = false, pad = 16) {
		this = Malloc.make(size + CAPACITY, zero, pad) - OFFSET_FIRST;
		_len = size;
	}

	public inline function toBytes(): haxe.io.Bytes {
		var b = haxe.io.Bytes.alloc(length);
		Raw.readBytes(this, b.length, b);
		return b;
	}

	public static inline function ofBytes(b: haxe.io.Bytes, align = 32): FBlock {
		var ret = new FBlock(b.length, false, align);
		Raw.writeBytes((ret: Ptr), b.length, b);
		return ret;
	}
}