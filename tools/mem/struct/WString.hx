package mem.struct;

import mem.Ptr;
import mem.Malloc.NUL;
import mem.struct.Comm.*;

abstract WString(Ptr) to Ptr {

	public var length(get, never): Int;
	private inline function get_length() return Memory.getI32(realEntry());

	public var addr(get, never): Ptr;
	private inline function get_addr() return this;

	private inline function new(addr: Ptr) this = cast addr;

	public inline function realEntry(): Ptr { return this - BY_LEN; }

	public inline function free(): Void { Ram.free( realEntry() ); this = NUL; }

	public inline function toString(): String return Ram.readUTFBytes(this, length);
}

class WStrImpl {

	public static function fromString(str:String):WString {
		var addr:Ptr;
		var base:Ptr;
		var length:Int;
	#if (neko || cpp || lua) // have not utf
		length = str.length;
		addr = Ram.malloc(length + BY_LEN + 1, false);
		Ram.writeString(addr + BY_LEN, length, str);
	#else
		var ba = writeString(str);
		length = ba.length;
		addr = Ram.malloc(length + BY_LEN + 1, false);
		Ram.writeBytes(addr + BY_LEN, length, ba);
	#end
		Memory.setI32(addr, length);
		base = addr + BY_LEN;
		Memory.setByte(base + length, 0);
		return @:privateAccess new WString(base);
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