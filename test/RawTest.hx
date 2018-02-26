package;

import raw.Ptr;
import raw.Fixed;
import raw.Ucs2;
import raw.fmt.WString;
import haxe.io.Bytes;

class RawTest {

	static inline function platform() {
		return
		#if flash
		"flash";
		#elseif hl
		"hl";
		#elseif js
		"js";
		#else
		"others";
		#end
	}

	static function main() {
		Raw.attach();
		t_malloc();
		t_fixed();
		//
		t_ucs2();
		t_base64();
		t_aes128();
		t_hash();

		// malloc by fixed-alloter
		var j1 = new Monkey(101, "Jo 乔");
		var j2 = new Monkey(202, "Shi 什");
		//trace(j1.__toOut());
		//trace(j2.__toOut());
		trace(platform() + " done!");
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
		raw.fmt.AES128.init();
		raw.fmt.AES128Embed.init();
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

	static function t_hash() {
		function eq_sha1(s: String) {
			var b = haxe.crypto.Sha1.make(haxe.io.Bytes.ofString(s));
			var si = Raw.mallocFromString(s);
			var so = new raw.fmt.FBlock(16, false, 8);
			raw.fmt.Sha1.make(si, si.length, so);
			var sb = Raw.mallocFromBytes(b);
			eq(Raw.memcmp(sb, so, so.length) == 0, "sha1");
			si.free();
			so.free();
			sb.free();
		}
		eq_sha1("hello world!");
		eq_sha1("0123456789");
		eq_sha1("明月几时有 把酒问青天");
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
		var fixed = Monkey.__fx;
		eq(fixed.TRAILING_ONES(0x7FFFFFFF) == 31, "TRAILING_ONES 1");
		eq(fixed.TRAILING_ONES(0xFFFFFFF7) ==  3, "TRAILING_ONES 2");
		eq(fixed.TRAILING_ONES(0x00000000) ==  0, "TRAILING_ONES 3");
		eq(fixed.TRAILING_ONES(0xFFF0FFFF) == 16, "TRAILING_ONES 4");
		eq(fixed.TRAILING_ONES(0xFFFFFF0F) ==  4, "TRAILING_ONES 5");

		function iter(v, ?pos: haxe.PosInfos) {
			var cur = fixed.h;
			var rest = 0;
			while (cur != Ptr.NUL) {
				//trace(fixed.chunk_detail(cur));
				rest += fixed.chunk_rest(cur);
				cur = cur.next;
			}
			eq(v == rest, "t_fixed: line: ", pos);
			//trace(fixed.toString());
		}

		var ap = [];
		for (i in 0...960) ap.push(fixed.malloc(0, false));
		eq(ap[23] == fixed.chunk_piece_ptr(fixed.h, 23), "chunk_piece_ptr");
		eq(((fixed.chunk_data_ptr(fixed.h) - fixed.h.meta) << 3) == fixed.ct, "chunk_data_ptr");
		raw.Ut.shuffle(ap);
		iter(0);

		for (i in 0...480) fixed.free(ap.pop());     // free 480
		iter(480);

		for (i in 0...480) ap.push(fixed.malloc(0, false));
		iter(0);
		raw.Ut.shuffle(ap);

		for (i in 0...960) fixed.free(ap.pop());     // free 960
		iter(960);
		fixed.destory();
		eq(raw.Malloc.isEmpty(), "after Chunk.destory");

	}
	static function eq(expr, msg, ?pos: haxe.PosInfos) if (!expr) throw '$msg: ----- line: ${pos.lineNumber}';
}

#if !macro
@:build(raw.Struct.make({bulk: 10}))
#end
abstract Monkey(Ptr) to Ptr {
	@idx(4 ) var id: Int;
	@idx(16) var name: String;

	public inline function new(i, n) {
		mallocAbind(CAPACITY, false); // the fixed allocater will ignore the value of first params.
		id = i;
		name = n;
	}
}
