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
# Test addiu instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------
         
        TEST_IMM_OP( 102,  addiu, 0x00000000, 0x00000000, 0x0000 );
        TEST_IMM_OP( 103,  addiu, 0x00000002, 0x00000001, 0x0001 );
        TEST_IMM_OP( 104,  addiu, 0x0000000a, 0x00000003, 0x0007 );
                                                                              
        TEST_IMM_OP( 105,  addiu, 0xffff8000, 0x00000000, 0x8000 );
        TEST_IMM_OP( 106,  addiu, 0x80000000, 0x80000000, 0x0000 );
        TEST_IMM_OP( 107,  addiu, 0x7fff8000, 0x80000000, 0x8000 );
        
        TEST_IMM_OP( 108,  addiu, 0x00007fff, 0x00000000, 0x7fff );
        TEST_IMM_OP( 109,  addiu, 0x7fffffff, 0x7fffffff, 0x0000 );
        TEST_IMM_OP( 110, addiu, 0x80007ffe, 0x7fffffff, 0x7fff );
                                                                                      
        TEST_IMM_OP( 111, addiu, 0x80007fff, 0x80000000, 0x7fff );
        TEST_IMM_OP( 112, addiu, 0x7fff7fff, 0x7fffffff, 0x8000 );
        
        TEST_IMM_OP( 113, addiu, 0xffffffff, 0x00000000, 0xffff );
        TEST_IMM_OP( 114, addiu, 0x00000000, 0xffffffff, 0x0001 );
        TEST_IMM_OP( 115, addiu, 0xfffffffe, 0xffffffff, 0xffff );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_IMM_SRC1_EQ_DEST( 116, addiu, 24, 13, 11 );
                        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_IMM_DEST_BYPASS( 117, 0, addiu, 24, 13, 11 );
        TEST_IMM_DEST_BYPASS( 118, 1, addiu, 23, 13, 10 );
        TEST_IMM_DEST_BYPASS( 119, 2, addiu, 22, 13,  9 );

        TEST_IMM_SRC1_BYPASS( 120, 0, addiu, 24, 13, 11 );
        TEST_IMM_SRC1_BYPASS( 121, 1, addiu, 23, 13, 10 );        
        TEST_IMM_SRC1_BYPASS( 122, 2, addiu, 22, 13,  9 );
                        
#
# Test addu instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------
         
        TEST_RR_OP( 202,  addu, 0x00000000, 0x00000000, 0x00000000 );
        TEST_RR_OP( 203,  addu, 0x00000002, 0x00000001, 0x00000001 );
        TEST_RR_OP( 204,  addu, 0x0000000a, 0x00000003, 0x00000007 );
                                                                              
        TEST_RR_OP( 205,  addu, 0xffff8000, 0x00000000, 0xffff8000 );
        TEST_RR_OP( 206,  addu, 0x80000000, 0x80000000, 0x00000000 );
        TEST_RR_OP( 207,  addu, 0x7fff8000, 0x80000000, 0xffff8000 );
        
        TEST_RR_OP( 208,  addu, 0x00007fff, 0x00000000, 0x00007fff );
        TEST_RR_OP( 209,  addu, 0x7fffffff, 0x7fffffff, 0x00000000 );
        TEST_RR_OP( 210, addu, 0x80007ffe, 0x7fffffff, 0x00007fff );
                                                                                      
        TEST_RR_OP( 211, addu, 0x80007fff, 0x80000000, 0x00007fff );
        TEST_RR_OP( 212, addu, 0x7fff7fff, 0x7fffffff, 0xffff8000 );
        
        TEST_RR_OP( 213, addu, 0xffffffff, 0x00000000, 0xffffffff );
        TEST_RR_OP( 214, addu, 0x00000000, 0xffffffff, 0x00000001 );
        TEST_RR_OP( 215, addu, 0xfffffffe, 0xffffffff, 0xffffffff );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 216, addu, 24, 13, 11 );
        TEST_RR_SRC2_EQ_DEST( 217, addu, 25, 14, 11 );
        TEST_RR_SRC12_EQ_DEST( 218, addu, 26, 13 );
        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 219, 0, addu, 24, 13, 11 );
        TEST_RR_DEST_BYPASS( 220, 1, addu, 25, 14, 11 );
        TEST_RR_DEST_BYPASS( 221, 2, addu, 26, 15, 11 );

        TEST_RR_SRC12_BYPASS( 222, 0, 0, addu, 24, 13, 11 );
        TEST_RR_SRC12_BYPASS( 223, 0, 1, addu, 25, 14, 11 );        
        TEST_RR_SRC12_BYPASS( 224, 0, 2, addu, 26, 15, 11 );
        TEST_RR_SRC12_BYPASS( 225, 1, 0, addu, 24, 13, 11 );
        TEST_RR_SRC12_BYPASS( 226, 1, 1, addu, 25, 14, 11 );        
        TEST_RR_SRC12_BYPASS( 227, 2, 0, addu, 26, 15, 11 );

        TEST_RR_SRC21_BYPASS( 228, 0, 0, addu, 24, 13, 11 );
        TEST_RR_SRC21_BYPASS( 229, 0, 1, addu, 25, 14, 11 );        
        TEST_RR_SRC21_BYPASS( 230, 0, 2, addu, 26, 15, 11 );
        TEST_RR_SRC21_BYPASS( 231, 1, 0, addu, 24, 13, 11 );
        TEST_RR_SRC21_BYPASS( 232, 1, 1, addu, 25, 14, 11 );        
        TEST_RR_SRC21_BYPASS( 233, 2, 0, addu, 26, 15, 11 );

#
# Test andi instruction.
#       

        #-------------------------------------------------------------
        # Logical tests
        #-------------------------------------------------------------
         
        TEST_IMM_OP( 302, andi, 0x00000f00, 0xff00ff00, 0x0f0f );
        TEST_IMM_OP( 303, andi, 0x000000f0, 0x0ff00ff0, 0xf0f0 );
        TEST_IMM_OP( 304, andi, 0x0000000f, 0x00ff00ff, 0x0f0f );
        TEST_IMM_OP( 305, andi, 0x0000f000, 0xf00ff00f, 0xf0f0 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_IMM_SRC1_EQ_DEST( 306, andi, 0x0000f000, 0xff00ff00, 0xf0f0 );
                        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_IMM_DEST_BYPASS( 307,  0, andi, 0x00000f00, 0x0ff00ff0, 0x0f0f );
        TEST_IMM_DEST_BYPASS( 308,  1, andi, 0x000000f0, 0x00ff00ff, 0xf0f0 );
        TEST_IMM_DEST_BYPASS( 309,  2, andi, 0x0000000f, 0xf00ff00f, 0x0f0f );
        
        TEST_IMM_SRC1_BYPASS( 310, 0, andi, 0x00000f00, 0x0ff00ff0, 0x0f0f );
        TEST_IMM_SRC1_BYPASS( 311, 1, andi, 0x000000f0, 0x00ff00ff, 0xf0f0 );
        TEST_IMM_SRC1_BYPASS( 312, 2, andi, 0x0000000f, 0xf00ff00f, 0x0f0f );
                        
#
# Test and instruction.
#       

        #-------------------------------------------------------------
        # Logical tests
        #-------------------------------------------------------------
         
        TEST_RR_OP( 402, and, 0x0f000f00, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_OP( 403, and, 0x00f000f0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_OP( 404, and, 0x000f000f, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_OP( 405, and, 0xf000f000, 0xf00ff00f, 0xf0f0f0f0 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 406, and, 0x0f000f00, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC2_EQ_DEST( 407, and, 0x00f000f0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC12_EQ_DEST( 408, and, 0xff00ff00, 0xff00ff00 );
                
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 409,  0, and, 0x0f000f00, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_DEST_BYPASS( 410, 1, and, 0x00f000f0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_DEST_BYPASS( 411, 2, and, 0x000f000f, 0x00ff00ff, 0x0f0f0f0f );

        TEST_RR_SRC12_BYPASS( 412, 0, 0, and, 0x0f000f00, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 413, 0, 1, and, 0x00f000f0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC12_BYPASS( 414, 0, 2, and, 0x000f000f, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 415, 1, 0, and, 0x0f000f00, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 416, 1, 1, and, 0x00f000f0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC12_BYPASS( 417, 2, 0, and, 0x000f000f, 0x00ff00ff, 0x0f0f0f0f );

        TEST_RR_SRC21_BYPASS( 418, 0, 0, and, 0x0f000f00, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 419, 0, 1, and, 0x00f000f0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC21_BYPASS( 420, 0, 2, and, 0x000f000f, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 421, 1, 0, and, 0x0f000f00, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 422, 1, 1, and, 0x00f000f0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC21_BYPASS( 423, 2, 0, and, 0x000f000f, 0x00ff00ff, 0x0f0f0f0f );

#
# Test beq instruction.
#       

        #-------------------------------------------------------------
        # Branch tests
        #-------------------------------------------------------------

        # Each test checks both forward and backward branches
        
        TEST_BR2_OP_TAKEN( 502, beq,  0,  0 );
        TEST_BR2_OP_TAKEN( 503, beq,  1,  1 );
        TEST_BR2_OP_TAKEN( 504, beq, -1, -1 );

        TEST_BR2_OP_NOTTAKEN( 505, beq,  0,  1 );
        TEST_BR2_OP_NOTTAKEN( 506, beq,  1,  0 );
        TEST_BR2_OP_NOTTAKEN( 507, beq, -1,  1 );
        TEST_BR2_OP_NOTTAKEN( 508, beq,  1, -1 );
                                        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_BR2_SRC12_BYPASS( 509,  0, 0, beq, 0, -1 );
        TEST_BR2_SRC12_BYPASS( 510, 0, 1, beq, 0, -1 );        
        TEST_BR2_SRC12_BYPASS( 511, 0, 2, beq, 0, -1 );
        TEST_BR2_SRC12_BYPASS( 512, 1, 0, beq, 0, -1 );
        TEST_BR2_SRC12_BYPASS( 513, 1, 1, beq, 0, -1 );        
        TEST_BR2_SRC12_BYPASS( 514, 2, 0, beq, 0, -1 );

        TEST_BR2_SRC12_BYPASS( 515, 0, 0, beq, 0, -1 );
        TEST_BR2_SRC12_BYPASS( 516, 0, 1, beq, 0, -1 );        
        TEST_BR2_SRC12_BYPASS( 517, 0, 2, beq, 0, -1 );
        TEST_BR2_SRC12_BYPASS( 518, 1, 0, beq, 0, -1 );
        TEST_BR2_SRC12_BYPASS( 519, 1, 1, beq, 0, -1 );        
        TEST_BR2_SRC12_BYPASS( 520, 2, 0, beq, 0, -1 );                        

        #-------------------------------------------------------------
        # Test delay slot instructions 
        #-------------------------------------------------------------
        
        TEST_CASE( 521, $2, 4, \
          li $2, 1; \
          beq $0, $0, 1f; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                     
                
#
# Test bgez instruction.
#       

        #-------------------------------------------------------------
        # Branch tests
        #-------------------------------------------------------------

        # Each test checks both forward and backward branches
        
        TEST_BR1_OP_TAKEN( 602, bgez, 0 );
        TEST_BR1_OP_TAKEN( 603, bgez, 1 );
                
        TEST_BR1_OP_NOTTAKEN( 604, bgez, -1  );
        TEST_BR1_OP_NOTTAKEN( 605, bgez, -10 );

        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_BR1_SRC1_BYPASS( 606, 0, bgez, -1 );
        TEST_BR1_SRC1_BYPASS( 607, 1, bgez, -1 );
        TEST_BR1_SRC1_BYPASS( 608, 2, bgez, -1 );

        #-------------------------------------------------------------
        # Test delay slot instructions
        #-------------------------------------------------------------
        
        TEST_CASE( 609, $2, 4, \
          li $2, 1; \
          bgez $0, 1f; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                             
                        
#
# Test bgtz instruction.
#       

        #-------------------------------------------------------------
        # Branch tests
        #-------------------------------------------------------------

        # Each test checks both forward and backward branches
        
        TEST_BR1_OP_TAKEN( 702, bgtz, 1 );
        TEST_BR1_OP_TAKEN( 703, bgtz, 10 );
                
        TEST_BR1_OP_NOTTAKEN( 704, bgtz, 0  );
        TEST_BR1_OP_NOTTAKEN( 705, bgtz, -1 );

        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_BR1_SRC1_BYPASS( 706, 0, bgtz, -1 );
        TEST_BR1_SRC1_BYPASS( 707, 1, bgtz, -1 );
        TEST_BR1_SRC1_BYPASS( 708, 2, bgtz, -1 );

        #-------------------------------------------------------------
        # Test delay slot instructions
        #-------------------------------------------------------------
        
        TEST_CASE( 709, $2, 4, \
          li $2, 1; \
          bgtz $2, 1f; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                     
                
#
# Test blez instruction.
#       

        #-------------------------------------------------------------
        # Branch tests
        #-------------------------------------------------------------

        # Each test checks both forward and backward branches
        
        TEST_BR1_OP_TAKEN( 802, blez, 0 );
        TEST_BR1_OP_TAKEN( 803, blez, -1 );
                
        TEST_BR1_OP_NOTTAKEN( 804, blez, 1  );
        TEST_BR1_OP_NOTTAKEN( 805, blez, 10 );

        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_BR1_SRC1_BYPASS( 806, 0, blez, 1 );
        TEST_BR1_SRC1_BYPASS( 807, 1, blez, 1 );                                        
        TEST_BR1_SRC1_BYPASS( 808, 2, blez, 1 );

        #-------------------------------------------------------------
        # Test delay slot instructions not executed nor bypassed
        #-------------------------------------------------------------
        
        TEST_CASE( 809, $2, 4, \
          li $2, 1; \
          blez $0, 1f; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                             
                
#
# Test bltz instruction.
#       

        #-------------------------------------------------------------
        # Branch tests
        #-------------------------------------------------------------

        # Each test checks both forward and backward branches
        
        TEST_BR1_OP_TAKEN( 902, bltz, -1 );
        TEST_BR1_OP_TAKEN( 903, bltz, -10 );
                
        TEST_BR1_OP_NOTTAKEN( 904, bltz, 0 );
        TEST_BR1_OP_NOTTAKEN( 905, bltz, 1 );

        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_BR1_SRC1_BYPASS( 906, 0, bltz, 1 );
        TEST_BR1_SRC1_BYPASS( 907, 1, bltz, 1 );                                        
        TEST_BR1_SRC1_BYPASS( 908, 2, bltz, 1 );

        #-------------------------------------------------------------
        # Test delay slot instructions
        #-------------------------------------------------------------
        
        TEST_CASE( 909, $2, 4, \
          li $2, 1; \
          li $3, -1;
          bltz $3, 1f; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                     
                
#
# Test bne instruction.
#       

        #-------------------------------------------------------------
        # Branch tests
        #-------------------------------------------------------------

        # Each test checks both forward and backward branches
        
        TEST_BR2_OP_TAKEN( 1002, bne,  0,  1 );
        TEST_BR2_OP_TAKEN( 1003, bne,  1,  0 );
        TEST_BR2_OP_TAKEN( 1004, bne, -1,  1 );
        TEST_BR2_OP_TAKEN( 1005, bne,  1, -1 );
        
        TEST_BR2_OP_NOTTAKEN( 1006, bne,  0,  0 );
        TEST_BR2_OP_NOTTAKEN( 1007, bne,  1,  1 );
        TEST_BR2_OP_NOTTAKEN( 1008, bne, -1, -1 );
                                        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_BR2_SRC12_BYPASS( 1009,  0, 0, bne, 0, 0 );
        TEST_BR2_SRC12_BYPASS( 1010, 0, 1, bne, 0, 0 );        
        TEST_BR2_SRC12_BYPASS( 1011, 0, 2, bne, 0, 0 );
        TEST_BR2_SRC12_BYPASS( 1012, 1, 0, bne, 0, 0 );
        TEST_BR2_SRC12_BYPASS( 1013, 1, 1, bne, 0, 0 );        
        TEST_BR2_SRC12_BYPASS( 1014, 2, 0, bne, 0, 0 );

        TEST_BR2_SRC12_BYPASS( 1015, 0, 0, bne, 0, 0 );
        TEST_BR2_SRC12_BYPASS( 1016, 0, 1, bne, 0, 0 );        
        TEST_BR2_SRC12_BYPASS( 1017, 0, 2, bne, 0, 0 );
        TEST_BR2_SRC12_BYPASS( 1018, 1, 0, bne, 0, 0 );
        TEST_BR2_SRC12_BYPASS( 1019, 1, 1, bne, 0, 0 );        
        TEST_BR2_SRC12_BYPASS( 1020, 2, 0, bne, 0, 0 );                        
        
        #-------------------------------------------------------------
        # Test delay slot instructions
        #-------------------------------------------------------------
        
        TEST_CASE( 1021, $2, 4, \
          li $2, 1; \
          bne $2, $0, 1f; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                     
        
#
# Test jalr instruction.
#       

        #-------------------------------------------------------------
        # Test 2: Basic test
        #-------------------------------------------------------------

test_1101:        
        li $30, 1101
        li $31, 0
        la $3, target_1101
        
linkaddr_1101:      
        jalr $16, $3
        nop
        nop
        
        j fail 
	nop

target_1101: 
        la $2, linkaddr_1101
        addiu $2, $2, 8
        bne $2, $16, fail

        #-------------------------------------------------------------
        # Test 3: Check r0 target and that r31 is not modified
        #-------------------------------------------------------------

test_1102:        
        li $30, 1102
        li $31, 0
        la $4, target_1102

linkaddr_1102:   
        jalr $0, $4
        nop
                
        j fail 
	nop

target_1102: 
        bne $31, $0, fail

        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_JALR_SRC1_BYPASS( 1104, 0, jalr );
        TEST_JALR_SRC1_BYPASS( 1105, 1, jalr );                
        TEST_JALR_SRC1_BYPASS( 1106, 2, jalr );

        #-------------------------------------------------------------
        # Test delay slot instructions
        #-------------------------------------------------------------
        
        TEST_CASE( 1107, $2, 4, \
          li $2, 1; \
          la $3, 1f;
          jalr $16, $3; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                             
                
#
# Test jal instruction.
#       

        #-------------------------------------------------------------
        # Test 2: Basic test
        #-------------------------------------------------------------

test_1202:        
        li $30, 1202
        li $31, 0
        
linkaddr_1202:      
        jal target_1202
        nop
        nop
        
        j fail 
	nop

target_1202: 
        la $2, linkaddr_1202
        addiu $2, $2, 8
        bne $2, $31, fail

        #-------------------------------------------------------------
        # Test delay slot instructions
        #-------------------------------------------------------------
        
        TEST_CASE( 1203, $2, 4, \
          li $2, 1; \
          jal 1f; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                             
        
#
# Test jr instruction.
#       

        #-------------------------------------------------------------
        # Test 2: Basic test
        #-------------------------------------------------------------

test_1302:        
        li $30, 1302
        li $31, 0
        la $3, target_1302
        
linkaddr_1302:
        jr $3
        nop
        nop
        
        j fail
	nop

target_1302:

        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_JR_SRC1_BYPASS( 1303, 0, jr );
        TEST_JR_SRC1_BYPASS( 1304, 1, jr );                
        TEST_JR_SRC1_BYPASS( 1305, 2, jr );        

        #-------------------------------------------------------------
        # Test delay slot instructions not executed nor bypassed
        #-------------------------------------------------------------
        
        TEST_CASE( 1306, $2, 4, \
          li $2, 1; \
          la $3, 1f;       
          jr $3; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                             
        
                
#
# Test j instruction.
#       

        #-------------------------------------------------------------
        # Test basic
        #-------------------------------------------------------------
        
        li $30, 1402;
        j test_1402;
	nop; 
        j fail;
	nop; 
test_1402:         
                
        #-------------------------------------------------------------
        # Test delay slot instructions not executed nor bypassed
        #-------------------------------------------------------------
        
        TEST_CASE( 1403, $2, 4, \
          li $2, 1; \
          j 1f; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
          addiu $2, 1; \
      1:  addiu $2, 1; \
          addiu $2, 1; \
        )                             
 
#
# Test lui instruction.
#       

        #-------------------------------------------------------------
        # Basic tests
        #-------------------------------------------------------------

        TEST_CASE( 1502, $2, 0x00000000, lui $2, 0x0000 );
        TEST_CASE( 1503, $2, 0xffff0000, lui $2, 0xffff );
        TEST_CASE( 1504, $2, 0x7fff0000, lui $2, 0x7fff ); 
        TEST_CASE( 1505, $2, 0x80000000, lui $2, 0x8000 );

#
# Test lw instruction.
#       

        #-------------------------------------------------------------
        # Basic tests
        #-------------------------------------------------------------

        TEST_LD_OP( 1602, lw, 0x00ff00ff, 0,  tdat16 );
        TEST_LD_OP( 1603, lw, 0xff00ff00, 4,  tdat16 );
        TEST_LD_OP( 1604, lw, 0x0ff00ff0, 8,  tdat16 );
        TEST_LD_OP( 1605, lw, 0xf00ff00f, 12, tdat16 );

        # Test with negative offset
        
        TEST_LD_OP( 1606, lw, 0x00ff00ff, -12, tdat16_4 );
        TEST_LD_OP( 1607, lw, 0xff00ff00, -8,  tdat16_4 );
        TEST_LD_OP( 1608, lw, 0x0ff00ff0, -4,  tdat16_4 );
        TEST_LD_OP( 1609, lw, 0xf00ff00f, 0,   tdat16_4 );
       
        # Test with a negative base

        TEST_CASE( 1610, $4, 0x00ff00ff, \
          la $2, tdat16; \
          addiu $2, $2, -32; \
          lw $4, 32($2); \
        )

        # Test with unaligned base

        TEST_CASE( 1611, $4, 0xff00ff00, \
          la $2, tdat16; \
          addiu $2, $2, -3; \
          lw $4, 7($2); \
        )

        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_LD_DEST_BYPASS( 1612, 0, lw, 0x0ff00ff0, 4, tdat16_2 );
        TEST_LD_DEST_BYPASS( 1613, 1, lw, 0xf00ff00f, 4, tdat16_3 );        
        TEST_LD_DEST_BYPASS( 1614, 2, lw, 0xff00ff00, 4, tdat16_1 );

        TEST_LD_SRC1_BYPASS( 1615, 0, lw, 0x0ff00ff0, 4, tdat16_2 );
        TEST_LD_SRC1_BYPASS( 1616, 1, lw, 0xf00ff00f, 4, tdat16_3 );
        TEST_LD_SRC1_BYPASS( 1617, 2, lw, 0xff00ff00, 4, tdat16_1 );
        
        #-------------------------------------------------------------
        # Test write-after-write hazard
        #-------------------------------------------------------------

        TEST_CASE( 1618, $3, 2, \
          la $4, tdat16; \
          lw $3, 0($4); \
          li $3, 2; \
        )

        TEST_CASE( 1619, $3, 2, \
          la $4, tdat16; \
          lw $3, 0($4); \
          nop; \
          li $3, 2; \
        )        
        
        
        #-------------------------------------------------------------
        # Test data
        #-------------------------------------------------------------

        .data
tdat16:
tdat16_1:  .word 0x00ff00ff
tdat16_2:  .word 0xff00ff00        
tdat16_3:  .word 0x0ff00ff0
tdat16_4:  .word 0xf00ff00f
	.text
	
#
# Test nor instruction.
#       

        #-------------------------------------------------------------
        # Logical tests
        #-------------------------------------------------------------
         
        TEST_RR_OP( 1702, nor, 0x00f000f0, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_OP( 1703, nor, 0x000f000f, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_OP( 1704, nor, 0xf000f000, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_OP( 1705, nor, 0x0f000f00, 0xf00ff00f, 0xf0f0f0f0 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 1706, nor, 0x00f000f0, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC2_EQ_DEST( 1707, nor, 0x00f000f0, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_EQ_DEST( 1708, nor, 0x00ff00ff, 0xff00ff00 );
                
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 1709,  0, nor, 0x00f000f0, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_DEST_BYPASS( 1710, 1, nor, 0x000f000f, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_DEST_BYPASS( 1711, 2, nor, 0xf000f000, 0x00ff00ff, 0x0f0f0f0f );

        TEST_RR_SRC12_BYPASS( 1712, 0, 0, nor, 0x00f000f0, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 1713, 0, 1, nor, 0x000f000f, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC12_BYPASS( 1714, 0, 2, nor, 0xf000f000, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 1715, 1, 0, nor, 0x00f000f0, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 1716, 1, 1, nor, 0x000f000f, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC12_BYPASS( 1717, 2, 0, nor, 0xf000f000, 0x00ff00ff, 0x0f0f0f0f );

        TEST_RR_SRC21_BYPASS( 1718, 0, 0, nor, 0x00f000f0, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 1719, 0, 1, nor, 0x000f000f, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC21_BYPASS( 1720, 0, 2, nor, 0xf000f000, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 1721, 1, 0, nor, 0x00f000f0, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 1722, 1, 1, nor, 0x000f000f, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC21_BYPASS( 1723, 2, 0, nor, 0xf000f000, 0x00ff00ff, 0x0f0f0f0f );

#
# Test ori instruction.
#       

        #-------------------------------------------------------------
        # Logical tests
        #-------------------------------------------------------------
         
        TEST_IMM_OP( 1802, ori, 0xff00ff0f, 0xff00ff00, 0x0f0f );
        TEST_IMM_OP( 1803, ori, 0x0ff0fff0, 0x0ff00ff0, 0xf0f0 );
        TEST_IMM_OP( 1804, ori, 0x00ff0fff, 0x00ff00ff, 0x0f0f );
        TEST_IMM_OP( 1805, ori, 0xf00ff0ff, 0xf00ff00f, 0xf0f0 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_IMM_SRC1_EQ_DEST( 1806, ori, 0xff00fff0, 0xff00ff00, 0xf0f0 );
                        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_IMM_DEST_BYPASS( 1807,  0, ori, 0x0ff0fff0, 0x0ff00ff0, 0xf0f0 );
        TEST_IMM_DEST_BYPASS( 1808,  1, ori, 0x00ff0fff, 0x00ff00ff, 0x0f0f );
        TEST_IMM_DEST_BYPASS( 1809,  2, ori, 0xf00ff0ff, 0xf00ff00f, 0xf0f0 );
        
        TEST_IMM_SRC1_BYPASS( 1810, 0, ori, 0x0ff0fff0, 0x0ff00ff0, 0xf0f0 );
        TEST_IMM_SRC1_BYPASS( 1811, 1, ori, 0x00ff0fff, 0x00ff00ff, 0x0f0f );
        TEST_IMM_SRC1_BYPASS( 1812, 2, ori, 0xf00ff0ff, 0xf00ff00f, 0xf0f0 );
                        
#
# Test or instruction.
#       

        #-------------------------------------------------------------
        # Logical tests
        #-------------------------------------------------------------
         
        TEST_RR_OP( 1902, or, 0xff0fff0f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_OP( 1903, or, 0xfff0fff0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_OP( 1904, or, 0x0fff0fff, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_OP( 1905, or, 0xf0fff0ff, 0xf00ff00f, 0xf0f0f0f0 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 1906, or, 0xff0fff0f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC2_EQ_DEST( 1907, or, 0xff0fff0f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_EQ_DEST( 1908, or, 0xff00ff00, 0xff00ff00 );
                
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 1909,  0, or, 0xff0fff0f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_DEST_BYPASS( 1910, 1, or, 0xfff0fff0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_DEST_BYPASS( 1911, 2, or, 0x0fff0fff, 0x00ff00ff, 0x0f0f0f0f );

        TEST_RR_SRC12_BYPASS( 1912, 0, 0, or, 0xff0fff0f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 1913, 0, 1, or, 0xfff0fff0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC12_BYPASS( 1914, 0, 2, or, 0x0fff0fff, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 1915, 1, 0, or, 0xff0fff0f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 1916, 1, 1, or, 0xfff0fff0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC12_BYPASS( 1917, 2, 0, or, 0x0fff0fff, 0x00ff00ff, 0x0f0f0f0f );
        
        TEST_RR_SRC21_BYPASS( 1918, 0, 0, or, 0xff0fff0f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 1919, 0, 1, or, 0xfff0fff0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC21_BYPASS( 1920, 0, 2, or, 0x0fff0fff, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 1921, 1, 0, or, 0xff0fff0f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 1922, 1, 1, or, 0xfff0fff0, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC21_BYPASS( 1923, 2, 0, or, 0x0fff0fff, 0x00ff00ff, 0x0f0f0f0f );

#
# Test sll instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------

        TEST_IMM_OP( 2002,  sll, 0x00000001, 0x00000001, 0  );
        TEST_IMM_OP( 2003,  sll, 0x00000002, 0x00000001, 1  );
        TEST_IMM_OP( 2004,  sll, 0x00000080, 0x00000001, 7  );        
        TEST_IMM_OP( 2005,  sll, 0x00004000, 0x00000001, 14 );
        TEST_IMM_OP( 2006,  sll, 0x80000000, 0x00000001, 31 );

        TEST_IMM_OP( 2007,  sll, 0xffffffff, 0xffffffff, 0  );
        TEST_IMM_OP( 2008,  sll, 0xfffffffe, 0xffffffff, 1  );
        TEST_IMM_OP( 2009,  sll, 0xffffff80, 0xffffffff, 7  );
        TEST_IMM_OP( 2010, sll, 0xffffc000, 0xffffffff, 14 );
        TEST_IMM_OP( 2011, sll, 0x80000000, 0xffffffff, 31 );

        TEST_IMM_OP( 2012, sll, 0x21212121, 0x21212121, 0  );
        TEST_IMM_OP( 2013, sll, 0x42424242, 0x21212121, 1  );
        TEST_IMM_OP( 2014, sll, 0x90909080, 0x21212121, 7  );
        TEST_IMM_OP( 2015, sll, 0x48484000, 0x21212121, 14 );
        TEST_IMM_OP( 2016, sll, 0x80000000, 0x21212121, 31 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_IMM_SRC1_EQ_DEST( 2017, sll, 0x00000080, 0x00000001, 7 );
        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_IMM_DEST_BYPASS( 2018, 0, sll, 0x00000080, 0x00000001, 7  );
        TEST_IMM_DEST_BYPASS( 2019, 1, sll, 0x00004000, 0x00000001, 14 );
        TEST_IMM_DEST_BYPASS( 2020, 2, sll, 0x80000000, 0x00000001, 31 );

        TEST_IMM_SRC1_BYPASS( 2021, 0, sll, 0x00000080, 0x00000001, 7  );
        TEST_IMM_SRC1_BYPASS( 2022, 1, sll, 0x00004000, 0x00000001, 14 );        
        TEST_IMM_SRC1_BYPASS( 2023, 2, sll, 0x80000000, 0x00000001, 31 );
        
#
# Test sllv instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------

        TEST_RR_OP( 2102,  sllv, 0x00000001, 0x00000001, 0  );
        TEST_RR_OP( 2103,  sllv, 0x00000002, 0x00000001, 1  );
        TEST_RR_OP( 2104,  sllv, 0x00000080, 0x00000001, 7  );        
        TEST_RR_OP( 2105,  sllv, 0x00004000, 0x00000001, 14 );
        TEST_RR_OP( 2106,  sllv, 0x80000000, 0x00000001, 31 );

        TEST_RR_OP( 2107,  sllv, 0xffffffff, 0xffffffff, 0  );
        TEST_RR_OP( 2108,  sllv, 0xfffffffe, 0xffffffff, 1  );
        TEST_RR_OP( 2109,  sllv, 0xffffff80, 0xffffffff, 7  );
        TEST_RR_OP( 2110, sllv, 0xffffc000, 0xffffffff, 14 );
        TEST_RR_OP( 2111, sllv, 0x80000000, 0xffffffff, 31 );

        TEST_RR_OP( 2112, sllv, 0x21212121, 0x21212121, 0  );
        TEST_RR_OP( 2113, sllv, 0x42424242, 0x21212121, 1  );
        TEST_RR_OP( 2114, sllv, 0x90909080, 0x21212121, 7  );
        TEST_RR_OP( 2115, sllv, 0x48484000, 0x21212121, 14 );
        TEST_RR_OP( 2116, sllv, 0x80000000, 0x21212121, 31 );

        # Verify that shifts only use bottom five bits

        TEST_RR_OP( 2117, sllv, 0x21212121, 0x21212121, 0xffffffe0 );
        TEST_RR_OP( 2118, sllv, 0x42424242, 0x21212121, 0xffffffe1 );
        TEST_RR_OP( 2119, sllv, 0x90909080, 0x21212121, 0xffffffe7 );
        TEST_RR_OP( 2120, sllv, 0x48484000, 0x21212121, 0xffffffee );
        TEST_RR_OP( 2121, sllv, 0x80000000, 0x21212121, 0xffffffff );        
                                 
        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 2122, sllv, 0x00000080, 0x00000001, 7  );
        TEST_RR_SRC2_EQ_DEST( 2123, sllv, 0x00004000, 0x00000001, 14 );
        TEST_RR_SRC12_EQ_DEST( 2124, sllv, 24, 3 );
        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 2125, 0, sllv, 0x00000080, 0x00000001, 7  );
        TEST_RR_DEST_BYPASS( 2126, 1, sllv, 0x00004000, 0x00000001, 14 );
        TEST_RR_DEST_BYPASS( 2127, 2, sllv, 0x80000000, 0x00000001, 31 );

        TEST_RR_SRC12_BYPASS( 2128, 0, 0, sllv, 0x00000080, 0x00000001, 7  );
        TEST_RR_SRC12_BYPASS( 2129, 0, 1, sllv, 0x00004000, 0x00000001, 14 );        
        TEST_RR_SRC12_BYPASS( 2130, 0, 2, sllv, 0x80000000, 0x00000001, 31 );
        TEST_RR_SRC12_BYPASS( 2131, 1, 0, sllv, 0x00000080, 0x00000001, 7  );
        TEST_RR_SRC12_BYPASS( 2132, 1, 1, sllv, 0x00004000, 0x00000001, 14 );        
        TEST_RR_SRC12_BYPASS( 2133, 2, 0, sllv, 0x80000000, 0x00000001, 31 );

        TEST_RR_SRC21_BYPASS( 2134, 0, 0, sllv, 0x00000080, 0x00000001, 7  );
        TEST_RR_SRC21_BYPASS( 2135, 0, 1, sllv, 0x00004000, 0x00000001, 14 );        
        TEST_RR_SRC21_BYPASS( 2136, 0, 2, sllv, 0x80000000, 0x00000001, 31 );
        TEST_RR_SRC21_BYPASS( 2137, 1, 0, sllv, 0x00000080, 0x00000001, 7  );
        TEST_RR_SRC21_BYPASS( 2138, 1, 1, sllv, 0x00004000, 0x00000001, 14 );        
        TEST_RR_SRC21_BYPASS( 2139, 2, 0, sllv, 0x80000000, 0x00000001, 31 );
        
#
# Test slti instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------
         
        TEST_IMM_OP( 2202,  slti, 0, 0x00000000, 0x0000 );
        TEST_IMM_OP( 2203,  slti, 0, 0x00000001, 0x0001 );
        TEST_IMM_OP( 2204,  slti, 1, 0x00000003, 0x0007 );
        TEST_IMM_OP( 2205,  slti, 0, 0x00000007, 0x0003 );        
                                                                    
        TEST_IMM_OP( 2206,  slti, 0, 0x00000000, 0x8000 );
        TEST_IMM_OP( 2207,  slti, 1, 0x80000000, 0x0000 );
        TEST_IMM_OP( 2208,  slti, 1, 0x80000000, 0x8000 );
        
        TEST_IMM_OP( 2209,  slti, 1, 0x00000000, 0x7fff );
        TEST_IMM_OP( 2210, slti, 0, 0x7fffffff, 0x0000 );
        TEST_IMM_OP( 2211, slti, 0, 0x7fffffff, 0x7fff );
                                                                            
        TEST_IMM_OP( 2212, slti, 1, 0x80000000, 0x7fff );
        TEST_IMM_OP( 2213, slti, 0, 0x7fffffff, 0x8000 );

        TEST_IMM_OP( 2214, slti, 0, 0x00000000, 0xffff );
        TEST_IMM_OP( 2215, slti, 1, 0xffffffff, 0x0001 );
        TEST_IMM_OP( 2216, slti, 0, 0xffffffff, 0xffff );
        
        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_IMM_SRC1_EQ_DEST( 2217, sltiu, 1, 11, 13 );
                        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_IMM_DEST_BYPASS( 2218, 0, slti, 0, 15, 10 );
        TEST_IMM_DEST_BYPASS( 2219, 1, slti, 1, 10, 16 );
        TEST_IMM_DEST_BYPASS( 2220, 2, slti, 0, 16,  9 );
        
        TEST_IMM_SRC1_BYPASS( 2221, 0, slti, 1, 11, 15 );
        TEST_IMM_SRC1_BYPASS( 2222, 1, slti, 0, 17,  8 );
        TEST_IMM_SRC1_BYPASS( 2223, 2, slti, 1, 12, 14 );
        
#
# Test sltiu instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------
         
        TEST_IMM_OP( 2302,  sltiu, 0, 0x00000000, 0x0000 );
        TEST_IMM_OP( 2303,  sltiu, 0, 0x00000001, 0x0001 );
        TEST_IMM_OP( 2304,  sltiu, 1, 0x00000003, 0x0007 );
        TEST_IMM_OP( 2305,  sltiu, 0, 0x00000007, 0x0003 );        
                                                                    
        TEST_IMM_OP( 2306,  sltiu, 1, 0x00000000, 0x8000 );
        TEST_IMM_OP( 2307,  sltiu, 0, 0x80000000, 0x0000 );
        TEST_IMM_OP( 2308,  sltiu, 1, 0x80000000, 0x8000 );
        
        TEST_IMM_OP( 2309,  sltiu, 1, 0x00000000, 0x7fff );
        TEST_IMM_OP( 2310, sltiu, 0, 0x7fffffff, 0x0000 );
        TEST_IMM_OP( 2311, sltiu, 0, 0x7fffffff, 0x7fff );
                                                                            
        TEST_IMM_OP( 2312, sltiu, 0, 0x80000000, 0x7fff );
        TEST_IMM_OP( 2313, sltiu, 1, 0x7fffffff, 0x8000 );

        TEST_IMM_OP( 2314, sltiu, 1, 0x00000000, 0xffff );
        TEST_IMM_OP( 2315, sltiu, 0, 0xffffffff, 0x0001 );
        TEST_IMM_OP( 2316, sltiu, 0, 0xffffffff, 0xffff );
        
        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_IMM_SRC1_EQ_DEST( 2317, sltiu, 1, 11, 13 );
                        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_IMM_DEST_BYPASS( 2318, 0, sltiu, 0, 15, 10 );
        TEST_IMM_DEST_BYPASS( 2319, 1, sltiu, 1, 10, 16 );
        TEST_IMM_DEST_BYPASS( 2320, 2, sltiu, 0, 16,  9 );
        
        TEST_IMM_SRC1_BYPASS( 2321, 0, sltiu, 1, 11, 15 );
        TEST_IMM_SRC1_BYPASS( 2322, 1, sltiu, 0, 17,  8 );
        TEST_IMM_SRC1_BYPASS( 2323, 2, sltiu, 1, 12, 14 );
                        
#
# Test slt instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------
         
        TEST_RR_OP( 2402,  slt, 0, 0x00000000, 0x00000000 );
        TEST_RR_OP( 2403,  slt, 0, 0x00000001, 0x00000001 );
        TEST_RR_OP( 2404,  slt, 1, 0x00000003, 0x00000007 );
        TEST_RR_OP( 2405,  slt, 0, 0x00000007, 0x00000003 );        
                                                                    
        TEST_RR_OP( 2406,  slt, 0, 0x00000000, 0xffff8000 );
        TEST_RR_OP( 2407,  slt, 1, 0x80000000, 0x00000000 );
        TEST_RR_OP( 2408,  slt, 1, 0x80000000, 0xffff8000 );
        
        TEST_RR_OP( 2409,  slt, 1, 0x00000000, 0x00007fff );
        TEST_RR_OP( 2410, slt, 0, 0x7fffffff, 0x00000000 );
        TEST_RR_OP( 2411, slt, 0, 0x7fffffff, 0x00007fff );
                                                                            
        TEST_RR_OP( 2412, slt, 1, 0x80000000, 0x00007fff );
        TEST_RR_OP( 2413, slt, 0, 0x7fffffff, 0xffff8000 );

        TEST_RR_OP( 2414, slt, 0, 0x00000000, 0xffffffff );
        TEST_RR_OP( 2415, slt, 1, 0xffffffff, 0x00000001 );
        TEST_RR_OP( 2416, slt, 0, 0xffffffff, 0xffffffff );
        
        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 2417, slt, 0, 14, 13 );
        TEST_RR_SRC2_EQ_DEST( 2418, slt, 1, 11, 13 );
        TEST_RR_SRC12_EQ_DEST( 2419, slt, 0, 13 );
        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 2420, 0, slt, 1, 11, 13 );
        TEST_RR_DEST_BYPASS( 2421, 1, slt, 0, 14, 13 );
        TEST_RR_DEST_BYPASS( 2422, 2, slt, 1, 12, 13 );

        TEST_RR_SRC12_BYPASS( 2423, 0, 0, slt, 0, 14, 13 );
        TEST_RR_SRC12_BYPASS( 2424, 0, 1, slt, 1, 11, 13 );        
        TEST_RR_SRC12_BYPASS( 2425, 0, 2, slt, 0, 15, 13 );
        TEST_RR_SRC12_BYPASS( 2426, 1, 0, slt, 1, 10, 13 );
        TEST_RR_SRC12_BYPASS( 2427, 1, 1, slt, 0, 16, 13 );        
        TEST_RR_SRC12_BYPASS( 2428, 2, 0, slt, 1,  9, 13 );

        TEST_RR_SRC21_BYPASS( 2429, 0, 0, slt, 0, 17, 13 );
        TEST_RR_SRC21_BYPASS( 2430, 0, 1, slt, 1,  8, 13 );        
        TEST_RR_SRC21_BYPASS( 2431, 0, 2, slt, 0, 18, 13 );
        TEST_RR_SRC21_BYPASS( 2432, 1, 0, slt, 1,  7, 13 );
        TEST_RR_SRC21_BYPASS( 2433, 1, 1, slt, 0, 19, 13 );        
        TEST_RR_SRC21_BYPASS( 2434, 2, 0, slt, 1,  6, 13 );

#
# Test sltu instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------
         
        TEST_RR_OP( 2502,  sltu, 0, 0x00000000, 0x00000000 );
        TEST_RR_OP( 2503,  sltu, 0, 0x00000001, 0x00000001 );
        TEST_RR_OP( 2504,  sltu, 1, 0x00000003, 0x00000007 );
        TEST_RR_OP( 2505,  sltu, 0, 0x00000007, 0x00000003 );        
                                                                    
        TEST_RR_OP( 2506,  sltu, 1, 0x00000000, 0xffff8000 );
        TEST_RR_OP( 2507,  sltu, 0, 0x80000000, 0x00000000 );
        TEST_RR_OP( 2508,  sltu, 1, 0x80000000, 0xffff8000 );
        
        TEST_RR_OP( 2509,  sltu, 1, 0x00000000, 0x00007fff );
        TEST_RR_OP( 2510, sltu, 0, 0x7fffffff, 0x00000000 );
        TEST_RR_OP( 2511, sltu, 0, 0x7fffffff, 0x00007fff );
                                                                            
        TEST_RR_OP( 2512, sltu, 0, 0x80000000, 0x00007fff );
        TEST_RR_OP( 2513, sltu, 1, 0x7fffffff, 0xffff8000 );

        TEST_RR_OP( 2514, sltu, 1, 0x00000000, 0xffffffff );
        TEST_RR_OP( 2515, sltu, 0, 0xffffffff, 0x00000001 );
        TEST_RR_OP( 2516, sltu, 0, 0xffffffff, 0xffffffff );
        
        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 2517, sltu, 0, 14, 13 );
        TEST_RR_SRC2_EQ_DEST( 2518, sltu, 1, 11, 13 );
        TEST_RR_SRC12_EQ_DEST( 2519, sltu, 0, 13 );
        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 2520, 0, sltu, 1, 11, 13 );
        TEST_RR_DEST_BYPASS( 2521, 1, sltu, 0, 14, 13 );
        TEST_RR_DEST_BYPASS( 2522, 2, sltu, 1, 12, 13 );

        TEST_RR_SRC12_BYPASS( 2523, 0, 0, sltu, 0, 14, 13 );
        TEST_RR_SRC12_BYPASS( 2524, 0, 1, sltu, 1, 11, 13 );        
        TEST_RR_SRC12_BYPASS( 2525, 0, 2, sltu, 0, 15, 13 );
        TEST_RR_SRC12_BYPASS( 2526, 1, 0, sltu, 1, 10, 13 );
        TEST_RR_SRC12_BYPASS( 2527, 1, 1, sltu, 0, 16, 13 );        
        TEST_RR_SRC12_BYPASS( 2528, 2, 0, sltu, 1,  9, 13 );

        TEST_RR_SRC21_BYPASS( 2529, 0, 0, sltu, 0, 17, 13 );
        TEST_RR_SRC21_BYPASS( 2530, 0, 1, sltu, 1,  8, 13 );        
        TEST_RR_SRC21_BYPASS( 2531, 0, 2, sltu, 0, 18, 13 );
        TEST_RR_SRC21_BYPASS( 2532, 1, 0, sltu, 1,  7, 13 );
        TEST_RR_SRC21_BYPASS( 2533, 1, 1, sltu, 0, 19, 13 );        
        TEST_RR_SRC21_BYPASS( 2534, 2, 0, sltu, 1,  6, 13 );

#
# Test sra instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------

        TEST_IMM_OP( 2602,  sra, 0x80000000, 0x80000000, 0  );
        TEST_IMM_OP( 2603,  sra, 0xc0000000, 0x80000000, 1  );
        TEST_IMM_OP( 2604,  sra, 0xff000000, 0x80000000, 7  );        
        TEST_IMM_OP( 2605,  sra, 0xfffe0000, 0x80000000, 14 );
        TEST_IMM_OP( 2606,  sra, 0xffffffff, 0x80000001, 31 );

        TEST_IMM_OP( 2607,  sra, 0x7fffffff, 0x7fffffff, 0  );
        TEST_IMM_OP( 2608,  sra, 0x3fffffff, 0x7fffffff, 1  );
        TEST_IMM_OP( 2609,  sra, 0x00ffffff, 0x7fffffff, 7  );
        TEST_IMM_OP( 2610, sra, 0x0001ffff, 0x7fffffff, 14 );
        TEST_IMM_OP( 2611, sra, 0x00000000, 0x7fffffff, 31 );

        TEST_IMM_OP( 2612, sra, 0x81818181, 0x81818181, 0  );
        TEST_IMM_OP( 2613, sra, 0xc0c0c0c0, 0x81818181, 1  );
        TEST_IMM_OP( 2614, sra, 0xff030303, 0x81818181, 7  );
        TEST_IMM_OP( 2615, sra, 0xfffe0606, 0x81818181, 14 );
        TEST_IMM_OP( 2616, sra, 0xffffffff, 0x81818181, 31 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_IMM_SRC1_EQ_DEST( 2617, sra, 0xff000000, 0x80000000, 7 );
        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_IMM_DEST_BYPASS( 2618, 0, sra, 0xff000000, 0x80000000, 7  );
        TEST_IMM_DEST_BYPASS( 2619, 1, sra, 0xfffe0000, 0x80000000, 14 );
        TEST_IMM_DEST_BYPASS( 2620, 2, sra, 0xffffffff, 0x80000001, 31 );

        TEST_IMM_SRC1_BYPASS( 2621, 0, sra, 0xff000000, 0x80000000, 7 );
        TEST_IMM_SRC1_BYPASS( 2622, 1, sra, 0xfffe0000, 0x80000000, 14 );        
        TEST_IMM_SRC1_BYPASS( 2623, 2, sra, 0xffffffff, 0x80000001, 31 );
        
#
# Test srav instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------

        TEST_RR_OP( 2702,  srav, 0x80000000, 0x80000000, 0  );
        TEST_RR_OP( 2703,  srav, 0xc0000000, 0x80000000, 1  );
        TEST_RR_OP( 2704,  srav, 0xff000000, 0x80000000, 7  );        
        TEST_RR_OP( 2705,  srav, 0xfffe0000, 0x80000000, 14 );
        TEST_RR_OP( 2706,  srav, 0xffffffff, 0x80000001, 31 );

        TEST_RR_OP( 2707,  srav, 0x7fffffff, 0x7fffffff, 0  );
        TEST_RR_OP( 2708,  srav, 0x3fffffff, 0x7fffffff, 1  );
        TEST_RR_OP( 2709,  srav, 0x00ffffff, 0x7fffffff, 7  );
        TEST_RR_OP( 2710, srav, 0x0001ffff, 0x7fffffff, 14 );
        TEST_RR_OP( 2711, srav, 0x00000000, 0x7fffffff, 31 );

        TEST_RR_OP( 2712, srav, 0x81818181, 0x81818181, 0  );
        TEST_RR_OP( 2713, srav, 0xc0c0c0c0, 0x81818181, 1  );
        TEST_RR_OP( 2714, srav, 0xff030303, 0x81818181, 7  );
        TEST_RR_OP( 2715, srav, 0xfffe0606, 0x81818181, 14 );
        TEST_RR_OP( 2716, srav, 0xffffffff, 0x81818181, 31 );

        # Verify that shifts only use bottom five bits

        TEST_RR_OP( 2717, srav, 0x81818181, 0x81818181, 0xffffffe0 );
        TEST_RR_OP( 2718, srav, 0xc0c0c0c0, 0x81818181, 0xffffffe1 );
        TEST_RR_OP( 2719, srav, 0xff030303, 0x81818181, 0xffffffe7 );
        TEST_RR_OP( 2720, srav, 0xfffe0606, 0x81818181, 0xffffffee );
        TEST_RR_OP( 2721, srav, 0xffffffff, 0x81818181, 0xffffffff );        
                                 
        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 2722, srav, 0xff000000, 0x80000000, 7  );
        TEST_RR_SRC2_EQ_DEST( 2723, srav, 0xfffe0000, 0x80000000, 14 );
        TEST_RR_SRC12_EQ_DEST( 2724, srav, 0, 7 );
        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 2725, 0, srav, 0xff000000, 0x80000000, 7  );
        TEST_RR_DEST_BYPASS( 2726, 1, srav, 0xfffe0000, 0x80000000, 14 );
        TEST_RR_DEST_BYPASS( 2727, 2, srav, 0xffffffff, 0x80000000, 31 );

        TEST_RR_SRC12_BYPASS( 2728, 0, 0, srav, 0xff000000, 0x80000000, 7  );
        TEST_RR_SRC12_BYPASS( 2729, 0, 1, srav, 0xfffe0000, 0x80000000, 14 );        
        TEST_RR_SRC12_BYPASS( 2730, 0, 2, srav, 0xffffffff, 0x80000000, 31 );
        TEST_RR_SRC12_BYPASS( 2731, 1, 0, srav, 0xff000000, 0x80000000, 7  );
        TEST_RR_SRC12_BYPASS( 2732, 1, 1, srav, 0xfffe0000, 0x80000000, 14 );        
        TEST_RR_SRC12_BYPASS( 2733, 2, 0, srav, 0xffffffff, 0x80000000, 31 );

        TEST_RR_SRC21_BYPASS( 2734, 0, 0, srav, 0xff000000, 0x80000000, 7  );
        TEST_RR_SRC21_BYPASS( 2735, 0, 1, srav, 0xfffe0000, 0x80000000, 14 );        
        TEST_RR_SRC21_BYPASS( 2736, 0, 2, srav, 0xffffffff, 0x80000000, 31 );
        TEST_RR_SRC21_BYPASS( 2737, 1, 0, srav, 0xff000000, 0x80000000, 7  );
        TEST_RR_SRC21_BYPASS( 2738, 1, 1, srav, 0xfffe0000, 0x80000000, 14 );        
        TEST_RR_SRC21_BYPASS( 2739, 2, 0, srav, 0xffffffff, 0x80000000, 31 );
        
#
# Test srl instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------

        TEST_IMM_OP( 2802,  srl, 0x80000000, 0x80000000, 0  );
        TEST_IMM_OP( 2803,  srl, 0x40000000, 0x80000000, 1  );
        TEST_IMM_OP( 2804,  srl, 0x01000000, 0x80000000, 7  );        
        TEST_IMM_OP( 2805,  srl, 0x00020000, 0x80000000, 14 );
        TEST_IMM_OP( 2806,  srl, 0x00000001, 0x80000001, 31 );

        TEST_IMM_OP( 2807,  srl, 0xffffffff, 0xffffffff, 0  );
        TEST_IMM_OP( 2808,  srl, 0x7fffffff, 0xffffffff, 1  );
        TEST_IMM_OP( 2809,  srl, 0x01ffffff, 0xffffffff, 7  );
        TEST_IMM_OP( 2810, srl, 0x0003ffff, 0xffffffff, 14 );
        TEST_IMM_OP( 2811, srl, 0x00000001, 0xffffffff, 31 );

        TEST_IMM_OP( 2812, srl, 0x21212121, 0x21212121, 0  );
        TEST_IMM_OP( 2813, srl, 0x10909090, 0x21212121, 1  );
        TEST_IMM_OP( 2814, srl, 0x00424242, 0x21212121, 7  );
        TEST_IMM_OP( 2815, srl, 0x00008484, 0x21212121, 14 );
        TEST_IMM_OP( 2816, srl, 0x00000000, 0x21212121, 31 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_IMM_SRC1_EQ_DEST( 2817, srl, 0x01000000, 0x80000000, 7 );
        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_IMM_DEST_BYPASS( 2818, 0, srl, 0x01000000, 0x80000000, 7  );
        TEST_IMM_DEST_BYPASS( 2819, 1, srl, 0x00020000, 0x80000000, 14 );
        TEST_IMM_DEST_BYPASS( 2820, 2, srl, 0x00000001, 0x80000001, 31 );

        TEST_IMM_SRC1_BYPASS( 2821, 0, srl, 0x01000000, 0x80000000, 7  );
        TEST_IMM_SRC1_BYPASS( 2822, 1, srl, 0x00020000, 0x80000000, 14 );        
        TEST_IMM_SRC1_BYPASS( 2823, 2, srl, 0x00000001, 0x80000001, 31 );
        
#
# Test srlv instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------

        TEST_RR_OP( 2902,  srlv, 0x80000000, 0x80000000, 0  );
        TEST_RR_OP( 2903,  srlv, 0x40000000, 0x80000000, 1  );
        TEST_RR_OP( 2904,  srlv, 0x01000000, 0x80000000, 7  );        
        TEST_RR_OP( 2905,  srlv, 0x00020000, 0x80000000, 14 );
        TEST_RR_OP( 2906,  srlv, 0x00000001, 0x80000001, 31 );

        TEST_RR_OP( 2907,  srlv, 0xffffffff, 0xffffffff, 0  );
        TEST_RR_OP( 2908,  srlv, 0x7fffffff, 0xffffffff, 1  );
        TEST_RR_OP( 2909,  srlv, 0x01ffffff, 0xffffffff, 7  );
        TEST_RR_OP( 2910, srlv, 0x0003ffff, 0xffffffff, 14 );
        TEST_RR_OP( 2911, srlv, 0x00000001, 0xffffffff, 31 );

        TEST_RR_OP( 2912, srlv, 0x21212121, 0x21212121, 0  );
        TEST_RR_OP( 2913, srlv, 0x10909090, 0x21212121, 1  );
        TEST_RR_OP( 2914, srlv, 0x00424242, 0x21212121, 7  );
        TEST_RR_OP( 2915, srlv, 0x00008484, 0x21212121, 14 );
        TEST_RR_OP( 2916, srlv, 0x00000000, 0x21212121, 31 );

        # Verify that shifts only use bottom five bits

        TEST_RR_OP( 2917, srlv, 0x21212121, 0x21212121, 0xffffffe0 );
        TEST_RR_OP( 2918, srlv, 0x10909090, 0x21212121, 0xffffffe1 );
        TEST_RR_OP( 2919, srlv, 0x00424242, 0x21212121, 0xffffffe7 );
        TEST_RR_OP( 2920, srlv, 0x00008484, 0x21212121, 0xffffffee );
        TEST_RR_OP( 2921, srlv, 0x00000000, 0x21212121, 0xffffffff );        
                                 
        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 2922, srlv, 0x01000000, 0x80000000, 7  );
        TEST_RR_SRC2_EQ_DEST( 2923, srlv, 0x00020000, 0x80000000, 14 );
        TEST_RR_SRC12_EQ_DEST( 2924, srlv, 0, 7 );
        
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 2925, 0, srlv, 0x01000000, 0x80000000, 7  );
        TEST_RR_DEST_BYPASS( 2926, 1, srlv, 0x00020000, 0x80000000, 14 );
        TEST_RR_DEST_BYPASS( 2927, 2, srlv, 0x00000001, 0x80000000, 31 );

        TEST_RR_SRC12_BYPASS( 2928, 0, 0, srlv, 0x01000000, 0x80000000, 7  );
        TEST_RR_SRC12_BYPASS( 2929, 0, 1, srlv, 0x00020000, 0x80000000, 14 );        
        TEST_RR_SRC12_BYPASS( 2930, 0, 2, srlv, 0x00000001, 0x80000000, 31 );
        TEST_RR_SRC12_BYPASS( 2931, 1, 0, srlv, 0x01000000, 0x80000000, 7  );
        TEST_RR_SRC12_BYPASS( 2932, 1, 1, srlv, 0x00020000, 0x80000000, 14 );        
        TEST_RR_SRC12_BYPASS( 2933, 2, 0, srlv, 0x00000001, 0x80000000, 31 );

        TEST_RR_SRC21_BYPASS( 2934, 0, 0, srlv, 0x01000000, 0x80000000, 7  );
        TEST_RR_SRC21_BYPASS( 2935, 0, 1, srlv, 0x00020000, 0x80000000, 14 );        
        TEST_RR_SRC21_BYPASS( 2936, 0, 2, srlv, 0x00000001, 0x80000000, 31 );
        TEST_RR_SRC21_BYPASS( 2937, 1, 0, srlv, 0x01000000, 0x80000000, 7  );
        TEST_RR_SRC21_BYPASS( 2938, 1, 1, srlv, 0x00020000, 0x80000000, 14 );        
        TEST_RR_SRC21_BYPASS( 2939, 2, 0, srlv, 0x00000001, 0x80000000, 31 );
        
#
# Test subu instruction.
#       

        #-------------------------------------------------------------
        # Arithmetic tests
        #-------------------------------------------------------------
         
        TEST_RR_OP( 3002,  subu, 0x00000000, 0x00000000, 0x00000000 );
        TEST_RR_OP( 3003,  subu, 0x00000000, 0x00000001, 0x00000001 );
        TEST_RR_OP( 3004,  subu, 0xfffffffc, 0x00000003, 0x00000007 );
                                                                              
        TEST_RR_OP( 3005,  subu, 0x00008000, 0x00000000, 0xffff8000 );
        TEST_RR_OP( 3006,  subu, 0x80000000, 0x80000000, 0x00000000 );
        TEST_RR_OP( 3007,  subu, 0x80008000, 0x80000000, 0xffff8000 );
        
        TEST_RR_OP( 3008,  subu, 0xffff8001, 0x00000000, 0x00007fff );
        TEST_RR_OP( 3009,  subu, 0x7fffffff, 0x7fffffff, 0x00000000 );
        TEST_RR_OP( 3010, subu, 0x7fff8000, 0x7fffffff, 0x00007fff );
                                                                                      
        TEST_RR_OP( 3011, subu, 0x7fff8001, 0x80000000, 0x00007fff );
        TEST_RR_OP( 3012, subu, 0x80007fff, 0x7fffffff, 0xffff8000 );
        
        TEST_RR_OP( 3013, subu, 0x00000001, 0x00000000, 0xffffffff );
        TEST_RR_OP( 3014, subu, 0xfffffffe, 0xffffffff, 0x00000001 );
        TEST_RR_OP( 3015, subu, 0x00000000, 0xffffffff, 0xffffffff );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 3016, subu, 2, 13, 11 );
        TEST_RR_SRC2_EQ_DEST( 3017, subu, 3, 14, 11 );
        TEST_RR_SRC12_EQ_DEST( 3018, subu, 0, 13 );
                
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 3019, 0, subu, 2, 13, 11 );
        TEST_RR_DEST_BYPASS( 3020, 1, subu, 3, 14, 11 );
        TEST_RR_DEST_BYPASS( 3021, 2, subu, 4, 15, 11 );

        TEST_RR_SRC12_BYPASS( 3022, 0, 0, subu, 2, 13, 11 );
        TEST_RR_SRC12_BYPASS( 3023, 0, 1, subu, 3, 14, 11 );        
        TEST_RR_SRC12_BYPASS( 3024, 0, 2, subu, 4, 15, 11 );
        TEST_RR_SRC12_BYPASS( 3025, 1, 0, subu, 2, 13, 11 );
        TEST_RR_SRC12_BYPASS( 3026, 1, 1, subu, 3, 14, 11 );        
        TEST_RR_SRC12_BYPASS( 3027, 2, 0, subu, 4, 15, 11 );

        TEST_RR_SRC21_BYPASS( 3028, 0, 0, subu, 2, 13, 11 );
        TEST_RR_SRC21_BYPASS( 3029, 0, 1, subu, 3, 14, 11 );        
        TEST_RR_SRC21_BYPASS( 3030, 0, 2, subu, 4, 15, 11 );
        TEST_RR_SRC21_BYPASS( 3031, 1, 0, subu, 2, 13, 11 );
        TEST_RR_SRC21_BYPASS( 3032, 1, 1, subu, 3, 14, 11 );        
        TEST_RR_SRC21_BYPASS( 3033, 2, 0, subu, 4, 15, 11 );

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
# Test xori instruction.
#       

        #-------------------------------------------------------------
        # Logical tests
        #-------------------------------------------------------------
         
        TEST_IMM_OP( 3202, xori, 0xff00f00f, 0xff00ff00, 0x0f0f );
        TEST_IMM_OP( 3203, xori, 0x0ff0ff00, 0x0ff00ff0, 0xf0f0 );
        TEST_IMM_OP( 3204, xori, 0x00ff0ff0, 0x00ff00ff, 0x0f0f );
        TEST_IMM_OP( 3205, xori, 0xf00f00ff, 0xf00ff00f, 0xf0f0 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_IMM_SRC1_EQ_DEST( 3206, xori, 0xff00f00f, 0xff00ff00, 0x0f0f );
                        
         #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_IMM_DEST_BYPASS( 3207,  0, xori, 0x0ff0ff00, 0x0ff00ff0, 0xf0f0 );
        TEST_IMM_DEST_BYPASS( 3208,  1, xori, 0x00ff0ff0, 0x00ff00ff, 0x0f0f );
        TEST_IMM_DEST_BYPASS( 3209,  2, xori, 0xf00f00ff, 0xf00ff00f, 0xf0f0 );
        
        TEST_IMM_SRC1_BYPASS( 3210, 0, xori, 0x0ff0ff00, 0x0ff00ff0, 0xf0f0 );
        TEST_IMM_SRC1_BYPASS( 3211, 1, xori, 0x00ff0ff0, 0x00ff00ff, 0x0f0f );
        TEST_IMM_SRC1_BYPASS( 3212, 2, xori, 0xf00f00ff, 0xf00ff00f, 0xf0f0 );

#
# Test xor instruction.
#       

        #-------------------------------------------------------------
        # Logical tests
        #-------------------------------------------------------------
         
        TEST_RR_OP( 3302, xor, 0xf00ff00f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_OP( 3303, xor, 0xff00ff00, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_OP( 3304, xor, 0x0ff00ff0, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_OP( 3305, xor, 0x00ff00ff, 0xf00ff00f, 0xf0f0f0f0 );

        #-------------------------------------------------------------
        # Source/Destination tests
        #-------------------------------------------------------------

        TEST_RR_SRC1_EQ_DEST( 3306, xor, 0xf00ff00f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC2_EQ_DEST( 3307, xor, 0xf00ff00f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_EQ_DEST( 3308, xor, 0x00000000, 0xff00ff00 );
                
        #-------------------------------------------------------------
        # Bypassing tests
        #-------------------------------------------------------------

        TEST_RR_DEST_BYPASS( 3309,  0, xor, 0xf00ff00f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_DEST_BYPASS( 3310, 1, xor, 0xff00ff00, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_DEST_BYPASS( 3311, 2, xor, 0x0ff00ff0, 0x00ff00ff, 0x0f0f0f0f );

        TEST_RR_SRC12_BYPASS( 3312, 0, 0, xor, 0xf00ff00f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 3313, 0, 1, xor, 0xff00ff00, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC12_BYPASS( 3314, 0, 2, xor, 0x0ff00ff0, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 3315, 1, 0, xor, 0xf00ff00f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC12_BYPASS( 3316, 1, 1, xor, 0xff00ff00, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC12_BYPASS( 3317, 2, 0, xor, 0x0ff00ff0, 0x00ff00ff, 0x0f0f0f0f );

        TEST_RR_SRC21_BYPASS( 3318, 0, 0, xor, 0xf00ff00f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 3319, 0, 1, xor, 0xff00ff00, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC21_BYPASS( 3320, 0, 2, xor, 0x0ff00ff0, 0x00ff00ff, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 3321, 1, 0, xor, 0xf00ff00f, 0xff00ff00, 0x0f0f0f0f );
        TEST_RR_SRC21_BYPASS( 3322, 1, 1, xor, 0xff00ff00, 0x0ff00ff0, 0xf0f0f0f0 );
        TEST_RR_SRC21_BYPASS( 3323, 2, 0, xor, 0x0ff00ff0, 0x00ff00ff, 0x0f0f0f0f );

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
	
	
