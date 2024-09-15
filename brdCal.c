#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int format(char argv[], int order){
char triple [3];
for(int i =0; i<3; i++){
if(argv[i] == '.'){break;}
else{triple[i] = argv[i];}
}
return atoi(triple);}






int main(int argc, char * argv[]){


printf("%s\n%d\n", argv[1] , format(argv[1], 1));



return 0;


}



