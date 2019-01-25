package mem.s;

import mem.Ptr;
import mem._macros.AES128Macros.*;

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
#if !macro @:build(mem.Struct.build()) #end
@:dce private abstract AES128Context(Ptr) to Ptr {
	@idx(176) var roundKey:AU8;
	@idx(4)   var tempa:AU8;   // local variable,
	@idx(32)  var xiv:AU8;     // Iv1, Iv2 tmp
	@idx(256) var sbox:AU8;    // const data table
	@idx(256) var rsbox:AU8;
	@idx(256) var rcon:AU8;
	inline public function reset():Void {
		Mem.memset(this, 0, 176 + (4 * 4));
	}
}

/**
	NOTE: This is the fill mode I personally use which is **not standard**.
	If you want to use it you need to modify the fill mode.
*/
class AES128 {

	static var aes:AES128Context = cast Ptr.NUL;

	//static var pstate: Ptr;

	static public function init():Void {
		if (aes != Ptr.NUL) return;
		// write to mem
		aes = new AES128Context();

		var org_box32:Array<Int>   = to32(1);
		var org_rsbox32:Array<Int> = to32(2);
		var org_rcon32:Array<Int>  = to32(3);

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

	static public function destory() {
		if (aes != Ptr.NUL) {
			aes.free();
			aes = cast Ptr.NUL;
		}
	}

	static public function ecbEncrypt(input: Ptr, key: Ptr, output: Ptr):Void {
		if (aes == Ptr.NUL) init();
		if (input != output) BlockCopy(output, input);
		if (key != Ptr.NUL) KeyExpansion(key);
		Cipher(output);
	}

	static public function ecbDecrypt(input: Ptr, key: Ptr, output: Ptr):Void {
		if (aes == Ptr.NUL) init();
		if (input != output) BlockCopy(output, input);
		if (key != Ptr.NUL) KeyExpansion(key);
		InvCipher(output);
	}

	static function XorWithIv (buf:Ptr, iv:Ptr):Void {
		setI32(buf +  0, getI32(buf +  0) ^ getI32(iv +  0));
		setI32(buf +  4, getI32(buf +  4) ^ getI32(iv +  4));
		setI32(buf +  8, getI32(buf +  8) ^ getI32(iv +  8));
		setI32(buf + 12, getI32(buf + 12) ^ getI32(iv + 12));
	}

	static public function cbcEncryptBuff(input: Ptr, key: Ptr, output: Ptr, length:Int, iv:Ptr/*16 bytes*/):Int {
		if (aes == Ptr.NUL) init();
		var i = 0;
		var remainders = length & (KEYLEN - 1); // eq length % KEYLEN;
		if (remainders > 0) {
			// only padding zero if not enough, if no remainders then no padding.
			Mem.memset(output + length, 0, KEYLEN - remainders);
		}
		if (iv == Ptr.NUL) {
			iv = aes.xiv;
			Mem.memset(iv, 0, KEYLEN);
		}
		// Skip the key expansion if key is passed as 0
		if (key != Ptr.NUL) KeyExpansion(key);

		while (i < length) {
			if (input != output) BlockCopy(output, input);
			XorWithIv(output, iv);
			Cipher(output);
			iv = output;
			input += KEYLEN;
			output += KEYLEN;
			i += KEYLEN;
		}
		return remainders > 0 ? length + (KEYLEN - remainders) : length;
	}

	// make sure the captial(io) is multi of 16.
	static public function cbcDecryptBuff(input: Ptr, key: Ptr, output: Ptr, length:Int, iv:Ptr/*16 bytes*/):Void {
		if (aes == Ptr.NUL) init();
		var i = 0;

		if (input == output) return cbcDecryptBuffIO(input, key, length, iv);

		if (key != Ptr.NUL) KeyExpansion(key);

		if (iv == Ptr.NUL) {
			iv = aes.xiv;
			Mem.memset(iv, 0, KEYLEN);
		}
		// Skip the key expansion if key is passed as 0

		while (i < length) {
			BlockCopy(output, input);
			InvCipher(output);
			// If iv is passed as 0, we continue to encrypt without re-setting the Iv
			XorWithIv(output, iv);
			iv = input;
			input += KEYLEN;
			output += KEYLEN;
			i += KEYLEN;
		}
	}

	// when output == input, make sure the captial(io) is multi of 16.
	static function cbcDecryptBuffIO(io: Ptr, key:Ptr, length:Int, iv:Ptr): Void {
		if (aes == Ptr.NUL) init();
		var i = 0;

		if (key != Ptr.NUL) KeyExpansion(key);

		if (iv == Ptr.NUL) {
			iv = aes.xiv;
			Mem.memset(iv, 0, KEYLEN);
		}

		var iv2:Ptr = iv + KEYLEN;
		var tmp:Ptr;
		while (i < length) {
			BlockCopy(iv2, io);
			InvCipher(io);
			XorWithIv(io, iv);
			// swap
			tmp = iv2;
			iv2 = iv;
			iv = tmp;
			io += KEYLEN;
			i += KEYLEN;
		}
	}

	// Note: Actually, We could call this method only once If you use the same "key/passwd"
	static function KeyExpansion(key: Ptr): Void {
		var i = 0;
		var tempa: Ptr = aes.tempa;
		var roundKey: Ptr = aes.roundKey;
		var sbox: Ptr = aes.sbox;
		var rcon: Ptr = aes.rcon;
		while ( i < Nk) {
			setI32(roundKey + (i << 2), getI32(key + (i << 2)));
		++i;
		}

		while (i < (Nb * (Nr + 1))) {
			setI32(tempa, getI32(roundKey + ((i - 1) << 2)));

			if (i % Nk == 0) {

			// This function rotates the 4 bytes in a word to the left once.
			// [a0,a1,a2,a3] becomes [a1,a2,a3,a0]
				setI32(tempa, getByte(tempa + 1) | getByte(tempa + 2) << 8 | getByte(tempa + 3) << 16 | getByte(tempa) << 24 );
			// Function Subword() , takes a four-byte input word and
			// applies the S-box to each of the four bytes to produce an output word.
				tempa[0] = getSBoxValue(tempa[0]);
				tempa[1] = getSBoxValue(tempa[1]);
				tempa[2] = getSBoxValue(tempa[2]);
				tempa[3] = getSBoxValue(tempa[3]);
				tempa[0] =  tempa[0] ^ rcon[i >> 2]; // i/Nk is float, Nk = 4
			}
			setI32(roundKey + (i << 2), getI32(roundKey + (i - Nk << 2)) ^ getI32(tempa)); //// OPT
		++i;
		}
	}

	// This function adds the round key to state.
	// The round key is added to the state by an XOR function.
	static function AddRoundKey(round: Int, state: Ptr): Void {
		var i = 0, j = 0;
		var roundKey: Ptr = aes.roundKey;
		while (i < 4) {
			setI32(state + (i << 2), getI32(state + (i << 2)) ^ getI32(roundKey + (round * (Nb << 2) + (i << 2)))); //// OPT
		++i;
		}
	}

	// The SubBytes Function Substitutes the values in the
	// state matrix with values in an S-box.
	static function SubBytes(state: Ptr) {
		var i = 0, j = 0;
		var sbox: Ptr = aes.sbox;
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
	static function ShiftRows(state: Ptr):Void {
		var temp = 0;
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
	static function MixColumns(state: Ptr) {
		var i = 0, Tmp = 0, Tm = 0, t = 0;
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
	static function InvMixColumns(state: Ptr):Void {
		var i = 0, a = 0, b = 0, c = 0, d = 0;
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
	static function InvSubBytes(state: Ptr):Void {
		var i = 0, j = 0;
		var rsbox: Ptr = aes.rsbox;
		while (i < 4) {
			j = 0;
			while (j < 4) {
				state[P(j, i)] = getSBoxInvert(state[P(j, i)]);
			++j;
			}
		++i;
		}
	}

	static function InvShiftRows(state: Ptr):Void {
		var temp = 0;
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
		state[P(1, 2)] = state[P(3, 2)];
		state[P(3, 2)] = temp;

		// Rotate third row 3 columns to right
		temp           = state[P(0, 3)];
		state[P(0, 3)] = state[P(1, 3)];
		state[P(1, 3)] = state[P(2, 3)];
		state[P(2, 3)] = state[P(3, 3)];
		state[P(3, 3)] = temp;
	}

	// Cipher is the main function that encrypts the PlainText.
	static function Cipher(state: Ptr):Void {
		// Add the First round key to the state before starting the rounds.
		AddRoundKey(0, state);
		// There will be Nr rounds.
		// The first Nr-1 rounds are identical.
		// These Nr-1 rounds are executed in the loop below.
		for(round in 1...Nr) {
		  SubBytes(state);
		  ShiftRows(state);
		  MixColumns(state);
		  AddRoundKey(round, state);
		}
		// The last round is given below.
		// The MixColumns function is not here in the last round.
		SubBytes(state);
		ShiftRows(state);
		AddRoundKey(Nr, state);
	}

	static function InvCipher(state: Ptr):Void {
		var round = Nr - 1;
		// Add the First round key to the state before star
		AddRoundKey(Nr, state);
		// There will be Nr rounds.
		// The first Nr-1 rounds are identical.
		// These Nr-1 rounds are executed in the loop below
		while (round > 0) {
		  InvShiftRows(state);
		  InvSubBytes(state);
		  AddRoundKey(round, state);
		  InvMixColumns(state);
		--round;
		}
		// The last round is given below.
		// The MixColumns function is not here in the last
		InvShiftRows(state);
		InvSubBytes(state);
		AddRoundKey(0, state);
	}

	// unsafe BlockCopy
	static function BlockCopy(output: Ptr, input: Ptr):Void {
		//Mem.memcpy(output, input, 16);
		setI32(output     , getI32(input     ));
		setI32(output +  4, getI32(input +  4));
		setI32(output +  8, getI32(input +  8));
		setI32(output + 12, getI32(input + 12));
	}
	static inline function getByte(ptr: Ptr):Int return ptr.getByte();
	static inline function  getI32(ptr: Ptr):Int return ptr.getI32();
	static inline function setByte(ptr: Ptr, v: Int):Void ptr.setByte(v);
	static inline function  setI32(ptr: Ptr, v: Int):Void ptr.setI32(v);
}
