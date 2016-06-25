package;

import mem.Ptr;
import mem.Malloc;
import haxe.io.Bytes;
import mem.struct.WString;

class Ram{

	static inline var LB:Int = 8;						// LB 只能为 2 的 n 次幂,
	static inline var LLB:Int = 8192;					// pow(2,13)

#if flash
	static var tmp:ByteArray = null;
	static var current:ByteArray = null;
	public static function select(?ba:ByteArray):Void{
		if (ba == null)
			ba = create(LLB);
		else if (ba.length < 1024)
			ba.length = 1024;
		tmp = flash.system.ApplicationDomain.currentDomain.domainMemory;
		Memory.select(ba);
		current = ba;
		if (tmp == current) tmp = null;
	}

	public static function create(len = LLB):ByteArray{
		var ba = new ByteArray();
		ba.length = len;
		ba.endian = flash.utils.Endian.LITTLE_ENDIAN;
		return ba;
	}

	public static function detach():Void{
		flash.system.ApplicationDomain.currentDomain.domainMemory = tmp;
	}
#else
	static var current:Bytes = null;
	public static function select(?ba:Bytes):Void{
		if (ba == null) ba = create(LLB);
		Memory.select(ba);
		current = ba;
	}
	public static function create(len = LLB):Bytes{
		return Bytes.alloc(len);
	}
	public static function detach():Void{}
#end
	// in bytes
	public static inline function malloc(size:UInt, zero:Bool = false):Ptr return Malloc.make(size, zero);

	public static inline function free(ptr:Ptr) Malloc.free(ptr);

	static function req(len:UInt){
		if(len > current.length){
		#if flash
			current.length = mem.Ut.pad8(len, LLB);
		#else
			var a = Bytes.alloc(mem.Ut.pad8(len, LLB));
			a.blit(0, current, 0, current.length);
			Memory.select(a);
			current = a;
		#end
		}
	}

	static inline var himagic = 0x80808080;
	static inline var lomagic = 0x01010101;
	public static function strlen(ptr:Ptr):Int{
		var i = 0;
		//while ((Memory.getI32(ptr + i) - lomagic) & himagic != 0) i += 4;
		while (Memory.getByte(ptr + i) != 0) i += 1;
		return i;
	}

#if flash
	// read from Memory To Bytes
	public static inline function readBytes(ptr:Ptr, len:Int, dst:ByteArray):Void {
		dst.writeBytes(current, ptr, len);
	}

	// read from Bytes To Memory
	public static inline function writeBytes(ptr:Ptr, len:Int, src:ByteArray):Void {
		src.readBytes(current, ptr, len);
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
		if (dst == src) return;
	#if flash
		current.position = src;
		current.readBytes(current, dst, size);
	#else
		current.blit(dst, current, src, size);
	#end
	/*  // slowly then above
		if (dst < src){
			while (size >= 4) {
				Memory.setI32(dst, Memory.getI32(src));
				dst += 4;
				src += 4;
				size -= 4;
			}
			while (0 != size--) {
				Memory.setByte( dst++, Memory.getByte( src++ ));
			}
		}else {// 逆序复制
			dst += size;
			src += size;
			while (size >= 4 ) {
				dst -= 4;
				src -= 4;
				size -= 4;
				Memory.setI32(dst, Memory.getI32(src));
			}
			while (0 != size--) {
				Memory.setByte(--dst , Memory.getByte(--src));
			}
		}
	*/
	}

	public static function memcmp(dst:Ptr, src: Ptr, size:Int):Bool{
		if (dst == src) return true;
	#if flash
		while (size >= 4){
			if (Memory.getI32(dst) != Memory.getI32(src)) return false;
			dst += 4;
			src += 4;
			size -= 4;
		}
	#end
		while (0 != size--) {
			if (Memory.getByte(dst++) != Memory.getByte(src++)) return false;
		}
		return true;
	}

	public static function memset(dst:Ptr, v:Int, size:Int):Void {
	#if flash
		var w:Int = v | (v << 8) | (v << 16) | (v << 24);
		while (size >= 4 ) {
			Memory.setI32(dst, w);
			dst	+= 4;
			size -= 4;
		}
		while (0 != size--) {
			Memory.setByte(dst++, v);
		}
	#else
		current.fill(dst, size, v);
	#end
	}

	public static inline function writeUTFBytes(dst:Ptr, str:String):Int{
	#if flash
		current.position = dst;
		current.writeUTFBytes(str);
		return current.position - dst;
	#else
		var a = Bytes.ofString(str);
		current.blit(dst, a, 0, a.length);
		return a.length;
	#end
	}


	public static function writeString(dst:Ptr, len:Int, str:String):Void{
		var jlen = str.length;
		var i = 0, c = 0, j = 0;
		while (i < len && j < jlen){
			c = StringTools.fastCodeAt(str, j++);
			// surrogate pair -- (copy from haxe.io.Bytes::getString)
			if( 0xD800 <= c && c <= 0xDBFF )
			       c = (c - 0xD7C0 << 10) | (StringTools.fastCodeAt(str, j++) & 0x3FF);
			if( c <= 0x7F )
				Memory.setByte(dst + i++, c);
			else if ( c <= 0x7FF ) {
				Memory.setByte(dst + i++, 0xC0 | (c >> 6) );
				if(i < len) Memory.setByte(dst + i++, 0x80 | (c & 63) );
			} else if ( c <= 0xFFFF ) {
				Memory.setByte(dst + i++, 0xE0 | (c >> 12) );
				if(i < len) Memory.setByte(dst + i++, 0x80 | ((c >> 6) & 63) );
				if(i < len) Memory.setByte(dst + i++, 0x80 | (c & 63) );
			} else {
				Memory.setByte(dst + i++, 0xF0 | (c >> 18));
				if(i < len) Memory.setByte(dst + i++, 0x80 | ((c >> 12) & 63));
				if(i < len) Memory.setByte(dst + i++, 0x80 | ((c >> 6) & 63));
				if(i < len) Memory.setByte(dst + i++, 0x80 | (c & 63));
			}
		}
	}

	public static inline function mallocFromString(str:String) return new WString(str);

	public static inline function readUTFBytes(dst:Ptr, len:Int):String{
	#if flash
		current.position = dst;
		return current.readUTFBytes(len);
	#else
		return current.getString(dst, len);
	#end
	}

	public static inline function strr(ptr:Ptr):String return readUTFBytes(ptr, strlen(ptr));

	public static function find(str:String, start:Ptr, end:Ptr = Malloc.NUL):Ptr{
		if (start < 0) return Malloc.NUL;
		if (end == Malloc.NUL) end = Malloc.getUsed();
		var wstr = mallocFromString(str);
		var ptr = findA(wstr.c_ptr, wstr.length, start, end);
		wstr.free();
		return ptr;
	}

	public static function findA(src:Ptr, len:Int, start:Ptr, end:Ptr):Ptr{
		var ptr = Malloc.NUL;
		end -= len;
		while(end >= start){
			if(memcmp(start, src, len)){
				ptr = start;
				break;
			}
			start += 1;
		}
		return ptr;
	}
}