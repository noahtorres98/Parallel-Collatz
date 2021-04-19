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

#include <cstdlib>
#include <cstdio>
#include <algorithm>
#include <sys/time.h>
#include <pthread.h>


static long thread_count;
static int global_maxlen;
static long bound;
pthread_mutex_t mutex;

static void* collatz(void* rank)
{
  long my_rank = (long)rank;

  // compute sequence lengths
  int maxlen = 0;
  for (long i = 1 + my_rank; i <= bound; i = i + thread_count) {
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
    maxlen = std::max(maxlen, len);
  }

  pthread_mutex_lock(&mutex);
  global_maxlen = std::max(maxlen, global_maxlen);
  pthread_mutex_unlock(&mutex);

  return NULL;
}

int main(int argc, char *argv[])
{
  printf("Collatz v1.4\n");

  // check command line
  if (argc != 3) {fprintf(stderr, "USAGE: %s upper_bound\n", argv[0]); exit(-1);}
  bound = atol(argv[1]);
  if (bound < 1) {fprintf(stderr, "ERROR: upper_bound must be at least 1\n"); exit(-1);}
  printf("upper bound: %ld\n", bound);

  thread_count = atol(argv[2]);

  if (thread_count < 1){
	 fprintf(stderr, "ERROR: number of threads must be at least 1\n"); exit(-1);
  }
  printf("requested number of threads: %ld\n", thread_count);

  pthread_t* thread_handles = new pthread_t [thread_count - 1];

  pthread_mutex_init(&mutex, 0);

  // start time
  timeval start, end;
  gettimeofday(&start, NULL);

  for (long thread = 0; thread < thread_count - 1; thread++){
  	  pthread_create(&thread_handles[thread], NULL, collatz, (void *)thread);
  }
  collatz((void *)(thread_count - 1));

  // execute timed code

  for (long thread = 0; thread < thread_count - 1; thread++){
	  pthread_join(thread_handles[thread], NULL);
  }

  // end time
  gettimeofday(&end, NULL);
  const double runtime = end.tv_sec - start.tv_sec + (end.tv_usec - start.tv_usec) / 1000000.0;
  printf("compute time: %.6f s\n", runtime);

  pthread_mutex_destroy(&mutex);

  // print result
  printf("longest sequence length: %d elements\n", global_maxlen);
  return 0;
}
