package mem.struct;

import mem.Ptr;

class AString implements Struct{

	@idx(2) var length:Int;				// MAX 65536

	public inline function new(len:Int) {
		addr = Malloc.make(len + CAPACITY + 1, false);
		length = len;
	}

	public var c_ptr(get, never):Ptr;
	inline function get_c_ptr():Ptr return addr + CAPACITY;


#if flash
	public inline function toString(){
		@:privateAccess {
			Ram.current.position = c_ptr;
			return Ram.current.readMultiByte(length, "us-ascii");
		}
	}
#else
	public function toString(){
		var cc = c_ptr;
		var buf = new StringBuf();
		for (i in 0...length){
			buf.addChar(Memory.getByte(cc + i));
		}
		return buf.toString();
	}
#end

	public static function fromString(str:String):AString{
		var astr = new AString(str.length);
		var length = str.length;
	#if flash
		@:privateAccess {
			Ram.current.position = astr.c_ptr;
			Ram.current.writeMultiByte(str, "us-ascii");
		}
	#else
		var cc = astr.c_ptr;
		for(i in 0...length){
			Memory.setByte(cc + i, StringTools.fastCodeAt(str, i));
		}
	#end
		Memory.setByte(astr.c_ptr + length + 1, 0);
		return astr;
	}
}
