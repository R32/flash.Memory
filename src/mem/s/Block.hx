package mem.s;

import mem.Ptr;

@:build(mem.Struct.build()) extern abstract Block(Ptr) to Ptr {
	@idx(4, -4) var _len: Int;
	var length(get, never): Int;

	private inline function get_length():Int return _len;

	inline function toBytes():haxe.io.Bytes return Mem.readBytes(this, length);

	inline function new(size: Int, zero: Bool, pad: Int) {
		this = mem.Alloc.req(size, zero, pad) - OFFSET_FIRST;
		_len = size;
	}

	@:arrayAccess inline function aget(i: Int):Int return (this + i).getByte();
	@:arrayAccess inline function aset(i: Int, v:Int):Void (this + i).setByte(v);

	static inline function alloc(size: Int):Block return new Block(size, false, 16);
}