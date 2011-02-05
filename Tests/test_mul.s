#include "test_macros.h"
	
	.set noreorder

        .text
_start:	
	j start
	nop 
exception:
	j exception
	nop
fail:
	sw $30,-4($0)
	j fail
	nop	
start:        

        #-------------------------------------------------------------
        # Multiplier tests
        #-------------------------------------------------------------
         
	TEST_LO( 102, 0 );
	TEST_LO( 103, 0xFFFFFFFF );
	TEST_LO( 104, 0xAAAA5555 );
	TEST_LO( 105, 0x5555AAAA );
	TEST_HI( 106, 0 );
	TEST_HI( 107, 0xFFFFFFFF );
	TEST_HI( 108, 0xAAAA5555 );
	TEST_HI( 109, 0x5555AAAA );

        TEST_MULDIV( 110, multu, 0, 0, 0, 0 );
        TEST_MULDIV( 111, multu, 2, 3, 6, 0 );
        TEST_MULDIV( 112, multu, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000001, 0xFFFFFFFE );
        TEST_MULDIV( 113, multu, 0x76543210, 0x76543210, 0xA44A4100, 0x36B1B9D7 );
        TEST_MULDIV( 114, multu, 0x80000000, 0x7FFFFFFF, 0x80000000, 0x3FFFFFFF );

        TEST_MULDIV( 120, divu, 14, 3, 4, 2 );
        TEST_MULDIV( 121, divu, 0x8000000, 1, 0x8000000, 0 );
        TEST_MULDIV( 122, divu, 0x7FFFFFF, 0x8000000, 0, 0x7FFFFFF);

        TEST_MULDIV( 150, mult, 0, 0, 0, 0 );
        TEST_MULDIV( 151, mult, 2, 3, 6, 0 );
        TEST_MULDIV( 152, mult, 0xFFFFFFFF, 0xFFFFFFFF, 0x00000001, 0x00000000 );
        TEST_MULDIV( 153, mult, 0x76543210, 0x76543210, 0xA44A4100, 0x36B1B9D7 );
        TEST_MULDIV( 154, mult, 0x80000000, 0x7FFFFFFF, 0x80000000, 0xC0000000 );

	TEST_MULDIV( 170, div, 14, 3, 4, 2 );
	TEST_MULDIV( 171, div, -14, 3, -4, -2 );
	TEST_MULDIV( 172, div, 14, -3, -4, 2 );
	TEST_MULDIV( 173, div, -14, -3, 4, 2 );


done:	ld $30,-4($0)
	addiu $30,$30,1
	sw $30,-4($0)
	j done
	nop
	
	
