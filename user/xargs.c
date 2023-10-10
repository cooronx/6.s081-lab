#include <kernel/types.h>
#include <user/user.h>

#define stdin 0
#define stdout 1
#define stderr 2

int main(int args_size,char *argv[]){
    
    if(args_size < 2){
        fprintf(2,"error use of xargs\n");
        exit(1);
    }

    int index = 0;
    int n;
    int pid;
    char c;
    char temp_arg[512];
    char *xargs[32];

    for(int i = 1;i<args_size;++i){
        xargs[i-1] = argv[i];
    }


    while( (n = read(stdin,&c,1)) > 0){
        if(c == '\n'){
            temp_arg[index] = 0;

            if((pid = fork()) < 0){
                fprintf(2,"create child process wrong\n");
                exit(1);
            }

            //child process
            if(pid == 0){
                xargs[args_size-1] = temp_arg;
                xargs[args_size] = 0;
                exec(xargs[0],xargs);
            }
            //parent process
            else{
                wait(0);
                index = 0;
            }
        }
        else{
            temp_arg[index++] = c;
        }
    }


    exit(0);
}