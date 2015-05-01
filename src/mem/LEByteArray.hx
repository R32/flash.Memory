package mem;

import flash.utils.ByteArray;
import flash.utils.Endian;

class LEByteArray extends ByteArray{
	
	public function new(len:UInt) {
		super();
		super.length = len;
		super.endian = Endian.LITTLE_ENDIAN;
	}
	
	override public function clear():Void {}
	
	@:setter(length) function set_length(len:UInt):Void {
		if(len > super.length){
		  super.length = len;
		}else if(len < super.length ){
			throw 'You are not allowed to change the length.';	
		}
	}
	
	@:setter(endian) function set_endian(endian:String):Void {
		throw 'You are not allowed to change the endian.';
	}
}