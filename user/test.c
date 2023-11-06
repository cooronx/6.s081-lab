#include "kernel/types.h"
#include "user/user.h"

int main(void){

    char c;
    int pid = fork();
    if(pid == 0){
        c = '/';
    }
    else{
        printf("parent pid = %d, child pid = %d \n",getpid(),pid);
        c = '\\';
    }


    for(int i = 0;i<10000;++i){
        write(2,&c,1);
    }
    exit(0);
}