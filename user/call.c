#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int g(int x) {
  return x+3;
}

int f(int x) {
  int temp = x;
  int cnt = 0;
  while(temp){
    temp /= 10;
    ++cnt;
  }
  return cnt;
}

void main(void) {
  printf("%d helasdaslo %d\n", f(8)+1, 13);
  exit(0);
}
