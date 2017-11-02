package raw.fmt;

import raw.Ptr;

@:build(raw.Struct.make())
@:native("FBlock")
abstract FBlock(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;

	public var length(get, never): Int;
	private inline function get_length() return _len;

	public inline function new(size: Int, zero: Bool, pad: Int) {
		this = Malloc.make(size + CAPACITY, zero, pad) - OFFSET_FIRST;
		_len = size;
	}

	public function toBytes(): haxe.io.Bytes {
		var b = haxe.io.Bytes.alloc(length);
		Raw.readBytes(this, b.length, b);
		return b;
	}

	public static function ofBytes(b: haxe.io.Bytes, align = 32): FBlock {
		var ret = new FBlock(b.length, false, align);
		Raw.writeBytes((ret: Ptr), b.length, b);
		return ret;
	}

	@:arrayAccess inline function get(i: Int):Int return Memory.getByte(this + i);
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setByte(this + i, v);
}