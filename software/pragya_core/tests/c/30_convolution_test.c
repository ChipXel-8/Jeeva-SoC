#include "pragya_test.h"

int img[8][8];
int out[6][6];

int kernel[3][3] =
{
    {1,2,1},
    {2,4,2},
    {1,2,1}
};

int main(void)
{
    int i, j, x, y;

    /* Initialize input image */
    for(i = 0; i < 8; i++)
    {
        for(j = 0; j < 8; j++)
        {
            img[i][j] = i + j;
        }
    }

    /* Perform 3x3 convolution */
    for(i = 0; i < 6; i++)
    {
        for(j = 0; j < 6; j++)
        {
            int sum = 0;

            for(x = 0; x < 3; x++)
            {
                for(y = 0; y < 3; y++)
                {
                    sum += img[i+x][j+y] * kernel[x][y];
                }
            }

            out[i][j] = sum;
        }
    }

    /* Verify a few known outputs */
    if(out[0][0] != 32)
        test_fail();

    if(out[0][1] != 48)
        test_fail();

    if(out[1][0] != 48)
        test_fail();

    if(out[5][5] != 192)
        test_fail();

    /* Test passed */
    test_pass();

    return 0;
}