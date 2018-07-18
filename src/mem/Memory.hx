package mem;

import Mem.b;

@:access(Mem.b) extern class Memory {
	static inline function select(rd : mem.RawData): Void {};
	static inline function setByte(i: Int, v: Int):Void b.set(i, v);
	static inline function setI16 (i: Int, v: Int):Void b.setUInt16(i, v);
	static inline function setI32 (i: Int, v: Int):Void b.setInt32(i, v);
	static inline function setFloat (i: Int, v: Float):Void b.setFloat(i, v);
	static inline function setDouble(i: Int, v: Float):Void b.setDouble(i, v);

	static inline function getByte(i: Int):Int return b.get(i);
	static inline function getUI16(i: Int):Int return b.getUInt16(i);
	static inline function getI32 (i: Int):Int return b.getInt32(i);
	static inline function getFloat (i: Int):Float return b.getFloat(i);
	static inline function getDouble(i: Int):Float return b.getDouble(i);

	static inline function signExtend1(v: Int):Int return v & 1 == 1 ? 0xffffffff : 0;
	static inline function signExtend8(v: Int):Int return v & 0x80 == 0x80 ? v | 0xffffff00:v;
	static inline function signExtend16(v: Int):Int return v & 0x8000 == 0x8000 ? v | 0xffff0000: v;
}
