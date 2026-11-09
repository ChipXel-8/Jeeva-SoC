#include "pragya_test.h"
#include <stdint.h>

volatile uint32_t mem[256];

volatile uint32_t a;
volatile uint32_t b;
volatile uint32_t c;
volatile uint32_t d;
volatile uint32_t sum;


/*========================================================
  1. Sequential PC progression
  Covers:
      pc_out normal PC changes
      pc_plus_4_pipline1_out changes
      id_valid = 1
========================================================*/

static void test_sequential_execution(void)
{
    for (int i = 0; i < 100; i++)
    {
        a = i;
        b = a + 1;
        c = b + 2;
        d = c + 3;

        if (d != (i + 6))
            test_fail();
    }
}


/*========================================================
  2. Taken branches
  Forces PC to change to branch targets.

  Covers:
      branch_taken
      PC target selection
      IF/ID flush
      id_valid changes
========================================================*/

static void test_taken_branches(void)
{
    sum = 0;

    for (int i = 0; i < 100; i++)
    {
        if (i < 50)
        {
            sum += i;
        }
        else
        {
            sum -= i;
        }
    }

    if (sum != -2500)
        test_fail();
}


/*========================================================
  3. Alternating branch direction
========================================================*/

static void test_alternating_branches(void)
{
    sum = 0;

    for (int i = 0; i < 100; i++)
    {
        if (i & 1)
            sum += 10;
        else
            sum -= 5;
    }

    if (sum != 250)
        test_fail();
}


/*========================================================
  4. Nested branches
========================================================*/

static void test_nested_branches(void)
{
    sum = 0;

    for (int i = 0; i < 20; i++)
    {
        for (int j = 0; j < 20; j++)
        {
            if (i > j)
                sum += 1;
            else if (i < j)
                sum += 2;
            else
                sum += 3;
        }
    }

    if (sum != 630)
        test_fail();
}


/*========================================================
  5. Function calls

  Generates JAL/JALR activity and larger PC movement.
========================================================*/

static uint32_t function_a(uint32_t x)
{
    return x + 10;
}

static uint32_t function_b(uint32_t x)
{
    return x * 2;
}

static uint32_t function_c(uint32_t x)
{
    return x ^ 0x55;
}


static void test_function_calls(void)
{
    uint32_t x = 1;

    for (int i = 0; i < 50; i++)
    {
        x = function_a(x);
        x = function_b(x);
        x = function_c(x);
    }

    if (x == 0)
        test_fail();
}


/*========================================================
  6. Loop back edges

  Very important for PC transitions.
========================================================*/

static void test_loop_back_edges(void)
{
    sum = 0;

    for (int i = 0; i < 200; i++)
    {
        sum += i;

        if (sum & 1)
            sum += 1;
        else
            sum += 2;
    }

    if (sum == 0)
        test_fail();
}


/*========================================================
  7. Load -> use dependencies

  Exercises IF/ID continuously while pipeline stalls.
========================================================*/

static void test_load_use(void)
{
    for (int i = 0; i < 100; i++)
        mem[i] = i + 1000;

    for (int i = 0; i < 100; i++)
    {
        a = mem[i];
        b = a + 1;
        c = b + 1;
        d = c + 1;

        if (d != (i + 1003))
            test_fail();
    }
}


/*========================================================
  8. Store -> load

  Exercises memory operations and pipeline activity.
========================================================*/

static void test_store_load(void)
{
    for (int i = 0; i < 100; i++)
    {
        mem[i] = i * 7;
        a = mem[i];

        if (a != (uint32_t)(i * 7))
            test_fail();
    }
}


/*========================================================
  9. Long straight-line code

  Keeps IF/ID continuously accepting instructions.
========================================================*/

static void test_long_sequence(void)
{
    a = 1;

    for (int i = 0; i < 500; i++)
    {
        a = a + 1;
        b = a + 2;
        c = b + 3;
        d = c + 4;
        a = d - 2;
    }

    if (a == 0)
        test_fail();
}


/*========================================================
  10. Conditional execution with many PC paths
========================================================*/

static void test_many_paths(void)
{
    sum = 0;

    for (int i = 0; i < 200; i++)
    {
        if ((i % 7) == 0)
            sum += 7;

        else if ((i % 5) == 0)
            sum += 5;

        else if ((i % 3) == 0)
            sum += 3;

        else if ((i & 1) == 0)
            sum += 2;

        else
            sum -= 1;
    }

    if (sum == 0)
        test_fail();
}


/*========================================================
  11. Multiple nested function calls
========================================================*/

static uint32_t calc1(uint32_t x)
{
    if (x & 1)
        return x + 3;
    else
        return x + 7;
}

static uint32_t calc2(uint32_t x)
{
    if (x & 2)
        return x << 1;
    else
        return x >> 1;
}

static uint32_t calc3(uint32_t x)
{
    if (x > 100)
        return x - 20;
    else
        return x + 20;
}


static void test_function_paths(void)
{
    uint32_t x = 1;

    for (int i = 0; i < 100; i++)
    {
        x = calc1(x);
        x = calc2(x);
        x = calc3(x);
    }

    if (x == 0)
        test_fail();
}


/*========================================================
  12. Main
========================================================*/

int main(void)
{
    test_sequential_execution();

    test_taken_branches();

    test_alternating_branches();

    test_nested_branches();

    test_function_calls();

    test_loop_back_edges();

    test_load_use();

    test_store_load();

    test_long_sequence();

    test_many_paths();

    test_function_paths();

    test_pass();

    return 0;
}