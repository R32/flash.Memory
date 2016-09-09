package mem.cpp;


import cpp.Star;
import mem.cpp.BytesData;

@:unreflective
@:include("cstring")
extern class NRam {
	@:native("::memcpy")
	static function memcpy(dst: Star<cpp.Char>, src: Star<cpp.Char>, len: Int): Void;

	@:native("::memcmp")
	static function memcmp(dst: Star<cpp.Char>, src: Star<cpp.Char>, len: Int): Int;

	@:native("::strlen")
	static function strlen(dst: Star<cpp.Char>): Int;

	@:native("::memset")
	static function memset(dst: Star<cpp.Char>, value: cpp.UInt8, num: Int):Void;
}