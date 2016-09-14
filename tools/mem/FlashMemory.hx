package mem;

// typedef Memory = flash.Memory;
// https://github.com/HaxeFoundation/haxe/commit/5b8bc7dd3dfb8999df8d86ccfdb9273dcc933d36
@:dce class FlashMemory {
#if !macro
	public static inline function select( b : flash.utils.ByteArray ): Void flash.system.ApplicationDomain.currentDomain.domainMemory = b;
#end
	macro public static function setByte(  addr, v ) return macro untyped __vmem_set__(0, $addr, $v);
	macro public static function setI16(   addr, v ) return macro untyped __vmem_set__(1, $addr, $v);
	macro public static function setI32(   addr, v ) return macro untyped __vmem_set__(2, $addr, $v);
	macro public static function setFloat( addr, v ) return macro untyped __vmem_set__(3, $addr, $v);
	macro public static function setDouble(addr, v ) return macro untyped __vmem_set__(4, $addr, $v);
	macro public static function getByte(  addr ) return macro untyped __vmem_get__(0, $addr);
	macro public static function getUI16(  addr ) return macro untyped __vmem_get__(1, $addr);
	macro public static function getI32(   addr ) return macro untyped __vmem_get__(2, $addr);
	macro public static function getFloat( addr ) return macro untyped __vmem_get__(3, $addr);
	macro public static function getDouble(addr ) return macro untyped __vmem_get__(4, $addr);
	macro public static function signExtend1( v ) return macro untyped __vmem_sign__(0, $v);
	macro public static function signExtend8( v ) return macro untyped __vmem_sign__(1, $v);
	macro public static function signExtend16(v ) return macro untyped __vmem_sign__(2, $v);
}