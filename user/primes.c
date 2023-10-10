#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int primes(int *oldFd) {
    // 关闭原管道写端
    close(oldFd[1]);
    int fd[2];
    int basis_prime;
    int num;
    // 若能从原管道读到数据
    if (read(oldFd[0], &basis_prime, 4)) {
        // 第一个数据为质数,进行输出
        printf("prime %d\n", basis_prime);
        // 创建管道和子进程
        pipe(fd);
        if (fork() == 0) {    //子进程
            // 递归调用
            primes(fd);
        } else {    // 父进程
            // 关闭新管道读端
            close(fd[0]);
            // 从原管道进行读取
            while (read(oldFd[0], &num, 4)) {
                // 不能被记录的质数整除则写入新管道
                if (num % basis_prime != 0) {
                    write(fd[1], &num, 4);
                }
            }
            // 此时父进程的原管道关闭, 则关闭原管道的读端
            close(oldFd[0]);
            // 关闭新管道的写端
            close(fd[1]);
            // 等待子进程结束
            wait((int *) 0);
        }
    } else {    // 此时说明原管道已关闭,第一个数字都读不出
        // 不创建子进程直接关闭原管道读端
        close(oldFd[0]);
    }
    exit(0);
}

int main() {
    int i;
    int fd[2];
    pipe(fd);
    if (fork() == 0) {
        primes(fd);
    } else {    // 父进程
        close(fd[0]);
        // 遍历 2~35 写入管道写端
        for (i = 2; i <= 35; ++i) {
            write(fd[1], &i, 4);
        }
        // 写完关闭管道写端并等待子进程结束
        close(fd[1]);
        wait((int *) 0);
    }
    exit(0);
}
