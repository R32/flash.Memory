#include "BData.h"

namespace mem{

	void BData::select(void* alloc, size_t len)
	{
		b = alloc;
		length = len;
		u8 = (uint8_t*) b;
		u16 = (uint16_t*) b;
		i32 = (int32_t*) b;
		i64 = (int64_t*) b;
		f4 = (float*) b;
		f8 = (double*) b;
	}

	char* BData::Cs()
	{
		return (char*) b;
	}

	void BData::resize(size_t len)
	{
		if(len <= length) return;
		void* newly = malloc(len);
		memcpy(newly, this->b, length);
		free(this->b);
		select(newly, len);
	}

	void BData::destory(BData* byte)
	{
		if(byte->b != NULL)
			byte->removeData();
		delete byte;
	}
}