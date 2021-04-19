/*
Collatz code for CS 4380 / CS 5351

Copyright (c) 2020 Texas State University. All rights reserved.

Redistribution in source or binary form, with or without modification,
is *not* permitted. Use in source or binary form, with or without
modification, is only permitted for academic use in CS 4380 or CS 5351
at Texas State University.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Author: Martin Burtscher
*/

#include <cstdio>
#include <algorithm>
#include <sys/time.h>
#include <cuda.h>

static const int ThreadsPerBlock = 1024;

static __global__ void collatz(int *maxlen)
{
	// compute sequence lengths
	const long i = 1 + 2 *(threadIdx.x + blockIdx.x * (long)blockDim.x);
	long val = i;
	int len = 1;
	while (val != 1) {
		len++;
		if ((val % 2) == 0) {
			val /= 2;  // even
		} else {
			val = 3 * val + 1;  // odd
		}
	}

	if (len > *maxlen){
		atomicMax(maxlen, len);
	}
}

static void CheckCuda()
{
  cudaError_t e;
  cudaDeviceSynchronize();
  if (cudaSuccess != (e = cudaGetLastError())) {
    fprintf(stderr, "CUDA error %d: %s\n", e, cudaGetErrorString(e));
    exit(-1);
  }
}

int main(int argc, char *argv[])
{
  printf("Collatz v1.4\n");

  // check command line
  if (argc != 2) {fprintf(stderr, "USAGE: %s upper_bound\n", argv[0]); exit(-1);}
  const long bound = atol(argv[1]);
  if (bound < 1) {fprintf(stderr, "ERROR: upper_bound must be at least 1\n"); exit(-1);}
  printf("upper bound: %ld\n", bound);

  // start time
  timeval start, end;
  gettimeofday(&start, NULL);

  // execute timed code
  int *device_maxlen;
  int host_maxlen;
  int size = sizeof(int);

  if (cudaSuccess != cudaMalloc((void **) &device_maxlen, size)) {fprintf(stderr, "ERROR could not allocate mem 1st\n"); exit(-1);}

  host_maxlen = 0;

  if (cudaSuccess != cudaMemcpy(device_maxlen, &host_maxlen, size, cudaMemcpyHostToDevice)) {fprintf(stderr, "ERROR could not allocate mem 2nd\n"); exit(-1);}

  gettimeofday(&start, NULL);

  collatz<<<((bound + 1)/ 2 + ThreadsPerBlock - 1) / ThreadsPerBlock, ThreadsPerBlock>>>(device_maxlen);
  cudaDeviceSynchronize();

  // end time
  gettimeofday(&end, NULL);
  const double runtime = end.tv_sec - start.tv_sec + (end.tv_usec - start.tv_usec) / 1000000.0;
  printf("compute time: %.6f s\n", runtime);

  CheckCuda();

  if (cudaSuccess != cudaMemcpy(&host_maxlen, device_maxlen, size, cudaMemcpyDeviceToHost)) {fprintf(stderr, "ERROR could not allocate mem 3rd\n"); exit(-1);}

  // print result
  printf("longest sequence length: %d elements\n", host_maxlen);
  return 0;
}
