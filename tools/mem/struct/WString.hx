package mem.struct;

import mem.Ptr;
import mem.Malloc.NUL;

/**
Utf8 String
*/
@:build(mem.Struct.StructBuild.make())
abstract WString(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;

	/**
	bytesLength, you can use mem.Utf8.length to calculate length of Utf8
	*/
	public var length(get, never): Int;

	private inline function get_length() return _len;

	public inline function toString(): String return Ram.readUTFBytes(this, length);

	private inline function new(len: Int) {
		mallocAbind(len + CAPACITY + 1, false);
		_len = len;
		this[len] = 0;
	}

	/////////////// static ///////////////

	public static function fromString(str:String):WString @:privateAccess {
	#if (neko || cpp || lua) // have not utf
		var length = str.length;
		var ws = new WString(length);
		Ram.writeString(ws, length, str);
	#elseif hl
		var length = 0;
		var b = str.bytes.utf16ToUtf8(0, length);
		var ws = new WString(length);
		Ram.current.b.blit(ws, b, 0, length);
	#else
		var ba = writeString(str);
		var length = ba.length;
		var ws = new WString(length);
		Ram.writeBytes(ws, length, ba);
	#end
		return ws;
	}

#if flash
	static var tba:flash.utils.ByteArray;
	static function writeString(s:String): flash.utils.ByteArray {
		if (tba == null) tba = new flash.utils.ByteArray();
		tba.clear();
		tba.writeUTFBytes(s);
		return tba;
	}
#else
	static function writeString(s:String):haxe.io.Bytes return haxe.io.Bytes.ofString(s);
#end
}
