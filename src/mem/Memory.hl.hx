package mem;

import Mem.b;

@:access(Mem.b) extern class Memory {
	static inline function select(rd : mem.RawData): Void {}
	static inline function setByte(i: Int, v: Int):Void b.setUI8(i, v);
	static inline function setI16 (i: Int, v: Int):Void b.setUI16(i, v);
	static inline function setI32 (i: Int, v: Int):Void b.setI32(i, v);
	static inline function setFloat (i: Int, v: Float):Void b.setF32(i, v);
	static inline function setDouble(i: Int, v: Float):Void b.setF64(i, v);

	static inline function getByte(i: Int):Int return b.getUI8(i);
	static inline function getUI16(i: Int):Int return b.getUI16(i);
	static inline function getI32 (i: Int):Int return b.getI32(i);
	static inline function getFloat (i: Int):Float return b.getF32(i);
	static inline function getDouble(i: Int):Float return b.getF64(i);

	static inline function signExtend1(v: Int):Int return v & 1 == 1 ? 0xffffffff : 0;
	static inline function signExtend8(v: Int):Int return v & 0x80 == 0x80 ? v | 0xffffff00:v;
	static inline function signExtend16(v: Int):Int return v & 0x8000 == 0x8000 ? v | 0xffff0000: v;
}