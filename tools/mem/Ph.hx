package mem;

import mem.Ptr;

/**
PtrHelper
*/
#if cpp
@:nativeGen @:headerCode("#define Ph_hx Ph_hx_obj") @:native("mem.Ph_hx")
#end
class Ph{
	// [a,b,c,d] = [d,c,b,a] in bytes
	static public function reverse(ptr:Ptr, len:Int):Void {
		var left: Int = ptr;
		var right:Int = left + len - 1;
		var c:Int;
		while (left < right) {
			c = Memory.getByte(left);
			Memory.setByte(left, Memory.getByte(right));
			Memory.setByte(right, c);
		++left;
		--right;
		}
	}

	static public function crc32(ptr:Ptr, len:Int):Int {
		var init = 0xFFFFFFFF;
		var crc = init;
		for (i in 0...len) {
			var tmp = (crc ^ ptr[i]) & 0xFF;
			for (j in 0...8) {
				if (tmp & 1 == 1)
					tmp = (tmp >>> 1) ^ 0xEDB88320;
				else
					tmp >>>= 1;
			}
			crc = (crc >>> 8) ^ tmp;
		}
		return crc ^ init;
	}

	static public function adler32(ptr:Ptr, len:Int):Int {
		var a = 1, b = 0, i = 0;
		while (i < len) {
			a = (a + ptr[i]) % 65521;
			b = (b + a) % 65521;
		++i;
		}
		return (b << 16) | a;
	}


	/////////////////////////////


	static public function toAscii(ptr: Ptr, len:Int): String {
	#if flash
		@:privateAccess @:mergeBlock {
			Ram.current.position = ptr;
			return Ram.current.readMultiByte(len, "us-ascii");
		}
	#elseif (neko || cpp || lua)
		return Ram.readUTFBytes(ptr, len);
	#elseif (js && (js_es > 3))
		return untyped __js__("String.fromCharCode.apply(null, {0})", Memory.b.b.slice(ptr, ptr + len));
	#else
		var buf = new StringBuf();
		for (i in 0...len){
			buf.addChar(ptr[i]);
		}
		return buf.toString();
	#end
	}

	// fast sort
	public static function sortU8(left:Int, right:Int, a:AU8):Void {
		Mt.qsort(sortU8);
	}

	public static function sortI32(left:Int, right:Int, a:AI32):Void {
		Mt.qsort(sortI32);
	}

}