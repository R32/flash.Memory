#ifndef FRAW_MBS
#define FRAW_MBS

#include "stdlib.h"
#include "stdint.h"
#include "string.h"
#include "locale.h"
#include "wchar.h"
#include "errno.h"

#include <malloc.h>
#if defined(__GNUC__) &&!defined(__MINGW32__)
#	include <alloca.h>
#endif

#include "hxcpp.h"


// Copyright (c) 2008-2010 Bjoern Hoehrmann <bjoern@hoehrmann.de>
// See http://bjoern.hoehrmann.de/utf-8/decoder/dfa/ for details.
#define UTF8_ACCEPT 0
#define UTF8_REJECT 12

static const uint8_t utf8d[] = {
	// The first part of the table maps bytes to character classes that
	// to reduce the size of the transition table and create bitmasks.
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
	7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
	8, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	10, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 3, 3, 11, 6, 6, 6, 5, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,

	// The second part is a transition table that maps a combination
	// of a state of the automaton and a character class to a state.
	0, 12, 24, 36, 60, 96, 84, 12, 12, 12, 48, 72, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
	12, 0, 12, 12, 12, 12, 12, 0, 12, 0, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 24, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 12, 12, 24, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 36, 12, 36, 12, 12, 12, 36, 12, 12, 12, 12, 12, 36, 12, 36, 12, 12,
	12, 36, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
};


static uint32_t utf8towcs(wchar_t* out, const char* src) {
	uint8_t byte;
	uint8_t type;
	uint32_t codep;
	uint32_t state = 0;
	uint32_t i = 0;
	if (out == NULL) {
		while (byte = (uint8_t)*src++) {
			type = utf8d[byte];

			state = utf8d[256 + state + type];

			if (state == UTF8_REJECT) {
				errno = EILSEQ;
				return -1;
			} else if (state == UTF8_ACCEPT) {
				++i;
			}
		}
	} else {
		while (byte = (uint8_t)*src++) {
			type = utf8d[byte];

			codep = state != UTF8_ACCEPT ?
				(byte & 0x3f) | (codep << 6) :
				(0xff >> type) & (byte);

			state = utf8d[256 + state + type];
			if (state == UTF8_REJECT) {
				errno = EILSEQ;
				return -1;
			} else if (state == UTF8_ACCEPT) {
				out[i++] = (wchar_t)codep;
			}
		}
		out[i] = 0;  // add "\0"
	}
	return i;
}

static uint32_t wcstoutf8(char* out, const wchar_t* src) {
	wchar_t c = 0;
	uint32_t i = 0;
	if (out == NULL) {
		while (c = *src++) {
			if (c < 0x80) {
				i++;
			} else if (c < 0x800) {
				i += 2;
			} else {
				i += 3;
			}
		}
	} else {
		while (c = *src++) {
			if (c < 0x80) {
				out[i++] = (char)c;
			} else if (c < 0x800) {
				out[i++] = (char)(0xC0 | (c >> 6));
				out[i++] = (char)(0x80 | (c & 63));
			} else {
				out[i++] = (char)(0xE0 | (c >> 12));
				out[i++] = (char)(0x80 | ((c >> 6) & 63));
				out[i++] = (char)(0x80 | (c & 63));
			}
		}
		out[i] = 0; // add "\0"
	}
	return i;
}

static String utf8tombs(String hxstr) {
	uint32_t mbs_len;
	const char* src = hxstr.__s;
	uint32_t wcs_len = utf8towcs(NULL, src);
	if (wcs_len == -1) return String("", 0);
	wchar_t* wcs = (wchar_t*) alloca(sizeof(wchar_t) * (wcs_len + 1));
	utf8towcs(wcs, src);
	mbs_len = wcstombs(NULL, wcs, 0);
	char* out = (char*) hx::InternalNew(mbs_len + 1, false);
	wcstombs(out, wcs, mbs_len);
	out[mbs_len] = 0;
	return String(out, mbs_len);
}

static String mbstoutf8(String hxstr) {
	uint32_t mbs_len;
	const char* src = hxstr.__s;
	uint32_t wcs_len = mbstowcs(NULL, src, 0);
	if (wcs_len == -1) return String("", 0);
	wchar_t* wcs = (wchar_t*) alloca(sizeof(wchar_t) * (wcs_len + 1));
	mbstowcs(wcs, src, wcs_len);
	wcs[wcs_len] = 0;

	mbs_len = wcstoutf8(NULL, wcs);
	char* out = (char*) hx::InternalNew(mbs_len + 1, false);
	wcstoutf8(out, wcs);
	return String(out, mbs_len);
}

#endif