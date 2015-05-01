package;

import flash.system.ApplicationDomain;
import flash.utils.ByteArray;
import flash.utils.IDataInput;
import flash.utils.IDataOutput;
import flash.Memory;
import haxe.Utf8;

import mem.LEByteArray;
import mem.MemoryChunk;


class Ram{
	
	// LB 只能为 2 的 n 次幂, 8,16,32,64.....Math.pow(2,n);
	static inline var LB:Int = 16;
	
	static var Comb:LEByteArray = null;
	static var Tmp:ByteArray;
	
	public static var total(get, never):Int;
	private static function get_total():Int {
		return 	Comb == null ? 0 : Comb.length; 
	}
	
	public static var ready(default,null):Bool = false;
		
	public static function attach():Void {
		if (Comb == null) {
			Comb = new LEByteArray(ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH);
		}
		
		if (ApplicationDomain.currentDomain.domainMemory != Comb) {
			Tmp = ApplicationDomain.currentDomain.domainMemory;
			Memory.select(Comb);
			ready = true;
		}	
	}
	
	public static function detach():Void {
		Memory.select(Tmp);
		ready = false;
	}
	
	// 以字节为单位
	public static function malloc(size:Int):Int {
		var ptr:Int = -1;
		if(ready && size > 0) {
			
			size += (LB - (size & (LB - 1)	)) & (LB - 1);	// 补满为 LB 的倍数.
			
			ptr = MemoryChunk.calc(size);
			
			if (size > (total - ptr)) {
				Comb.length = ptr + size;
			}		
			new MemoryChunk(ptr, size);
		}else {
			throw 'not ready or size <= 0';
		}
		return ptr;
	}
	
	public static function free(ptr:Int):Bool {
		if (ready) {
			return MemoryChunk.free(ptr);
		}
		return false;
	}
	
	/**
	* 从 ptr 处读取 len 数据,写到 dst 中
	* @param	ptr
	* @param	len
	* @param	dst
	*/
	public static function readBytes(ptr:Int, len:Int, dst:IDataOutput):Void {
		while (len >= 4) {
			dst.writeInt(Memory.getI32( ptr ));
			ptr += 4;
			len -= 4;
		}
		while (0 !=len--) {
			dst.writeByte(Memory.getByte(ptr++));
		}
	}
	
	/**
	* 从 src 中读 len 数据,写到 ptr 位置
	* @param	ptr
	* @param	len
	* @param	src
	*/
	public static function writeBytes(ptr:Int, len:Int, src:IDataInput):Void {
		while (len >= 4) {
			Memory.setI32(ptr, src.readInt());
			ptr += 4;
			len -= 4;
		}
		while (0 != len --) {
			Memory.setByte(ptr++, src.readByte());
		}	
	}
	
	/**
	* 
	* @param	dst ptr
	* @param	src ptr 
	* @param	size
	*/
	public static function memcpy(dst:Int,src:Int,size:Int):Void {
		if (src > dst){
			while (size >= 4) {
				Memory.setI32(dst,	Memory.getI32(src));
				dst += 4;
				src += 4;
				size -= 4;
			}
			while (0 != size--) {
				Memory.setByte( dst++ ,	Memory.getByte( src++ ));
			}
		}else {// 逆序复制
			dst += size;
			src += size;
			while (size >= 4 ) {
				dst -= 4;
				src -= 4;
				size -= 4;
				Memory.setI32(dst,	Memory.getI32(src));
			}
			while (0 != size--) {
				Memory.setByte( --dst ,	Memory.getByte( --src ));
			}
		}
	}
	
	/**
	* 
	* @param	dst
	* @param	v	0x00 ~ 0xFF
	* @param	size	
	*/
	public static function memset(dst:Int,v:Int,size:Int):Void {
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
	
	public static function mallocFromString(str:String):Int {
		// 实际上在 flash 中, str 的长度中文也只算一个字符.
		throw "Does not yet support";
		return 0;
	}
	
}