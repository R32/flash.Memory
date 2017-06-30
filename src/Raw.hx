package;

import raw.Ptr;
import raw.RawData;

class Raw {
	static inline var LLB = 16 << 15;  // 512K

	static var current: RawData = null;

	public static function attach(rd:RawData = null):Void {
		if (rd == null) {
			if (current != null) {
				return Memory.select(current);
			}
			rd = create();
		}
		#if flash
		else if (rd.length < 1024) @:privateAccess {
			rd.b.length = 1024;
			rd.length = 1024;
		}
		#end
		if (rd != current) {
			current = rd;
			Memory.select(rd);
		}
	}

	public static inline function create(size = 0): RawData {
		return haxe.io.Bytes.alloc(size <= 0 ? LLB : (size < 1024 ? 1024 : size));
	}

	public static inline function toString() {
		return 'RAW: [Volume: ${current.length / 1024}KB, Usage: ${raw.Malloc.getUsed() / 1024}KB]';
	}
	// stdlib
	public static inline function malloc(size: Int, zero = false): Ptr return raw.Malloc.make(size, zero, 8);

	public static inline function free(ptr: Ptr) raw.Malloc.free(ptr);

	public static function realloc(src: Ptr, new_size: Int): Ptr @:privateAccess {
		var src_blk = raw.Malloc.indexOf(src);
		if (new_size <= 0 || src_blk == Ptr.NUL) throw "Invalid arguments";
		new_size = raw.Ut.align(new_size, 8);
		var src_size = src_blk.entrySize;
		if (src_blk == raw.Malloc.last) {
			if (new_size > src_size) reqCheck( src.toInt() + new_size);
			src_blk.size = new_size + raw.Malloc.Block.CAPACITY;
		} else if (new_size > src_size) {
			var new_ptr = malloc(new_size, false);
			var new_blk = new raw.Malloc.Block(new_ptr - raw.Malloc.Block.CAPACITY);
			memcpy(new_ptr, src, src_size);
			src_blk.free();
			src = new_ptr;
		}
		return src;
	}

	public static inline function memcpy(dst: Ptr, src: Ptr, size: Int):Void {
		if (dst == src || size <= 0) return;
		current.blit(dst.toInt(), current, src.toInt(), size);
	}

	static public function memcmp(ptr1: Ptr, ptr2: Ptr, len: Int):Int {
	#if hl
		return @:privateAccess current.b.compare(ptr1.toInt(), current.b, ptr2.toInt(), len);
	#else
		var i = 0 , c1 = 0, c2 = 0;
		#if flash
		var len4 = len - (len & (4 - 1));
		while (i < len4) {
			if (Memory.getI32(ptr1 + i) != Memory.getI32(ptr2 + i)) break;
		i += 4;
		}
		#end
		while (i < len) {
			c1 = ptr1[i];
			c2 = ptr2[i];
			if (c1 != c2) break;
		++i;
		}
		return c1 - c2;
	#end
	}

	public static function memset(dst: Ptr, v: Int, size: Int):Void {
	#if flash
		var w = v == 0 ? 0 : (v | (v << 8) | (v << 16) | (v << 24));
		while (size >= 4 ) {
			Memory.setI32(dst, w);
			dst	+= 4;
			size -= 4;
		}
		while (0 < size--) {
			Memory.setByte(dst++, v);
		}
	#else
		current.fill(dst.toInt(), size, v);
	#end
	}

	static function reqCheck(bytesLength: Int) @:privateAccess {
		bytesLength = 0x7FFFFFFF & bytesLength;
		if (bytesLength > current.length) {
			var expand = raw.Ut.align(bytesLength, LLB);
		#if flash
			current.b.length = expand;
			current.length = expand;
		#else
			var a = create(expand);
			a.blit(0, current, 0, current.length);
			Memory.select(a);
			current = a;
		#end
		}
	}

	// from raw to bytes
	public static inline function readBytes(ptr: Ptr, len: Int, dst: haxe.io.Bytes): Void {
		dst.blit(0, current, ptr.toInt(), len);
	}

	public static inline function writeBytes(ptr: Ptr, len: Int, src: haxe.io.Bytes): Void {
		current.blit(ptr.toInt(), src, 0, len);
	}

	public static inline var SMAX = LLB;  // 512K
	public static function strlen(ptr: Ptr, max = SMAX): Int {
		var i = 0;
		while (i < max && Memory.getByte(ptr + i) != 0) ++i;
		return i;
	}

	public static inline function mallocFromString(str: String): raw.struct.WString {
		return raw.struct.WString.ofString(str);
	}

	public static inline function mallocFromBytes(b: haxe.io.Bytes): raw.struct.FBlock {
		return raw.struct.FBlock.ofBytes(b);
	}

	// max in bytes
	public static inline function writeUtf8(dst: Ptr, str: String, max = SMAX): Int {
		return raw.struct.WString.ofstrn(dst, str, max);
	}

	public static inline function readUtf8(src: Ptr, len: Int): String {
		return current.getString(src.toInt(), len);
	}

	public static function writeUcs2(out: Ptr, str: String, max = SMAX): Int {
		return raw.Ucs2.ofstr(out, str, max);
	}

	public static function readUcs2(src: Ptr, len: Int): String {
		return raw.Ucs2.tostr(src, len);
	}
}