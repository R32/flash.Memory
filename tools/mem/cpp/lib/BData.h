#ifndef INCLUDED_BDATA_
#define INCLUDED_BDATA_

#include "stdafx.h"

namespace mem {

	class BData {

	private:
		size_t  length;
		void* b;
		uint8_t* u8;
		uint16_t* u16;
		int32_t* i32;
		int64_t* i64;
		float* f4;
		double* f8;

		void select(void* alloc, size_t len);
	public:
		explicit BData(const BData& that);

		explicit BData(size_t len)
		{
			select(malloc(len), len);
		}

		inline const size_t Length() { return length; }
		inline uint8_t* U8() { return u8; }
		inline uint16_t* U16() { return u16; }
		inline int32_t* I32() { return i32; }
		inline int64_t* I64() { return i64; }
		inline float* F4() { return f4; }
		inline double* F8() { return f8; }

		char* Cs();
		void resize(size_t len);

		inline void removeData(){
			free(b);
			b = NULL;
		}

		inline uint8_t get(size_t pos)
		{
			assert(pos >= 0 && pos  < length);
			return u8[pos];
		}
		inline void set(size_t pos, uint8_t v)
		{
			assert(pos >= 0 && pos  < length);
			u8[pos] = v;
		}

		//  src -> this[pos]
		inline void blit(size_t pos, BData* src, size_t srcpos, size_t len)
		{
			assert(!(pos < 0 || srcpos < 0 || len < 0 || pos + len > this->length || srcpos + len > src->length));
			::memcpy(this->U8() + pos, src->U8() + srcpos, len);
		}

		inline void fill(size_t pos, size_t len, uint8_t value)
		{
			assert(pos >= 0 && (pos + len) <= length);
			::memset(u8 + pos, value, len);
		}

		// -DNDEBUG defined in stdafx.h
		inline double getDouble(size_t pos)
		{
			assert(pos >= 0 && (pos + sizeof(double)) <= length);
			return *(double*)(u8 + pos);
		}
		inline void setDouble(size_t pos, double v)
		 {
			assert(pos >= 0 && (pos + sizeof(double)) <= length);
			*(double*)(u8 + pos) = v;
		}

		inline float getFloat(size_t pos)
		{
			assert(pos >= 0 && (pos + sizeof(float)) <= length);
			return *(float*)(u8 + pos);
		}
		inline void setFloat(size_t pos, float v)
		{
			assert(pos >= 0 && (pos + sizeof(float)) <= length);
		 	*(float*)(u8 + pos) = v;
		}

		inline uint16_t getUInt16(size_t pos)
		{
			assert(pos >= 0 && (pos + sizeof(uint16_t)) <= length);
			return *(uint16_t*)(u8 + pos);
		}
		inline void setUInt16(size_t pos, uint16_t v)
		{
			assert(pos >= 0 && (pos + sizeof(uint16_t)) <= length);
			*(uint16_t*)(u8 + pos) = v;
		}


		inline int32_t getInt32(size_t pos) {
			assert(pos >= 0 && (pos + sizeof(int32_t)) <= length);
			return *(int32_t*)(u8 + pos);
		}
		inline void setInt32(size_t pos, int32_t v)
		{
			assert(pos >= 0 && (pos + sizeof(int32_t)) <= length);
		 	*(int32_t*)(u8 + pos) = v;
		}

		inline int64_t getInt64(size_t pos)
		{
			assert(pos >= 0 && (pos + sizeof(int64_t)) <= length);
			return *(int64_t*)(u8 + pos);
		}
		inline void setInt64(size_t pos, int64_t v)
		{
			assert(pos >= 0 && (pos + sizeof(int64_t)) <= length);
			*(int64_t*)(u8 + pos) = v;
		}

		static void destory(BData* byte);
	};
}

#endif