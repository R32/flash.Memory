package mem;

class Utf8 {
	// return the number of UCS2 characters
	static public function length(utf: Ptr, bytes: Int): Int {
		var max = utf + bytes;
		var len = 0;
		while (utf < max) {
			var c = utf.getByte();
			if ( c < 0x80 ) {
				if (c == 0) break;
				++ utf;
			} else if ( c < 0xC0 ) {
				break;
			} else if ( c < 0xE0 ) {
				if ( utf[1] & 0x80 == 0 ) break;
				utf += 2;
			} else if ( c < 0xF0 ) {
				if ( utf[1] & utf[2] & 0x80 == 0 ) break;
				utf += 3;
			} else {
				if ( utf[1] & utf[2] & utf[3] & 0x80 == 0 ) break;
				utf += 4;
				len += 2; // surrogate pair
				continue;
			}
			++ len;
		}
		return len;
	}

	/**
	*
	* @param out
	* @param utf: Ptr of utf8
	* @param bytes: BytesLength of utf8
	* @return The number of UCS2(wchar_t) to "out", not including the eventual terminating null character.
	*/
	static public function toUcs2(out: Ptr, utf: Ptr, bytes: Int): Int {
		if (out == Ptr.NUL) {
			return length(utf, bytes);
		} else {
			var ucs = out;
			var max = utf + bytes;
			var c: Int, c2: Int, c3: Int, c4: Int;
			while (utf < max) {
				c = utf.getByte();
				if ( c < 0x80 ) {
					if (c == 0) break;
					++ utf;
				} else if ( c < 0xC0 ) {
					break;
				} else if ( c < 0xE0 ) {
					c2 = utf[1];
					if (c2 & 0x80 == 0) break;
					c = ((c & 0x3F) << 6) | (c2 & 0x7F);
					utf += 2;
				} else if ( c < 0xF0 ) {
					c2 = utf[1];
					c3 = utf[2];
					if ( c2 & c3 & 0x80 == 0 ) break;
					c = ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (c3 & 0x7F);
					utf += 3;
				} else {
					c2 = utf[1];
					c3 = utf[2];
					c4 = utf[3];
					if ( c2 & c3 & c4 & 0x80 == 0 ) break;
					c = ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 & 0x7F) << 6) | (c4 & 0x7F);
					out.setI16((c >> 10) + 0xD7C0);
					(out + 2).setI16((c & 0x3FF) + 0xDC00);
					out += 4;
					utf += 4;
					continue;
				}
				out.setI16(c);
				out += 2;
			}
			return (out - ucs) >> 1;
		}
	}

	/**
	* example:
	*   ```hx
	*   var bytes = Utf8.ofUcs2(Ptr.NUL, ucs2_ptr, wchar_len);
	*   var out = Mem.malloc(bytes + 1);
	*   Utf8.ofUcs2(out, ucs2_ptr, wchar_len);
	*   out[bytes] = 0;
	*   ```
	* @param out: Ptr of utf8 long enough to contain the resulting sequence (at most, max bytes).
	* 		if out == Ptr.NUL then only count the number of bytes needed for the conversion
	* @param ucs: Ptr of ucs2
	* @param wlen: length of wchar_t(ucs2)
	* @return The number of bytes written to out, not including the eventual ending null-character.
	*/
	static public function ofUcs2(out: Ptr, ucs: Ptr, wlen: Int): Int {
		var max = ucs + (wlen << 1);
		var bytes = 0;
		if (out == Ptr.NUL) {
			while (ucs < max) {
				var c = ucs.getUI16();
				if (c == 0) break;
				if (c < 0x80) {
					++ bytes;
				} else if (c < 0x800) {
					bytes += 2;
				} else if (c >= 0xD800 && c <= 0xDFFF) {
					bytes += 4;
					ucs += 4;
					continue;
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
				} else if (c >= 0xD800 && c <= 0xDFFF) {
					ucs += 2; // surrogate pair
					c = (((c - 0xD800) << 10) | (ucs.getUI16() - 0xDC00)) + 0x10000;
					out[bytes++] = (0xF0 | (c>>18));
					out[bytes++] = (0x80 | ((c >> 12) & 63));
					out[bytes++] = (0x80 | ((c >> 6) & 63));
					out[bytes++] = (0x80 | (c & 63));
				} else {
					out[bytes++] = (0xE0 | (c >> 12));
					out[bytes++] = (0x80 | ((c >> 6) & 63));
					out[bytes++] = (0x80 | (c & 63));
				}
				ucs += 2;
			}
		}
		return bytes;
	}

	/**
	* @param out: utf8 string will be written.
	* @param max: Limit the number of bytes written to out
	* @param src: haxe String.
	* @return The number of bytes written to out, not including the eventual ending null-character.
	*/
	static public function ofString(out: Ptr, max: Int, src: String): Int {
		inline function char(i):Int return StringTools.fastCodeAt(src, i);
	#if (!utf16)
		if (out == Ptr.NUL) return src.length;
		var len = Ut.imin(max, src.length);
		for (i in 0...len)
			out[i] = char(i);
		if (max > len) out[len] = 0;
		return len;
	#else
		var i = 0;
		var len = src.length;
		var bytes = 0;
		if (out == Ptr.NUL) { // ignore the max
			while (i < len) {
				var c = char(i++);
				if (c < 0x80) {
					++ bytes;
				} else if (c < 0x800) {
					bytes += 2;
				} else if (c >= 0xD800 && c <= 0xDFFF) {
					if (i == len) break;
					++ i;
					bytes += 4;
				} else {
					bytes += 3;
				}
			}
		} else {
			while (i < len && bytes < max) {
				var c = char(i++);
				if (c < 0x80) {
					out[bytes++] = c;
				} else if (c < 0x800) {
					if (bytes + 1 == max) break;
					out[bytes++] = (0xC0 | (c >> 6));
					out[bytes++] = (0x80 | (c & 63));
				} else if (c >= 0xD800 && c <= 0xDFFF) {
					if (i == len || bytes + 3 >= max) break;
					c = (((c - 0xD800) << 10) | (char(i) - 0xDC00)) + 0x10000;
					out[bytes++] = (0xF0 | (c>>18));
					out[bytes++] = (0x80 | ((c >> 12) & 63));
					out[bytes++] = (0x80 | ((c >> 6) & 63));
					out[bytes++] = (0x80 | (c & 63));
				} else {
					if (bytes + 2 >= max) break;
					out[bytes++] = (0xE0 | (c >> 12));
					out[bytes++] = (0x80 | ((c >> 6) & 63));
					out[bytes++] = (0x80 | (c & 63));
				}
			}
			if (max > bytes) out[bytes] = 0;
		}
		return bytes;
	#end
	}

	/**
	* @param src: utf8 ptr
	* @param len: The number of bytes will be readding from src
	* @return
	*/
	@:access(Mem.b) static public function getString(src: Ptr, len: Int): String {
	#if hl
		var b = new hl.Bytes(len + 1);
		b.blit(0, Mem.b, src.toInt(), len);
		b[len] = 0;
		return @:privateAccess String.fromUTF8(b);
	#elseif flash
		Mem.b.position = src.toInt();
		return Mem.b.readUTFBytes(len);
	#else
		#if !js
		var i = 0;
		var utf = src;
		while (i < len) {
			if (utf.getByte() == 0) break;
			++ utf;
		}
		len = Ut.imin(len, utf - src);
		#end
		return Mem.b.getString(src.toInt(), len);
	#end
	}
}
