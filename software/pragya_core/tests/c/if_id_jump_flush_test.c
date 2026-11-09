#include "pragya_test.h"
#include <stdint.h>

volatile int signature[32];

int main(void)
{
    /*------------------------------------------
      Initialize
    ------------------------------------------*/

    for(int k=0;k<32;k++)
        signature[k]=0;

    /*------------------------------------------
      Forward Control Flow
    ------------------------------------------*/

    goto label1;

    signature[0]=0xAAAAAAAA;
    signature[1]=0xBBBBBBBB;

label1:

    signature[2]=0x11111111;

    /*------------------------------------------
      Second Jump
    ------------------------------------------*/

    goto label2;

    signature[3]=0xCCCCCCCC;
    signature[4]=0xDDDDDDDD;

label2:

    signature[5]=0x22222222;

    /*------------------------------------------
      Conditional Control Flow
    ------------------------------------------*/

    for(int k=0;k<20;k++)
    {
        if(k==10)
            goto label3;

        signature[6]=k;
    }

label3:

    signature[7]=0x33333333;

    /*------------------------------------------
      Multiple Jumps
    ------------------------------------------*/

    goto label4;

    signature[8]=0xAAAAAAAA;

label4:

    goto label5;

    signature[9]=0xBBBBBBBB;

label5:

    signature[10]=0x44444444;

    /*------------------------------------------
      Verify Jump Targets
    ------------------------------------------*/

    if(signature[2]!=0x11111111)
        test_fail();

    if(signature[5]!=0x22222222)
        test_fail();

    if(signature[7]!=0x33333333)
        test_fail();

    if(signature[10]!=0x44444444)
        test_fail();

    test_pass();

    return 0;
}