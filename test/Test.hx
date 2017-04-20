package;

import mem.obs.SXor;
import mem.obs.Hex;
import mem.Ptr;
import mem.Ut;
import mem.Ut.toFixed;
import mem.Ph;
import mem.obs.Md5;
import mem.obs.Sha1;
import mem.obs.Sha256;
import mem.obs.AES128;
import mem.struct.WString;
import mem.struct.AString;
import mem.Utf8;
import mem.Malloc.dump;
#if cpp
import mem.cpp.Gbk;
import mem.cpp.BytesData;
import mem.cpp.NRam;
#end
import haxe.Log;

class Test {
	public static function main(){
		Ram.attach(1024);
		Ram.malloc(Ut.rand(128, 1), false);
		Hex.init();
		SXor.init();
		Utf8.init();
		Md5.init();
		Sha1.init();
		Sha256.init();
		AES128.init();
		mem.obs.Crc32.init();
		ASS.test();
		test_utf8();
		test_md5();
		test_sha1();
		test_aes128();
		test_xor_domainLock();
		test_raw();
	}

	static function test_raw() @:privateAccess {
		trace("----------- raw -----------");
		var as1 = AString.fromHexString("6bc1bee22e409f96e93d7e117393172a");
		var as2 = Ram.malloc(128);
		Ram.memcpy(as2, as1, as1.length);

		Ram.memcpy(as2 + 1, as2, as1.length);
		trace("memcpy/memcmp: " + (Ram.memcmp(as2 + 1, as1, as1.length) == 0));

		Ram.memcpy(as2, as2 + 1, as1.length);
		trace("memcpy/memcmp: " + (Ram.memcmp(as1, as2, as1.length) == 0));

		var s = "abcde你好, 世界";
		var b0 = haxe.io.Bytes.ofString(s);
		Ram.writeBytes(as2, b0.length, #if flash b0.getData() #else b0 #end);
		var b1 = haxe.io.Bytes.alloc(b0.length);
		Ram.readBytes(as2, b1.length, #if flash b1.getData() #else b1 #end);
		trace("writeBytes/readBytes: " + (b1.toString() == s));

		var size = Ram.writeUTFBytes(as2, s);
		var s2 = Ram.readUTFBytes(as2, size);
		trace("writeUTFBytes/readUTFBytes: " + (s2 == s));

		var as3 = Ram.malloc(128, true);
		Ram.writeString(as3, 5, s);
		trace("writeString: " + (Ram.readUTFBytes(as3, 5) == s.substr(0,5)));

		var ws = WString.fromString(s);
		trace("WString.fromString: " + (ws.toString() == s));
	}

	static function test_aes128() {
		trace("----------- AES EBC -----------");
		var as1 = AString.fromHexString("6bc1bee22e409f96e93d7e117393172a");// 3ad77bb40d7a3660a89ecaf32466ef97
		var as2 = AString.fromHexString("ae2d8a571e03ac9c9eb76fac45af8e51");// f5d3d58503b9699de785895a96fdbaaf
		var as3 = AString.fromHexString("30c81c46a35ce411e5fbc1191a0a52ef");// 43b1cd7f598ece23881b00e3ed030688
		var key = AString.fromHexString("2b7e151628aed2a6abf7158809cf4f3c");//
		Hex.trace(key, key.length, true, "the key  : ");

		AES128.ecbEncrypt(as1, key, as1);
		AES128.ecbEncrypt(as2, key, as2);
		AES128.ecbEncrypt(as3, key, as3);
		Hex.trace(as1, as1.length, true, "ebc enc 1: ");
		Hex.trace(as2, as2.length, true, "ebc enc 2: ");
		Hex.trace(as3, as3.length, true, "ebc enc 3: ");

		AES128.ecbDecrypt(as1, key, as1);
		AES128.ecbDecrypt(as2, key, as2);
		AES128.ecbDecrypt(as3, key, as3);
		Hex.trace(as1, as1.length, true, "ebc dec 1: ");
		Hex.trace(as2, as2.length, true, "ebc dec 2: ");
		Hex.trace(as3, as3.length, true, "ebc dec 3: ");

		trace("----------- AES CBC -----------");
		var as4 = AString.fromHexString("6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e5130c81c46a35ce411e5fbc1191a0a52ef");
		Hex.trace(as4, as4.length, true, "cbc org str: ");

		var as4out = AString.alloc(as4.length);
		AES128.cbcEncryptBuff(as4, cast 0, as4, as4.length, cast 0);

		AES128.cbcDecryptBuff(as4, cast 0, as4out, as4out.length, cast 0);
		Hex.trace(as4out, as4.length, true, "cbc dec out: ");

		// input==output
		AES128.cbcDecryptBuffIO(as4, cast 0, as4.length, cast 0);
		Hex.trace(as4, as4.length, true, "cbc dec i=o: ");

		var file = haxe.Resource.getBytes("testjs");
		var multi_of_16 = Ut.padmul(file.length, 16);
		var org = Ram.mallocFromBytes(file, 16);
		var out = Ram.malloc(multi_of_16);
		AES128.cbcEncryptBuff(org, key, out, multi_of_16, cast 0);
		var last = haxe.Timer.stamp();
		AES128.cbcDecryptBuff(out, key, out, multi_of_16, cast 0);
		var sec = haxe.Timer.stamp() - last;

		trace('file: ${file.length/1024}Kb, DEC(output <> input) sec: $sec.\nfile.last_32_ascii: '
		+ Ph.toAscii((out:Ptr) + file.length - 32, 32)
		+ ", memcmp: " + Ram.memcmp(org, out, file.length)
		);
		trace(dump());
	}

	static function test_sha1() {
		trace("----------- SHA1 ------------");
		var file = haxe.Resource.getBytes("testjs");
		var filePtr = Ram.mallocFromBytes(file);

		var out0 = Ram.malloc(20, true);
		var now = haxe.Timer.stamp();
		for(i in 0...3) Sha1.make(filePtr, file.length, out0);
		var time0 = haxe.Timer.stamp() - now;

		var out1:haxe.io.Bytes = null;
		now = haxe.Timer.stamp();
		for(i in 0...3) out1 = haxe.crypto.Sha1.make(file);
		var time1 = haxe.Timer.stamp() - now;
		Hex.trace(out0, 20, true, "_SHA1(loop * 3) mem sec: " + toFixed(time0, 5) + ", hash:");
		trace("SHA1(loop * 3) std sec: " + toFixed(time1, 5)  +", hash: "  + out1.toHex());


		trace("----------- SHA256 ------------");
		now = haxe.Timer.stamp();
		var out00 = Ram.malloc(32);
		var out11:haxe.io.Bytes = null;
		for (i in 0...3) Sha256.make(filePtr, file.length, out00);
		var time00 = haxe.Timer.stamp() - now;
		now = haxe.Timer.stamp();
		for (i in 0...3) out11 = haxe.crypto.Sha256.make(file);
		var time01 = haxe.Timer.stamp() - now;
		Hex.trace(out00, 32, true, "SHA256(loop * 3) mem sec: " + toFixed(time00, 5) + ", hash:");
		trace("SHA256(loop * 3) std sec: " + toFixed(time01, 5)  +", hash: "  + out11.toHex());
	}

	public static function test_md5():Void {
		var file = haxe.Resource.getBytes("testjs");
		var filePtr = Ram.mallocFromBytes(file);
		trace('******* filesize: ${file.length/1024}Kb *******');
		trace("----------- MD5 ------------");
		var out0 = Ram.malloc(16, true);
		var now = haxe.Timer.stamp();
		for(i in 0...3) Md5.make(filePtr, file.length, out0);
		var time0 = haxe.Timer.stamp() - now;

		var out1:haxe.io.Bytes = null;
		now = haxe.Timer.stamp();
		for(i in 0...3) out1 = haxe.crypto.Md5.make(file);
		var time1 = haxe.Timer.stamp() - now;

		var out2:Int = 0;
		now = haxe.Timer.stamp();
		for (i in 0...3) out2 = mem.obs.Crc32.make(filePtr, file.length);
		var time2 = haxe.Timer.stamp() - now;
		Hex.trace(out0, 16, true, "_MD5(loop * 3) mem sec: " + toFixed(time0, 5) + ", hash: ");
		trace("MD5(loop * 3) std sec: " + toFixed(time1, 5)  +", hash: "  + out1.toHex());
		trace("Crc32(loop * 3) mem sec: " + toFixed(time2, 5)  +", hash: 0x"  + StringTools.hex(out2));
	}

	public static function test_utf8() {
		trace("----------- Utf8 ------------");
		/*
		var utf8d = @:privateAccess Utf8.utf8d;
		var t = [];
		for (i in 0...400)
			t[i] = utf8d[i];
		var p = 0;
		for (i in 0...7) {
			trace(t.slice(p, p + 0x20).join(", "));
			p += 0x20;
		}
		for (i in 0...3) {
			trace(t.slice(p, p + 0x10).map(function(v) { return "0x" + StringTools.hex(v); } ).join(", "));
			p += 0x10;
		}
		for (i in 0...4) {
			trace(t.slice(p, p + 0x20).join(", "));
			p += 0x20;
		}
		trace("");
		*/
		var str = "这里有几a个中b文c字符";
		#if cpp
		trace(Gbk.u2Gbk('str: $str, utf-length: ${str.length}'));
		#else
		trace(('str: $str, utf-length: ${str.length}'));
		#end

		var ws = Ram.mallocFromString(str);

		trace("Utf8.length(str): " + Utf8.length(ws, ws.length));
		var a = [];
		Utf8.iter(ws, ws.length, function(ch) {
		#if (neko || cpp)
			a.push(ch);
		#else
			a.push(String.fromCharCode(ch));
		#end
		} );
		trace(a.join(" "));
	}

	public static function test_xor_domainLock() {
		trace("----------- Simple XOR -----------");
		var ws:WString = Ram.mallocFromString("我可以永远笑着扮演你的配角, 在你的背后自已煎熬..ABC");
		var xor = mem.obs.Xor.fromHexString(haxe.crypto.Md5.encode("hello"));
		xor.run(ws, ws.length, ws);
		SXor.make(ws, ws.length, ws);
		#if cpp
		trace(Gbk.u2Gbk(ws.toString()));
		#else
		trace("XOR: " + (ws.toString()));
		#end
		ws.free();
#if flash
		mem.obs.DomainLock.check();
		//trace(@:privateAccess mem.obs.DomainLock.filter("http://cn.bing.com/search?q=i+have+no+idea+for+this&go=%E6%8F%90%E4%BA%A4&qs=n&form=QBLH&pq=i+have+no+idea+for+this&sc=0-23&sp=-1&sk=&cvid=CBE4556873664FCE8D1E1E8B4418FA47"));
#end
	}
}

class ASS implements mem.IStruct{
	@idx(10) var u8:AU8;
	@idx(10) var u16:AU16;
	@idx(10) var i32:AI32;
	@idx(10) var f4:AF4;
	@idx(10) var f8:AF8;
	public static function test() {
		var len = 10;
		if(( ASS.__U8_BYTE == len
		&& ASS.__U16_BYTE == len * 2
		&& ASS.__I32_BYTE == len * 4
		&& ASS.__F4_BYTE == len * 4
		&& ASS.__F8_BYTE == len * 8
		) && (
		   ASS.__U8_OF == len * 4 + len * 2 + len
		&& ASS.__U16_OF == len + len * 4 + len * 2 + len
		&& ASS.__I32_OF == len * 2 + len + len * 4 + len * 2 + len
		&& ASS.__F4_OF  == len * 4 + len * 2 + len + len * 4 + len * 2 + len
		&& ASS.__F8_OF  == len * 4 + len * 4 + len * 2 + len + len * 4 + len * 2 + len
		&& ASS.CAPACITY == len * 8 + len * 4 + len * 4 + len * 2 + len + len * 4 + len * 2 + len
		) && (
		   ASS.__U8_LEN == len
		&& ASS.__U16_LEN == len
		&& ASS.__I32_LEN == len
		&& ASS.__F4_LEN == len
		&& ASS.__F8_LEN == len
		)) trace("----------- struct done. ------------");
		else throw "struct";
	}
}