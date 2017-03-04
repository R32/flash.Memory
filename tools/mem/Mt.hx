package mem;



/**
some macro or inline values
*/
@:dce class Mt {

	// http://codereview.stackexchange.com/questions/77782/quick-sort-implementation#answer-77788
	// Note: sometimes still stack overflow when input is greater than 30K on flash player debug
	macro static public function qsort(rec) return macro @:mergeBlock {
		if (left >= right) return;

		var i = left, j = right;

		var mid = left + (right - left >> 1);

		var pivot = a[mid]; // swap(left, mid) to prevent stack overflow

		var ti = a[left], tj = pivot;
		if (left < mid) {
			a[left] = tj;
			a[mid]  = ti;
		}

		while (i < j) {
			while (i < j) {
				tj = a[j];
				if (tj < pivot) break;
			-- j;
			}

			while (i < j) {
				ti = a[i];
				if (ti > pivot) break;
			++ i;
			}

			if (i < j) {
				a[i] = tj;
				a[j] = ti;
			}
		}

		if (left < i) {
			a[left] = a[i];
			a[i] = pivot;
			$rec(left , i - 1, a);
		}
		if (i + 1 < right) $rec(i + 1, right, a);
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
		// The first part of the table maps bytes to character classes that
		// to reduce the size of the transition table and create bitmasks.
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
		7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
		8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
		10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8,

		// The second part is a transition table that maps a combination
		// of a state of the automaton and a character class to a state.
		0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
		12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
		12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
		12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
		12,36,12,12,12,12,12,12,12,12,12,12,
	];
#end
}