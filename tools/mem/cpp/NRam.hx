package mem.cpp;


import cpp.RawPointer;
import mem.cpp.BytesData;

@:unreflective
@:include("cstring")
extern class NRam {
	@:native("::memcpy")
	static function memcpy(dst: RawPointer<cpp.Void>, src: RawPointer<cpp.Void>, len: Int): Void;

	@:native("::memcmp")
	static function memcmp(dst: RawPointer<cpp.Void>, src: RawPointer<cpp.Void>, len: Int): Int;

	@:native("::strlen")
	static function strlen(dst: RawPointer<cpp.Char>): Int;

	@:native("::memset")
	static function memset(dst: RawPointer<cpp.Void>, value: cpp.UInt8, num: Int):Void;
}