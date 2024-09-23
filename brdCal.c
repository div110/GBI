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



int todec(int data_bin){
char binary_text[8];
sprintf(binary_text, "%d", data_bin);
for(int i=0;i<8;i++){binary_text[i]=binary_text[i]-48;
if(!binary_text[i]){
binary_text[i] = 0;}
printf("%d\n", binary_text[i]);}
int data_dec=0;
int length =      sizeof(binary_text)/sizeof(binary_text[0])-1;
printf("Length of the number: %ld\n", sizeof(binary_text)/sizeof(binary_text[0]));
for(int i=0;i<=length;i++){
//printf("Data for i=%d : %d\n", i, data_dec);
data_dec+=power(2,length-i)*binary_text[i];
}
return data_dec;}








int main(int argc, char * argv[]){

int binaryIP1 = tobin(format(argv[1],1));
int binaryIP2 = tobin(format(argv[1],2));
int binaryIP3 = tobin(format(argv[1],3));
int binaryIP4 = tobin(format(argv[1],4));
int binaryMASK1 = tobin(format(argv[2],1));
int binaryMASK2 = tobin(format(argv[2],2));
int binaryMASK3 = tobin(format(argv[2],3));
int binaryMASK4 = tobin(format(argv[2],4));
//printf("%d\t%d\t%d\t%d\n",binaryIP1, binaryIP2, binaryIP3, binaryIP4);
//printf("%d\t%d\t%d\t%d\n",binaryMASK1,binaryMASK2,binaryMASK3,binaryMASK4); 
printf("%d\n",todec(10101000));


return 0;


}
