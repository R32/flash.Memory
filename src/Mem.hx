package;

import mem.Ptr;

@:access(mem.Alloc)
class Mem {

	static var b: mem.RawData;
	static var bmax: Int;
	static var gsize: Int;

	static public function init(init = LLB, grow = LLB) {
		if (b != null) return;
		gsize = grow;
		bmax = init >= 1024 ? mem.Ut.align(init, 16): LLB;
		b = make(bmax);
		mem.Memory.select(b);
	}

	static public function grow(size: Int): Void {
		if (size > bmax) {
			size = mem.Ut.align(size, gsize);
		#if flash
			b.length = size;
		#else
			var a = make(size);
			a.blit(0, b, 0, bmax);
			mem.Memory.select(a);
			b = a;
		#end
			bmax = size;
		}
	}

	#if !flash inline #end
	static public function memset(dst: Ptr, v: Int, size: Int):Void {
	#if flash
		var w = v == 0 ? 0 : (v | (v << 8) | (v << 16) | (v << 24));
		while (size >= 4 ) {
			dst.setI32(w);
			dst	+= 4;
			size -= 4;
		}
		while (0 < size--) {
			dst.setByte(v);
			++ dst;
		}
	#else
		b.fill(dst.toInt(), size, v);
	#end
	}

	#if hl inline #end
	static public function memcmp(p1: Ptr, p2: Ptr, len: Int):Int {
	#if hl
		return b.compare(p1.toInt(), b, p2.toInt(), len); // return (-1, 0, 1) in HL
	#else
		var i = 0 , r = 0;
		#if flash
		var len4 = len - (len & (4 - 1));
		while (i < len4) {
			if ((p1 + i).getI32() != (p2 + i).getI32()) break;
			i += 4;
		}
		#end
		while (r == 0 && i < len) {
			r = p1[i] - p2[i];
			++i;
		}
		return r; // return (r<0, r==0, r>0)
	#end
	}

	static public inline function memcpy(dst: Ptr, src: Ptr, size: Int):Void {
	#if flash
		b.position = src.toInt();
		b.readBytes(b, dst.toInt(), size);
	#else
		b.blit(dst.toInt(), b, src.toInt(), size);
	#end
	}

	static public inline function readBytes(src: Ptr, len: Int): haxe.io.Bytes {
		var ret = haxe.io.Bytes.alloc(len);
	#if hl
		@:privateAccess ret.b.blit(0, b, src.toInt(), len);
	#elseif flash
		b.position = src.toInt();
		b.readBytes(@:privateAccess ret.b, 0, len);
	#else
		ret.blit(0, b, src.toInt(), len);
	#end
		return ret;
	}

	static public inline function writeBytes(dst: Ptr, len: Int, src: haxe.io.Bytes): Void {
	#if hl
		b.blit(dst.toInt(), @:privateAccess src.b, 0, len);
	#elseif flash
		b.position = dst.toInt();
		b.writeBytes(@:privateAccess src.b, 0, len);
	#else
		b.blit(dst.toInt(), src, 0, len);
	#end
	}

	static function make(size: Int): mem.RawData {
	#if hl
		return new hl.Bytes(size);
	#elseif flash
		var ba = new flash.utils.ByteArray();
		ba.length = size;
		ba.endian = flash.utils.Endian.LITTLE_ENDIAN;
		return ba;
	#else
		return haxe.io.Bytes.alloc(size);
	#end
	}

	static public inline function malloc(size, clear = false): Ptr return mem.Alloc.req(size, clear);

	static public inline function free(ptr: Ptr) mem.Alloc.free(mem.Alloc.hd(ptr));

	public static function realloc(src: Ptr, req: Int): Ptr {
		var hd = mem.Alloc.hd(src);
		if (hd == Ptr.NUL) return Ptr.NUL; // TODO: throw a error?
		req = @:privateAccess mem.Alloc.ALIGN_LB(req);
		var size = hd.entrySize;
		if (hd == mem.Alloc.last) {
			if (req > size) {
				grow( src.toInt() + req );
				hd.size = req + 8;
			}
		} else if (req > size) {
			var x:Ptr = mem.Alloc.req(req, false);
			memcpy(x, src, size);
			mem.Alloc.free(hd);
			src = x;
		}
		return src;
	}

	static public function mallocFromString(s: String): mem.s.UTF8String {
		var ts = new mem.s.UTF8String(mem.Utf8.ofString(Ptr.NUL, 0, s));
		mem.Utf8.ofString(ts, ts.length, s);
		return ts;
	}
	static public function mallocFromBytes(b: haxe.io.Bytes): mem.s.Block {
		var ret = mem.s.Block.alloc(b.length);
		Mem.writeBytes(ret, b.length, b);
		return ret;
	}
	static public function mallocFromHex(hex: String): mem.s.Block {
		var len = hex.length >> 1;
		var b = mem.s.Block.alloc(len);
		for (i in 0...len) {
			var high = StringTools.fastCodeAt(hex,  i << 1);
			var low  = StringTools.fastCodeAt(hex, (i << 1) + 1);
			high = (high & 0xF) + ((high & 0x40) >> 6) * 9;
			low  = (low  & 0xF) + ((low  & 0x40) >> 6) * 9;
			b[i] = ((high << 4) | low)  & 0xFF;
		}
		return b;
	}

	static inline var LLB = 16 << 15; // 512K
}