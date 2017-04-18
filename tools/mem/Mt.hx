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
}