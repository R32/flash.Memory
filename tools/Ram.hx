package;

import mem.Ptr;
import mem.Malloc;
import haxe.io.Bytes;
import mem.struct.WString;
#if (cpp && !keep_bytes)
import cpp.Star;
import mem.cpp.BytesData;
import mem.cpp.NRam;
typedef RawData = Star<BytesData>;
#elseif flash
typedef RawData = flash.utils.ByteArray;
#elseif hl
typedef RawData = hl.Bytes;
#else
typedef RawData = haxe.io.Bytes;
#end

class Ram{

	static inline var LLB = 16 << 10;  // 16384, 16K
	static var current:RawData = null;
	static var bytesLength(get, never):Int;
	static inline function get_bytesLength() return #if hl currentLength; #else current.length; #end

#if hl
	static var currentLength:Int = 0;
#end

#if flash
	static var tmp:RawData = null;

	public static function select(?ba:RawData):Void {
		if (ba == null)
			ba = create(LLB);
		else if (ba.length < 1024)
			ba.length = 1024;
		tmp = flash.system.ApplicationDomain.currentDomain.domainMemory;
		Memory.select(ba);
		current = ba;
		if (tmp == current) tmp = null;
	}

	public static function create(len = LLB):RawData {
		var ba = new ByteArray();
		ba.length = len;
		ba.endian = flash.utils.Endian.LITTLE_ENDIAN;
		return ba;
	}

	public static function attach():Void {
		if (current == null) {
			select(null); // create new
		} else if (current != flash.system.ApplicationDomain.currentDomain.domainMemory) {
			tmp = flash.system.ApplicationDomain.currentDomain.domainMemory;
			Memory.select(current);
		}
	}

	public static function detach():Void {
		flash.system.ApplicationDomain.currentDomain.domainMemory = tmp;
	}
#else
	public static function select(?ba:RawData #if hl ,?len:Int #end):Void {
		if (ba == null) {
			ba = create(LLB);
			#if hl len = LLB; #end
		}
		Memory.select(ba);
		current = ba;
		#if hl currentLength = len; #end
	}
	public static inline function create(len = LLB):RawData {
	  #if hl
		return new hl.Bytes(len);
	  #elseif (cpp && !keep_bytes)
		return BytesData.createStar(len);
	  #else
		return Bytes.alloc(len);
	  #end
	}

	public static function attach():Void {
		if (current == null)
			select(null);
		else if(Memory.b != current)
			Memory.select(current);
	}

	public static function detach():Void {}
#end

	// in bytes
	public static inline function malloc(size:UInt, zero:Bool = false):Ptr return Malloc.make(size, zero, 8);

	public static inline function free(entry :Ptr) Malloc.free(entry);

	static function req(len: Int) {
		if (len > bytesLength) {
			var expand = mem.Ut.padmul(len, 4 << 10);  // 4K
		#if flash
			current.length = expand;
		#elseif (cpp && !keep_bytes)
			current.resize(expand);
		#else
			var a = create(expand);
			a.blit(0, current, 0, bytesLength);
			Memory.select(a);
			current = a;
			#if hl
			currentLength = expand;
			#end
		#end
		}
	}

	static inline var himagic = 0x80808080;
	static inline var lomagic = 0x01010101;
	public static function strlen(ptr:Ptr):Int {
		var i = 0;
		//while ((Memory.getI32(ptr + i) - lomagic) & himagic != 0) i += 4;
		while (Memory.getByte(ptr + i) != 0) i += 1;
		return i;
	}

#if flash
	// from Memory To Bytes
	public static inline function readBytes(ptr:Ptr, len:Int, dst:ByteArray):Void {
		dst.writeBytes(current, ptr, len);
	}

	// from Bytes To Memory
	public static inline function writeBytes(ptr:Ptr, len:Int, src:ByteArray):Void {
		src.position = 0;
		src.readBytes(current, ptr, len);
	}
#elseif (cpp && !keep_bytes)
	// hxcpp/include/Array.h -- "inline char * getBase() const..."
	public static inline function readBytes(ptr:Ptr, len:Int, dst:Bytes):Void {
		var b:Star<cpp.Char> = untyped dst.getData().getBase();
		NRam.memcpy(b, current.cs() + (ptr:Int), len);
	}
	public static inline function writeBytes(ptr:Ptr, len:Int, src:Bytes):Void {
		var b:Star<cpp.Char> = untyped src.getData().getBase();
		NRam.memcpy(current.cs() + (ptr:Int), b, len);
	}
#elseif hl
	public static inline function readBytes(ptr:Ptr, len:Int, dst:Bytes):Void {
		@:privateAccess dst.b.blit(0, current, ptr, len);
	}
	public static inline function writeBytes(ptr:Ptr, len:Int, src:Bytes):Void {
		@:privateAccess current.blit(ptr, src.b, 0, len);
	}
#else
	public static inline function readBytes(ptr:Ptr, len:Int, dst:Bytes):Void {
		dst.blit(0, current, ptr, len);
	}
	public static inline function writeBytes(ptr:Ptr, len:Int, src:Bytes):Void {
		current.blit(ptr, src, 0, len);
	}
#end

	public static inline function memcpy(dst:Ptr, src:Ptr, size:Int):Void {
		if (dst == src || size <= 0) return;
	#if flash
		current.position = src;
		current.readBytes(current, dst, size);
	#else
		current.blit(dst, current, src, size);
	#end
	}

	public static function memcpyPure(dst:Int, src:Int, size:Int):Void {
		if (dst < src) {
			while (size >= 4) {
				Memory.setI32(dst, Memory.getI32(src));
				dst  += 4;
				src  += 4;
			size -= 4;
			}
			while (size > 0) {
				Memory.setByte(dst, Memory.getByte(src));
				++dst;
				++src;
			--size;
			}
		} else if(dst > src) { // reverse
			dst += size;
			src += size;
			while (size >= 4 ) {
				dst -= 4;
				src -= 4;
				Memory.setI32(dst, Memory.getI32(src));
			size -= 4;
			}
			while (size > 0) {
				--dst;
				--src;
				Memory.setByte(dst , Memory.getByte(src));
			--size;
			}
		}
	}

	static public function memcmp(ptr1: Ptr, ptr2: Ptr, len: Int):Int {
	#if (cpp && !keep_bytes)
		var base = current.cs();
		return NRam.memcmp(base + (ptr1:Int), base + (ptr2:Int), len);
	#elseif hl
		return current.compare(ptr1, current, ptr2, len);
	#else
		var i = 0 , c1 = 0, c2 = 0;
		#if flash
		var len4 = len - (len & (4 - 1));
		while (i < len4) {
			c1 = Memory.getI32(ptr1 + i);
			c2 = Memory.getI32(ptr2 + i);
			if (c1 != c2) break;
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

	public static function memset(dst:Ptr, v:Int, size:Int):Void {
	#if flash
		var w:Int = v == 0 ? 0 : v | (v << 8) | (v << 16) | (v << 24);
		while (size >= 4 ) {
			Memory.setI32(dst, w);
			dst	+= 4;
			size -= 4;
		}
		while (0 < size--) {
			Memory.setByte(dst++, v);
		}
	#else
		current.fill(dst, size, v);
	#end
	}

	public static inline function writeUTFBytes(dst:Ptr, str:String):Int {
	#if flash
		current.position = dst;
		current.writeUTFBytes(str);
		return current.position - dst;
	#elseif (cpp && !keep_bytes)
		// write string to mem
		var b:Star<cpp.Char> = cpp.NativeString.c_str(str).ptr;
		NRam.memcpy(current.cs() + (dst:Int), b, str.length);
		return str.length;
	#elseif hl
		var size = 0;
		@:mergeBlock @:privateAccess {
			var b = str.bytes.utf16ToUtf8(0, size);
			current.blit(dst, b, 0, size);
		}
		return size;
	#else
		var a = Bytes.ofString(str);
		current.blit(dst, a, 0, a.length);
		return a.length;
	#end
	}

	public static function writeString(dst:Ptr, len:Int, str:String):Void {
	#if (neko || cpp || lua)
		for (i in 0...len)
			Memory.setByte(dst + i, StringTools.fastCodeAt(str, i));
	#elseif hl
		var size = 0;
		@:privateAccess var b = str.bytes.utf16ToUtf8(0, size);
		current.blit(dst, b, 0, len < size ? len : size);
	#else
		var slen = str.length;
		var i = 0, c = 0, j = 0;
		while (i < len && j < slen) {
			c = StringTools.fastCodeAt(str, j++);
			// surrogate pair -- (copy from haxe.io.Bytes::getString)
			if( 0xD800 <= c && c <= 0xDBFF )
				c = (c - 0xD7C0 << 10) | (StringTools.fastCodeAt(str, j++) & 0x3FF);

			if ( c <= 0x7F ) {
				dst[i] = c;
				i += 1;
			} else if ( c <= 0x7FF ) {
				if (i + 2 <= len) {
					dst[i + 0] = 0xC0 | (c >> 6);
					dst[i + 1] = 0x80 | (c & 63);
				} else {
					dst[i] = 0;
				}
				i += 2;
			} else if ( c <= 0xFFFF ) {
				if (i + 3 <= len) {
					dst[i + 0] = 0xE0 | (c >> 12);
					dst[i + 1] = 0x80 | (c >>  6 & 63);
					dst[i + 2] = 0x80 | (c >>  0 & 63);
				} else {
					dst[i] = 0;
				}
				i += 3;
			} else {
				if (i + 4 <= len) {
					dst[i + 0] = 0xF0 | (c >> 18);
					dst[i + 1] = 0x80 | (c >> 12 & 63);
					dst[i + 2] = 0x80 | (c >>  6 & 63);
					dst[i + 3] = 0x80 | (c >>  0 & 63);
				} else {
					dst[i] = 0;
				}
				i += 4;
			}
		}
		if (i < len) dst[i] = 0;
	#end
	}

	public static inline function mallocFromString(str:String):WString return WStrImpl.fromString(str);

	public static function mallocFromBytes(b:Bytes, align = 32):mem.struct.FBlock {
		var ret = new mem.struct.FBlock(b.length, false, align);
	#if flash
		writeBytes(ret, b.length, b.getData());
	#else
		writeBytes(ret, b.length, b);
	#end
		return ret;
	}

	public static inline function readUTFBytes(dst:Ptr, len:Int):String {
	#if flash
		current.position = dst;
		return current.readUTFBytes(len);
	#elseif (cpp && !keep_bytes)
		return untyped __cpp__("_hx_string_create({0}, {1})", current.cs() + (dst:Int), len);
	#elseif hl
		var b = new hl.Bytes(len + 1);
		b.blit(0, current, dst, len);
		b[len] = 0;
		return @:privateAccess String.fromUTF8(b);
	#else
		return current.getString(dst, len);
	#end
	}

	// public static inline function strr(ptr:Ptr):String return readUTFBytes(ptr, strlen(ptr));
	// below only for test
	public static function find(str:String, start:Ptr, end:Ptr = Malloc.NUL):Ptr {
		if ((start:Int) < 0) return Malloc.NUL;
		if (end == Malloc.NUL) end = cast Malloc.getUsed();
		var wstr = mallocFromString(str);
		var ptr = findA(wstr, wstr.length, start, end);
		wstr.free();
		return ptr;
	}

	public static function findA(src:Ptr, len:Int, start:Ptr, end:Ptr):Ptr {
		var ptr = Malloc.NUL;
		end -= len;
		while(end >= start){
			if(memcmp(start, src, len) == 0){
				ptr = start;
				break;
			}
			start += 1;
		}
		return ptr;
	}
}