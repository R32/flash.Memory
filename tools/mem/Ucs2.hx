package mem;

import mem.Ptr;

@idx(2, "&") abstract Ucs2(Ptr) to Ptr {

	public function getString(bytesLength: Int): String @:privateAccess {
	#if js
		return untyped __js__("String.fromCharCode.apply(null, {0})",
			new js.html.Int16Array(Memory.b.b.buffer.slice(this, (this: Int) +  bytesLength))
		);
	#elseif flash
		Fraw.current.position = this;
		return Fraw.current.readMultiByte(bytesLength, "unicode");
	#elseif hl
		var hlb = new hl.Bytes(bytesLength + 2);
		hlb.blit(0, Memory.b, this, bytesLength);
		hlb.setUI16(bytesLength, 0);
		return String.__alloc__(hlb, bytesLength >> 1);
	#else
		var utf8 = new haxe.Utf8((bytesLength >> 1) + 1);
		var pos:Int = cast this;
		var end = pos + bytesLength;
		while (pos < end) {
			utf8.addChar(Memory.getUI16(pos));
			pos += 2;
		}
		utf8.addChar(0);
		return utf8.toString();
	#end
	}

	// bytesLength used for limit the length
	public function setString(str: String, bytesLength: Int = 0): Void @:privateAccess {
		var size = haxe.Utf8.length(str) << 1;
		if (bytesLength == 0)
			bytesLength = size;
		else
			bytesLength = Ut.imin(size, bytesLength);

	#if js
		var u8 = Memory.b.b;
		var code = 0, i = 0;
		while (i < bytesLength) {
			code = str.charCodeAt(i >> 1);
			u8[(this:Int) + i++] = code & 0xff;
			u8[(this:Int) + i++] = code >> 8;
		}
	#elseif flash
		Fraw.current.position = this;
		if (str.length > (bytesLength >> 1)) str = str.substr(0, bytesLength >> 1);
		Fraw.current.writeMultiByte(str, "unicode");
	#elseif hl
		var hlb = str.bytes;
		Memory.b.blit(this, hlb, 0, bytesLength);
	#else
		size = bytesLength >> 1;
		var i = 0;
		while (i < size) {
			Memory.setI16(this + (i << 1), haxe.Utf8.charCodeAt(str, i));
			++ i;
		}
	#end
	}

	@:arrayAccess inline function get(i: Int):Int return Memory.getUI16((this:Int) + (i + i)); // (i + i) same as (i << 1)
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setI16((this:Int) + (i + i), v);

	public static inline function fromPtr(ptr: Ptr): Ucs2 return cast ptr;
}