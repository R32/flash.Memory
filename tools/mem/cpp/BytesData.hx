package mem.cpp;

import cpp.RawPointer;
import cpp.Pointer;
import cpp.Star;

@:structAccess
@:include("./lib/BData.h")
@:sourceFile("./lib/BData.cpp")
@:native("mem::BData")
extern class BytesData {

	var length(get, never): Int;
	@:native("Length") private function get_length(): Int;

	@:native("Offset") function offset(dx: Int): cpp.RawPointer<cpp.Void>;

	// will copy old data to malloc(len)
	function resize(len: Int):Void;
	function blit(pos:Int, src: Star<BytesData>, srcpos:Int, len: Int):Void;
	function fill(pos: Int, len: Int, value: cpp.UInt8):Void;

	@:native("new mem::BData") static function create(len:Int):Star<BytesData>;

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