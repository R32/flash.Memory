#include "stdafx.h"
#include "BData.h"
#include "stdio.h"

#undef NDEBUG
#include "assert.h"

int main(int argc, const char* argv[]){

	mem::BData* byte = new mem::BData(128);

	byte->setInt32(sizeof(int) * 2, 0x55667788);
	byte->setInt32(sizeof(int) * 3, 0x11223344);

	size_t base = 2 * sizeof(int);

	assert( byte->getInt64(base) == 0x01122334455667788LL
	&& byte->get(0 + base) == 0x88
	&& byte->get(7 + base) == 0x11
	&& byte->getUInt16(0 + base) == 0x7788
	&& byte->getInt32(1 + base) == 0x44556677
	);

	byte->blit(100, byte, base, 8);
	byte->resize(1024);
	byte->resize(2048);

	assert( byte->getInt64(100) == 0x01122334455667788LL
	&& byte->get(0 + 100) == 0x88
	&& byte->get(7 + 100) == 0x11
	&& byte->getUInt16(0 + 100) == 0x7788
	&& byte->getInt32(1 + 100) == 0x44556677
	);

	byte->fill(200, 8, 0x22);
	assert(byte->getInt64(200) == 0x2222222222222222LL);

	printf("done! sizeof(BData) == %d\n", sizeof(mem::BData));

	mem::BData::destory(byte);
	return 0;
}