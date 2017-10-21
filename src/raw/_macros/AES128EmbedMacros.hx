package raw._macros;

import haxe.macro.Context;
import haxe.io.Bytes;
import raw._macros.AES128Macros.Nb;
import raw._macros.AES128Macros.Nr;
import raw._macros.AES128Macros.Nk;

class AES128EmbedMacros {

	static function hex2bytes(s: String): Bytes {
		var len = s.length >> 1;
		var ret = Bytes.alloc(len);
		var j = 0;
		for (i in 0...len) {
			j = i + i;
			ret.set(i, Std.parseInt("0x" + s.charAt(j) + s.charAt(j + 1)));
		}
		return ret;
	}

	public static function build(?saveAs: String) {

		var key = Context.definedValue("aes_embed");
		var kbytes: Bytes;
		if (key == null) {
			key = "2b7e151628aed2a6abf7158809cf4f3c"; // for test
			kbytes = hex2bytes(key);
		} else {
			kbytes = haxe.crypto.Sha1.make(Bytes.ofString(key));
		}

		var rname = "_" + StringTools.hex(haxe.crypto.Crc32.make(kbytes));
		var fields = Context.getBuildFields();
		fields.push({
			name : "_R",
			access: [AStatic, AInline],
			kind: FVar(macro :String, macro $v{rname}),
			pos: Context.currentPos()
		});

		var bin = KeyExpansion(kbytes);

		if (saveAs != null) {
			try {
				sys.io.File.saveBytes(saveAs, bin);
			} catch (e: Dynamic) {
				trace("save failed: " + Std.string(e));
			}
		}

		Context.addResource(rname, bin);
		return fields;
	}

	static function KeyExpansion(kbytes: Bytes) {
		var sbox  = @:privateAccess AES128Macros.sbox_org;       // Array<uint_8>
		var rsbox = @:privateAccess AES128Macros.rsbox_org;
		var rcon  = @:privateAccess AES128Macros.Rcon_org;

		var bin = Bytes.alloc(176 + 4); // see AES128Embed.KeyExpansionBin;

		var roundKey = 0; // see AES128Embed.KeyExpansionBin;
		var tempa = 176;

		var i = 0;

		while (i < Nk) {
			bin.set(roundKey + (i << 2) + 0, kbytes.get((i << 2) + 0));
			bin.set(roundKey + (i << 2) + 1, kbytes.get((i << 2) + 1));
			bin.set(roundKey + (i << 2) + 2, kbytes.get((i << 2) + 2));
			bin.set(roundKey + (i << 2) + 3, kbytes.get((i << 2) + 3));
		++ i;
		}

		var j = 0;
		var k = 0;
		while (i < (Nb * (Nr + 1))) {
			j = 0;
			while(j < 4) {
				bin.set(tempa + j, bin.get(roundKey + j + ((i - 1) << 2)));
			++ j;
			}

			if (i % Nk == 0) {
				// [a0,a1,a2,a3] becomes [a1,a2,a3,a0]
				k = bin.get(tempa + 0);
				bin.set(tempa + 0, bin.get(tempa + 1));
				bin.set(tempa + 1, bin.get(tempa + 2));
				bin.set(tempa + 2, bin.get(tempa + 3));
				bin.set(tempa + 3, k);

				// applies the S-box to each of the four bytes to produce an output word.
				bin.set(tempa + 0, sbox[bin.get(tempa + 0)]);
				bin.set(tempa + 1, sbox[bin.get(tempa + 1)]);
				bin.set(tempa + 2, sbox[bin.get(tempa + 2)]);
				bin.set(tempa + 3, sbox[bin.get(tempa + 3)]);
				bin.set(tempa + 0, bin.get(tempa + 0) ^ rcon[i >> 2]);
			}

			bin.set(roundKey + (i << 2) + 0, bin.get(roundKey + ((i - Nk) << 2) + 0) ^ bin.get(tempa + 0));
			bin.set(roundKey + (i << 2) + 1, bin.get(roundKey + ((i - Nk) << 2) + 1) ^ bin.get(tempa + 1));
			bin.set(roundKey + (i << 2) + 2, bin.get(roundKey + ((i - Nk) << 2) + 2) ^ bin.get(tempa + 2));
			bin.set(roundKey + (i << 2) + 3, bin.get(roundKey + ((i - Nk) << 2) + 3) ^ bin.get(tempa + 3));
		++ i;
		}
		return bin;
	}
}