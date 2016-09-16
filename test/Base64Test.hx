package;

import StringTools.hex;

class Base64Test {
	public static function main() {
		Ram.select();
		mem.obs.Crc32.init();
		mem.struct.Base64.init();
		mem.obs.Hex.init();

		var file = haxe.Resource.getBytes("res"); // -resource
		if (file == null)
			throw "need -resource XXXXX@res";
		var fp = Ram.mallocFromBytes(file);
		trace('file: ${file.length / 1024}KB');

		// crc32
		var last = haxe.Timer.stamp();
		var r0 = haxe.crypto.Crc32.make(file);        // calc
		var rt0 = haxe.Timer.stamp() - last;

		last = haxe.Timer.stamp();
		var r1 = mem.obs.Crc32.make(fp, file.length); // calc
		var rt1 = haxe.Timer.stamp() - last;
		trace('haxe crc32 : ${hex(r0)}, time sec: $rt0');
		trace('mem crc32 : ${hex(r1)}, time sec: $rt1');

		// adler32
		last = haxe.Timer.stamp();
		var a0 = haxe.crypto.Adler32.make(file);      // calc
		var at0 = haxe.Timer.stamp() - last;
		last = haxe.Timer.stamp();
		var a1 = mem.Ph.adler32(fp, file.length);     // calc
		var at1 = haxe.Timer.stamp() - last;
		trace('haxe adler32 : ${hex(a0)}, time sec: $at0');
		trace('mem adler32 : ${hex(a1)}, time sec: $at1');

		// base64
		last = haxe.Timer.stamp();
		var b0 = haxe.crypto.Base64.encode(file);     // encode
		var bd0 = haxe.crypto.Base64.decode(b0);      // decode
		var bt0 = haxe.Timer.stamp() - last;

		last = haxe.Timer.stamp();
		var b1 = mem.struct.Base64.encode(fp, file.length);  // encode
		var bd1 = b1.toBlock();                              // decode
		var bt1 = haxe.Timer.stamp() - last;
		trace('haxe base64 enc/dec : time sec: $bt0');
		trace('mem base64 enc/dec : time sec: $bt1');

		trace(b0 == b1.toString());
		trace(Ram.memcmp(fp, bd1, file.length));
	}
}
