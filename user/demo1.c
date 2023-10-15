#include "kernel/types.h"
#include "user/user.h"

int check(int mid){
    if(mid == 1)return 0;
    if(mid == 2)return 1;
    for(int i = 2;i*i <= mid;++i){
        if(mid % i == 0){
            return 0;
        }
    } 
    return 1;
}


int main(){

    printf("%d\n",check(5));

    demo();
    exit(0);
}