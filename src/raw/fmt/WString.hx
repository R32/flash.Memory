package raw.fmt;

import raw.Ptr;

/**
Mbs
*/
@:build(raw.Struct.make())
abstract WString(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;
	public var length(get, never): Int;
	private inline function get_length() return _len;

	inline function new(bytesLength: Int) {
		mallocAbind(bytesLength + (CAPACITY + 1), false);
		_len = bytesLength;
		this[bytesLength] = 0;
	}

	public inline function toString(): String {
		return Raw.readUtf8(this, length);
	}

	public static inline function ofString(str: String): WString {
		var len = ofstr(Ptr.NUL, str);
		var ws = new WString(len);
		ofstr(cast ws, str);
		return ws;
	}

	// UCS2     : js, flash, as3, hl, java, c#
	// MBS(UTF8): cpp, neko, python, lua.
	public static function ofstr(out: Ptr, str: String): Int {
	#if (cpp || neko || python || lua)
		if (out != Ptr.NUL) {
			for (i in 0...str.length) {
				out[i] = StringTools.fastCodeAt(str, i);
			}
		}
		return str.length;
	#else
		var c: Int;
		var len = 0;
		if (out == Ptr.NUL) {
			for (i in 0...str.length) {
				c = StringTools.fastCodeAt(str, i);
				if (c < 0x80) {
					++ len;
				} else if (c < 0x800) {
					len += 2;
				} else {
					len += 3;
				}
			}
		} else {
			for (i in 0...str.length) {
				c = StringTools.fastCodeAt(str, i);
				if (c < 0x80) {
					out[len++] = c;
				} else if (c < 0x800) {
					out[len++] = (0xC0 | (c >> 6));
					out[len++] = (0x80 | (c & 63));
				} else {
					out[len++] = (0xE0 | (c >> 12));
					out[len++] = (0x80 | ((c >> 6) & 63));
					out[len++] = (0x80 | (c & 63));
				}
			}
		}
		return len;
	#end
	}

	// "max" of bytes to write to out;
	public static function ofstrn(out: Ptr, str: String, max: Int): Int {
	#if (cpp || neko || python || lua)
		max = Ut.imin(max, str.length);
		if (out != Ptr.NUL) {
			for (i in 0...max) {
				out[i] = StringTools.fastCodeAt(str, i);
			}
		}
		return max;
	#else
		var c: Int;
		var len = 0;
		if (out == Ptr.NUL) {
			return ofstr(Ptr.NUL, str);
		} else {
			for (i in 0...str.length) {
				c = StringTools.fastCodeAt(str, i);
				if (c < 0x80) {
					if (max - len < 1) break;
					out[len++] = c;
				} else if (c < 0x800) {
					if (max - len < 2) break;
					out[len++] = (0xC0 | (c >> 6));
					out[len++] = (0x80 | (c & 63));
				} else {
					if (max - len < 3) break;
					out[len++] = (0xE0 | (c >> 12));
					out[len++] = (0x80 | ((c >> 6) & 63));
					out[len++] = (0x80 | (c & 63));
				}
			}
		}
		return len;
	#end
	}
}