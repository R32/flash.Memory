package mem.struct;

import mem.Ptr;
import mem.Malloc.NUL;
import mem.struct.AString.AStrImpl.PADD;

abstract AString(Ptr) to Ptr {

	public var length(get, never): Int;
	private inline function get_length() return Memory.getI32((this:Int) - PADD);

	public var addr(get, never): Ptr;
	private inline function get_addr() return this;

	private inline function new(addr: Ptr) this = cast addr;

	public inline function free(): Void { Ram.free(cast ((this:Int) - PADD)); this = NUL; }

	public inline function toString(): String return Ph.toAscii(this, length);
}

class AStrImpl {

	public static inline var PADD = 4; // for variable length

	public static function alloc(len: Int):AString {
		var addr = Ram.malloc(len + PADD + 1);
		Memory.setI32(addr, len);
		Memory.setByte(addr + len + PADD, 0);
		return @:privateAccess new AString(addr + PADD);
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
		for(i in 0...sa.length){
			Memory.setByte(sa.addr + i, StringTools.fastCodeAt(str, i));
		}
	#end
		return sa;
	}

	public static function fromHexString(hex:String):AString {
		var len = hex.length >> 1;
		var sa = alloc(len);
		var j:Int;
		for (i in 0...len){
			j = i + i;
			Memory.setByte(sa.addr + i, Std.parseInt("0x" + hex.charAt(j) + hex.charAt(j + 1) ));
		}
		return sa;
	}
}
