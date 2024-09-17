#include <stdio.h>
#include <stdlib.h>
#include <string.h>


int power(int number, int exponent){
if(exponent==0){number=1;}         
else{
int base = number; 
for(int i=1; i<exponent;i++){
number=number*base;}}
return number;}




int format(char argv[], int order){
int pos[5];
pos[0]=-1;
int slot=1;
char triple [4];
for(int i=0;i<=3;i++){triple[i]=' ';}
for(int i=0; i<strlen(argv);i++){
if(argv[i]=='.'){pos[slot]=i;slot = slot+1;}}
pos[4]=strlen(argv);
//printf("%d%d%d%d%d\n", pos[0],pos[1],pos[2],pos[3],pos[4]);
for(int i =pos[order-1]+1; i<pos[order]; i++){
triple[i%4]=argv[i];}
return atoi(triple);}



int tobin(int data){
char data_bin[8];
for(int i=7;i>=0;i--){
if(data<power(2,i)){data_bin[7-i]='0';}
else{data_bin[7-i]='1';data=data-power(2,i);}}
return atoi(data_bin);}





int main(int argc, char * argv[]){
printf("%d %d %d %d\n", format(argv[1],1),format(argv[1],2),format(argv[1],3),format(argv[1],4));
int binary1 = format(argv[1],1);
int binary2 = format(argv[1],2);
int binary3 = format(argv[1],3);
int binary4 = format(argv[1],4);
printf("%d %d %d %d\n", tobin(binary1),tobin(binary2),tobin(binary3),tobin(binary4));
return 0;


}
