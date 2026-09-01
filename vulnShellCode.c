#include <stdio.h>

// declaration of gets to avoid compiler issues
extern char *gets(char *); 

#define BUFSIZE 32

#define FLAG_BUFFER 128

void vuln()
{
    puts("Ingrese un string, y este será impreso de vuelta:");
    char buf[BUFSIZE];
    gets(buf);
    puts(buf);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    vuln();
    return 0;
}
