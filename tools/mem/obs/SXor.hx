package mem.obs;


#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools.here;
import haxe.crypto.Md5;
import haxe.io.Bytes;
import haxe.Int64;
import mem.Ut;
import mem.obs.SxIntBuild;

/**
* 构建一个 256 字节的数据字段, 在生成后将为固定的字节, 或许未来将从网络上获得生成好的 256 字节 + 8个Int 的明码.
*/
class SxBuild{
	static inline var SX_MAX = 256;
	public static function make(dk:String){
		var dv:String = Context.definedValue(dk);
		if (dv == null || dv == "" || dv == "1") Context.error("Must provide -D " + dk + "=passwd", here());
		var keys = Md5.make(Bytes.ofString(dv));
		var bytes = Bytes.alloc(SX_MAX);

		// 随机填充数据
		for (i in 0...SX_MAX) bytes.set(i, Ut.rand(SX_MAX, 1));


		// 随机的位置, 不过最终这个值还是固定值, 一次性生成 12 个, 后 8 位用于存放地址的地址
		var sx:Array<Int> = [];
		for(i in 1...(SX_MAX >> 2) - 1){
			sx.push(i << 2);
		}
		Ut.shuffle(sx, 5);
		sx = sx.slice(0, 12);
		Ut.shuffle(sx, 2);

		var i64s:Array<haxe.Int64> = [];
		for (i in 0...4) {
			i64s[i] = SxIntBuild.make(sx[i], i);			// Int64(位置)
			//bytes.setInt32(sx[i], keys.getInt32(i << 2)); // error ????
			for (j in 0...4) {
				bytes.set(sx[i] + j, keys.get((i << 2) + j));					// 将 key  值写入
				bytes.set(sx[4 + i] + j , (i64s[i].low >> (j * 8)) & 0xFF);		// 将 low  值写入
				bytes.set(sx[8 + i] + j , (i64s[i].high >> (j * 8)) & 0xFF);	// 将 hight值写入
			}
		}
		//trace(i64s[0].low == bytes.getInt32(sx[4 + 0]) &&  i64s[0].high == bytes.getInt32(sx[8 + 0]));
		//trace(i64s[3].low == bytes.getInt32(sx[4 + 3]) &&  i64s[3].high == bytes.getInt32(sx[8 + 3]));
		//trace(sx.toString() + ", md5: " + keys.toHex());

		var fields = Context.getBuildFields();

		var codes:Array<Expr> = [];
		var chunk = SX_MAX >> 2;	// (256/4) = 64
		for (i in 0...chunk) codes.push( macro Memory.setI32(sa.c_ptr + $v{i << 2}, $v{bytes.getInt32($v{i << 2})}) );
		Ut.shuffle(codes, 3);

		var pos = here();
		fields.push({
			name: "init",
			access: [APublic, AStatic, AInline],
			meta:[{name: ":dce", pos: pos}],
			pos: pos,
			kind: FFun({
				ret: macro :Void,
				args:[],
				expr: macro {
					if (@:privateAccess Ram.current == null) throw "Need to init ApplicationDomain.currentDomain.domainMemory";
					if (sa != mem.Malloc.NUL) return;
					sa = new SxKeys($v{SX_MAX});
					$b{codes};
					x_0 = SxInt.fromInt2(Memory.getI32(sa.c_ptr + $v{sx[4 + 0]}), Memory.getI32(sa.c_ptr + $v{sx[8 + 0]}));
					x_1 = SxInt.fromInt2(Memory.getI32(sa.c_ptr + $v{sx[4 + 1]}), Memory.getI32(sa.c_ptr + $v{sx[8 + 1]}));
					x_2 = SxInt.fromInt2(Memory.getI32(sa.c_ptr + $v{sx[4 + 2]}), Memory.getI32(sa.c_ptr + $v{sx[8 + 2]}));
					x_3 = SxInt.fromInt2(Memory.getI32(sa.c_ptr + $v{sx[4 + 3]}), Memory.getI32(sa.c_ptr + $v{sx[8 + 3]}));
				}
			})
		});

		return fields;
	}
}

#else

import mem.Ptr;
import mem.obs.SxInt;
import mem.obs.SxIntBuild;

@:build(mem.obs.SXor.SxBuild.make("sx-pwd"))
@:dce class SXor{
	static var x_0:SxInt;
	static var x_1:SxInt;
	static var x_2:SxInt;
	static var x_3:SxInt;
	static var sa:SxKeys = mem.Malloc.NUL;

	public static inline function make(src:Ptr, len:Int, dst:Ptr):Void{
		//if (dst == -1)
			//dst = src;
		//else if (dst > src && dst < src + len)
			//throw "It will be overwritten";
		var offset = 0;
		var b4 = len - (len % 4);
		var mod = 0;
		while (b4 > offset){
			mod = offset >> 2;
			switch(mod % 4){
			case 0: Memory.setI32(dst + offset, Memory.getI32(src + offset) ^ Memory.getI32( sa.c_ptr + x_0.calc_0() ));
			case 1: Memory.setI32(dst + offset, Memory.getI32(src + offset) ^ Memory.getI32( sa.c_ptr + x_1.calc_1() ));
			case 2: Memory.setI32(dst + offset, Memory.getI32(src + offset) ^ Memory.getI32( sa.c_ptr + x_2.calc_2() ));
			default:Memory.setI32(dst + offset, Memory.getI32(src + offset) ^ Memory.getI32( sa.c_ptr + x_3.calc_3() ));
			}
			offset += 4;
		}
		while (len > offset) {
			mod = offset % 16;
			switch(mod >> 2){
			case 0: Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte((mod % 4) + sa.c_ptr + x_0.calc_0() ));
			case 1: Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte((mod % 4) + sa.c_ptr + x_1.calc_1() ));
			case 2: Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte((mod % 4) + sa.c_ptr + x_2.calc_2() ));
			default:Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte((mod % 4) + sa.c_ptr + x_3.calc_3() ));
			}
			offset += 1;
		}
	}

	public static inline function test(){
		var t = haxe.io.Bytes.alloc(16);
		var p0 = x_0.calc_0();
		var p1 = x_1.calc_1();
		var p2 = x_2.calc_2();
		var p3 = x_3.calc_3();
		trace([p0, p1, p2, p3]);
	#if flash
		Ram.readBytes(sa.c_ptr + p0, 4, t.getData());
		Ram.readBytes(sa.c_ptr + p1, 4, t.getData());
		Ram.readBytes(sa.c_ptr + p2, 4, t.getData());
		Ram.readBytes(sa.c_ptr + p3, 4, t.getData());
		trace(t.toHex());
	#end
	}

}
#end