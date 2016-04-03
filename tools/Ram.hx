package;

import mem.Ptr;
import mem.Malloc;
import haxe.io.Bytes;
import mem.struct.WString;

class Ram{
	static inline var LB:Int = 8;						// LB 只能为 2 的 n 次幂,
	static inline var LLB:Int = 8192;					// pow(2,13)

	public static var on_init(default, null):Array<Void->Void> = []; // simple
	public static function deInit(f:Void->Void){
		for(i in 0...on_init.length){
			if(on_init[i] == f){
				on_init.splice(i, 1);
				break;
			}
		}
	}

#if flash
	static var stack = new Array<ByteArray>();
	static var current:ByteArray = null;
	public static function select(ba:ByteArray):Void{
		if (ba.length < 1024) ba.length = 1024;
		Memory.select(ba);
		if (current != null) stack.push(current);
		current = ba;
		for(f in on_init) f();
	}

	public static function create(len = LLB):ByteArray{
		var ba = new ByteArray();
		ba.length = len;
		ba.endian = flash.utils.Endian.LITTLE_ENDIAN;
		return ba;
	}
#else
	static var stack = new Array<Bytes>();
	static var current:Bytes = null;
	public static function select(ba:Bytes):Void{
		Memory.select(ba);
		if (current != null) stack.push(current);
		current = ba;
		for(f in on_init) f();
	}
	public static function create(len = LLB):Bytes{
		return Bytes.alloc(len);
	}
#end
	public static function end():Void{
		current = stack.pop();
		if (current != null) Memory.select(current);
	}
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

	public static function find(str:String, start:Ptr):Ptr{
		if (start < 0) return 0;
		var end:Int = Malloc.getUsed();
		var wstr = mallocFromString(str);
		var ptr = 0;
		var len = wstr.length;
		var dst = wstr.c_ptr;
		end -= len;
		while (end >= start){
			if(memcmp(start, dst, len)){
				ptr = start;
				break;
			}
			start += 1;
		}
		wstr.free();
		return ptr;
	}
}