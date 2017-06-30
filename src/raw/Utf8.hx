package raw;

import raw.Ptr;

@:enum private abstract UTF8Valid(Int) to Int {
	var UTF8_ACCEPT = 0;
	var UTF8_REJECT = 12;
}

class Utf8 {

	static var utf8d_table(default, null): Ptr = Ptr.NUL;

	public static function init() {
		if (utf8d_table != Ptr.NUL) return;

		var data = raw._macros.Utf8Macros.data32();

		var len = data.length;

		utf8d_table = Raw.malloc(len << 2, false);

		for (i in 0...len) {
			Memory.setI32(utf8d_table + (i << 2), data[i]);
		}
	}

	public static function length(src: Ptr, max = Raw.SMAX): Int {
		if (utf8d_table == Ptr.NUL) init();
		var i = 0, len = 0, state = 0, utf8d = utf8d_table;
		var byte:Int, type:Int;
		while (i < max) {
			byte = src[i];
			if (byte == 0) break;
			type = utf8d[byte];
			state = utf8d[256 + state + type];
			if (state == UTF8_REJECT)
				return -1;
			else if (state == UTF8_ACCEPT)
				++ len;
			++i;
		}
		return len;
	}

	// return len of wchar_t。
	public static function toucs2(out: Ptr, utf: Ptr, size: Int): Int {
		if (utf8d_table == Ptr.NUL) init();
		if (out == Ptr.NUL) return length(utf, size);
		var i = 0, len = 0, state = 0, codep = 0, utf8d = utf8d_table;
		var byte: Int, type: Int;
		while (i < size) {
			byte = utf[i];
			if (byte == 0) break;
			type = utf8d[byte];

			codep = state != UTF8_ACCEPT ?
				(byte & 0x3f) | (codep << 6) :
				(0xff >> type) & (byte);

			state = utf8d[256 + state + type];
			if (state == UTF8_REJECT)
				return -1;
			else if (state == UTF8_ACCEPT) {
				Memory.setI16(out + len, codep);
				len += 2;
			}
			++i;
		}
		return len >> 1;
	}

	// return bytesLength of Utf8。
	public static function ofucs2(out: Ptr, ucs: Ptr, size: Int): Int {
		var len = 0;
		var i = 0;
		var c: Int;
		if (out == Ptr.NUL) {
			while (size - i > 1) {
				c = Memory.getUI16(ucs + i);
				if (c == 0) break;
				if (c < 0x80) {
					++ len;
				} else if (c < 0x800) {
					len += 2;
				} else {
					len += 3;
				}
				i += 2;
			}
		} else {
			while (size - i > 1) {
				c = Memory.getUI16(ucs + i);
				if (c == 0) break;
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
				i += 2;
			}
		}
		return len;
	}
}