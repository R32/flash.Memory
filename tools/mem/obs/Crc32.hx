package mem.obs;

import mem.Ptr;

/**
Crc32 checksum using a const table
*/
class Crc32 {

	static var table:AI32 = cast Ptr.NUL;

	public static function init() {
		if (table != Ptr.NUL) return;
		table = cast Fraw.malloc(256 << 2, false);

		var i = 0, j = 0, d = 0;

		while (i < 256) {
			d = i;
			j = 0;
			while (j < 8) {
				if (d & 1 == 0)
					d >>>= 1;
				else
					d =  0xEDB88320 ^ (d >>> 1);
			++j;
			}
			table[i] = d;
		++i;
		}
	}

	public static function make(data: Ptr, len: Int): Int {
		var i = 0, index = 0 , crc = 0xFFFFFFFF;
		var tb:AI32 = table;
		while (i < len) {
			index = (crc ^ data[i]) & 0xFF;
			crc = (crc >>> 8) ^ tb[index];
		++i;
		}
		return ~crc;
	}
}