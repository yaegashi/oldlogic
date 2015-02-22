#include "fileio.h"
#include "string.h"

void finit(FILE *stream, void *ptr, size_t size)
{
	stream->ptr = ptr;
	stream->begin = ptr;
	stream->end = (char *)ptr+size;
}

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream)
{
	size_t leftbytes = (char *)stream->end - (char *)stream->ptr;
	size_t leftblocks = leftbytes / size;
	size_t n = nmemb < leftblocks ? nmemb : leftblocks;
	if (n > 0) {
		size_t bytes = size * n;
		memcpy(ptr, stream->ptr, bytes);
		stream->ptr = (char *)stream->ptr + bytes;
	}
	return n;
}
