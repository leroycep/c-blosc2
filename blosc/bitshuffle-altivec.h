/*********************************************************************
  Blosc - Blocked Shuffling and Compression Library

  Copyright (c) 2021  The Blosc Development Team <blosc@blosc.org>
  https://blosc.org
  License: BSD 3-Clause (see LICENSE.txt)

  See LICENSE.txt for details about copyright and rights to use.
**********************************************************************/

/* ALTIVEC-accelerated shuffle/unshuffle routines. */

#ifndef BITSHUFFLE_ALTIVEC_H
#define BITSHUFFLE_ALTIVEC_H

#include "blosc2/blosc2-common.h"


BLOSC_NO_EXPORT int64_t
    bshuf_trans_byte_elem_altivec(void* in, void* out, const size_t size,
                                  const size_t elem_size, void* tmp_buf);

BLOSC_NO_EXPORT int64_t
    bshuf_trans_byte_bitrow_altivec(void* in, void* out, const size_t size,
                                    const size_t elem_size);

BLOSC_NO_EXPORT int64_t
    bshuf_shuffle_bit_eightelem_altivec(void* in, void* out, const size_t size,
                                     const size_t elem_size);

/**
  ALTIVEC-accelerated bitshuffle routine.
*/
BLOSC_NO_EXPORT int64_t
    bshuf_trans_bit_elem_altivec(void* in, void* out, const size_t size,
                              const size_t elem_size, void* tmp_buf);

/**
  ALTIVEC-accelerated bitunshuffle routine.
*/
BLOSC_NO_EXPORT int64_t
    bshuf_untrans_bit_elem_altivec(void* in, void* out, const size_t size,
                                const size_t elem_size, void* tmp_buf);

#endif /* BITSHUFFLE_ALTIVEC_H */
