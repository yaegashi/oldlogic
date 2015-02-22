#ifndef __STRING_H
#define __STRING_H

#include <stddef.h>

size_t strlen(const char * s);
void *memset(void *s, int c, size_t count);
void *memcpy(void *dest, const void *src, size_t count);
char * strncpy(char *dest, const char *src, size_t count);
int strcmp(const char *cs, const char *ct);
int strncmp(const char * cs, const char * ct, size_t count);

#endif /* __STRING_H */
