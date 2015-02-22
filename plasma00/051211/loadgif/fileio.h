#ifndef _FILEIO_H
#define _FILEIO_H

/* $Id: fileio.h 58 2005-12-01 20:34:59Z yaegashi $ */

#include <stddef.h>

typedef struct {
	void *ptr, *begin, *end;
} FILE;

void finit(FILE *stream, void *ptr, size_t size);
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);

#endif
