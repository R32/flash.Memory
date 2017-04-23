package mem.struct;

import mem.Ptr;

// ascii string
@:build(mem.Struct.make())
abstract AString(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;

	public var length(get, never): Int;

	private inline function get_length() return _len;

	public inline function toString(): String return Ph.toAscii(this, length);

	private inline function new(len: Int) {
		mallocAbind(len + CAPACITY + 1, false);
		_len = len;
		this[len] = 0;
	}

	@:arrayAccess inline function get(i: Int):Int return Memory.getByte((this:Int) + i);
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setByte((this:Int) + i, v);

	/////////////// static ///////////////

	public static function alloc(len: Int):AString {

		return new AString(len);
	}

	// if str contains the utf-characters, the result is unspecified.
	public static function fromString(str:String):AString @:privateAccess {
		var sa = alloc(str.length);
	#if flash
		Fraw.current.position = sa;
		Fraw.current.writeMultiByte(str, "us-ascii");
	#elseif hl
		var size = 0;
		var b = str.bytes.utf16ToUtf8(0, size);
		Fraw.current.b.blit(sa, b, 0, str.length);
	#elseif (neko || cpp || lua)
		Fraw.writeUTFBytes(sa, str);
	#else
		for (i in 0...sa.length)
			sa[i] = StringTools.fastCodeAt(str, i);
	#end
		return sa;
	}

	public static function fromHexString(hex:String):AString {
		var len = hex.length >> 1;
		var sa = alloc(len);
		var j:Int;
		for (i in 0...len){
			j = i + i;
			sa[i] = Std.parseInt("0x" + hex.charAt(j) + hex.charAt(j + 1) );
		}
		return sa;
	}
}
