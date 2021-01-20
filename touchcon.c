#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/errno.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

// タイムアウト付きコネクト(非同期コネクト)
// https://qiita.com/hidetaka0/items/501ad17b4c23c3adee03
int connect_with_timeout(int socket, struct sockaddr *name, int namelen, struct timeval *timeout)
{
    //接続前に一度非同期に変更
    int flags = fcntl(socket, F_GETFL);
    if(-1 == flags)
    {
      printf("fcntl(socket, F_GETFL)\n");
      return -1;
    }
    int result = fcntl(socket, F_SETFL, flags | O_NONBLOCK);
    if(-1 == result)
    {
      printf("fcntl(socket, F_SETFL, flags | O_NONBLOCK)\n");
      return -1;
    }

    //接続
    result = connect(socket, name, namelen);
    if(-1 == result)
    {
      if (EINPROGRESS == errno)
      {
        //非同期接続成功だとここに入る。select()で完了を待つ。
        errno = 0;
      }
      else
      {
        //接続失敗 同期に戻す。
        fcntl(socket, F_SETFL, flags);
        printf("%d: fcntl(socket, F_SETFL, flags)\n", errno);
        return -1;
      }
    }

    //同期に戻す。
    result = fcntl(socket, F_SETFL, flags );
    if(-1 == result)
    {
        //error
        printf("next: fcntl(socket, F_SETFL, flags )\n");
        return -1;
    }

    //セレクトで待つ
    fd_set readFd, writeFd, errFd;
    FD_ZERO(&readFd);
    FD_ZERO(&writeFd);
    FD_ZERO(&errFd);
    FD_SET(socket, &readFd);
    FD_SET(socket, &writeFd);
    FD_SET(socket, &errFd);
    int sockNum = select(socket + 1, &readFd, &writeFd, &errFd, timeout);
    if(0 == sockNum)
    {
        //timeout error
        printf("timeout\n");
        return -1;
    }
    else if(FD_ISSET(socket, &readFd) || FD_ISSET(socket, &writeFd) )
    {
        //読み書きできる状態
    }
    else
    {
        //error
        printf("an error\n");
        return -1;
    }

    //ソケットエラー確認
    int optval = 0;
    socklen_t optlen = (socklen_t)sizeof(optval);
    errno = 0;
    result = getsockopt(socket, SOL_SOCKET, SO_ERROR, (void *)&optval, &optlen);
    if(result < 0)
    {
        return -1;
    }
    else if(0 != optval)
    {
        return -1;
    }

    return 0;
}

int main(int argc, char *argv[])
{
  char *addr = argv[1];
  char *port = argv[2];
  int count = 0;

  printf("addr: %s, port: %s\n", addr, port);

  int sock;
  sock = socket(AF_INET, SOCK_STREAM, 0);

  struct sockaddr_in server;
  server.sin_family = AF_INET;
  server.sin_port = htons(atoi(port));
  server.sin_addr.s_addr = inet_addr(addr);

  struct timeval timeout;      
  timeout.tv_sec  = 0;
  timeout.tv_usec = 10000;

  while (connect_with_timeout(sock, (struct sockaddr *)&server, sizeof(server), &timeout) < 0)
  {
    sock = socket(AF_INET, SOCK_STREAM, 0);
    timeout.tv_sec = 0;
    timeout.tv_usec = 10000;
    count++;
  }

  printf("timeout count: %d\n", count);

  close(sock);
  return 0;
}
