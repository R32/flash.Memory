package mem;



/**
some macro or inline values
*/
@:dce class Mt {

	// ref by Ph.sortU8, or Ph.sortI32
	// https://github.com/ParkinWu/FastSort
	macro static public function qsort(rec) return macro @:mergeBlock {
		if (left >= right) return;
		var i = left, j = right;
		var pivot = a[left];

		var ti = pivot, tj = pivot; // auto type

		while (i < j) {
			while (i < j) {
				tj = a[j];
				if (tj < pivot) break;
			--j;
			}
			while (i < j) {
				ti = a[i];
				if (ti > pivot) break;
			++i;
			}
			if (i < j && ti != tj) {
				a[i] = tj;
				a[j] = ti;
			}
		}
		if (left < i) {
			a[left] = a[i];
			a[i] = pivot;
			$rec(left , i - 1, a);
			$rec(i + 1, right, a);
		} else {
			$rec(i + 1, right, a);
		}
	};

	// for mem.Utf8
	macro static public function utf8DataTo32() {
		var len = utf8_init_data.length;
		var byte = haxe.io.Bytes.alloc(len);
		for (i in 0...len)
			byte.set(i, utf8_init_data[i]);
		return macro $v{ [for (i in 0...len >> 2) byte.getInt32(i << 2) ] };
	}
#if macro
	static var utf8_init_data = [
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 00..1f
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 20..3f
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 40..5f
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 60..7f
		1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, // 80..9f
		7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, // a0..bf
		8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, // c0..df
		0xa,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x4,0x3,0x3, // e0..ef
		0xb,0x6,0x6,0x6,0x5,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8, // f0..ff
		0x0,0x1,0x2,0x3,0x5,0x8,0x7,0x1,0x1,0x1,0x4,0x6,0x1,0x1,0x1,0x1, // s0..s0
		1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1, // s1..s2
		1,2,1,1,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1, // s3..s4
		1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,3,1,1,1,1,1,1, // s5..s6
		1,3,1,1,1,1,1,3,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1, // s7..s8
	];
#end
}