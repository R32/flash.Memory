package mem.obs;

import mem.Ptr;

#if !macro
@:build(mem.obs._macros.AES128EmbedMacros.build())
#end
class AES128Embed {

	static var b: Ptr;

	public static function init() {
		if (b == Ptr.NUL)
			b = Fraw.mallocFromBytes(haxe.Resource.getBytes(_R)); // _R defined by macro
		AES128.init();
		Fraw.memcpy(@:privateAccess AES128.aes, b, 176 + 4);      // override "roundKey" + "tempa"
	}

	public static inline function cbcEncryptBuff(input: Ptr, output: Ptr, length:Int, iv:Ptr): Void {
		AES128.cbcEncryptBuff(input, Ptr.NUL, output, length, iv);
	}

	public static inline function cbcDecryptBuff(input: Ptr, output: Ptr, length:Int, iv:Ptr): Void {
		AES128.cbcDecryptBuff(input, Ptr.NUL, output, length, iv);
	}
}