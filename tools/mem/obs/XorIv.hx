package mem.obs;

import mem.Ptr;
import mem.Ut;

class XorIv {

	var iv: Ptr;

	private function new() {
		iv = Fraw.malloc(16, false);
	}

	public function encrypt(dst: Ptr, src: Ptr, len: Int): Void {
		if (src == dst || Ut.inZone(src, dst, len)) throw haxe.io.Error.OutsideBounds;
		Fraw.memcpy(dst, src, len);
		xor(dst, src, len);
	}

	// dst == src is allowed
	public function decrypt(dst: Ptr, src: Ptr, len: Int): Void {
		if (Ut.inZone(src, dst, len)) throw haxe.io.Error.Overflow;
		xor(dst, src, len);
	}

	function xor(dst: Ptr, src: Ptr, len: Int): Void {
		var i = 0;
		// xor with IV
		#if (flash || hl || cpp)
		if (i < IV_SIZE) {
			Memory.setI32(dst + i, Memory.getI32(src + i) ^ Memory.getI32(iv + i));
		i += 4;
		}
		#end
		while (i < IV_SIZE) {
			Memory.setByte(dst + i, Memory.getByte(src + i) ^ Memory.getByte(iv + i));
		++ i;
		}

		// xor with src
		#if (flash || hl || cpp)
		var b4 = len - (len & (4 - 1));
		while (i < b4) {
			Memory.setI32(dst + i, Memory.getI32(dst + i) ^ Memory.getI32(src));
		i   += 4;
		src += 4;
		}
		#end
		while (i < len) {
			Memory.setByte(dst + i, Memory.getByte(dst + i) ^ Memory.getByte(src));
		++ src;
		++ i;
		}
	}

	static inline var IV_SIZE = 16;

	public static function fromHexString(hex: String): XorIv {
		var ret = new XorIv();
		var len = hex.length >> 1;
		var j:Int;
		for (i in 0...len){
			j = i + i;
			ret.iv[i] = Std.parseInt("0x" + hex.charAt(j) + hex.charAt(j + 1) );
		}
		return ret;
	}

	public static function fromBytes(b: haxe.io.Bytes): XorIv {
		var ret = new XorIv();
		#if flash
		Fraw.writeBytes(ret.iv, 16, b.getData());
		#else
		Fraw.writeBytes(ret.iv, 16, b);
		#end
		return ret;
	}
}