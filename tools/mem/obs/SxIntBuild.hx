package mem.obs;

/**
 only used when macro build, if release
*/
import mem.Ptr;

@:enum private abstract ToIntMod(Int) from Int{
	var ZERO = 0;
	var ONE = 1;
	var TWO = 2;
	var THREE = 3;
}

@:dce class SxIntBuild{

	static function vx(v:Int):Array<Int>{
		var va = [0, 0, 0, 0, 0, 0, 0, 0];

		va[0] = v > 0xFF ? 0xFF : v;

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
	// only for test or macro build
	public static function make(v:Int, mod:ToIntMod = ZERO):haxe.Int64{
		var va = vx(v);
		switch (mod) {//(va[4] | va[5] << 8 | va[6] << 16 | va[7] << 24, va[0] | va[1] << 8 | va[2] << 16 | va[3] << 24)
			case ZERO: // 4~7, 3~6, 0~5, 1~2
				return haxe.Int64.make(va[7] | va[0] << 8 | va[3] << 16 | va[4] << 24, va[5] | va[2] << 8 | va[1] << 16 | va[6] << 24);
			case ONE:  // 0~7, 2~5, 3~4, 1~6
				return haxe.Int64.make(va[3] | va[2] << 8 | va[1] << 16 | va[0] << 24, va[7] | va[6] << 8 | va[5] << 16 | va[4] << 24);
			case TWO:  // 0~4, 1~7, 2~6, 3~5
				return haxe.Int64.make(va[0] | va[3] << 8 | va[2] << 16 | va[1] << 24, va[4] | va[7] << 8 | va[6] << 16 | va[5] << 24);
			case THREE:// 4~5, 6~7, 0~1, 2~3
				return haxe.Int64.make(va[5] | va[4] << 8 | va[7] << 16 | va[6] << 24, va[1] | va[0] << 8 | va[3] << 16 | va[2] << 24);
		}
	}
}