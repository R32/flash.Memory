package mem.obs;

import mem.Ptr;
import mem.obs._macros.SxInt.*;
import mem.Ptr.Memory.setI32;
import mem.Ptr.Memory.getI32;
/**
* 每个 x_n 的值为 8字节的明文, 通过这个明文计算将得到一个密钥块(4字节)的"位置值"
*/
#if !macro
@:build(mem.obs._macros.SxInt.SXorBuild.make("sx-pwd"))
#end
class SXor {
	static var x_0: AU8;
	static var x_1: AU8;
	static var x_2: AU8;
	static var x_3: AU8;
	static var  sa: Ptr = Malloc.NUL;

	public static function create(low:Int, high:Int):AU8 {
		var r:AU8 = cast mem.Malloc.make(8, false);
	#if !neko
		setI32(r, low);
		setI32(r + 4, high);
	#else
		r[0] = low & 0xff;
		r[1] = ( low >>  8) & 0xff;
		r[2] = ( low >> 16) & 0xff;
		r[3] = ( low >>>24) & 0xff;
		r[4] = high & 0xff;
		r[5] = (high >>  8) & 0xff;
		r[6] = (high >> 16) & 0xff;
		r[7] = (high >>>24) & 0xff;
	#end
		return r;
	}

	public static inline function make(src:Ptr, len:Int, dst:Ptr):Void {
		var offset = 0;
		var bmod = 0;
		var p:Int = sa;
	#if !neko	// Uncaught exception $sset on neko
		var b4 = len - (len & (4 - 1));
		var mod = 0;
		while (b4 > offset) {
			switch (mod) {
			case 0: setI32(dst + offset, getI32(src + offset) ^ getI32( p + c0(x_0) ));
			case 1: setI32(dst + offset, getI32(src + offset) ^ getI32( p + c1(x_1) ));
			case 2: setI32(dst + offset, getI32(src + offset) ^ getI32( p + c2(x_2) ));
			default:setI32(dst + offset, getI32(src + offset) ^ getI32( p + c3(x_3) ));
			}
		offset += 4;
		mod    += 1;
		mod = mod & (4 - 1);
		}

		while (bmod < 3) {
			switch (mod) {
			case 0:  Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte(p + bmod + c0(x_0)));
			case 1:  Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte(p + bmod + c1(x_1)));
			case 2:  Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte(p + bmod + c2(x_2)));
			default: Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte(p + bmod + c3(x_3)));
			}
		++offset;
		++bmod;
		}
	#else
		while (offset < len) {
			bmod = bmod & (4 - 1);
			switch((offset >> 2) & (4 - 1)) {
			case 0:  Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte(p + bmod + c0(x_0)));
			case 1:  Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte(p + bmod + c1(x_1)));
			case 2:  Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte(p + bmod + c2(x_2)));
			default: Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte(p + bmod + c3(x_3)));
			}
		++offset;
		++bmod;
		}
	#end
	}

	@:dce public static inline function test(){
		var t = haxe.io.Bytes.alloc(16);
		var p0 = c0(x_0);
		var p1 = c1(x_1);
		var p2 = c2(x_2);
		var p3 = c3(x_3);
		trace([p0, p1, p2, p3]);
	#if flash
		Ram.readBytes(sa + p0, 4, t.getData());
		Ram.readBytes(sa + p1, 4, t.getData());
		Ram.readBytes(sa + p2, 4, t.getData());
		Ram.readBytes(sa + p3, 4, t.getData());
		trace(t.toHex());
	#end
	}
}