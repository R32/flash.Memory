package mem;

class Ucs2 {
	/**
	* @param src: ucs2 ptr
	* @param wlen: number of wchar_t(UCS2)
	* @return
	*/
	static public function getString(src: Ptr, wlen: Int): String @:privateAccess {
		var bytes = wlen << 1;
	#if hl
		bytes = Ut.imin(bytes, Mem.b.ucs2Length(src.toInt()) << 1);
		var b = new hl.Bytes(bytes + 2);
		b.blit(0, Mem.b, src.toInt(), bytes);
		b.setUI16(bytes, 0);
		return String.__alloc__(b, bytes >> 1);
	#elseif flash
		Mem.b.position = src.toInt();
		return Mem.b.readMultiByte(bytes, "unicode");
	#elseif (js && js_es >= 5)
		var max = src + bytes;
		var ucs = src;
		while (ucs < max) {
			if (ucs.getUI16() == 0) break;
			ucs += 2;
		}
		bytes = Ut.imin(bytes, ucs - src);
		return js.Syntax.code("String.fromCharCode.apply(null, {0})",
			new js.lib.Int16Array(Mem.b.b.buffer.slice(src.toInt(), src.toInt() + bytes))
		);
	#else
		var utf8 = new haxe.Utf8(mem.Utf8.ofUcs2(Ptr.NUL, src, wlen));
		var max = src + bytes;
		while (src < max) {
			var c = src.getUI16();
			if (c == 0) {
				break;
			} else if (c >= 0xD800 && c <= 0xDFFF) {
				src += 2;
				c = (((c - 0xD800) << 10) | (src.getUI16() - 0xDC00)) + 0x10000;
			}
			utf8.addChar(c);
			src += 2;
		}
		return utf8.toString();
	#end
	}

	/**
	* @param out: ucs2 ptr
	* @param wlen: limit the number of wchar_t(UCS2) written to out.
	* @param src:
	* @return number of wchar_t(UCS2) written to out, not including the eventual ending null-character.
	*/
	static public function ofString(out: Ptr, wlen: Int, src: String): Int @:privateAccess {
	#if !utf16
		inline function char(i) return StringTools.fastCodeAt(src, i);
		var bytes = src.length;
		var i = 0;
		var c: Int;
		if (out == Ptr.NUL) {
			var len = 0;
			while (i < bytes) {
				c = char(i);
				if ( c < 0x80 ) {
					++ i;
				} else if ( c < 0xC0 ) {
					break;
				} else if ( c < 0xE0 ) {
					if ( char(i+1) & 0x80 == 0 ) break;
					i += 2;
				} else if ( c < 0xF0 ) {
					if ( char(i+1) & char(i+2) & 0x80 == 0 ) break;
					i += 3;
				} else {
					if ( char(i+1) & char(i+2) & char(i+3) & 0x80 == 0 ) break;
					i += 4;
					len += 2;
					continue;
				}
				++ len;
			}
			return len;
		} else {
			var ucs = out;
			var c2: Int, c3: Int, c4: Int;
			while (i < bytes) {
				c = char(i);
				if ( c < 0x80 ) {
					++ i;
				} else if ( c < 0xC0 ) {
					break;
				} else if ( c < 0xE0 ) {
					c2 = char(i + 1);
					if (c2 & 0x80 == 0) break;
					c = ((c & 0x3F) << 6) | (c2 & 0x7F);
					i += 2;
				} else if ( c < 0xF0 ) {
					c2 = char(i + 1);
					c3 = char(i + 2);
					if ( c2 & c3 & 0x80 == 0 ) break;
					c = ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | (c3 & 0x7F);
					i += 3;
				} else {
					c2 = char(i + 1);
					c3 = char(i + 2);
					c4 = char(i + 3);
					if ( c2 & c3 & c4 & 0x80 == 0 ) break;
					c = ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 & 0x7F) << 6) | (c4 & 0x7F);
					ucs.setI16((c >> 10) + 0xD7C0);
					(ucs + 2).setI16((c & 0x3FF) + 0xDC00);
					ucs += 4;
					i += 4;
					continue;
				}
				ucs.setI16(c);
				ucs += 2;
			}
			return (ucs - out) >> 1;
		}
	#else
		var len = src.length;
		if (out == Ptr.NUL) {
			return len;
		} else {
			var min = Ut.imin(len, wlen);
		#if hl
			Mem.b.blit(out.toInt(), src.bytes, 0, min << 1);
		#elseif flash
			if (wlen < len) src = src.substr(0, wlen);
			Mem.b.position = out.toInt();
			Mem.b.writeMultiByte(src, "unicode");
		#else
			var i = 0;
			var p = out.toInt();
			while (i < min) {
				var c = StringTools.fastCodeAt(src, i);
				Memory.setByte(p++, c & 0xff);
				Memory.setByte(p++, c >> 8);
				++ i;
			}
		#end
			if (wlen > len)
				(out + (len << 1)).setI16(0);
			return min;
		}
	#end
	}
}