#include <stdio.h>
#include <stdlib.h>
#include <string.h>




int format(char argv[], int order){
int pos[5];
pos[0]=0;

int slot=1;
char triple [3];



for(int i=0; i<strlen(argv);i++){
if(argv[i]=='.'){pos[slot]=i;slot = slot+1;
	//printf("%d\n", i);
}

else{}
}
pos[4]=strlen(argv);

//printf("%d%d%d\n", pos[0],pos[1],pos[2]);

for(int i =pos[order-1]; i<pos[order]; i++){


if(argv[i] == '.'){break;}
else{triple[i] = argv[i];}
}
return atoi(triple);}










int main(int argc, char * argv[]){

printf("%d\n", format(argv[1],1));
printf("%d\n", format(argv[1],32));
printf("%d\n", format(argv[1],3));
printf("%d\n", format(argv[1],4));

return 0;
}
