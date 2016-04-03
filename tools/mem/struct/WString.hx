package mem.struct;

import mem.Malloc;
import mem.Ptr;

#if !macro
@:build(mem.Struct.StructBuild.make())
#end
abstract WString(Ptr){
	@idx(4) var length:Int;
	public inline function new(str:String){
		this = Malloc.NUL;		// error if not hove this line: mission this = value;
		var ba = WStrHelps.writeString(str);
		this = Malloc.make(ba.length + CAPACITY, true);
		length = ba.length;
		Ram.writeBytes(this + CAPACITY, ba.length, ba);
		#if flash
			ba.clear();
		#end
	}

	public var c_ptr(get, never):Ptr;
	inline function get_c_ptr():Ptr return this + CAPACITY;

	public inline function toString():String{
		return Ram.readUTFBytes(c_ptr, length);
	}
}

private class WStrHelps{
#if flash
	static var tmpb = new flash.utils.ByteArray();

	static public function writeString(s:String):flash.utils.ByteArray{
		tmpb.writeUTFBytes(s);
		tmpb.position = 0;
		return tmpb;
	}
#else
	static public function writeString(s:String):haxe.io.Bytes{
		return haxe.io.Bytes.ofString(s);
	}
#end
}