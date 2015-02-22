#include <stddef.h>

void breakpoint(void);
int giftofb(void *fb, void *src, size_t srclen, int image_no);
char * const fb = (char * const)(0xc0000);
char * const gif = (char * const)(0x80000);

int main()
{
	while (1) {
		giftofb(fb, gif, 0x40000, 0);
		breakpoint();
	}
	return 0;
}
