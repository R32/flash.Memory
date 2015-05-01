package mem;
import flash.Memory;



class UnsafeBase<T>{
	public var size(default, null):Int;
	
	public var ptr(default,null):Int;
	
	public var length(default,null):Int;
	
	// 填充数组
	public inline function fill(v:Int) Ram.memset(ptr, v, size);
	
	// 释放内存占用
	public inline function free() Ram.free(ptr);
	
	public function toString():String{
		var str = new StringBuf();
		for(i in 0...length){
			str.addChar(Memory.getByte(ptr + i));
		}
		return str.toString();
	}
	
	public function toHex():String{
		var str = "";
		for (i in 0...size) {
			var n = Memory.getByte(ptr + i);
			str += StringTools.hex( (n >> 4) & 0xf) + StringTools.hex(n & 0xf);
		}
		return str;
	}
}


class UnsafeArray extends UnsafeBase<Int>{

	public function new(len:Int){
		size = len;
		ptr = Ram.malloc(size);
		length = len;
	}
		
	public inline function set(i:Int, v:Int){
		Memory.setByte(ptr + i, v);	
	}
	
	public inline function get(i:Int):Int{
		return Memory.getByte(ptr + i);
	}
}


class UnsafeArray16 extends UnsafeBase<Int>{
	
	static inline var W:Int = 1;
	
	public function new(len:Int) {
		length = len;
		size = len << W;
		this.ptr = Ram.malloc(size);
	}
	
	public inline function set(i:Int, v:Int){
		Memory.setI16(ptr + (i << W), v);	
	}
	
	public inline function get(i:Int):Int{
		return Memory.getUI16(ptr + (i << W));			// 为什么这个是 UI16 ???
	}

}

class UnsafeArray32 extends UnsafeBase<Int>{
	
	static inline var W:Int = 2;
	
	public function new(len:Int) {
		length = len;
		size = len << W;
		this.ptr = Ram.malloc(size);
	}
	
	public inline function set(i:Int, v:Int){
		Memory.setI32(ptr + (i << W), v);	
	}
	
	public inline function get(i:Int):Int{
		return Memory.getI32(ptr + (i << W));
	}

}

class UnsafeArrayFlaot extends UnsafeBase<Float> {
	
	static inline var W:Int = 2;
	
	public function new(len:Int) {
		length = len;
		size = len << W;
		this.ptr = Ram.malloc(size);
	}
	
	public inline function set(i:Int, v:Float){
		Memory.setFloat(ptr + (i << W), v);	
	}
	
	public inline function get(i:Int):Float{
		return Memory.getFloat(ptr + (i << W));
	}
}


class UnsafeArrayDouble extends UnsafeBase<Float>{
	
	static inline var W:Int = 3;
	
	public function new(len:Int) {
		length = len;
		size = len << W;
		this.ptr = Ram.malloc(size);
	}
	
	public inline function set(i:Int, v:Float){
		Memory.setDouble(ptr + (i << W), v);	
	}
	
	public inline function get(i:Int):Float{
		return Memory.getDouble(ptr + (i << W));
	}
}