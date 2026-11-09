#include "pragya_test.h"

volatile int result;

int main(void)
{
    asm volatile(

    /* Initialize registers */
    "li x5,5\n"
    "li x6,6\n"
    "li x7,7\n"
    "li x8,8\n"
    "li x9,9\n"
    "li x10,10\n"
    "li x11,11\n"
    "li x12,12\n"
    "li x13,13\n"
    "li x14,14\n"
    "li x15,15\n"
    "li x16,16\n"
    "li x17,17\n"
    "li x18,18\n"
    "li x19,19\n"
    "li x20,20\n"
    "li x21,21\n"
    "li x22,22\n"
    "li x23,23\n"
    "li x24,24\n"
    "li x25,25\n"
    "li x26,26\n"
    "li x27,27\n"
    "li x28,28\n"
    "li x29,29\n"
    "li x30,30\n"
    "li x31,31\n"

    /* ADD */
    "add x5,x6,x7\n"
    "add x6,x7,x8\n"
    "add x7,x8,x9\n"
    "add x8,x9,x10\n"
    "add x9,x10,x11\n"
    "add x10,x11,x12\n"
    "add x11,x12,x13\n"
    "add x12,x13,x14\n"
    "add x13,x14,x15\n"
    "add x14,x15,x16\n"
    "add x15,x16,x17\n"
    "add x16,x17,x18\n"
    "add x17,x18,x19\n"
    "add x18,x19,x20\n"
    "add x19,x20,x21\n"
    "add x20,x21,x22\n"
    "add x21,x22,x23\n"
    "add x22,x23,x24\n"
    "add x23,x24,x25\n"
    "add x24,x25,x26\n"
    "add x25,x26,x27\n"
    "add x26,x27,x28\n"
    "add x27,x28,x29\n"
    "add x28,x29,x30\n"
    "add x29,x30,x31\n"

    /* SUB */
    "sub x30,x31,x29\n"
    "sub x29,x30,x28\n"
    "sub x28,x29,x27\n"
    "sub x27,x28,x26\n"
    "sub x26,x27,x25\n"

    /* XOR */
    "xor x25,x26,x24\n"
    "xor x24,x25,x23\n"
    "xor x23,x24,x22\n"
    "xor x22,x23,x21\n"

    /* OR */
    "or x21,x22,x20\n"
    "or x20,x21,x19\n"
    "or x19,x20,x18\n"

    /* AND */
    "and x18,x19,x17\n"
    "and x17,x18,x16\n"

    /* SLL */
    "sll x16,x17,x5\n"

    /* SRL */
    "srl x15,x16,x6\n"

    /* SRA */
    "sra x14,x15,x7\n"

    /* SLT */
    "slt x13,x14,x8\n"

    /* SLTU */
    "sltu x12,x13,x9\n"

    /* Immediate instructions */
    "addi x11,x11,5\n"
    "xori x10,x10,0x55\n"
    "ori  x9,x9,0xaa\n"
    "andi x8,x8,0x0f\n"
    "slti x7,x7,20\n"
    "sltiu x6,x6,30\n"
    "slli x5,x5,1\n"
    "srli x31,x31,1\n"
    "srai x30,x30,1\n"

    :
    :
    : "memory"
    );

    result = 1;

    if(result != 1)
        test_fail();

    test_pass();

    return 0;
}
