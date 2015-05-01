package;

import flash.system.ApplicationDomain;
import flash.utils.ByteArray;
import flash.utils.IDataInput;
import flash.utils.IDataOutput;
import flash.Memory;
import mem.LEByteArray;
import mem.MemoryChunk;

/**
* 只有在不经常交换数据时, flash.Memory 才会有性能上的提升
* 只有 直接将 ByteArray 直接挂到 ApplicationDomain.currentDomain.domainMemory 中去？这样就省去内存管理了
*/
class Ram{
	
	/**
	* LB 只能为 2 的 n 次幂, 8,16,32,64.....Math.pow(2,n);
	*/
	static inline var LB:Int = 16;
	
	static var bts:LEByteArray = null;
	
	static var tmp:ByteArray = null;

	public static var total(get, never):Int;
	private static function get_total():Int {
		return 	bts == null ? 0 : bts.length; 
	}
	
	public static var ready(default,null):Bool = false;
	

	public static inline function init():Void {attach();}
	
	
	/**
	* 将 bts 关联到 DomainMemory,如果 DomainMemory 不为 null时,DomainMemory的值会被暂存在 tmp上
	* 直到调用 detach 才会恢复 DomainMemory 之前所关联的对象
	*/
	public static function attach():Void {
		if (bts == null) {
			bts = new LEByteArray(ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH);
		}
		if (ApplicationDomain.currentDomain.domainMemory != bts) {
			tmp = ApplicationDomain.currentDomain.domainMemory;
		}
		
		if (!ready) {
			Memory.select(bts);
			ready = true;
		}
	}
	
	/**
	* 除非使用多个flash.Memory 管理,如 flash alchemy, 否则很多情况下都不需要调用这个方法,
	*/
	public static function detach():Void {
		Memory.select(tmp);
		ready =  false;
	}
	
	
	/**
	* 	分配 size 字节,返回 一个 Int 类型的内存地址.
	* @param	size
	* @return
	*/
	public static function malloc(size:Int):Int {
		var ptr:Int = 0;
		if(ready && size > 0) {
			
			size += (LB - (size & (LB - 1)	)) & (LB - 1);	// 补满为 LB 的倍数.
			
			ptr = MemoryChunk.calcPtr(size);
			
			if (size > (total - ptr)) {
				bts.length = ptr + size;
			}
			
			new MemoryChunk(ptr, size);
		}else {
			throw 'not ready or size <= 0';
		}
		return ptr;
	}
	
	public static function free(ptr:Int):Bool {
		if (ready) {
			return MemoryChunk.release(ptr);
		}
		return false;
	}
	
	/**
	* 从 domainByteArray 中读数据,写到 dst 中,写数据前需要自行设置 dst 的 position 位置
	* @param	ptr
	* @param	len
	* @param	dst #if openfl ByteArray #else IDataOutput #end 因为openfl 的 ByteArray 没有接口 IDataOutput 
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
	* 从 src 中读数据,写到 domainByteArray 的指定位置,读数据前需要自行设置 src 的 position 位置
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
	* @param	dst
	* @param	src
	* @param	size
	*/
	public static function memcpy(dst:Int,src:Int,size:Int):Void {
		// for flash.Memory
		if (src > dst){
			while (size >= 4) {
				Memory.setI32(dst,	Memory.getI32(src));
				dst += 4;
				src += 4;
				size -= 4;
				//trace("++++++ 4 ++++++");
			}
			while (0 != size--) {
				Memory.setByte( dst++ ,	Memory.getByte( src++ ));
				//trace("++++++ 1 ++++++");
			}
		}else {// 逆序复制
			dst += size;
			src += size;
			while (size >= 4 ) {
				dst -= 4;
				src -= 4;
				size -= 4;
				Memory.setI32(dst,	Memory.getI32(src));
				//trace("------ 4 ------");
			}
			while (0 != size--) {
				Memory.setByte( --dst ,	Memory.getByte( --src ));
				//trace("------ 1 ------");
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
}