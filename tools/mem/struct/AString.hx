package mem.struct;

import mem.Ptr;

class AString{

	public var length(default, null):Int;
	public var addr(default, null):Ptr;

	public function new(len:Int) {
		addr = Malloc.make(len + 1, false);
		length = len;
		Memory.setByte(addr + len, 0);
	}

	public inline function free():Void {
		Malloc.free(addr);
		addr = Malloc.NUL;
	};

	public function toString() {
	#if flash
		@:privateAccess @:mergeBlock{
			Ram.current.position = addr;
			return Ram.current.readUTFBytes(length);
		}
	#elseif (neko || cpp || lua)
		return Ram.readUTFBytes(addr, length);
	#else
		var cc = addr;
		var buf = new StringBuf();
		for (i in 0...length){
			buf.addChar(Memory.getByte(cc + i));
		}
		return buf.toString();
	#end
	}

	public static function fromString(str:String): AString{
		var sa = new AString(str.length);
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

	public static function fromHexString(hex:String):AString{
		var len = hex.length >> 1;
		var sa = new AString(len);
		var j:Int;
		for (i in 0...len){
			j = i + i;
			Memory.setByte(sa.addr + i, Std.parseInt("0x" + hex.charAt(j) + hex.charAt(j + 1) ));
		}
		return sa;
	}
}
