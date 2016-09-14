package mem.struct;

import mem.Malloc;
import mem.Ptr;

class WString {

	public var length(default, null):Int;

	public var addr(default, null):Ptr;

	public function new(str:String) {

	#if (neko || cpp || lua) // it's not utf
		length = str.length;
		addr = Malloc.make(length + 1, false);
		Ram.writeString(addr, length, str);
	#else
		var ba = writeString(str);
		addr = Malloc.make(ba.length, false);
		length = ba.length;
		Ram.writeBytes(addr, length, ba);
		#if flash
			ba.clear();
		#end
	#end
		Memory.setByte(addr + length, 0);
	}

	public inline function free():Void {
		Malloc.free(this.addr);
		addr = Malloc.NUL;
	}

	public inline function toString(): String {
		return Ram.readUTFBytes(addr, length);
	}

#if flash
	static var tmpb = new flash.utils.ByteArray();

	static function writeString(s:String): flash.utils.ByteArray{
		tmpb.writeUTFBytes(s);
		tmpb.position = 0;
		return tmpb;
	}
#else
	static function writeString(s:String):haxe.io.Bytes return haxe.io.Bytes.ofString(s);
#end
}