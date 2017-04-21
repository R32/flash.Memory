package mem.obs;

import mem.Ptr;
import mem.obs._macros.Md5Macros.*;

/*
 *  RFC 1321 compliant MD5 implementation
 *
 *  Copyright (C) 2006-2013, Brainspark B.V.
 *
 *  This file is part of PolarSSL (http://www.polarssl.org)
 *  Lead Maintainer: Paul Bakker <polarssl_maintainer at polarssl.org>
 *
 *  All rights reserved.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */
#if !macro @:build(mem.Struct.make()) #end
@:dce private abstract Md5Context(Ptr) to Ptr {
	@idx(2) var total: AI32;   // [len: 2, bytes: 4]
	@idx(4) var state: AI32;
	@idx(64) var buffer: AU8;
	@idx(8) var msglen:AU8;
	@idx(64) var padding: AU8; // const
	public inline function new() {
		this = Fraw.malloc(CAPACITY, true);
		padding[0] = 0x80;
	}

	public inline function reset():Void {
		Fraw.memset(this, 0, CAPACITY - 64);
	}
}


class Md5 {

	static var m5:Md5Context = cast Malloc.NUL;

	public static function init():Void {
		if (m5 == Malloc.NUL) m5 = new Md5Context();
	}

	public static function make(input: Ptr, ilen:Int, output: Ptr) {
		m5.reset();
		starts(m5);
		update(m5, input, ilen);
		finish(m5, output);
	}

	static function starts(ctx: Md5Context):Void {
		ctx.state[0] = 0x67452301;
		ctx.state[1] = 0xEFCDAB89;
		ctx.state[2] = 0x98BADCFE;
		ctx.state[3] = 0x10325476;
	}

	static function update(ctx: Md5Context, input: Ptr, ilen:Int):Void {
		var fill, left = 0;
		if (ilen <= 0) return;

		left = ctx.total[0] & 0x3F;
		fill = 64 - left;

		ctx.total[0] += ilen;
		ctx.total[0] &= 0xFFFFFFFF;

		if (ctx.total[0] < ilen) ctx.total[1] += 1;

		if (left > 0 && ilen >= fill) {
			Fraw.memcpy((ctx.buffer:Ptr) + left, input, fill);
			process(ctx.state, ctx.buffer);
			input += fill;
			ilen -= fill;
			left = 0;
		}

		while (ilen >= 64) {
			process(ctx.state, input);
			input += 64;
			ilen -= 64;
		}
		if (ilen > 0) Fraw.memcpy((ctx.buffer:Ptr) + left, input, ilen);
	}

	// N.B: crash on Neko, becouse this function is too large after macro expansion... Sha1 is the same.
	static function process(state: AI32, data: Ptr):Void {
		var A = 0, B = 0, C = 0, D = 0;

		var X:AI32 = cast data;

		A = state[0];
		B = state[1];
		C = state[2];
		D = state[3];

		P( A, B, C, D,  0,  7, 0xD76AA478, F1 );
		P( D, A, B, C,  1, 12, 0xE8C7B756, F1 );
		P( C, D, A, B,  2, 17, 0x242070DB, F1 );
		P( B, C, D, A,  3, 22, 0xC1BDCEEE, F1 );
		P( A, B, C, D,  4,  7, 0xF57C0FAF, F1 );
		P( D, A, B, C,  5, 12, 0x4787C62A, F1 );
		P( C, D, A, B,  6, 17, 0xA8304613, F1 );
		P( B, C, D, A,  7, 22, 0xFD469501, F1 );
		P( A, B, C, D,  8,  7, 0x698098D8, F1 );
		P( D, A, B, C,  9, 12, 0x8B44F7AF, F1 );
		P( C, D, A, B, 10, 17, 0xFFFF5BB1, F1 );
		P( B, C, D, A, 11, 22, 0x895CD7BE, F1 );
		P( A, B, C, D, 12,  7, 0x6B901122, F1 );
		P( D, A, B, C, 13, 12, 0xFD987193, F1 );
		P( C, D, A, B, 14, 17, 0xA679438E, F1 );
		P( B, C, D, A, 15, 22, 0x49B40821, F1 );

		P( A, B, C, D,  1,  5, 0xF61E2562, F2 );
		P( D, A, B, C,  6,  9, 0xC040B340, F2 );
		P( C, D, A, B, 11, 14, 0x265E5A51, F2 );
		P( B, C, D, A,  0, 20, 0xE9B6C7AA, F2 );
		P( A, B, C, D,  5,  5, 0xD62F105D, F2 );
		P( D, A, B, C, 10,  9, 0x02441453, F2 );
		P( C, D, A, B, 15, 14, 0xD8A1E681, F2 );
		P( B, C, D, A,  4, 20, 0xE7D3FBC8, F2 );
		P( A, B, C, D,  9,  5, 0x21E1CDE6, F2 );
		P( D, A, B, C, 14,  9, 0xC33707D6, F2 );
		P( C, D, A, B,  3, 14, 0xF4D50D87, F2 );
		P( B, C, D, A,  8, 20, 0x455A14ED, F2 );
		P( A, B, C, D, 13,  5, 0xA9E3E905, F2 );
		P( D, A, B, C,  2,  9, 0xFCEFA3F8, F2 );
		P( C, D, A, B,  7, 14, 0x676F02D9, F2 );
		P( B, C, D, A, 12, 20, 0x8D2A4C8A, F2 );

		P( A, B, C, D,  5,  4, 0xFFFA3942, F3 );
		P( D, A, B, C,  8, 11, 0x8771F681, F3 );
		P( C, D, A, B, 11, 16, 0x6D9D6122, F3 );
		P( B, C, D, A, 14, 23, 0xFDE5380C, F3 );
		P( A, B, C, D,  1,  4, 0xA4BEEA44, F3 );
		P( D, A, B, C,  4, 11, 0x4BDECFA9, F3 );
		P( C, D, A, B,  7, 16, 0xF6BB4B60, F3 );
		P( B, C, D, A, 10, 23, 0xBEBFBC70, F3 );
		P( A, B, C, D, 13,  4, 0x289B7EC6, F3 );
		P( D, A, B, C,  0, 11, 0xEAA127FA, F3 );
		P( C, D, A, B,  3, 16, 0xD4EF3085, F3 );
		P( B, C, D, A,  6, 23, 0x04881D05, F3 );
		P( A, B, C, D,  9,  4, 0xD9D4D039, F3 );
		P( D, A, B, C, 12, 11, 0xE6DB99E5, F3 );
		P( C, D, A, B, 15, 16, 0x1FA27CF8, F3 );
		P( B, C, D, A,  2, 23, 0xC4AC5665, F3 );

		P( A, B, C, D,  0,  6, 0xF4292244, F4 );
		P( D, A, B, C,  7, 10, 0x432AFF97, F4 );
		P( C, D, A, B, 14, 15, 0xAB9423A7, F4 );
		P( B, C, D, A,  5, 21, 0xFC93A039, F4 );
		P( A, B, C, D, 12,  6, 0x655B59C3, F4 );
		P( D, A, B, C,  3, 10, 0x8F0CCC92, F4 );
		P( C, D, A, B, 10, 15, 0xFFEFF47D, F4 );
		P( B, C, D, A,  1, 21, 0x85845DD1, F4 );
		P( A, B, C, D,  8,  6, 0x6FA87E4F, F4 );
		P( D, A, B, C, 15, 10, 0xFE2CE6E0, F4 );
		P( C, D, A, B,  6, 15, 0xA3014314, F4 );
		P( B, C, D, A, 13, 21, 0x4E0811A1, F4 );
		P( A, B, C, D,  4,  6, 0xF7537E82, F4 );
		P( D, A, B, C, 11, 10, 0xBD3AF235, F4 );
		P( C, D, A, B,  2, 15, 0x2AD7D2BB, F4 );
		P( B, C, D, A,  9, 21, 0xEB86D391, F4 );

		state[0] += A;
		state[1] += B;
		state[2] += C;
		state[3] += D;
	}


	static function finish(ctx: Md5Context, output: Ptr):Void {

		var last = 0, padn = 0, high = 0, low = 0;

		high = ( ctx.total[0] >> 29 )
			|  ( ctx.total[1] <<  3 );
		low =  ( ctx.total[0] <<  3 );

		Memory.setI32(ctx.msglen, low);
		Memory.setI32(ctx.msglen + 4, high);

		last = ctx.total[0] & 0x3F;
		padn = ( last < 56 ) ? ( 56 - last ) : ( 120 - last );

		update(ctx, ctx.padding, padn);
		update(ctx, ctx.msglen, 8);

		Fraw.memcpy(output, ctx.state, 16);
	}
}