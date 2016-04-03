package mem.struct;

import mem.Malloc;
import mem.Ptr;

class WString implements mem.Struct{

	@idx(2) var length:Int;

	public inline function new(str:String){
		var ba = writeString(str);
		addr = Malloc.make(ba.length + CAPACITY, true);
		length = ba.length;
		Ram.writeBytes(c_ptr, ba.length, ba);
		#if flash
			ba.clear();
		#end
	}

	public var c_ptr(get, never):Ptr;
	inline function get_c_ptr():Ptr return addr + CAPACITY;

	public inline function toString():String{
		return Ram.readUTFBytes(c_ptr, length);
	}

#if flash
	static var tmpb = new flash.utils.ByteArray();

	static public function writeString(s:String):flash.utils.ByteArray{
		tmpb.writeUTFBytes(s);
		tmpb.position = 0;
		return tmpb;
	}
#else
	static public function writeString(s:String):haxe.io.Bytes return haxe.io.Bytes.ofString(s);
#end
}