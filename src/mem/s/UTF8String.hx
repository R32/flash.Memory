package mem.s;

import mem.Ptr;

@:build(mem.Struct.auto()) extern abstract UTF8String(Ptr) to Ptr {
	@idx(4, -4) var _len: Int;

	var length(get, never): Int;
	private inline function get_length():Int return _len;

	inline function toString():String return mem.Utf8.getString(this, length);

	inline function new(bytes: Int) {
		this = alloc((CAPACITY + 1) + bytes, false);
		_len = bytes;
		this[bytes] = 0;
	}
}