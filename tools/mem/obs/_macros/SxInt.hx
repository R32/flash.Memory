package mem.obs._macros;


#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools.here;
import haxe.crypto.Md5;
import haxe.io.Bytes;
import haxe.Int64;
import mem.Ut;
@:dce class SXorBuild {
	static function vx(v: Int/*uint8_t*/): Array<Int> {
		var va = [0, 0, 0, 0, 0, 0, 0, 0];

		va[0] = v & 0xFF;

		va[7] = mem.Ut.rand(0xFF, 1);
		va[0] ^= va[7];

		// (~45 & 0xFF) == 210
		// ((100 & 210) | (100 & 45)) == 100
		va[6] = mem.Ut.rand(0xFF, 1);
		va[5] = va[0] & va[6];
		va[0] &= ~va[6] & 255;
		va[0] ^= va[5];

		va[4] = mem.Ut.rand(0xFF, 1);
		va[3] = va[0] & va[4];
		va[0] &= ~va[4] & 255;
		va[0] ^= va[3];

		va[2] = mem.Ut.rand(0xFF, 1);
		va[1] = va[0] & va[2];
		va[0] &= ~va[2] & 255;
		va[0] ^= va[1];
		return va;
	}
	// 一个 0x04 ~ 0xF7 的数(必须为4的整倍)用于分段保存密钥的地址
	static function createSxInt(v: Int/*uint8_t*/, mod = 0): haxe.Int64{
		var va = vx(v);
		switch (mod) {//(va[4] | va[5] << 8 | va[6] << 16 | va[7] << 24, va[0] | va[1] << 8 | va[2] << 16 | va[3] << 24)
			case 0:  // 4~7, 3~6, 0~5, 1~2
				return haxe.Int64.make(va[7] | va[0] << 8 | va[3] << 16 | va[4] << 24, va[5] | va[2] << 8 | va[1] << 16 | va[6] << 24);
			case 1:  // 0~7, 2~5, 3~4, 1~6
				return haxe.Int64.make(va[3] | va[2] << 8 | va[1] << 16 | va[0] << 24, va[7] | va[6] << 8 | va[5] << 16 | va[4] << 24);
			case 2:  // 0~4, 1~7, 2~6, 3~5
				return haxe.Int64.make(va[0] | va[3] << 8 | va[2] << 16 | va[1] << 24, va[4] | va[7] << 8 | va[6] << 16 | va[5] << 24);
			case 3:  // 4~5, 6~7, 0~1, 2~3
				return haxe.Int64.make(va[5] | va[4] << 8 | va[7] << 16 | va[6] << 24, va[1] | va[0] << 8 | va[3] << 16 | va[2] << 24);
			case _:
				throw "???";
		}
	}

	public static function make(dk:String){
		var dv:String = Context.definedValue(dk);
		if (dv == null || dv == "" || dv == "1") Context.error("Must provide -D " + dk + "=passwd", here());
		var keys = Md5.make(Bytes.ofString(dv));

		// 随机数据串, 最后它将 ==  密钥(16字节) + (4 * SxInt(8字节每个)) + (rand_uint8 * REST)
		var bytes = Bytes.alloc(SX_MAX);
		// 值随机为 [0x4, 0xF7],
		for (i in 0...SX_MAX) bytes.set(i, Ut.rand(SX_MAX - 8, 4) );


		// 密钥将要存放的位置, 位置是随机的 确保其为 4 的整倍数
		var cx:Array<Int> = [];
		for(i in 1...(SX_MAX >> 2) - 1){ // i in [1, 63) if SX_MAX == 256
			cx.push(i << 2);
		}
		Ut.shuffle(cx, 5);
		cx = cx.slice(0, 12);
		Ut.shuffle(cx, 2);

		var i64s:Array<haxe.Int64> = [];
		for (i in 0...4) {
			i64s[i] = createSxInt(cx[i], i);
			for (j in 0...4) {
				bytes.set(cx[i + 0] + j , keys.get((i << 2) + j));
				bytes.set(cx[4 + i] + j , (i64s[i].low >> (j * 8)) & 0xFF);
				bytes.set(cx[8 + i] + j , (i64s[i].high >> (j * 8)) & 0xFF);
			}
		}

		var fields = Context.getBuildFields();

		var codes:Array<Expr> = [];

		if (Context.defined("flash10_3")) {
			var chunk = SX_MAX >> 2;	// (256/4) = 64
			for (i in 0...chunk)
				codes.push( macro Memory.setI32(p + $v{i << 2}, $v{bytes.getInt32($v{i << 2})}) );
			Ut.shuffle(codes, 3);
		}else{
			codes.push(macro {
				var hex = $v{bytes.toHex()};
				var i = 0;
				while (i < $v{SX_MAX << 1}){ // 256 * 2
					Memory.setByte(p + (i >> 1), Std.parseInt("0x" + hex.charAt(i) + hex.charAt(i + 1)));
					i += 2;
				}
			});
		}

		var pos = here();
		fields.push({
			name: "init",
			access: [APublic, AStatic],
			meta:[{name: ":analyzer", pos: pos, params:[macro no_const_propagation]}],
			pos: pos,
			kind: FFun({
				ret: macro :Void,
				args:[],
				expr: macro {
					if (@:privateAccess Ram.current == null) throw "Ram.current is null";
					if (sa != mem.Malloc.NUL) return;
					sa = Malloc.make($v { SX_MAX }, false);
					var p:Int = cast sa;
					$a{codes};
					x_0 = x_n(Memory.getI32(p + $v{cx[4 + 0]}), Memory.getI32(p + $v{cx[8 + 0]}));
					x_1 = x_n(Memory.getI32(p + $v{cx[4 + 1]}), Memory.getI32(p + $v{cx[8 + 1]}));
					x_2 = x_n(Memory.getI32(p + $v{cx[4 + 2]}), Memory.getI32(p + $v{cx[8 + 2]}));
					x_3 = x_n(Memory.getI32(p + $v{cx[4 + 3]}), Memory.getI32(p + $v{cx[8 + 3]}));
				}
			})
		});

		return fields;
	}
	static inline var SX_MAX = 256;
}
#end

// 0 --- 4~7,3~6,0~5,1~2
//// v_0 ^ v_1 | (v_2 & v_1) ^ v_3 | (v_4 & v_3) ^ v_5 | (v_6 & v_5) ^ v_7
//   v_5 ^ v_2 | (v_1 & v_2) ^ v_6 | (v_7 & v_6) ^ v_0 | (v_3 & v_0) ^ v_4;

// 1 --- 0~7,2~5,3~4,1~6
//// v_0 ^ v_1 | (v_2 & v_1) ^ v_3 | (v_4 & v_3) ^ v_5 | (v_6 & v_5) ^ v_7
//   v_7 ^ v_6 | (v_5 & v_6) ^ v_4 | (v_3 & v_4) ^ v_2 | (v_1 & v_2) ^ v_0;

// 2 --- 0~4, 1~7, 2~6, 3~5
//// v_0 ^ v_1 | (v_2 & v_1) ^ v_3 | (v_4 & v_3) ^ v_5 | (v_6 & v_5) ^ v_7
//   v_4 ^ v_7 | (v_6 & v_7) ^ v_5 | (v_0 & v_5) ^ v_3 | (v_2 & v_3) ^ v_1;

// 3 --- 4~5, 6~7, 0~1, 2~3
//// v_0 ^ v_1 | (v_2 & v_1) ^ v_3 | (v_4 & v_3) ^ v_5 | (v_6 & v_5) ^ v_7
//   v_1 ^ v_0 | (v_3 & v_0) ^ v_2 | (v_5 & v_2) ^ v_4 | (v_7 & v_4) ^ v_6;

@:dce class SxInt {
  #if (macro || flash)
	macro public static function c0(v) return macro untyped (__vmem_get__(0, $v + 5) ^ __vmem_get__(0, $v + 2) | (__vmem_get__(0, $v + 1) & __vmem_get__(0, $v + 2)) ^ __vmem_get__(0, $v + 6) | (__vmem_get__(0, $v + 7) & __vmem_get__(0, $v + 6)) ^ __vmem_get__(0, $v + 0) | (__vmem_get__(0, $v + 3) & __vmem_get__(0, $v + 0)) ^ __vmem_get__(0, $v + 4));
	macro public static function c1(v) return macro untyped (__vmem_get__(0, $v + 7) ^ __vmem_get__(0, $v + 6) | (__vmem_get__(0, $v + 5) & __vmem_get__(0, $v + 6)) ^ __vmem_get__(0, $v + 4) | (__vmem_get__(0, $v + 3) & __vmem_get__(0, $v + 4)) ^ __vmem_get__(0, $v + 2) | (__vmem_get__(0, $v + 1) & __vmem_get__(0, $v + 2)) ^ __vmem_get__(0, $v + 0));
	macro public static function c2(v) return macro untyped (__vmem_get__(0, $v + 4) ^ __vmem_get__(0, $v + 7) | (__vmem_get__(0, $v + 6) & __vmem_get__(0, $v + 7)) ^ __vmem_get__(0, $v + 5) | (__vmem_get__(0, $v + 0) & __vmem_get__(0, $v + 5)) ^ __vmem_get__(0, $v + 3) | (__vmem_get__(0, $v + 2) & __vmem_get__(0, $v + 3)) ^ __vmem_get__(0, $v + 1));
	macro public static function c3(v) return macro untyped (__vmem_get__(0, $v + 1) ^ __vmem_get__(0, $v + 0) | (__vmem_get__(0, $v + 3) & __vmem_get__(0, $v + 0)) ^ __vmem_get__(0, $v + 2) | (__vmem_get__(0, $v + 5) & __vmem_get__(0, $v + 2)) ^ __vmem_get__(0, $v + 4) | (__vmem_get__(0, $v + 7) & __vmem_get__(0, $v + 4)) ^ __vmem_get__(0, $v + 6));
  #else
	#if js inline #end public static function c0(v:mem.Ptr.AU8):Int return v[5] ^ v[2] | (v[1] & v[2]) ^ v[6] | (v[7] & v[6]) ^ v[0] | (v[3] & v[0]) ^ v[4];
	#if js inline #end public static function c1(v:mem.Ptr.AU8):Int return v[7] ^ v[6] | (v[5] & v[6]) ^ v[4] | (v[3] & v[4]) ^ v[2] | (v[1] & v[2]) ^ v[0];
	#if js inline #end public static function c2(v:mem.Ptr.AU8):Int return v[4] ^ v[7] | (v[6] & v[7]) ^ v[5] | (v[0] & v[5]) ^ v[3] | (v[2] & v[3]) ^ v[1];
	#if js inline #end public static function c3(v:mem.Ptr.AU8):Int return v[1] ^ v[0] | (v[3] & v[0]) ^ v[2] | (v[5] & v[2]) ^ v[4] | (v[7] & v[4]) ^ v[6];
  #end
}
