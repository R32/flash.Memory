package;


import mem.Chunk;
import mem.Ptr;
import haxe.io.Bytes;

class Ram{
	static inline var LB:Int = 8;						// LB 只能为 2 的 n 次幂,
	static inline var LLB:Int = 8192;					// pow(2,13)

#if flash
	static var tmpb:ByteArray = new ByteArray();
	static var stack = new Array<ByteArray>();
	static var current:ByteArray = null;
	public static function select(ba:ByteArray):Void{
		if (ba.length < 1024) ba.length = 1024;
		Memory.select(ba);
		if (current != null) stack.push(current);
		current = ba;
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
	public static function malloc(size:UInt, zero:Bool = false):Ptr {

		size = mem.Ut.pad8(size, LB);

		var ptr = Chunk.calc(size); // always ptr >= 16

		if ((size + ptr) > current.length) {
		#if flash
			current.length = mem.Ut.pad8(ptr + size, LLB);
		#else
			var a = Bytes.alloc(mem.Ut.pad8(ptr + size, LLB));
			a.blit(0, current, 0, current.length);
			Memory.select(a);
			current = a;
		#end
		}
		new Chunk(ptr, size);
		if (zero) memset(ptr, 0, size);
		return ptr;
	}

	public static inline function free(ptr:Ptr):Bool {
		return Chunk.free(ptr);
	}

	static inline var himagic = 0x80808080;
	static inline var lomagic = 0x01010101;
	public static function strlen(ptr:Ptr):Int{
		var i = 0;
		//TODO: 这段4字节检测, 在flash上似乎没有优势？？可以删除掉注释测试性能
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

	public static function mallocFromString(str:String):Pts{
	#if flash
		tmpb.position = 0;
		tmpb.writeUTFBytes(str);
		tmpb.position = 0;
	#else
		var tmpb = haxe.io.Bytes.ofString(str);
	#end
		var len = tmpb.length;
		var ptr = Ram.malloc(len, true);
		writeBytes(ptr, len, tmpb);
	#if flash
		tmpb.clear();
	#end
		return {ptr:ptr, len: len};
	}

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
		var end:Int = Chunk.get_used();
		var pts = mallocFromString(str);
		var ptr = 0;
		end -= pts.len;
		while (end >= start){
			if(memcmp(start, pts.ptr, pts.len)){
				ptr = start;
				break;
			}
			start += 1;
		}
		pts.free();
		return ptr;
	}
}