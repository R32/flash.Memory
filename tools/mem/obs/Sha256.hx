package mem.obs;

import mem.Ptr;
import mem.obs._macros.Sha256Macros.*;
import Fraw.memcpy;
import StringTools.hex;

#if !macro @:build(mem.Struct.make()) #end
@:dce private abstract Sha256Context(Ptr) to Ptr {
	@idx( 8) var S:AI32;
	@idx(64) var W:AI32;
	@idx( 4) var length:Int;    // TODO: the original is 64bit
	@idx( 4) var curlen:Int;
	@idx( 8) var state:AI32;
	@idx(64) var buf:AU8;       // BLOCK_SIZE
	@idx(64) var K:AI32;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  LibSha256
//
//  Implementation of SHA256 hash function.
//  Original author: Tom St Denis, tomstdenis@gmail.com, http://libtom.org
//  Modified by WaterJuice retaining Public Domain license.
//
//  This is free and unencumbered software released into the public domain - June 2013 waterjuice.org
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Sha256{

	static var sa: Sha256Context = cast Malloc.NUL;

	public static function init() {
		if (sa != Malloc.NUL) return;
		sa = new Sha256Context();
		var ktable = [
			0x428A2F98,0x71374491,0xB5C0FBCF,0xE9B5DBA5,0x3956C25B,
			0x59F111F1,0x923F82A4,0xAB1C5ED5,0xD807AA98,0x12835B01,
			0x243185BE,0x550C7DC3,0x72BE5D74,0x80DEB1FE,0x9BDC06A7,
			0xC19BF174,0xE49B69C1,0xEFBE4786,0x0FC19DC6,0x240CA1CC,
			0x2DE92C6F,0x4A7484AA,0x5CB0A9DC,0x76F988DA,0x983E5152,
			0xA831C66D,0xB00327C8,0xBF597FC7,0xC6E00BF3,0xD5A79147,
			0x06CA6351,0x14292967,0x27B70A85,0x2E1B2138,0x4D2C6DFC,
			0x53380D13,0x650A7354,0x766A0ABB,0x81C2C92E,0x92722C85,
			0xA2BFE8A1,0xA81A664B,0xC24B8B70,0xC76C51A3,0xD192E819,
			0xD6990624,0xF40E3585,0x106AA070,0x19A4C116,0x1E376C08,
			0x2748774C,0x34B0BCB5,0x391C0CB3,0x4ED8AA4A,0x5B9CCA4F,
			0x682E6FF3,0x748F82EE,0x78A5636F,0x84C87814,0x8CC70208,
			0x90BEFFFA,0xA4506CEB,0xBEF9A3F7,0xC67178F2
		];
		var k:AI32 = sa.K;
		for (i in 0...ktable.length)
			k[i] = ktable[i];
	}

	public static function make(input: Ptr, ilen:Int, output: Ptr):Void {
		starts(sa);
		update(sa, input, ilen);
		finish(sa, cast output);
	}

	static function starts(ctx: Sha256Context):Void {
		ctx.length = 0;
		ctx.curlen = 0;
		ctx.state[0] = 0x6A09E667;
		ctx.state[1] = 0xBB67AE85;
		ctx.state[2] = 0x3C6EF372;
		ctx.state[3] = 0xA54FF53A;
		ctx.state[4] = 0x510E527F;
		ctx.state[5] = 0x9B05688C;
		ctx.state[6] = 0x1F83D9AB;
		ctx.state[7] = 0x5BE0CD19;
	}

	static function update(ctx: Sha256Context/*Context*/, input: Ptr/*Buffer*/, ilen:Int /*BufferSize*/):Void {
		var n = 0;

		if (ctx.curlen > Sha256Context.__BUF_LEN) return;

		while (ilen > 0) {
			if (ctx.curlen == 0 && ilen >= BLOCK_SIZE) {
				process(ctx.state, input);
				ctx.length += BLOCK_SIZE << 3;
				input = cast input + BLOCK_SIZE;
				ilen -= BLOCK_SIZE;
			} else {
				n = MIN(ilen, BLOCK_SIZE - ctx.curlen);
				memcpy(cast ctx.buf + ctx.curlen, input, n);
				ctx.curlen += n;
				input = cast input + n;
				ilen -= n;
				if (ctx.curlen == BLOCK_SIZE) { // this block is no test
					process(ctx.state, ctx.buf);
					ctx.length += BLOCK_SIZE << 3;
					ctx.curlen = 0;
				}
			}
		}
	}

	static function process(state: AI32/*uint32_t state[5]*/, data: AU8/*const uint8_t buffer[64]*/):Void {
		var t0 = 0, t1 = 0, t = 0, i = 0;
		var S:AI32 = sa.S;
		var W:AI32 = sa.W;
		var K:AI32 = sa.K;

		while (i < 8) {
			S[i] = state[i];
		++i;
		}

		i = 0;
		while (i < 16) {
			LOAD32H(W[i], (data: Ptr) + (i << 2));
		++i;
		}
		// i = 16;
		while (i < 64) {
			W[i] = Gamma1( W[i-2]) + W[i-7] + Gamma0( W[i-15] ) + W[i-16];
		++i;
		}

		i = 0;
		while (i < 64) {
			Sha256Round( S[0], S[1], S[2], S[3], S[4], S[5], S[6], S[7], i );
			t = S[7];
			S[7] = S[6];
			S[6] = S[5];
			S[5] = S[4];
			S[4] = S[3];
			S[3] = S[2];
			S[2] = S[1];
			S[1] = S[0];
			S[0] = t;
		++i;
		}

		i = 0;
		while (i < 8) {
			state[i] = state[i] + S[i];
		++i;
		}
	}

	static function finish(ctx: Sha256Context, output: AU8/* SHA256_HASH* Digest */): Void {
		var i = 0, curlen = ctx.curlen;

		if (curlen >= Sha256Context.__BUF_LEN) return;

		ctx.length += curlen * 8;

		ctx.buf[curlen++] = 0x80;

		if (curlen > 56) {
			while (curlen < 64) {
				ctx.buf[curlen++] = 0;
			}
			process(ctx.state, ctx.buf);
			curlen = 0;
		}

		while (curlen < 56) {
			ctx.buf[curlen++] = 0;
		}

		STORE64H(ctx.length, (ctx.buf:Ptr) + 56);

		process(ctx.state, ctx.buf);

		while (i < 8) {
			STORE32H(ctx.state[i], (output:Ptr) + (i << 2));
		++i;
		}
	}
}