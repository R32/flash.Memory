package;

import raw.Ptr;
import raw.Fixed;
import raw.Ucs2;
import raw.fmt.WString;

class RawTest {

	static function main() {
		Raw.attach();
		t_malloc();
		t_fixed();
		//
		t_ucs2();
		t_base64();
		t_aes128();

		// malloc by fixed-alloter
		var j1 = new Monkey(101, "Jo 乔");
		var j2 = new Monkey(202, "Shi 什");
		eq((j2: Ptr) - (j1: Ptr) == MonkeyAlc.SIZEOF, "Monkey(fixed-alloter)");
	}
	static inline function BLK16(size) return new raw.fmt.FBlock(size, false, 16);

	static function t_ucs2() {
		var str = "hi 为什么这样子";
		var size = Raw.writeUcs2(Ptr.NUL, str);
		var s1 = BLK16(size);
		Raw.writeUcs2(s1, str, size);
		eq(str == Raw.readUcs2(s1, size), "UCS2");
		s1.free();
	}

	static function t_aes128() {
		var sa = [
			"6bc1bee22e409f96e93d7e117393172a",
			"ae2d8a571e03ac9c9eb76fac45af8e51",
			"30c81c46a35ce411e5fbc1191a0a52ef",
			"f69f2445df4f9b17ad2b417be66c3710"
		];
		var re = [
			"3ad77bb40d7a3660a89ecaf32466ef97",
			"f5d3d58503b9699de785895a96fdbaaf",
			"43b1cd7f598ece23881b00e3ed030688",
			"7b0c785e27e8ad3f8223207104725dd4"
		];

		var key = Raw.mallocFromHex("2b7e151628aed2a6abf7158809cf4f3c");
		for (i in 0...sa.length) {
			var b = Raw.mallocFromHex(sa[i]);
			var o = BLK16(b.length);
			var r = Raw.mallocFromHex(re[i]);

			raw.fmt.AES128.ecbEncrypt(b, key, o);
			eq(Raw.memcmp(o, r, b.length) == 0, "AES EBC Encrypt");

			raw.fmt.AES128.ecbDecrypt(o, key, o); // input == output
			eq(Raw.memcmp(o, b, b.length) == 0, "AES EBC Decrypt");
			b.free();
			o.free();
			r.free();
		}

		var b4 = Raw.mallocFromHex(sa.join("")); // length = 16 * 4;
		var o4 = BLK16(b4.length);
		var o5 = BLK16(b4.length);

		var o6 = BLK16(b4.length);
		var o7 = BLK16(b4.length);

		raw.fmt.AES128.cbcEncryptBuff(b4, key, o4, b4.length, Ptr.NUL);  //
		raw.fmt.AES128Embed.init();  // copy const KeyExpansion
		raw.fmt.AES128Embed.cbcEncryptBuff(b4, o6, b4.length, Ptr.NUL);  // AES128Embed
		eq(Raw.memcmp(o4, o6, b4.length) == 0, "CBC AES128Embed == AES128");

		raw.fmt.AES128.cbcDecryptBuff(o4, key, o5, b4.length, Ptr.NUL);  // input != output
		raw.fmt.AES128.cbcDecryptBuff(o4, key, o4, b4.length, Ptr.NUL);  // input == output
		raw.fmt.AES128Embed.init();  // copy const KeyExpansion
		raw.fmt.AES128Embed.cbcDecryptBuff(o6, o7, b4.length, Ptr.NUL);  // AES128Embed
		eq(Raw.memcmp(b4, o4, b4.length) == 0, "AES CBC Encrypt/Decrypt(input != output)");
		eq(Raw.memcmp(b4, o5, b4.length) == 0, "AES CBC Encrypt/Decrypt(input == output)");
		eq(Raw.memcmp(b4, o7, b4.length) == 0, "AES CBC AES128Embed");

		b4.free();
		o4.free();
		o5.free();
		o6.free();
		o7.free();
		key.free();
	}

	static function t_base64() {
		var str = "hi 为什么这样子";
		var s1 = Raw.mallocFromString(str);
		var b64 = raw.fmt.Base64.encode(s1, s1.length);
		eq(b64.toString() == haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(str)), "Base64 Encode");
		var s2 = raw.fmt.Base64.decode(b64, b64.length);
		eq(Raw.memcmp(s1, s2, s1.length) == 0, "Base64 Decode");

		var b1 = Raw.mallocFromHex("003c176e659bea0f29a3e9bf7880c112b1b31b4dc826268187");
		var b58 = raw.fmt.Base58.encode(b1, b1.length);
		eq(b58.toString() == "16UjcYNBG9GTK4uq2f7yYEbuifqCzoLMGS", "Base58 Encode");
		var b2 = raw.fmt.Base58.decode(b58, b58.length);
		eq(Raw.memcmp(b1, b2, b1.length) == 0, "Base58 Decode");
	}

	static function t_malloc() {
		function randAlloc() {
			return Raw.malloc(Std.int(512 * Math.random()) + 16);
		}
		var ap = [];

		for (i in 0...512) ap.push(randAlloc());   // alloc 512
		raw.Ut.shuffle(ap);

		for (i in 0...256) Raw.free(ap.pop());     // free 256
		//trace(raw.Malloc.toString());

		for (i in 0...256) ap.push(randAlloc());   // alloc 256
		raw.Ut.shuffle(ap);

		for (i in 0...256) Raw.free(ap.pop());     // free 256
		//trace(raw.Malloc.toString());

		for (i in 0...256) Raw.free(ap.pop());     // free 256
		//trace(raw.Malloc.toString());

		eq(raw.Malloc.isEmpty(), "raw.Malloc");
	}

	static function t_fixed() @:privateAccess {
		function iter(v) {
			var cur = Chunk.h;
			var rest = 0;
			while (cur != Ptr.NUL) {
				//trace(cur.toString());
				rest += cur.rest;
				cur = cur.next;
			}
			eq(v == rest, "t_fixed");
			//trace('-----------------');
		}

		var ap = [];
		for (i in 0...64) ap.push(Chunk.malloc(0, false));
		raw.Ut.shuffle(ap);

		for (i in 0...32) Chunk.free(ap.pop());     // free 256
		iter(32);

		for (i in 0...32) ap.push(Chunk.malloc(0, false));
		iter(0);
		raw.Ut.shuffle(ap);
		for (i in 0...64) Chunk.free(ap.pop());     // free 512
		iter(64);

		Chunk.destory();
		eq(raw.Malloc.isEmpty(), "after Chunk.destory");
	}
	static inline function eq(expr, msg) if (!expr) throw msg;
}

#if !macro
@:build(raw.Struct.make({count: 64}))
#end
abstract Monkey(Ptr) to Ptr {
	@idx(4 ) var id: Int;
	@idx(16) var name: String;

	public inline function new(i, n) {
		mallocAbind(CAPACITY, false);
		id = i;
		name = n;
	}
}
