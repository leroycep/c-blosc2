/*********************************************************************
    Blosc - Blocked Shuffling and Compression Library

    Copyright (c) 2021  The Blosc Development Team <blosc@blosc.org>
    https://blosc.org
    License: BSD 3-Clause (see LICENSE.txt)

    See LICENSE.txt for details about copyright and rights to use.

    Test program demonstrating use of the Blosc filter from C code.
    To compile this program:

    $ gcc -O test_bytedelta.c -o test_bytedelta -lblosc2

    To run:

    $ ./test_bytedelta
    Successful roundtrip!
    Compression: 41472 -> 4937 (8.4x)
    rand: 36535 obtained

    Successful roundtrip!
    Compression: 1792 -> 1005 (1.8x)
    mixed_values: 787 obtained

    Successful roundtrip!
    Compression: 16128 -> 1599 (10.1x)
    arange_like: 14529 obtained

**********************************************************************/

#include <stdio.h>
#include <inttypes.h>
#include "blosc2/filters-registry.h"
#include "b2nd.h"

static int test_bytedelta(blosc2_schunk *schunk) {

  int64_t nchunks = schunk->nchunks;
  int32_t chunksize = (int32_t) (schunk->chunksize);
  uint8_t *data_in = malloc(chunksize);
  int decompressed;
  int64_t csize;
  int64_t dsize;
  int64_t csize_f = 0;
  uint8_t *data_out = malloc(chunksize + BLOSC2_MAX_OVERHEAD);
  uint8_t *data_dest = malloc(chunksize);

  /* Create a context for compression */
  blosc2_cparams cparams = BLOSC2_CPARAMS_DEFAULTS;
  cparams.typesize = schunk->typesize;
  cparams.compcode = BLOSC_LZ4;
  cparams.filters[BLOSC2_MAX_FILTERS - 2] = BLOSC_SHUFFLE;
  cparams.filters[BLOSC2_MAX_FILTERS - 1] = BLOSC_FILTER_BYTEDELTA;
  cparams.filters_meta[BLOSC2_MAX_FILTERS - 1] = 0;  // 0 means typesize when using schunks
  cparams.clevel = 9;
  cparams.nthreads = 1;
  cparams.blocksize = schunk->blocksize;
  cparams.schunk = schunk;
  blosc2_context *cctx;
  cctx = blosc2_create_cctx(cparams);
  if (cctx == NULL) {
    printf("Cannot create compression context!\n");
    return -1;
  }

  blosc2_dparams dparams = BLOSC2_DPARAMS_DEFAULTS;
  dparams.nthreads = 1;
  dparams.schunk = schunk;
  blosc2_context *dctx;
  dctx = blosc2_create_dctx(dparams);
  if (cctx == NULL) {
    printf("Cannot create decompression context!\n");
    return -1;
  }

  for (int ci = 0; ci < nchunks; ci++) {

    decompressed = blosc2_schunk_decompress_chunk(schunk, ci, data_in, chunksize);
    if (decompressed < 0) {
      printf("Error decompressing chunk \n");
      return -1;
    }

    /* Compress with clevel=5 and shuffle active  */
    csize = blosc2_compress_ctx(cctx, data_in, chunksize, data_out, chunksize + BLOSC2_MAX_OVERHEAD);
    if (csize == 0) {
      printf("Buffer is incompressible.  Giving up.\n");
      return -1;
    } else if (csize < 0) {
      printf("Compression error.  Error code: %" PRId64 "\n", csize);
      return (int) csize;
    }
    csize_f += csize;

    /* Decompress  */
    dsize = blosc2_decompress_ctx(dctx, data_out, chunksize + BLOSC2_MAX_OVERHEAD, data_dest, chunksize);
    if (dsize <= 0) {
      printf("Decompression error.  Error code: %" PRId64 "\n", dsize);
      return (int) dsize;
    }

    for (int i = 0; i < chunksize; i++) {
      if (data_in[i] != data_dest[i]) {
        printf("i: %d, data %u, dest %u", i, data_in[i], data_dest[i]);
        printf("\n Decompressed data differs from original!\n");
        return -1;
      }
    }
  }
  csize_f = csize_f / nchunks;

  free(data_in);
  free(data_out);
  free(data_dest);
  blosc2_free_ctx(cctx);
  blosc2_free_ctx(dctx);

  printf("Successful roundtrip!\n");
  printf("Compression: %d -> %" PRId64 " (%.1fx)\n", chunksize, csize_f, (1. * chunksize) / (double) csize_f);
  return (int) (chunksize - csize_f);
}


int rand_() {
  int8_t ndim = 3;
  int typesize = 4;
  int64_t shape[] = {32, 18, 32};
  int32_t chunkshape[] = {17, 16, 24};
  int32_t blockshape[] = {8, 9, 8};
  int64_t nelem = 1;
  for (int i = 0; i < ndim; ++i) {
    nelem *= (int) (shape[i]);
  }
  int64_t size = typesize * nelem;
  float *data = malloc(size);
  for (int64_t i = 0; i < nelem; i++) {
    data[i] = (float) (rand() % 220);
  }

  blosc2_cparams cparams = BLOSC2_CPARAMS_DEFAULTS;
  cparams.typesize = typesize;
  blosc2_storage b2_storage = {.cparams=&cparams};
  b2_storage.contiguous = true;

  b2nd_context_t *ctx = b2nd_create_ctx(&b2_storage, ndim, shape, chunkshape, blockshape, NULL, 0,
                                        NULL, 0);

  b2nd_array_t *arr;
  BLOSC_ERROR(b2nd_from_cbuffer(ctx, &arr, data, size));
  blosc2_schunk *schunk = arr->sc;

  /* Run the test. */
  int result = test_bytedelta(schunk);
  BLOSC_ERROR(b2nd_free_ctx(ctx));
  BLOSC_ERROR(b2nd_free(arr));
  free(data);
  return result;
}

int mixed_values() {
  int8_t ndim = 2;
  int typesize = 4;
  int64_t shape[] = {128, 111};
  int32_t chunkshape[] = {32, 11};
  int32_t blockshape[] = {16, 7};
  int64_t nelem = 1;
  for (int i = 0; i < ndim; ++i) {
    nelem *= (int) (shape[i]);
  }
  int64_t size = typesize * nelem;
  int32_t *data = calloc(nelem, typesize);
  for (int i = 0; i < (nelem / 4); i++) {
    data[i * 4] = 11111111;
    data[i * 4 + 1] = 99999999;
  }

  blosc2_cparams cparams = BLOSC2_CPARAMS_DEFAULTS;
  cparams.typesize = typesize;
  blosc2_storage b2_storage = {.cparams=&cparams};
  b2_storage.contiguous = true;

  b2nd_context_t *ctx = b2nd_create_ctx(&b2_storage, ndim, shape, chunkshape, blockshape, NULL, 0,
                                        NULL, 0);

  b2nd_array_t *arr;
  BLOSC_ERROR(b2nd_from_cbuffer(ctx, &arr, data, size));
  blosc2_schunk *schunk = arr->sc;

  /* Run the test. */
  int result = test_bytedelta(schunk);
  BLOSC_ERROR(b2nd_free_ctx(ctx));
  BLOSC_ERROR(b2nd_free(arr));
  free(data);

  return result;
}

int arange_like() {
  int8_t ndim = 2;
  int typesize = 8;
  int64_t shape[] = {128, 111};
  int32_t chunkshape[] = {48, 32};
  int32_t blockshape[] = {14, 18};
  int64_t nelem = 1;
  for (int i = 0; i < ndim; ++i) {
    nelem *= (int) (shape[i]);
  }
  int64_t size = typesize * nelem;
  double *data = malloc(size);
  for (int64_t i = 0; i < nelem; i++) {
    data[i] = (double) i;
  }

  blosc2_cparams cparams = BLOSC2_CPARAMS_DEFAULTS;
  cparams.typesize = typesize;
  blosc2_storage b2_storage = {.cparams=&cparams};
  b2_storage.contiguous = true;

  b2nd_context_t *ctx = b2nd_create_ctx(&b2_storage, ndim, shape, chunkshape, blockshape, NULL, 0,
                                        NULL, 0);

  b2nd_array_t *arr;
  BLOSC_ERROR(b2nd_from_cbuffer(ctx, &arr, data, size));
  blosc2_schunk *schunk = arr->sc;

  /* Run the test. */
  int result = test_bytedelta(schunk);
  BLOSC_ERROR(b2nd_free_ctx(ctx));
  BLOSC_ERROR(b2nd_free(arr));
  free(data);

  return result;
}


int main(void) {
  int result;
  blosc2_init();

  result = rand_();
  printf("rand: saved %d bytes \n \n", result);
  if (result < 0)
    return result;

  result = mixed_values();
  printf("mixed_values: saved %d bytes \n \n", result);
  if (result < 0)
    return result;

  result = arange_like();
  printf("arange_like: saved %d bytes \n \n", result);
  if (result < 0)
    return result;

  blosc2_destroy();
  return BLOSC2_ERROR_SUCCESS;
}
