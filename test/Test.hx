package;

import haxe.crypto.Md5;
import mem.Ptr;
import mem.Malloc;
import haxe.Log;
import haxe.Timer;
import haxe.io.Bytes;
import haxe.unit.TestCase;
import haxe.Utf8;
import mem.Ut;
import mem.obs.SxInt;
import mem.obs.SXor;
import mem.obs.SxIntBuild;

import mem.obs.Hex;
import mem.struct.WString;
import mem.struct.AString;
import mem.obs.Xor;
import haxe.unit.TestRunner;
import haxe.Int64;

class Test extends TestCase{

	function testMemcpy() {
		print("test Ram\n");
		var array = "0123456789abcdefABXYZ中文012345679字符这里写下了些什XYZ中文012345679我像是一个你可有可无的影子？".split("");
		var string = array.join("");
		var bytes = Bytes.ofString(string);
		var ptr = Ram.malloc(2048);
		var src = ptr;
		var len = Ram.writeUTFBytes(ptr, string);
		var wstr = Ram.readUTFBytes(ptr, len);
		print("readUtf:\t" + wstr + "\n");
		print("bytes:  \t" + bytes.toString() + "\n");
		assertTrue(wstr == string && string == bytes.toString());

		trace("find: " + ptr + ", " +Ram.readUTFBytes(Ram.find("0123456789", ptr), 10));

		cp(ptr + 1 , src, len, "dst > src:\t"); // 字符已经被上一行覆盖, 因此
		cp(ptr, src + 1, len, "dst < src:\t");	// 注意不要传递 -1 的 ptr 值
		cp(ptr + len, src, len, "new addr:\t");
		assertFalse(Ram.memcmp(ptr + (len >> 1), src, len >> 1));
		assertTrue(Ram.memcmp(ptr + len, src, len));
		Memory.setByte(ptr + len, 0);
		assertTrue(Ram.strlen(ptr) == len);

		var wstr = new WString(array.join(""));
		print("WString: " + wstr.toString() + "\n");
		wstr.free();

		Ram.free(ptr);
		assertTrue(true);

		var ss = AString.fromString("0123456789ABCDEF");
		print(ss.__toOut() + "\n");
		print(ss.toString() + "\n");
		var hex = Hex.export(ss.c_ptr, ss.length);
		trace("----hex: " + hex.toString() + "\n");
		mem.Ut.reverse(ss.c_ptr, ss.length);

		trace("reverse: " + ss.toString());
		ss.free();
		hex.free();
	}


	public function testSxInt(){
		var ci_0 = SxInt.fromInt64(SxIntBuild.make(235, 0));
		//ci_0.value = SxIntBuild.v0(239);
		trace(ci_0.__toOut() + "--- value: " + ci_0.calc_0());

		var t0 = Timer.stamp();

		for (i in 1...256){
			var r = Std.int(Math.random() * 254.0) + 1;
			var x = SxInt.fromInt64(SxIntBuild.make(r, 0));
			assertTrue(x.calc_0() == r);
			x.free();
		}

		for (i in 1...256){
			var r = Std.int(Math.random() * 254.0) + 1;
			var x = SxInt.fromInt64(SxIntBuild.make(r, 1));
			assertTrue(x.calc_1() == r);
			x.free();
		}

		for (i in 1...256){
			var r = Std.int(Math.random() * 254.0) + 1;
			var x = SxInt.fromInt64(SxIntBuild.make(r, 2));
			assertTrue(x.calc_2() == r);
			x.free();
		}

		for (i in 1...256){
			var r = Std.int(Math.random() * 254.0) + 1;
			var x = SxInt.fromInt64(SxIntBuild.make(r, 3));
			assertTrue(x.calc_3() == r);
			x.free();
		}

		var sa = Ram.mallocFromString("我可以永远笑着扮演你的配角, 在你的背后自已煎熬, 如果你不想要, 想退出要趁早, 就算迷恋你的微笑..ABC");
		var nx = Xor.fromHexString(haxe.crypto.Md5.encode("hello"));
		nx.make(sa.c_ptr, sa.length, sa.c_ptr);
		SXor.make(sa.c_ptr, sa.length, sa.c_ptr);
		SXor.test();
		var t1 = Timer.stamp() - t0;
		trace("sa:length: "+ sa.length + ", time: " + t1 + "sec, memory: " + Malloc.getUsed());
		trace(sa.toString());
	}

	function cp(dst:Int, src:Int, len:Int, desc:String){
		var out = Bytes.alloc(len);
		Ram.memcpy(dst, src, len);
		Ram.readBytes(dst, len, #if flash out.getData() #else out #end);
		print(desc + out.getString(0, len) + "\n");
	}

	public static function main(){
		Ram.select(Ram.create());
		var randShim = Ram.malloc(Ut.rand(64, 1), false);
		Hex.init();
		SXor.init();
		var runner = new TestRunner();
		var test = new Test();
		runner.add(test);
		runner.run();
	}
}