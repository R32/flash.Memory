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
			AES128.init(Ptr.NUL);
		Mem.memcpy(@:privateAccess AES128.aes, b, 176 + 4);      // override "roundKey" + "tempa"
	}

	static public function destory() {
		if (b != Ptr.NUL) {
			b.free();
			b = cast Ptr.NUL;
		}
	}
}