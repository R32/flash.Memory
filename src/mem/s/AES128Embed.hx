package mem.s;

import mem.Ptr;

#if !macro
@:build(mem._macros.AES128EmbedMacros.build())
#end
class AES128Embed {

	static var b: mem.s.Block = cast Ptr.NUL;

	public static function init() @:privateAccess {
		if (b == Ptr.NUL) {
			b = Mem.mallocFromBytes(haxe.Resource.getBytes(_R)); // _R defined by macro
		}
		if (AES128.aes == Ptr.NUL)
			AES128.init();
		Mem.memcpy(@:privateAccess AES128.aes, b, 176 + 4);      // override "roundKey" + "tempa"
	}

	static public function destory() {
		b.free();
		b = cast Ptr.NUL;
	}

	public static inline function cbcEncryptBuff(input: Ptr, output: Ptr, length:Int, iv:Ptr): Void {
		AES128.cbcEncryptBuff(input, Ptr.NUL, output, length, iv);
	}

	public static inline function cbcDecryptBuff(input: Ptr, output: Ptr, length:Int, iv:Ptr): Void {
		AES128.cbcDecryptBuff(input, Ptr.NUL, output, length, iv);
	}
}