#include <stdio.h>
#include <stdlib.h>
#include <string.h>

 //////////POWER FUNCTION////////////////
////////////////////////////////////////
int power(int number, int exponent){
if(exponent==0){number=1;}         
else{
int base = number; 
for(int i=1; i<exponent;i++){
number=number*base;}}
return number;}
////////////////////////////////////////

 ////////////////////>>FORMATING TO DECIMAL OCTETS<<//////////////////////
/////////////////////////////////////////////////////////////////////////
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
/////////////////////////////////////////////////////////////////////////


 ////////////////>>CONVERT TO BINARY<<////////////////
/////////////////////////////////////////////////////
int tobin(int data){
char data_bin[8];
for(int i=7;i>=0;i--){
if(data<power(2,i)){data_bin[7-i]='0';}
else{data_bin[7-i]='1';data=data-power(2,i);}}
return atoi(data_bin);}    //return atoi(data_bin);
//////////////////////////////////////////////////////


 ////////////////////////CONVERT TO DECIMAL//////////////////////////////
////////////////////////////////////////////////////////////////////////
int todec(int data_bin){
int count=0;
int n = data_bin;
while(n != 0){
n=n/10;
count++;
}
char binary_text[count];
sprintf(binary_text, "%d", data_bin);
for(int i=0;i<count;i++){binary_text[i]=binary_text[i]-48;
if(binary_text[i]!=1){
binary_text[i] = 0;}
//printf("%d\n", binary_text[i]);
}
int data_dec=0;
//printf("Length of the number: %d\n", count);
for(int i=0;i<count;i++){
//printf("Data for i=%d : %d\n", i, power(2,count-i-1)*binary_text[i]);
data_dec+=power(2,count-1-i)*binary_text[i];
}
return data_dec;}
/////////////////////////////////////////////////////////////////////////

 /////////////////////////BROADCAST OCTETS////////////////////////////////
/////////////////////////////////////////////////////////////////////////
int broadcast(int ip, int mask){
int broadcast_value=0;
int freeBit=8;

if(mask != 0){
int compare=0;
for(int i=0;i<8;i++){
compare = 0;
for(int j=i;j>=0;j--){
compare+=power(10,j);
//printf("%d   %d\n",j, compare);
if(mask == compare){freeBit=j;
	break;}
}
}}
//printf("number of free bits: %d\n",freeBit);

broadcast_value=ip/power(10,freeBit);
//printf("frozen bits: %d\n", broadcast_value);
broadcast_value*=power(10,freeBit);
//printf("cleared octet: %d\n", broadcast_value);
for(int i=0;i<freeBit;i++){
////////////////
//HERE DODELAT//
////////////////
broadcast_value+=power(10,i);
//printf("Broadcast Value: %d\n", broadcast_value);
}

return broadcast_value;}
/////////////////////////////////////////////////////////////////////////





int main(int argc, char * argv[]){

int binaryIP1 = tobin(format(argv[1],1));
int binaryIP2 = tobin(format(argv[1],2));
int binaryIP3 = tobin(format(argv[1],3));
int binaryIP4 = tobin(format(argv[1],4));
int binaryMASK1 = tobin(format(argv[2],1));
int binaryMASK2 = tobin(format(argv[2],2));
int binaryMASK3 = tobin(format(argv[2],3));
int binaryMASK4 = tobin(format(argv[2],4));



//broadcast(10101010,11111111);
//broadcast(1,11111111);
//broadcast(11000111,11110000);







//printf("Binary IP: %d\t%d\t%d\t%d\n",binaryIP1, binaryIP2, binaryIP3, binaryIP4);
//printf("Binary MASK: %d\t%d\t%d\t%d\n",binaryMASK1,binaryMASK2,binaryMASK3,binaryMASK4);
//printf("%d %d %d %d\n", sizeof(binaryBC1)/sizeof(binaryBC1[0]),sizeof(binaryBC2)/sizeof(binaryBC2[0]),sizeof(binaryBC3)/sizeof(binaryBC3[0]),sizeof(binaryBC4)/sizeof(binaryBC4[0]))
//printf("Binary BC: %d\t%d\t%d\t%d\n", broadcast(binaryIP1,binaryMASK1),broadcast(binaryIP2,binaryMASK2),broadcast(binaryIP3,binaryMASK3),broadcast(binaryIP4,binaryMASK4));
int BC1=broadcast(binaryIP1,binaryMASK1);
int BC2=broadcast(binaryIP2,binaryMASK2);
int BC3=broadcast(binaryIP3,binaryMASK3);
int BC4=broadcast(binaryIP4,binaryMASK4);


printf("%d.%d.%d.%d\n",todec(BC1),todec(BC2),todec(BC3),todec(BC4));

return 0;


}
