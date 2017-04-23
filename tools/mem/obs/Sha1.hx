package mem.obs;

import mem.Ptr;
import mem.obs._macros.Sha1Macros.*;

#if !macro @:build(mem.Struct.make()) #end
@:dce private abstract Sha1Context(Ptr) to Ptr {
	@idx(8)  var finalcount:AU8;   // local variable, in "finish"

	@idx(5)  var State: AI32;      // Sha1Context begin
	@idx(2)  var Count: AI32;
	@idx(64) var Buffer: AU8;

	@idx(64)      var c:AU8;       // local variable in "process", union, CHAR64LONG16
	@idx(16, -64) var l:AI32;

	@idx(1)  var x80:AU8;          // for padding
	@idx(1)  var x0:AU8;

	public inline function new():Void {
		this = Fraw.malloc(CAPACITY, false);
		x80[0] = 0x80;
		x0[0] = 0;
	}
	public inline function reset():Void {
		Fraw.memset(this, 0, CAPACITY - 2);
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  LibSha1
//
//  Implementation of SHA1 hash function.
//  Original author:  Steve Reid <sreid@sea-to-sky.net>
//  Contributions by: James H. Brown <jbrown@burgoyne.com>, Saul Kravitz <Saul.Kravitz@celera.com>,
//  and Ralph Giles <giles@ghostscript.com>
//  Modified by WaterJuice retaining Public Domain license.
//
//  This is free and unencumbered software released into the public domain - June 2013 waterjuice.org
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Sha1{

	static var sa: Sha1Context = cast Ptr.NUL;

	public static function init():Void {
		if (sa == Ptr.NUL) sa = new Sha1Context();
	}

	public static function make(input: Ptr, ilen:Int, output: Ptr):Void {
		sa.reset();
		starts(sa);
		update(sa, input, ilen);
		finish(sa, cast output);
	}

	static function starts(ctx: Sha1Context):Void {
		ctx.State[0] = 0x67452301;
		ctx.State[1] = 0xEFCDAB89;
		ctx.State[2] = 0x98BADCFE;
		ctx.State[3] = 0x10325476;
		ctx.State[4] = 0xC3D2E1F0;
		ctx.Count[0] = 0;
		ctx.Count[1] = 0;
	}

	static function update(ctx: Sha1Context/*Context*/, input: Ptr/*Buffer*/, ilen:Int /*BufferSize*/):Void {
		var i = 0, j = 0;

		j = (ctx.Count[0] >> 3) & 63;

		ctx.Count[0] += ilen << 3;
		if ( ctx.Count[0] < (ilen << 3)) {

			ctx.Count[1]++;
		}

		ctx.Count[1] += ilen >> 29;

		if ( (j + ilen) > 63) {

			i = 64 - j;

			Fraw.memcpy((ctx.Buffer:Ptr) + j, input, i);

			process(ctx.State, ctx.Buffer);

			while ((i + 63) < ilen) {
				process(ctx.State, cast (input + i));
				i += 64;
			}
			j = 0;
		} else {
			i = 0;
		}

		ilen -= i;
		if (ilen == 1)
			Memory.setByte(ctx.Buffer + j, Memory.getByte(input + i));
		else if (ilen > 0)
			Fraw.memcpy((ctx.Buffer:Ptr) + j, input + i, ilen);
	}

	// this function is too large for neko
	static function process(state: AI32/*uint32_t state[5]*/, data: AU8/*const uint8_t buffer[64]*/):Void {
		var a = state[0];
		var b = state[1];
		var	c = state[2];
		var	d = state[3];
		var	e = state[4];

		var L:AI32 = sa.l;  // L is associated with macros
		Fraw.memcpy(sa.c, data, 64);

		var La = 0, Lb = 0, Lc = 0, Ld = 0;

		R0(a,b,c,d,e, 0); R0(e,a,b,c,d, 1); R0(d,e,a,b,c, 2); R0(c,d,e,a,b, 3);
		R0(b,c,d,e,a, 4); R0(a,b,c,d,e, 5); R0(e,a,b,c,d, 6); R0(d,e,a,b,c, 7);
		R0(c,d,e,a,b, 8); R0(b,c,d,e,a, 9); R0(a,b,c,d,e,10); R0(e,a,b,c,d,11);
		R0(d,e,a,b,c,12); R0(c,d,e,a,b,13); R0(b,c,d,e,a,14); R0(a,b,c,d,e,15);
		R1(e,a,b,c,d,16); R1(d,e,a,b,c,17); R1(c,d,e,a,b,18); R1(b,c,d,e,a,19);
		R2(a,b,c,d,e,20); R2(e,a,b,c,d,21); R2(d,e,a,b,c,22); R2(c,d,e,a,b,23);
		R2(b,c,d,e,a,24); R2(a,b,c,d,e,25); R2(e,a,b,c,d,26); R2(d,e,a,b,c,27);
		R2(c,d,e,a,b,28); R2(b,c,d,e,a,29); R2(a,b,c,d,e,30); R2(e,a,b,c,d,31);
		R2(d,e,a,b,c,32); R2(c,d,e,a,b,33); R2(b,c,d,e,a,34); R2(a,b,c,d,e,35);
		R2(e,a,b,c,d,36); R2(d,e,a,b,c,37); R2(c,d,e,a,b,38); R2(b,c,d,e,a,39);
		R3(a,b,c,d,e,40); R3(e,a,b,c,d,41); R3(d,e,a,b,c,42); R3(c,d,e,a,b,43);
		R3(b,c,d,e,a,44); R3(a,b,c,d,e,45); R3(e,a,b,c,d,46); R3(d,e,a,b,c,47);
		R3(c,d,e,a,b,48); R3(b,c,d,e,a,49); R3(a,b,c,d,e,50); R3(e,a,b,c,d,51);
		R3(d,e,a,b,c,52); R3(c,d,e,a,b,53); R3(b,c,d,e,a,54); R3(a,b,c,d,e,55);
		R3(e,a,b,c,d,56); R3(d,e,a,b,c,57); R3(c,d,e,a,b,58); R3(b,c,d,e,a,59);
		R4(a,b,c,d,e,60); R4(e,a,b,c,d,61); R4(d,e,a,b,c,62); R4(c,d,e,a,b,63);
		R4(b,c,d,e,a,64); R4(a,b,c,d,e,65); R4(e,a,b,c,d,66); R4(d,e,a,b,c,67);
		R4(c,d,e,a,b,68); R4(b,c,d,e,a,69); R4(a,b,c,d,e,70); R4(e,a,b,c,d,71);
		R4(d,e,a,b,c,72); R4(c,d,e,a,b,73); R4(b,c,d,e,a,74); R4(a,b,c,d,e,75);
		R4(e,a,b,c,d,76); R4(d,e,a,b,c,77); R4(c,d,e,a,b,78); R4(b,c,d,e,a,79);

		state[0] += a;
		state[1] += b;
		state[2] += c;
		state[3] += d;
		state[4] += e;
	}

	static function finish(ctx: Sha1Context, output: AU8/* SHA1_HASH* Digest */): Void {

		var finalcount:AU8 = ctx.finalcount;
		var Count:AI32 = ctx.Count;

		for (i in 0...8) {
			finalcount[i] = Count[(i >= 4 ? 0 : 1)]
				>> (((3 - (i & 3)) * 8)  & 255);
		}

		update(ctx, ctx.x80, 1);


		var x0 = ctx.x0;
		while ((Count[0] & 504) != 448) {
			update(ctx, x0, 1);
		}

		update(ctx, finalcount, 8);

		var State = ctx.State;
		for(i in 0...SHA1_HASH_SIZE) {
			output[i] = ((State[i>>2] >> ((3-(i & 3)) * 8) ) & 255);
		}

	}
}