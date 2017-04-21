package mem;

import mem.Ptr;

abstract Ucs2(Ptr) to Ptr {

	public function toString(): String @:privateAccess {
	#if (js || flash || hl)
		var end:Int = cast this;
		while (Memory.getUI16(end) != 0) end += 2;
	#end

	#if js
		return untyped __js__("String.fromCharCode.apply(null, {0})",
			new js.html.Int16Array(Memory.b.b.buffer.slice(this, end))
		);
	#elseif flash
		Ram.current.position = this;
		return Ram.current.readMultiByte( end - (this:Int), "unicode");
	#elseif hl
		var bytesLength = end - (this:Int);
		var hlb = new hl.Bytes(bytesLength + 2);
		hlb.blit(0, Memory.b, this, bytesLength);
		hlb.setUI16(bytesLength, 0);
		return String.__alloc__(hlb, bytesLength >> 1);
	#else
		var utf8 = new haxe.Utf8();
		var pos:Int = cast this;
		while (true) {
			var code = Memory.getUI16(pos);
			if (code == 0) break;
			utf8.addChar(code);
			pos += 2;
		}
		return utf8.toString();
	#end
	}

	// unsafe
	public function copyfromString(str: String): Void @:privateAccess {
	#if js
		var bytesLength = str.length << 1;
		var u8 = Memory.b.b;
		var code = 0, i = 0;
		while (i < bytesLength) {
			code = str.charCodeAt(i >> 1);
			u8[(this:Int) + i++] = code & 0xff;
			u8[(this:Int) + i++] = (code >> 8) & 0xff;
		}
		u8[(this:Int) + i++] = 0;
		u8[(this:Int) + i++] = 0;
	#elseif flash
		Ram.current.position = this;
		Ram.current.writeMultiByte(str, "unicode");
		Ram.current.writeShort(0);
	#elseif hl
		var bytesLength = str.length << 1;
		var hlb = str.bytes;
		Memory.b.blit(this, hlb, 0, bytesLength);
		Memory.b.setUI16((this:Int) + bytesLength, 0);
	#else
		var bytesLength = haxe.Utf8.length(str) << 1;
		var pos:Int = cast this;
		haxe.Utf8.iter(str, function(code) {
			Memory.setI16(pos, code);
			pos += 2;
		} );
	#end
	}

	@:arrayAccess inline function get(i: Int):Int return Memory.getUI16((this:Int) + (i + i)); // (i + i) same as (i << 1)
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setI16((this:Int) + (i + i), v);

	public static inline function fromPtr(ptr: Ptr): Ucs2 return cast ptr;
}