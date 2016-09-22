package mem.struct;

import mem.Ptr;
import mem.Malloc.NUL;
import mem.struct.Comm.*;

abstract AString(Ptr) to Ptr {

	public var length(get, never): Int;
	private inline function get_length() return Memory.getI32(realEntry());

	public var addr(get, never): Ptr;
	private inline function get_addr() return this;

	private inline function new(addr: Ptr) this = cast addr;

	public inline function realEntry(): Ptr { return this - BY_LEN; }

	public inline function free(): Void { Ram.free( realEntry() ); this = NUL; }

	public inline function toString(): String return Ph.toAscii(this, length);
}

class AStrImpl {

	public static function alloc(len: Int):AString {
		var addr = Ram.malloc(len + BY_LEN + 1);
		Memory.setI32(addr, len);
		Memory.setByte(addr + len + BY_LEN, 0);
		return @:privateAccess new AString(addr + BY_LEN);
	}

	public static function fromString(str:String):AString {
		var sa = alloc(str.length);
	#if flash
		@:privateAccess {
			Ram.current.position = sa.addr;
			Ram.current.writeMultiByte(str, "us-ascii");
		}
	#elseif (neko || cpp || lua)
		Ram.writeUTFBytes(sa.addr, str);
	#else
		for (i in 0...sa.length)
			sa.addr[i] = StringTools.fastCodeAt(str, i);
	#end
		return sa;
	}

	public static function fromHexString(hex:String):AString {
		var len = hex.length >> 1;
		var sa = alloc(len);
		var j:Int;
		for (i in 0...len){
			j = i + i;
			sa.addr[i] = Std.parseInt("0x" + hex.charAt(j) + hex.charAt(j + 1) );
		}
		return sa;
	}
}
