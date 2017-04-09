package mem.obs;

import mem.Ptr;
import mem.Malloc.NUL;
import mem.Ptr.Memory.setI32;
import mem.Ptr.Memory.getI32;
import mem.Ptr.Memory.getByte;
import mem.Ptr.Memory.setByte;
import mem.obs._macros.AES128Macros.*;

/**
This is an implementation of the AES128 algorithm, specifically ECB and CBC mode.

The implementation is verified against the test vectors in:
  National Institute of Standards and Technology Special Publication 800-38A 2001 ED

ECB-AES128
----------

  plain-text:
    6bc1bee22e409f96e93d7e117393172a
    ae2d8a571e03ac9c9eb76fac45af8e51
    30c81c46a35ce411e5fbc1191a0a52ef
    f69f2445df4f9b17ad2b417be66c3710

  key:
    2b7e151628aed2a6abf7158809cf4f3c

  resulting cipher
    3ad77bb40d7a3660a89ecaf32466ef97
    f5d3d58503b9699de785895a96fdbaaf
    43b1cd7f598ece23881b00e3ed030688
    7b0c785e27e8ad3f8223207104725dd4


NOTE:   String length must be evenly divisible by 16byte (str_len % 16 == 0)
        You should pad the end of the string with zeros if this is not the case.

Project Org: https://github.com/kokke/tiny-AES128-C

Ported by r32
*/
#if !macro @:build(mem.Struct.StructBuild.make()) #end
@:dce private abstract AES128Context(Ptr) to Ptr {
	@idx(176) var roundKey:AU8;
	@idx(4)   var tempa:AU8;   // local variable,
	@idx(32)  var tbuf:AU8;    // cbcDecryptBuff if inout == output, 32
	@idx(256) var sbox:AU8;     // const data table
	@idx(256) var rsbox:AU8;
	@idx(256) var rcon:AU8;
	inline public function reset():Void {
		Ram.memset(this, 0, 176 + (4 * 4));
	}
}

// N.B: 现在 haxe 编译器局部变量过多, 看以后是否会解决再优化这一块, 先不管它
@:analyzer(no_copy_propagation)
class AES128 {

	static var aes:AES128Context = cast NUL;

	static var pstate: Ptr;

	static public function init():Void {
		if (aes != NUL) return;
		// write to mem
		aes = new AES128Context();

		var org_box32:Array<Int> = to32(1);
		var org_rsbox32:Array<Int> = to32(2);
		var org_rcon32:Array<Int> = to32(3);

		var box32: AI32 = cast aes.sbox;
		var rbox32:AI32 = cast aes.rsbox;
		var Rcon32:AI32 = cast aes.rcon;

		var i = 0, len = 256 >> 2;
		while (i < len) {
			box32[i] = org_box32[i];
			rbox32[i] = org_rsbox32[i];
			Rcon32[i] = org_rcon32[i];
		++i;
		}
		org_box32 = org_rsbox32 = org_rcon32 = null;
	}

	static public function ecbEncrypt(input: Ptr, key: Ptr, output: Ptr):Void {
		if (input != output) BlockCopy(output, input);

		pstate = output;

		if (key != NUL) KeyExpansion(key);

		Cipher();
	}

	static public function ecbDecrypt(input: Ptr, key: Ptr, output: Ptr):Void {
		if (input != output) BlockCopy(output, input);

		pstate = output;

		if (key != NUL) KeyExpansion(key);

		InvCipher();
	}

	static inline function XorWithIv (buf:Ptr, iv:Ptr):Void {
		setI32(buf +  0, getI32(buf +  0) ^ getI32(iv +  0));
		setI32(buf +  4, getI32(buf +  4) ^ getI32(iv +  4));
		setI32(buf +  8, getI32(buf +  8) ^ getI32(iv +  8));
		setI32(buf + 12, getI32(buf + 12) ^ getI32(iv + 12));
	}

	/**
	 IMPORTANT: make sure that (capability(input/output) > length) && (capability(input/output) % 16 == 0)

	 example:

	 ```haxe
	 var file = haxe.Resource.getBytes("res");
	 var input = mem.struct.FBlock.fromBytes(file, 16);
	 var output = input;
	 AES128.cbcEncryptBuff(input, cast 0, output, file.length, cast 0);  // no key, no iv
	 ```
	*/
	static public function cbcEncryptBuff(input: Ptr, key: Ptr, output: Ptr, length:Int, iv:Ptr/*16 bytes*/):Void {
		var i = 0;

		var remainders = length & (KEYLEN - 1); // eq length % KEYLEN;

		if (input != output) BlockCopy(output, input);

		pstate = output;

		// Skip the key expansion if key is passed as 0
		if (key != NUL) KeyExpansion(key);

		while (i < length) {
			if (iv != NUL) XorWithIv(input, iv);
			if (input != output) BlockCopy(output, input);
			pstate = output;
			Cipher();
			iv = output;
			input += KEYLEN;
			output += KEYLEN;
		i += KEYLEN;
		}

		if (remainders > 0) {
			if (input != output) BlockCopy(output, input);
			Ram.memset(output + remainders, 0, KEYLEN - remainders); /* add 0-padding */
			pstate = output;
			Cipher();
		}
	}


	static public function cbcDecryptBuff(input: Ptr, key: Ptr, output: Ptr, length:Int, iv:Ptr/*16 bytes*/):Void {
		var i = 0;

		var remainders = length & (KEYLEN - 1); // eq length % KEYLEN;

		BlockCopy(output, input);

		pstate = output;

		// Skip the key expansion if key is passed as 0
		if (key != NUL) KeyExpansion(key);

		while (i < length) {
			BlockCopy(output, input);
			pstate = output;
			InvCipher();
			// If iv is passed as 0, we continue to encrypt without re-setting the Iv
			if (iv != NUL) XorWithIv(output, iv);
			iv = input;
			input += KEYLEN;
			output += KEYLEN;
		i += KEYLEN;
		}

		if (remainders > 0) {
			BlockCopy(output, input);
			Ram.memset(output + remainders, 0, KEYLEN - remainders); /* add 0-padding */
			pstate = output;
			XorWithIv(output, iv);
		}
	}

	// when output == input
	static public function cbcDecryptBuffIO(io: Ptr, key:Ptr, length:Int, iv:Ptr): Void {

		var i = 0, j = 0;

		var remainders:Int = length & (KEYLEN - 1); // eq length % KEYLEN;

		var tb:Ptr = aes.tbuf; // 32 bites

		pstate = io;
		if (key != NUL) KeyExpansion(key);

		BlockCopy(tb + KEYLEN, io);
		InvCipher();
		if (iv != NUL) XorWithIv(io, iv);
		io += KEYLEN;
		i += KEYLEN;

		while (i < length) {
			pstate = io;
			if ( j & 1 == 1) {
				BlockCopy(tb + KEYLEN, io);
				InvCipher();
				XorWithIv(io, tb);
			 } else {
				BlockCopy(tb, io);
				InvCipher();
				XorWithIv(io, tb + KEYLEN);
			}
			++j;
			io += KEYLEN;
			i += KEYLEN;
		}

		if (remainders > 0) {
			Ram.memset(io + remainders, 0, KEYLEN - remainders); // add 0-padding
			pstate = io;
			XorWithIv(io, j & 1 == 1 ? tb : tb + KEYLEN);
		}
	}

	// This function produces Nb(Nr+1) round keys. The round keys are used in each round to decrypt the states.
	static function KeyExpansion(key: Ptr): Void {
		var i = 0;

		var tempa: AU8 = aes.tempa;
		var roundKey: AU8 = aes.roundKey;
		var sbox:AU8 = aes.sbox;
		var rcon:AU8 = aes.rcon;
		while ( i < Nk) {
			//roundKey[(i << 2) + 0] = pkey[(i << 2) + 0];
			//roundKey[(i << 2) + 1] = pkey[(i << 2) + 1];
			//roundKey[(i << 2) + 2] = pkey[(i << 2) + 2];
			//roundKey[(i << 2) + 3] = pkey[(i << 2) + 3];
			setI32(roundKey + (i << 2), getI32(key + (i << 2)));  //// OPT
		++i;
		}

		while (i < (Nb * (Nr + 1))) {
			////j = 0;
			////while (j < 4) {
			////	tempa[j] = roundKey[(i - 1) * 4 + j];
			////++j;
			////}
			setI32(tempa, getI32(roundKey + ((i - 1) << 2))); //// OPT

			if (i % Nk == 0) {

			// This function rotates the 4 bytes in a word to the left once.
			// [a0,a1,a2,a3] becomes [a1,a2,a3,a0]
				////k = tempa[0];
				////tempa[0] = tempa[1];
				////tempa[1] = tempa[2];
				////tempa[2] = tempa[3];
				////tempa[3] = k;
				setI32(tempa, getByte(tempa + 1) | getByte(tempa + 2) << 8 | getByte(tempa + 3) << 16 | getByte(tempa) << 24 );
			// Function Subword() , takes a four-byte input word and
			// applies the S-box to each of the four bytes to produce an output word.
				tempa[0] = getSBoxValue(tempa[0]);
				tempa[1] = getSBoxValue(tempa[1]);
				tempa[2] = getSBoxValue(tempa[2]);
				tempa[3] = getSBoxValue(tempa[3]);
				tempa[0] =  tempa[0] ^ rcon[i >> 2]; // i/Nk is float, Nk = 4
			}// else if (Nk > 6 && i % Nk == 4) {    // NK == 4, never > 6....
			// Function Subword()
			//	tempa[0] = getSBoxValue(tempa[0]);
			//	tempa[1] = getSBoxValue(tempa[1]);
			//	tempa[2] = getSBoxValue(tempa[2]);
			//	tempa[3] = getSBoxValue(tempa[3]);
			//}
			////roundKey[(i << 2) + 0] = roundKey[((i - Nk) << 2) + 0] ^ tempa[0];
			////roundKey[(i << 2) + 1] = roundKey[((i - Nk) << 2) + 1] ^ tempa[1];
			////roundKey[(i << 2) + 2] = roundKey[((i - Nk) << 2) + 2] ^ tempa[2];
			////roundKey[(i << 2) + 3] = roundKey[((i - Nk) << 2) + 3] ^ tempa[3];
			setI32(roundKey + (i << 2), getI32(roundKey + (i - Nk << 2)) ^ getI32(tempa)); //// OPT
		++i;
		}
	}

	// This function adds the round key to state.
	// The round key is added to the state by an XOR function.
	static function AddRoundKey(round: Int): Void {
		var i = 0, j = 0;
		var state:AU8 = pstate;     // uint_t state[4][4];
		var roundKey:AU8 = aes.roundKey;
		while (i < 4) {
			////j = 0;
			////while (j < 4) {
			////	state[(i << 2) + j] ^= roundKey[round * (Nb << 2) + i * Nb + j];
			////++j;
			////}
			setI32(state + (i << 2), getI32(state + (i << 2)) ^ getI32(roundKey + (round * (Nb << 2) + (i << 2)))); //// OPT
		++i;
		}
	}

	// The SubBytes Function Substitutes the values in the
	// state matrix with values in an S-box.
	static function SubBytes() {
		var i = 0, j = 0;
		var state:AU8 = pstate;     // uint_t state[4][4];
		var sbox:AU8 = aes.sbox;
		while (i < 4) {
			j = 0;
			while (j < 4) {
				state[P(j, i)] = getSBoxValue(state[P(j, i)]);
			++j;
			}
		++i;
		}
	}

	// The ShiftRows() function shifts the rows in the state to the left.
	// Each row is shifted with different offset.
	// Offset = Row number. So the first row is not shifted.
	static function ShiftRows():Void {
		var temp = 0;
		var state:AU8 = pstate;
		// Rotate first row 1 columns to left
		temp           = state[P(0, 1)];
		state[P(0, 1)] = state[P(1, 1)];
		state[P(1, 1)] = state[P(2, 1)];
		state[P(2, 1)] = state[P(3, 1)];
		state[P(3, 1)] = temp;

		// Rotate second row 2 columns to left
		temp           = state[P(0, 2)];
		state[P(0, 2)] = state[P(2, 2)];
		state[P(2, 2)] = temp;

		temp           = state[P(1, 2)];
		state[P(1, 2)] = state[P(3, 2)];
		state[P(3, 2)] = temp;
		// Rotate third row 3 columns to left
		temp           = state[P(0, 3)];
		state[P(0, 3)] = state[P(3, 3)];
		state[P(3, 3)] = state[P(2, 3)];
		state[P(2, 3)] = state[P(1, 3)];
		state[P(1, 3)] = temp;
	}

	// MixColumns function mixes the columns of the state matrix
	static function MixColumns() {
		var i = 0, Tmp = 0, Tm = 0, t = 0;
		var state:AU8 = pstate;
		while (i < 4) {
			t   = state[P(i, 0)];
			Tmp = state[P(i, 0)] ^ state[P(i, 1)] ^ state[P(i, 2)] ^ state[P(i, 3)] ;
			Tm  = state[P(i, 0)] ^ state[P(i, 1)] ; Tm = xtime(Tm);  state[P(i, 0)] ^= Tm ^ Tmp ;
			Tm  = state[P(i, 1)] ^ state[P(i, 2)] ; Tm = xtime(Tm);  state[P(i, 1)] ^= Tm ^ Tmp ;
			Tm  = state[P(i, 2)] ^ state[P(i, 3)] ; Tm = xtime(Tm);  state[P(i, 2)] ^= Tm ^ Tmp ;
			Tm  = state[P(i, 3)] ^ t ;              Tm = xtime(Tm);  state[P(i, 3)] ^= Tm ^ Tmp ;
		++i;
		}
	}

	// Multiply is used to multiply numbers in the field GF(2^8)
	static inline function Multiply(x:Int, y:Int):Int {
		return
			((y      & 1) * x) ^
			((y >> 1 & 1) * xtime(x)) ^
			((y >> 2 & 1) * xtime(xtime(x))) ^
			((y >> 3 & 1) * xtime(xtime(xtime(x)))) ^
			((y >> 4 & 1) * xtime(xtime(xtime(xtime(x)))));
	}

	// MixColumns function mixes the columns of the state matrix.
	// The method used to multiply may be difficult to understand for the inexperienced.
	// Please use the references to gain more information.
	static function InvMixColumns():Void {
		var i = 0, a = 0, b = 0, c = 0, d = 0;
		var state:AU8 = pstate;
		while (i < 4) {
			a = state[P(i, 0)];
			b = state[P(i, 1)];
			c = state[P(i, 2)];
			d = state[P(i, 3)];

			state[P(i, 0)] = Multiply(a, 0x0e) ^ Multiply(b, 0x0b) ^ Multiply(c, 0x0d) ^ Multiply(d, 0x09);
			state[P(i, 1)] = Multiply(a, 0x09) ^ Multiply(b, 0x0e) ^ Multiply(c, 0x0b) ^ Multiply(d, 0x0d);
			state[P(i, 2)] = Multiply(a, 0x0d) ^ Multiply(b, 0x09) ^ Multiply(c, 0x0e) ^ Multiply(d, 0x0b);
			state[P(i, 3)] = Multiply(a, 0x0b) ^ Multiply(b, 0x0d) ^ Multiply(c, 0x09) ^ Multiply(d, 0x0e);
		++i;
		}
	}

	// The SubBytes Function Substitutes the values in the
	// state matrix with values in an S-box.
	static function InvSubBytes():Void {
		var i = 0, j = 0;
		var state:AU8 = pstate;
		var rsbox:AU8 = aes.rsbox;
		while (i < 4) {
			j = 0;
			while (j < 4) {
				state[P(j, i)] = getSBoxInvert(state[P(j, i)]);
			++j;
			}
		++i;
		}
	}

	static function InvShiftRows():Void {
		var temp = 0;
		var state:AU8 = pstate;
		// Rotate first row 1 columns to right
		temp           = state[P(3, 1)];
		state[P(3, 1)] = state[P(2, 1)];
		state[P(2, 1)] = state[P(1, 1)];
		state[P(1, 1)] = state[P(0, 1)];
		state[P(0, 1)] = temp;

		// Rotate second row 2 columns to right
		temp           = state[P(0, 2)];
		state[P(0, 2)] = state[P(2, 2)];
		state[P(2, 2)] = temp;

		temp=state[P(1, 2)];
		state[P(1, 2)]=state[P(3, 2)];
		state[P(3, 2)]=temp;

		// Rotate third row 3 columns to right
		temp           = state[P(0, 3)];
		state[P(0, 3)] = state[P(1, 3)];
		state[P(1, 3)] = state[P(2, 3)];
		state[P(2, 3)] = state[P(3, 3)];
		state[P(3, 3)] = temp;
	}

	// Cipher is the main function that encrypts the PlainText.
	static function Cipher():Void {
		// Add the First round key to the state before starting the rounds.
		AddRoundKey(0);
		// There will be Nr rounds.
		// The first Nr-1 rounds are identical.
		// These Nr-1 rounds are executed in the loop below.
		for(round in 1...Nr) {
		  SubBytes();
		  ShiftRows();
		  MixColumns();
		  AddRoundKey(round);
		}
		// The last round is given below.
		// The MixColumns function is not here in the last round.
		SubBytes();
		ShiftRows();
		AddRoundKey(Nr);
	}

	static function InvCipher():Void {
		var round = Nr - 1;
		// Add the First round key to the state before star
		AddRoundKey(Nr);
		// There will be Nr rounds.
		// The first Nr-1 rounds are identical.
		// These Nr-1 rounds are executed in the loop below
		while (round > 0) {
		  InvShiftRows();
		  InvSubBytes();
		  AddRoundKey(round);
		  InvMixColumns();
		--round;
		}
		// The last round is given below.
		// The MixColumns function is not here in the last
		InvShiftRows();
		InvSubBytes();
		AddRoundKey(0);
	}

	// unsafe BlockCopy
	static inline function BlockCopy(output: Ptr, input: Ptr):Void {
		Memory.setI32(output     , Memory.getI32(input     ));
		Memory.setI32(output +  4, Memory.getI32(input +  4));
		Memory.setI32(output +  8, Memory.getI32(input +  8));
		Memory.setI32(output + 12, Memory.getI32(input + 12));
	}
}