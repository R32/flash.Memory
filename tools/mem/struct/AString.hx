package mem.struct;

import mem.Ptr;
import mem.Malloc.NUL;

@:build(mem.Struct.StructBuild.make())
abstract AString(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;

	public var length(get, never): Int;
	public var addr(get, never): Ptr;  // legacy

	private inline function get_length() return _len;
	private inline function get_addr() return this;

	public inline function toString(): String return Ph.toAscii(this, length);

	private inline function new(len: Int) {
		mallocAbind(len + CAPACITY + 1, false);
		_len = len;
		this[len] = 0;
	}

	@:arrayAccess inline function get(i: Int):Int return Memory.getByte((this:Int) + i);
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setByte((this:Int) + i, v);
}

class AStrImpl {

	public static function alloc(len: Int):AString {
		return @:privateAccess new AString(len);
	}

	// if str contains the utf-characters, the result is unspecified.
	public static function fromString(str:String):AString @:privateAccess {
		var sa = alloc(str.length);
	#if flash
		Ram.current.position = sa;
		Ram.current.writeMultiByte(str, "us-ascii");
	#elseif hl
		var size = 0;
		var b = str.bytes.utf16ToUtf8(0, size);
		Ram.current.b.blit(sa, b, 0, str.length);
	#elseif (neko || cpp || lua)
		Ram.writeUTFBytes(sa, str);
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
