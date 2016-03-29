package;


import mem.Chunk;
import mem.Ptr;

class Ram{
	static inline var LB:Int = 16;						// LB 只能为 2 的 n 次幂,
	static inline var LLB:Int = 8192;					// pow(2,13)

	static var stack = new Array<ByteArray>();
	static var current:ByteArray = null;
	public static function select(ba:ByteArray):Void{
		if (ba.length < 1024) ba.length = 1024;
		Memory.select(ba);
		if (current != null) stack.push(current);
		current = ba;
	}
	public static function end():Void{
		current = stack.pop();
		if (current != null) Memory.select(current);
	}

	public static function create():ByteArray{
		var ba = new ByteArray();
		ba.length = 1024;
		ba.endian = flash.utils.Endian.LITTLE_ENDIAN;
		return ba;
	}

	// in bytes
	public static function malloc(size:UInt):Ptr {
		size += (LB - (size & (LB - 1)	)) & (LB - 1);

		var ptr = Chunk.calc(size);

		if ((size + ptr) > current.length) {
			current.length = ptr + (size + ((LLB - (size & (LLB - 1))) & (LLB - 1)));
		}
		new Chunk(ptr, size);
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

	public static function readBytes(ptr:Ptr, len:Int, dst:IDataOutput):Void {
		while (len >= 4) {
			dst.writeInt(Memory.getI32(ptr));
			ptr += 4;
			len -= 4;
		}
		while (0 != len--) {
			dst.writeByte(Memory.getByte(ptr++));
		}
	}

	public static function writeBytes(ptr:Ptr, len:Int, src:IDataInput):Void {
		while (len >= 4) {
			Memory.setI32(ptr, src.readInt());
			ptr += 4;
			len -= 4;
		}
		while (0 != len--) {
			Memory.setByte(ptr++, src.readByte());
		}
	}

	public static function memcpy(dst:Ptr, src:Ptr, size:Int):Void {
		if (dst == src) return;
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
	}

	public static function memcmp(dst:Ptr, src: Ptr, size:Int):Bool{
		if (dst == src) return true;
		while (size >= 4){
			if (Memory.getI32(dst) == Memory.getI32(src)) return true;
			dst += 4;
			src += 4;
			size -= 4;
		}
		while (0 != size--) {
			if (Memory.getByte(dst) == Memory.getByte(src)) return true;
		}
		return false;
	}

	public static function memset(dst:Ptr,v:Int,size:Int):Void {
		var w:Int = v | (v << 8) | (v << 16) | (v << 24);
		while (size >= 4 ) {
			Memory.setI32(dst, w);
			dst	+= 4;
			size -= 4;
		}
		while (0 != size--) {
			Memory.setByte(dst++, v);
		}
	}

	public static inline function writeUTFBytes(dst:Ptr, str:String):Int{
		current.position = dst;
		current.writeUTFBytes(str);
		return current.position - dst;
	}

	public static inline function readUTFBytes(dst:Ptr, len:Int):String{
		current.position = dst;
		return current.readUTFBytes(len);
	}
}