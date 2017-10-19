package raw;

import raw.Ptr;

@idx(2, "&") abstract Ucs2(Ptr) to Ptr {

	public inline function getString(max: Int): String {
		return tostr(this, max);
	}

	// bytesLength used for limit the length
	public inline function setString(str: String, max = Raw.SMAX): Int {
		return ofstr(this, str, max);
	}

	@:arrayAccess inline function get(i: Int):Int return Memory.getUI16(this + (i + i)); // (i + i) same as (i << 1)
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setI16(this + (i + i), v);

	// "max" of bytes to write to out;
	public static function ofstr(out: Ptr, str: String, max: Int): Int @:privateAccess {
		var len = haxe.Utf8.length(str);
		if (out == Ptr.NUL) return len << 1;
		max = Ut.imin(max, len << 1);
	#if js
		var u8 = Raw.current.b;
		var i = 0, code = 0;
		while (i < max) {
			code = StringTools.fastCodeAt(str, i >> 1);
			u8[out.toInt() + i++] = code & 0xff;
			u8[out.toInt() + i++] = code >> 8;
		}
	#elseif flash
		Raw.current.b.position = out.toInt();
		if (len > (max >> 1)) str = str.substr(0, max >> 1);
		Raw.current.b.writeMultiByte(str, "unicode");
	#elseif hl
		var hlb = str.bytes;
		Raw.current.b.blit(out.toInt(), hlb, 0, max);
	#else
		if (len > (max >> 1)) str = haxe.Utf8.sub(str, 0, max >> 1);
		haxe.Utf8.iter(str, function (code){
			Memory.setI16(out, code);
			out += 2;
		});
	#end
		return max;
	}

	// read str from (ptr + size)
	public static function tostr(ptr: Ptr, size: Int): String @:privateAccess {
	#if js
		return untyped __js__("String.fromCharCode.apply(null, {0})",
			new js.html.Int16Array(Raw.current.b.buffer.slice(ptr.toInt(), ptr.toInt() +  size))
		);
	#elseif flash
		Raw.current.b.position = ptr.toInt();
		return Raw.current.b.readMultiByte(size, "unicode");
	#elseif hl
		var hlb = new hl.Bytes(size + 2);
		hlb.blit(0, Memory.b, ptr.toInt(), size);
		hlb.setUI16(size, 0);
		return String.__alloc__(hlb, size >> 1);
	#else
		var len = Utf8.ofucs2(Ptr.NUL, ptr, size);
		var utf8 = new haxe.Utf8(len + 1);
		var i = 0;
		while (size - i > 1) {
			utf8.addChar(Memory.getUI16(ptr + i));
			i += 2;
		}
		utf8.addChar(0);
		return utf8.toString();
	#end
	}
}