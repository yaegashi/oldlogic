/*
 * $Id: openwince.h,v 1.1 2005/09/29 08:31:18 telka Exp $
 *
 * Common header file
 * Copyright (C) 2002 ETC s.r.o.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the ETC s.r.o. nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Written by Marcel Telka <marcel@telka.sk>, 2002.
 *
 */

#ifndef	COMMON_H
#define	COMMON_H

#ifndef LANGUAGE
#	ifdef __ASSEMBLY__
#		define LANGUAGE ASM
#	else
#		define LANGUAGE C
#	endif
#endif

#ifndef ASM
#define	ASM	0
#endif

#ifndef C
#define	C	1
#endif

#define	MAX_BITS_ABS_VAL	1024
#define	BITS_ABS(a)		(((((a) + MAX_BITS_ABS_VAL) / MAX_BITS_ABS_VAL) * 2 - 1) * (a))
#define	BITS_MIN(a,b)		(((a) + (b) - BITS_ABS((a) - (b))) / 2)

#define	bit(b)			(1 << (b))
#define	bits(b1,b2)		(((2 << BITS_ABS((b1) - (b2))) - 1) << BITS_MIN(b1,b2))
#define	bits_val(b1,b2,v)	(((v) << BITS_MIN(b1,b2)) & bits(b1,b2))
#define	bits_get(b1,b2,v)	(((v) & bits(b1,b2)) >> BITS_MIN(b1,b2))

#endif /* COMMON_H */
