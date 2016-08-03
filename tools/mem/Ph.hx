package mem;

import mem.Ptr;

/**
PtrHelper
*/
class Ph{
	// [a,b,c,d] = [d,c,b,a] in bytes
	static public function reverse(ptr:Ptr, len:Int):Void{
		var right = ptr + len - 1;
		var cc:Int;
		while(ptr < right){
			cc = Memory.getByte(ptr);
			Memory.setByte(ptr++, Memory.getByte(right));
			Memory.setByte(right--, cc);
		}
	}
}