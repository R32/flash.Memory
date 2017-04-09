#include "BData.h"

namespace mem{

	void BData::select(void* space, size_t len)
	{
		b = space;
		length = len;
	}

	void BData::resize(size_t len)
	{
		if(len <= length || b == NULL) return;
		void* newly = realloc(b, len);
		select(newly, len);
	}

	void BData::destory(BData* byte)
	{
		if(byte->b != NULL)
			byte->removeData();
		delete byte;
	}
}