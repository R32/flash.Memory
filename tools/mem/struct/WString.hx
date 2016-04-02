package mem.struct;

import mem.Malloc;
import mem.Ptr;

#if !macro
@:build(mem.Struct.StructBuild.make())
#end
abstract WString(Ptr){
	@idx var length:Int;
	public inline function new(str:String){
		this = Malloc.NUL;		// error if not hove this line: mission this = value;
		var ba = WStrHelps.writeString(str);
		length = ba.length;
		this = Malloc.make(ba.length + CAPACITY, true);
		Ram.writeBytes(this, ba.length, ba);
		#if flash
			ba.clear();
		#end
	}

	public inline function toString():String{
		return Ram.readUTFBytes(this, length);
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