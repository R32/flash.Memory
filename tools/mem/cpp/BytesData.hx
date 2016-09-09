package mem.cpp;

import cpp.RawPointer;
import cpp.Pointer;
import cpp.Star;

@:unreflective
@:include("./lib/BData.h")
@:sourceFile("./lib/BData.cpp")
@:native("mem::BData")
extern class BytesData {

	var length(get, never): Int;
	@:native("Length") private function get_length(): Int;

	var U8(get, never): RawPointer<cpp.UInt8>;
	@:native("U8") private function get_U8(): RawPointer<cpp.UInt8>;

	var U16(get, never): RawPointer<cpp.UInt16>;
	@:native("U16") private function get_U16(): RawPointer<cpp.UInt16>;

	var I32(get, never): RawPointer<cpp.Int32>;
	@:native("I32") private function get_I32(): RawPointer<cpp.Int32>;

	public var I64(get, never): RawPointer<cpp.Int64>;
	@:native("I64") function get_I64(): RawPointer<cpp.Int64>;

	var F4(get, never): RawPointer<cpp.Float32>;
	@:native("F4") private function get_F4(): RawPointer<cpp.Float32>;

	var F8(get, never): RawPointer<cpp.Float64>;
	@:native("F8") private function get_F8(): RawPointer<cpp.Float64>;


	@:native("U8") function star(): cpp.Star<cpp.UInt8>;
	@:native("Cs") function cs(): cpp.Star<cpp.Char>;

	// will copy old data to malloc(len)
	function resize(len: Int):Void;
	function blit(pos:Int, src: Star<BytesData>, srcpos:Int, len: Int):Void;
	function fill(pos: Int, len: Int, value: cpp.UInt8):Void;

	@:native("new mem::BData") static function create(len:Int):Pointer<BytesData>;

	@:native("new mem::BData") static function createStar(len:Int):Star<BytesData>;

	@:native("mem::BData::destory") static function destory(bs: Star<BytesData>):Void;

	function get(p: Int): cpp.UInt8;
	function set(p: Int, v:cpp.UInt8): Void;

	function getDouble(p: Int): cpp.Float64;
	function setDouble(p: Int, v:cpp.Float64): Void;

	function getFloat(p: Int): cpp.Float32;
	function setFloat(p: Int, v:cpp.Float32): Void;

	function getUInt16(p: Int): cpp.UInt16;
	function setUInt16(p: Int, v:cpp.UInt16): Void;

	function getInt32(p: Int): cpp.Int32;
	function setInt32(p: Int, v:cpp.Int32): Void;

	function getInt64(p: Int): cpp.Int64;
	function setInt64(p: Int, v:cpp.Int64): Void;

	// will be delete this->b;
	function removeData():Void;
}