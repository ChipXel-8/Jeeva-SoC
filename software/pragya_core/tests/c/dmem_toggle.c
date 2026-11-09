#include "pragya_test.h"
#include <stdint.h>

/* ============================================================
   Memory declarations
   ============================================================ */

volatile uint32_t mem[128];

volatile uint8_t  byte_mem[64];
volatile uint16_t half_mem[32];

volatile int a, b, c, d, e, f;
volatile int sum;


/* ============================================================
   MAIN
   ============================================================ */

int main(void)
{

    /* ========================================================
       1. INITIALIZE WORD MEMORY
       ======================================================== */

    for(int k = 0; k < 128; k++)
        mem[k] = k;


    /* ========================================================
       2. BASIC WORD STORE -> LOAD
       Covers normal word accesses
       ======================================================== */

    for(int k = 0; k < 32; k++)
    {
        mem[k] = 0x1000 + k;

        a = mem[k];

        if(a != (0x1000 + k))
            test_fail();
    }


    /* ========================================================
       3. BYTE STORE / LOAD
       
       IMPORTANT:
       Accesses offsets:
       
           +0 -> mem_addr[1:0] = 00
           +1 -> mem_addr[1:0] = 01
           +2 -> mem_addr[1:0] = 10
           +3 -> mem_addr[1:0] = 11
       
       This is the important section for your missing
       mem_addr[0] and mem_addr[1] toggle coverage.
       ======================================================== */

    volatile uint8_t *byte_ptr =
        (volatile uint8_t *)mem;

    byte_ptr[0] = 0x11;
    byte_ptr[1] = 0x22;
    byte_ptr[2] = 0x33;
    byte_ptr[3] = 0x44;

    if(byte_ptr[0] != 0x11)
        test_fail();

    if(byte_ptr[1] != 0x22)
        test_fail();

    if(byte_ptr[2] != 0x33)
        test_fail();

    if(byte_ptr[3] != 0x44)
        test_fail();


    /* ========================================================
       4. BYTE ACCESS AT MULTIPLE WORD LOCATIONS
       ======================================================== */

    for(int k = 0; k < 16; k++)
    {
        byte_ptr[(k * 4) + 0] = 0x10 + k;
        byte_ptr[(k * 4) + 1] = 0x20 + k;
        byte_ptr[(k * 4) + 2] = 0x30 + k;
        byte_ptr[(k * 4) + 3] = 0x40 + k;

        if(byte_ptr[(k * 4) + 0] != (0x10 + k))
            test_fail();

        if(byte_ptr[(k * 4) + 1] != (0x20 + k))
            test_fail();

        if(byte_ptr[(k * 4) + 2] != (0x30 + k))
            test_fail();

        if(byte_ptr[(k * 4) + 3] != (0x40 + k))
            test_fail();
    }


    /* ========================================================
       5. HALF-WORD STORE / LOAD
       
       Aligned half-word accesses:
       
           offset +0 -> address bit[1:0] = 00
           offset +2 -> address bit[1:0] = 10
       
       This exercises LH/LHU and SH.
       ======================================================== */

    volatile uint16_t *half_ptr =
        (volatile uint16_t *)mem;

    half_ptr[0] = 0x1234;
    half_ptr[1] = 0x5678;
    half_ptr[2] = 0xABCD;
    half_ptr[3] = 0xEF01;

    if(half_ptr[0] != 0x1234)
        test_fail();

    if(half_ptr[1] != 0x5678)
        test_fail();

    if(half_ptr[2] != 0xABCD)
        test_fail();

    if(half_ptr[3] != 0xEF01)
        test_fail();


    /* ========================================================
       6. BYTE ENABLE TEST
       
       Write different bytes into the same word.
       This should exercise all four byte enables:
       
           0001
           0010
           0100
           1000
       ======================================================== */

    byte_ptr[16] = 0xAA;
    byte_ptr[17] = 0xBB;
    byte_ptr[18] = 0xCC;
    byte_ptr[19] = 0xDD;

    if(byte_ptr[16] != 0xAA)
        test_fail();

    if(byte_ptr[17] != 0xBB)
        test_fail();

    if(byte_ptr[18] != 0xCC)
        test_fail();

    if(byte_ptr[19] != 0xDD)
        test_fail();


    /* ========================================================
       7. SIGNED / UNSIGNED BYTE LOADS
       ======================================================== */

    byte_ptr[24] = 0x80;
    byte_ptr[25] = 0xFF;
    byte_ptr[26] = 0x7F;
    byte_ptr[27] = 0x01;

    volatile int8_t *signed_byte_ptr =
        (volatile int8_t *)mem;

    if(signed_byte_ptr[24] != -128)
        test_fail();

    if(signed_byte_ptr[25] != -1)
        test_fail();

    if(signed_byte_ptr[26] != 127)
        test_fail();

    if(signed_byte_ptr[27] != 1)
        test_fail();


    /* ========================================================
       8. LOAD-USE HAZARD
       ======================================================== */

    for(int k = 0; k < 20; k++)
    {
        mem[k] = k;

        a = mem[k];
        b = a + 1;
        c = b + 2;
        d = c + 3;

        if(d != (k + 6))
            test_fail();
    }


    /* ========================================================
       9. STORE -> LOAD HAZARD
       ======================================================== */

    for(int k = 0; k < 20; k++)
    {
        mem[k] = k * 10;

        a = mem[k];

        if(a != (k * 10))
            test_fail();
    }


    /* ========================================================
       10. RAW DEPENDENCY CHAIN
       ======================================================== */

    a = 1;

    for(int k = 0; k < 50; k++)
    {
        b = a + k;
        c = b + 1;
        d = c + 2;
        e = d + 3;
        f = e + 4;

        a = f;
    }

    if(a == 0)
        test_fail();


    /* ========================================================
       11. TAKEN / NOT-TAKEN BRANCHES
       ======================================================== */

    sum = 0;

    for(int k = 0; k < 50; k++)
    {
        if(k < 25)
            sum += k;
        else
            sum -= k;
    }

    if(sum != -625)
        test_fail();


    /* ========================================================
       12. ALTERNATING BRANCHES
       ======================================================== */

    sum = 0;

    for(int k = 0; k < 40; k++)
    {
        if(k & 1)
            sum += 3;
        else
            sum -= 2;
    }

    if(sum != 20)
        test_fail();


    /* ========================================================
       13. NESTED BRANCHES
       ======================================================== */

    sum = 0;

    for(int x = 0; x < 8; x++)
    {
        for(int y = 0; y < 8; y++)
        {
            if(x > y)
                sum++;

            else if(x < y)
                sum += 2;

            else
                sum += 3;
        }
    }

    if(sum != 92)
        test_fail();


    /* ========================================================
       14. CONTINUOUS MEMORY HAZARDS
       ======================================================== */

    for(int k = 0; k < 32; k++)
    {
        mem[k] = k + 100;

        a = mem[k];
        b = a + 1;

        mem[k + 32] = b;

        c = mem[k + 32];

        if(c != (k + 101))
            test_fail();
    }


    /* ========================================================
       15. FORWARDING + STALL MIX
       ======================================================== */

    a = 5;

    for(int k = 0; k < 60; k++)
    {
        a = a + 1;
        b = a + 2;
        c = b + 3;
        d = c + 4;

        mem[k] = d;

        e = mem[k];

        a = e;
    }

    if(a == 0)
        test_fail();


    /* ========================================================
       16. ALU PIPELINE STRESS
       ======================================================== */

    a = 1;

    for(int k = 0; k < 100; k++)
    {
        a = a + k;
        a = a ^ k;
        a = a + 3;
        a = a - 2;
        a = a << 1;
        a = a >> 1;
    }

    if(a == 0)
        test_fail();


    /* ========================================================
       17. MEMORY BURST
       ======================================================== */

    for(int k = 0; k < 64; k++)
        mem[k] = k * 5;

    for(int k = 0; k < 64; k++)
    {
        if(mem[k] != (k * 5))
            test_fail();
    }


    /* ========================================================
       18. BYTE ADDRESS PATTERN
       
       Explicitly repeat 00/01/10/11 address pattern.
       ======================================================== */

    for(int k = 0; k < 32; k++)
    {
        byte_ptr[(k * 4) + 0] = 0x55;
        byte_ptr[(k * 4) + 1] = 0xAA;
        byte_ptr[(k * 4) + 2] = 0x33;
        byte_ptr[(k * 4) + 3] = 0xCC;

        a = byte_ptr[(k * 4) + 0];
        b = byte_ptr[(k * 4) + 1];
        c = byte_ptr[(k * 4) + 2];
        d = byte_ptr[(k * 4) + 3];

        if(a != 0x55)
            test_fail();

        if(b != 0xAA)
            test_fail();

        if(c != 0x33)
            test_fail();

        if(d != 0xCC)
            test_fail();
    }


    /* ========================================================
       TEST PASS
       ======================================================== */

    test_pass();

    return 0;
}