#include "kernel/types.h"
#include "user/user.h"

int main(int args,char *argv[]){
    if(args != 2){
        fprintf(2,"wrong use of sleep\n");
        exit(0);
    }

    //get the second int
    int ticks = atoi(argv[1]);
    int state = sleep(ticks);
    exit(state);
}