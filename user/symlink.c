#include "kernel/types.h"
#include "user.h"

int main(int argc, char *argv[]){

    if(argc < 3){
        printf("symlink syntax error");
        exit(-1);
    }

    symlink(argv[1],argv[2]);
    exit(0);
}