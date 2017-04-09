package mem.cpp;


@:unreflective
@:include("./lib/utf2gbk/utf8.h")
@:sourceFile("./lib/utf2gbk/utf8.c")
private extern class NativeGbk {
	@:native("::utf8_to_gb")
	static function utf8_to_gb(src: cpp.RawConstPointer<cpp.Char>, dst: cpp.RawPointer<cpp.Char>, len: Int): Void;
}

// 如果你的 cpp 类只有静态方法, 没有其它的属性, 可以使用 @:nativeGen（防止定义的类继承 GC） + @:headerCode（简单 Hack）,
class Gbk{
	static public function u2Gbk(ustr: String): String {

		var len = ustr.length;

		// 从 GC 申请内存, 让 Gc 自动处理内存释放
		var output:cpp.Pointer<cpp.Char> = cast cpp.NativeGc.allocGcBytes(len);

		NativeGbk.utf8_to_gb(cpp.NativeString.raw(ustr), cast output.raw, len);
		// 新建的字符串, 将与 output 共享内存, 而不是重建复本.
		// 并且重新检测转换后的字符长度. 使字符串加减正常
		return cpp.NativeString.fromGcPointer(cast output, untyped __cpp__("::strlen((char*){0})", output.raw));
	}
}