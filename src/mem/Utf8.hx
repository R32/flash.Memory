package mem;

class Utf8 {

	public static function length(p: Ptr, bytes: Int): Int {
		var max = p + bytes;
		var len = 0;
		while (p < max) {
			var c = p.getByte();
			++ len;
			if ( c < 0x80 ) {
				if (c == 0) {
					-- len;
					break;
				}
				++ p;
			} else if ( c < 0xC0 ) {
				return len - 1;
			} if ( c < 0xE0 ) {
				if ( (p[1] & 0x80) == 0 ) return len - 1;
				p += 2;
			} else if ( c < 0xF0 ) {
				if ( ((p[1] & p[2]) & 0x80) == 0 ) return len - 1;
				p += 3;
			} else if ( c < 0xF8 ) {
				if ( ((p[1] & p[2] & p[3]) & 0x80) == 0 ) return len - 1;
				++ len; // surrogate pair
				p += 4;
			} else {
				return len;
			}
		}
		return len;
	}

	public static function toUcs2(out: Ptr, utf: Ptr, bytes: Int): Int {
		if (out == Ptr.NUL) {
			return length(utf, bytes);
		} else {
			var max = utf + bytes;
			var len = 0;
			var c: Int, c2: Int, c3: Int;
			while (utf < max) {
				c = p.getByte();
				if ( c < 0x80 ) {
					if( c == 0 ) break;
				} else if( c < 0xE0 ) {

				} else if( c < 0xF0 ) {

				} else {

				}
			}
			return len;
		}
	}

	/**
	* @param out: Ptr of utf8 long enough to contain the resulting sequence (at most, max bytes).
	* 		if out == Ptr.NUL then only count the number of bytes needed for the conversion
	* @param ucs: Ptr of ucs2
	* @param bytes: Bytes of ucs2, Must be an integer multiple of 2.
	* @return The number of bytes written to out, not including the eventual ending null-character.
	*/
	public static function ofUcs2(out: Ptr, ucs: Ptr, bytes: Int): Int {
		var i = 0;
		var max = ucs + (bytes & 0xFFFFFE); // limit in 24bit
		bytes = 0;
		if (out == Ptr.NUL) {
			while (ucs < max) {
				var c = ucs.getUI16();
				if (c == 0) break;
				if (c < 0x80) {
					++ bytes;
				} else if (c < 0x800) {
					bytes += 2;
				} else {
					bytes += 3;
				}
				ucs += 2;
			}
		} else {
			while (ucs < max) {
				var c = ucs.getUI16();
				if (c == 0) break;
				if (c < 0x80) {
					out[bytes++] = c;
				} else if (c < 0x800) {
					out[bytes++] = (0xC0 | (c >> 6));
					out[bytes++] = (0x80 | (c & 63));
				} else {
					out[bytes++] = (0xE0 | (c >> 12));
					out[bytes++] = (0x80 | ((c >> 6) & 63));
					out[bytes++] = (0x80 | (c & 63));
				}
				i += 2;
			}
		}
		return bytes;
	}
}
