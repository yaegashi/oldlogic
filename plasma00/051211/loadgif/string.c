/* $Id: string.c 58 2005-12-01 20:34:59Z yaegashi $ */

#include "string.h"

size_t
strlen(const char * s)
{
	const char *t;
	for (t = s; *t; t++);
	return t - s;
}


void *
memset(void *s, int c, size_t count)
{
	char *t = (char *)s;
	while (count-- > 0)
		*t++ = c;
	return s;
}


void *
memcpy(void *dest, const void *src, size_t count)
{
	char *t = (char *)dest, *s = (char *)src;
	while (count-- > 0)
		*t++ = *s++;
	return dest;
}


char *
strncpy(char *dest, const char *src, size_t count)
{
	char *tmp = dest;
	while (count-- > 0) {
		if ((*tmp++ = *src++) == 0)
			break;
	}
	return dest;
}


int
strcmp(const char *cs, const char *ct)
{
	register signed char __res;
	while (1) {
		if ((__res = *cs - *ct++) != 0 || !*cs++)
			break;
	}
	return __res;
}


int
strncmp(const char * cs, const char * ct, size_t count)
{
	register signed char __res = 0;
	while (count) {
		if ((__res = *cs - *ct++) != 0 || !*cs++)
			break;
		count--;
	}
	return __res;
}
