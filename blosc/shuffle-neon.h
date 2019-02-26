/*********************************************************************
  Blosc - Blocked Shuffling and Compression Library

  Author: Francesc Alted <francesc@blosc.org>

  Note: Adapted for NEON by Lucian Marc.

  See LICENSE.txt for details about copyright and rights to use.
**********************************************************************/

/* NEON-accelerated shuffle/unshuffle routines. */

#ifndef SHUFFLE_NEON_H
#define SHUFFLE_NEON_H

#include "blosc-common.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
  NEON-accelerated shuffle routine.
*/
BLOSC_NO_EXPORT void shuffle_neon(const int32_t bytesoftype, const int32_t blocksize,
                                  const uint8_t* const _src, uint8_t* const _dest);

/**
  NEON-accelerated unshuffle routine.
*/
BLOSC_NO_EXPORT void unshuffle_neon(const size_t bytesoftype, const size_t blocksize,
                                    const uint8_t *_src, uint8_t *_dest);

#ifdef __cplusplus
}
#endif

#endif /* SHUFFLE_NEON_H */
