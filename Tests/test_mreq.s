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

#
# Test sw instruction.
#       

        #-------------------------------------------------------------
        # Basic tests
        #-------------------------------------------------------------

        TEST_ST_OP( 3102, lw, sw, 0x00aa00aa, 0,  tdat31 );
        TEST_ST_OP( 3103, lw, sw, 0xaa00aa00, 4,  tdat31 );
        TEST_ST_OP( 3104, lw, sw, 0x0aa00aa0, 8,  tdat31 );
        TEST_ST_OP( 3105, lw, sw, 0xa00aa00a, 12, tdat31 );

        # Test with negative offset
        
        TEST_ST_OP( 3106, lw, sw, 0x00aa00aa, -12, tdat31_8 );
        TEST_ST_OP( 3107, lw, sw, 0xaa00aa00, -8,  tdat31_8 );
        TEST_ST_OP( 3108, lw, sw, 0x0aa00aa0, -4,  tdat31_8 );
        TEST_ST_OP( 3109, lw, sw, 0xa00aa00a, 0,   tdat31_8 );
       
        # Test with a negative base

        TEST_CASE( 3110, $4, 0x12345678, \
          la $2, tdat31_9; \
          li $3, 0x12345678; \
          addiu $5, $2, -32; \
          sw $3, 32($5); \
          lw $4, 0($2); \
        )

        # Test with unaligned base

        TEST_CASE( 3111, $4, 0x58213098, \
          la $2, tdat31_9; \
          li $3, 0x58213098; \
          addiu $2, $2, -3; \
          sw $3, 7($2); \
          la $5, tdat31_10; \
          lw $4, 0($5); \
        )
                
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_ST_SRC12_BYPASS( 3112, 0, 0, lw, sw, 0xaabbccdd, 0,  tdat31 );
        TEST_ST_SRC12_BYPASS( 3113, 0, 1, lw, sw, 0xdaabbccd, 4,  tdat31 );
        TEST_ST_SRC12_BYPASS( 3114, 0, 2, lw, sw, 0xddaabbcc, 8,  tdat31 );
        TEST_ST_SRC12_BYPASS( 3115, 1, 0, lw, sw, 0xcddaabbc, 12, tdat31 );
        TEST_ST_SRC12_BYPASS( 3116, 1, 1, lw, sw, 0xccddaabb, 16, tdat31 );
        TEST_ST_SRC12_BYPASS( 3117, 2, 0, lw, sw, 0xbccddaab, 20, tdat31 );
        
        TEST_ST_SRC21_BYPASS( 3118, 0, 0, lw, sw, 0x00112233, 0,  tdat31 );
        TEST_ST_SRC21_BYPASS( 3119, 0, 1, lw, sw, 0x30011223, 4,  tdat31 );        
        TEST_ST_SRC21_BYPASS( 3120, 0, 2, lw, sw, 0x33001122, 8,  tdat31 );
        TEST_ST_SRC21_BYPASS( 3121, 1, 0, lw, sw, 0x23300112, 12, tdat31 );
        TEST_ST_SRC21_BYPASS( 3122, 1, 1, lw, sw, 0x22330011, 16, tdat31 );
        TEST_ST_SRC21_BYPASS( 3123, 2, 0, lw, sw, 0x12233001, 20, tdat31 );


        #-------------------------------------------------------------
        # Test data
        #-------------------------------------------------------------

        .data
tdat31:
tdat31_1:  .word 0xdeadbeef
tdat31_2:  .word 0xdeadbeef        
tdat31_3:  .word 0xdeadbeef
tdat31_4:  .word 0xdeadbeef
tdat31_5:  .word 0xdeadbeef
tdat31_6:  .word 0xdeadbeef        
tdat31_7:  .word 0xdeadbeef
tdat31_8:  .word 0xdeadbeef        
tdat31_9:  .word 0xdeadbeef         
tdat31_10: .word 0xdeadbeef
	.text

#
# Test lb/lbu instructions.
#       

        #-------------------------------------------------------------
        # lb Basic tests
        #-------------------------------------------------------------

        TEST_LD_OP( 3402, lb, 0x00000012, 0,  tdat34 );
        TEST_LD_OP( 3403, lb, 0x00000034, 1,  tdat34 );
        TEST_LD_OP( 3404, lb, 0xffffff89, 2,  tdat34 );
        TEST_LD_OP( 3405, lb, 0xffffffAB, 3,  tdat34 );

        # Test with negative offset
        
        TEST_LD_OP( 3406, lb, 0x00000012, -4,  tdat34_4 );
        TEST_LD_OP( 3407, lb, 0x00000034, -3,  tdat34_4 );
        TEST_LD_OP( 3408, lb, 0xffffff89, -2,  tdat34_4 );
        TEST_LD_OP( 3409, lb, 0xffffffAB, -1,  tdat34_4 );
	
        #-------------------------------------------------------------
        # lbu Basic tests
        #-------------------------------------------------------------

        TEST_LD_OP( 3410, lbu, 0x00000012, 0,  tdat34 );
        TEST_LD_OP( 3411, lbu, 0x00000034, 1,  tdat34 );
        TEST_LD_OP( 3412, lbu, 0x00000089, 2,  tdat34 );
        TEST_LD_OP( 3413, lbu, 0x000000AB, 3,  tdat34 );

        # Test with negative offset
        
        TEST_LD_OP( 3414, lbu, 0x00000012, -4,  tdat34_4 );
        TEST_LD_OP( 3415, lbu, 0x00000034, -3,  tdat34_4 );
        TEST_LD_OP( 3416, lbu, 0x00000089, -2,  tdat34_4 );
        TEST_LD_OP( 3417, lbu, 0x000000AB, -1,  tdat34_4 );
	
        #-------------------------------------------------------------
        # Test data
        #-------------------------------------------------------------

        .data
tdat34:		.word 0x123489AB
tdat34_4:	
	.text

#
# Test lh/lhu instructions.
#       

        #-------------------------------------------------------------
        # lh Basic tests
        #-------------------------------------------------------------

        TEST_LD_OP( 3502, lh, 0x00001234, 0,  tdat35 );
        TEST_LD_OP( 3503, lh, 0xffff89AB, 2,  tdat35 );

        # Test with negative offset
        
        TEST_LD_OP( 3504, lh, 0x00001234, -4,  tdat35_4 );
        TEST_LD_OP( 3505, lh, 0xffff89AB, -2,  tdat35_4 );
	
        #-------------------------------------------------------------
        # lh Basic tests
        #-------------------------------------------------------------

        TEST_LD_OP( 3506, lhu, 0x00001234, 0,  tdat35 );
        TEST_LD_OP( 3507, lhu, 0x000089AB, 2,  tdat35 );

        # Test with negative offset
        
        TEST_LD_OP( 3508, lhu, 0x00001234, -4,  tdat35_4 );
        TEST_LD_OP( 3509, lhu, 0x000089AB, -2,  tdat35_4 );
	
        #-------------------------------------------------------------
        # Test data
        #-------------------------------------------------------------

        .data
tdat35:		.word 0x123489AB
tdat35_4:	
	.text
		

#
# Test sb/sh instructions
#       

        #-------------------------------------------------------------
        # Basic tests
        #-------------------------------------------------------------

	la $2,tdat36
	sw $0,0($2)
        TEST_STBH_OP( 3602, sb, 0x56, 0x56000000,  0, tdat36 );
        TEST_STBH_OP( 3603, sb, 0x78, 0x56007800,  2, tdat36 );
        TEST_STBH_OP( 3604, sb, 0xCD, 0x56CD7800,  1, tdat36 );
        TEST_STBH_OP( 3605, sb, 0xEF, 0x56CD78EF,  3, tdat36 );
	
	la $2,tdat36
	sw $0,0($2)
        TEST_STBH_OP( 3606, sh, 0x5678, 0x00005678,  2, tdat36 );
        TEST_STBH_OP( 3607, sh, 0xCDEF, 0xCDEF5678,  0, tdat36 );
	
        #-------------------------------------------------------------
        # Test data
        #-------------------------------------------------------------

        .data
tdat36:		.word 0
	.text
		

done:	ld $30,-4($0)
	addiu $30,$30,1
	sw $30,-4($0)
	j done
	nop
	
	
