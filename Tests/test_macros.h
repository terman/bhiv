#*****************************************************************************
# smipsv2_macros.S
#-----------------------------------------------------------------------------
# $Id: test_macros.h,v 1.1.1.1 2006/02/20 03:53:13 cbatten Exp $
#
# Helper macros for forming test cases.
#       

#-----------------------------------------------------------------------
# Helper macros
#-----------------------------------------------------------------------
                        
#define TEST_CASE( testnum, testreg, correctval, code... ) \
test_ ## testnum: \
    code; \
    li $29, correctval; \
    li $30, testnum; \
    bne testreg, $29, fail; \
    nop;

# We use a macro hack to simpify code generation for various numbers
# of bubble cycles. 

#define TEST_INSERT_NOPS_0 
#define TEST_INSERT_NOPS_1  nop; TEST_INSERT_NOPS_0
#define TEST_INSERT_NOPS_2  nop; TEST_INSERT_NOPS_1
#define TEST_INSERT_NOPS_3  nop; TEST_INSERT_NOPS_2
#define TEST_INSERT_NOPS_4  nop; TEST_INSERT_NOPS_3
#define TEST_INSERT_NOPS_5  nop; TEST_INSERT_NOPS_4
#define TEST_INSERT_NOPS_6  nop; TEST_INSERT_NOPS_5
#define TEST_INSERT_NOPS_7  nop; TEST_INSERT_NOPS_6
#define TEST_INSERT_NOPS_8  nop; TEST_INSERT_NOPS_7
#define TEST_INSERT_NOPS_9  nop; TEST_INSERT_NOPS_8
#define TEST_INSERT_NOPS_10 nop; TEST_INSERT_NOPS_9

#-----------------------------------------------------------------------
# Tests for instructions with immediate operand
#-----------------------------------------------------------------------

#define TEST_IMM_OP( testnum, inst, result, val1, imm ) \
    TEST_CASE( testnum, $4, result, \
      li $2, val1; \
      inst $4, $2, imm; \
    )

#define TEST_IMM_SRC1_EQ_DEST( testnum, inst, result, val1, imm ) \
    TEST_CASE( testnum, $2, result, \
      li $2, val1; \
      inst $2, $2, imm; \
    )

#define TEST_IMM_DEST_BYPASS( testnum, nop_cycles, inst, result, val1, imm ) \
    TEST_CASE( testnum, $7, result, \
      li $5, 0; \
1:    li $2, val1; \
      inst $4, $2, imm; \
      TEST_INSERT_NOPS_ ## nop_cycles \
      addiu $7, $4, 0; \
      addiu $5, $5, 1; \
      li $6, 2; \
      bne $5, $6, 1b; \
      nop; \
    )

#define TEST_IMM_SRC1_BYPASS( testnum, nop_cycles, inst, result, val1, imm ) \
    TEST_CASE( testnum, $4, result, \
      li $5, 0; \
1:    li $2, val1; \
      TEST_INSERT_NOPS_ ## nop_cycles \
      inst $4, $2, imm; \
      addiu $5, $5, 1; \
      li $6, 2; \
      bne $5, $6, 1b; \
      nop; \
    )

#-----------------------------------------------------------------------
# Tests for an instruction with register-register operands
#-----------------------------------------------------------------------

#define TEST_RR_OP( testnum, inst, result, val1, val2 ) \
    TEST_CASE( testnum, $4, result, \
      li $2, val1; \
      li $3, val2; \
      inst $4, $2, $3; \
    )

#define TEST_RR_SRC1_EQ_DEST( testnum, inst, result, val1, val2 ) \
    TEST_CASE( testnum, $2, result, \
      li $2, val1; \
      li $3, val2; \
      inst $2, $2, $3; \
    )

#define TEST_RR_SRC2_EQ_DEST( testnum, inst, result, val1, val2 ) \
    TEST_CASE( testnum, $3, result, \
      li $2, val1; \
      li $3, val2; \
      inst $3, $2, $3; \
    )

#define TEST_RR_SRC12_EQ_DEST( testnum, inst, result, val1 ) \
    TEST_CASE( testnum, $2, result, \
      li $2, val1; \
      inst $2, $2, $2; \
    )

#define TEST_RR_DEST_BYPASS( testnum, nop_cycles, inst, result, val1, val2 ) \
    TEST_CASE( testnum, $7, result, \
      li $5, 0; \
1:    li $2, val1; \
      li $3, val2; \
      inst $4, $2, $3; \
      TEST_INSERT_NOPS_ ## nop_cycles \
      addiu $7, $4, 0; \
      addiu $5, $5, 1; \
      li $6, 2; \
      bne $5, $6, 1b; \
      nop; \
    )

#define TEST_RR_SRC12_BYPASS( testnum, src1_nops, src2_nops, inst, result, val1, val2 ) \
    TEST_CASE( testnum, $4, result, \
      li $5, 0; \
1:    li $2, val1; \
      TEST_INSERT_NOPS_ ## src1_nops \
      li $3, val2; \
      TEST_INSERT_NOPS_ ## src2_nops \
      inst $4, $2, $3; \
      addiu $5, $5, 1; \
      li $6, 2; \
      bne $5, $6, 1b; \
      nop; \
    )

#define TEST_RR_SRC21_BYPASS( testnum, src1_nops, src2_nops, inst, result, val1, val2 ) \
    TEST_CASE( testnum, $4, result, \
      li $5, 0; \
1:    li $3, val2; \
      TEST_INSERT_NOPS_ ## src1_nops \
      li $2, val1; \
      TEST_INSERT_NOPS_ ## src2_nops \
      inst $4, $2, $3; \
      addiu $5, $5, 1; \
      li $6, 2; \
      bne $5, $6, 1b; \
      nop; \
 )

#-----------------------------------------------------------------------
# Test hi/lo
#-----------------------------------------------------------------------

#define TEST_LO( testnum, result ) \
  TEST_CASE( testnum, $3, result, \
    li $2, result; \
    mtlo $2; \
    mflo $3; \
  )

#define TEST_HI( testnum, result ) \
  TEST_CASE( testnum, $3, result, \
    li $2, result; \
    mthi $2; \
    mfhi $3; \
  )

#-----------------------------------------------------------------------
# Test mul/div instructions
#-----------------------------------------------------------------------

#define TEST_MULDIV( testnum, inst, rs, rt, result_lo, result_hi ) \
test_ ## testnum: \
 li $2, rs; \
 li $3, rt; \
 inst $2,$3; \
 li $4,result_lo; \
 li $5,result_hi; \
 mflo $2; \
 bne $2,$4,fail; \
 mfhi $3; \
 bne $3,$5,fail; \
 nop;

#-----------------------------------------------------------------------
# Test memory instructions
#-----------------------------------------------------------------------

#define TEST_LD_OP( testnum, inst, result, offset, base ) \
    TEST_CASE( testnum, $4, result, \
      la $2, base; \
      inst $4, offset($2); \
    )

#define TEST_ST_OP( testnum, load_inst, store_inst, result, offset, base ) \
    TEST_CASE( testnum, $4, result, \
      la $2, base; \
      li $3, result; \
      store_inst $3, offset($2); \
      load_inst $4, offset($2); \
    )

#define TEST_STBH_OP( testnum, store_inst, svalue, result, offset, base ) \
    TEST_CASE( testnum, $4, result, \
      la $2, base; \
      li $3, result; \
      li $4, svalue; \
      store_inst $4, offset($2); \
      lw $4, ($2); \
    )

#define TEST_LD_DEST_BYPASS( testnum, nop_cycles, inst, result, offset, base ) \
test_ ## testnum: \
    li $30, testnum; \
    li $5, 0; \
1:  la $2, base; \
    inst $4, offset($2); \
    TEST_INSERT_NOPS_ ## nop_cycles \
    addiu $7, $4, 0; \
    li $29, result; \
    bne $7, $29, fail; \
    addiu $5, $5, 1; \
    li $6, 2; \
    bne $5, $6, 1b; \
    nop; \

#define TEST_LD_SRC1_BYPASS( testnum, nop_cycles, inst, result, offset, base ) \
test_ ## testnum: \
    li $30, testnum; \
    li $5, 0; \
1:  la $2, base; \
    TEST_INSERT_NOPS_ ## nop_cycles \
    inst $4, offset($2); \
    li $29, result; \
    bne $4, $29, fail; \
    addiu $5, $5, 1; \
    li $6, 2; \
    bne $5, $6, 1b; \
    nop; \
 
#define TEST_ST_SRC12_BYPASS( testnum, src1_nops, src2_nops, load_inst, store_inst, result, offset, base ) \
test_ ## testnum: \
    li $30, testnum; \
    li $5, 0; \
1:  la $2, result; \
    TEST_INSERT_NOPS_ ## src1_nops \
    la $3, base; \
    TEST_INSERT_NOPS_ ## src2_nops \
    store_inst $2, offset($3); \
    load_inst $4, offset($3); \
    li $29, result; \
    bne $4, $29, fail; \
    addiu $5, $5, 1; \
    li $6, 2; \
    bne $5, $6, 1b; \
    nop; \

#define TEST_ST_SRC21_BYPASS( testnum, src1_nops, src2_nops, load_inst, store_inst, result, offset, base ) \
test_ ## testnum: \
    li $30, testnum; \
    li $5, 0; \
1:  la $3, base; \
    TEST_INSERT_NOPS_ ## src1_nops \
    la $2, result; \
    TEST_INSERT_NOPS_ ## src2_nops \
    store_inst $2, offset($3); \
    load_inst $4, offset($3); \
    li $29, result; \
    bne $4, $29, fail; \
    addiu $5, $5, 1; \
    li $6, 2; \
    bne $5, $6, 1b; \
    nop; \

#-----------------------------------------------------------------------
# Test branch instructions
#-----------------------------------------------------------------------

#define TEST_BR1_OP_TAKEN( testnum, inst, val1 ) \
test_ ## testnum: \
    li $30, testnum; \
    li $2, val1; \
    inst $2, 2f; \
    nop; \
    bne $0, $30, fail; \
    nop; \
1:  bne $0, $30, 3f; \
    nop; \
2:  inst $2, 1b; \
    nop; \
    bne $0, $30, fail; \
3:  nop;

#define TEST_BR1_OP_NOTTAKEN( testnum, inst, val1 ) \
test_ ## testnum: \
    li $30, testnum; \
    li $2, val1; \
    inst $2, 1f; \
    bne $0, $30, 2f; \
    nop; \
1:  bne $0, $30, fail; \
    nop; \
2:  inst $2, 1b; \
3:  nop;

#define TEST_BR1_SRC1_BYPASS( testnum, nop_cycles, inst, val1 ) \
test_ ## testnum: \
    li $30, testnum; \
    li $5, 0; \
1:  li $2, val1; \
    TEST_INSERT_NOPS_ ## nop_cycles \
    inst $2, fail; \
    addiu $5, $5, 1; \
    li $6, 2; \
    bne $5, $6, 1b; \
    nop;

#define TEST_BR2_OP_TAKEN( testnum, inst, val1, val2 ) \
test_ ## testnum: \
    li $30, testnum; \
    li $2, val1; \
    li $3, val2; \
    inst $2, $3, 2f; \
    nop; \
    bne $0, $30, fail; \
    nop; \
1:  bne $0, $30, 3f; \
    nop; \
2:  inst $2, $3, 1b; \
    nop; \
    bne $0, $30, fail; \
3:  nop;

#define TEST_BR2_OP_NOTTAKEN( testnum, inst, val1, val2 ) \
test_ ## testnum: \
    li $30, testnum; \
    li $2, val1; \
    li $3, val2; \
    inst $2, $3, 1f; \
    nop; \
    bne $0, $30, 2f; \
    nop; \
1:  bne $0, $30, fail; \
    nop; \
2:  inst $2, $3, 1b; \
3:  nop;

#define TEST_BR2_SRC12_BYPASS( testnum, src1_nops, src2_nops, inst, val1, val2 ) \
test_ ## testnum: \
    li $30, testnum; \
    li $5, 0; \
1:  li $2, val1; \
    TEST_INSERT_NOPS_ ## src1_nops \
    li $3, val2; \
    TEST_INSERT_NOPS_ ## src2_nops \
    inst $2, $3, fail; \
    nop; \
    addiu $5, $5, 1; \
    li $6, 2; \
    bne $5, $6, 1b; \
    nop;

#define TEST_BR2_SRC21_BYPASS( testnum, src1_nops, src2_nops, inst, val1, val2 ) \
test_ ## testnum: \
    li $30, testnum; \
    li $5, 0; \
1:  li $3, val2; \
    TEST_INSERT_NOPS_ ## src1_nops \
    li $2, val1; \
    TEST_INSERT_NOPS_ ## src2_nops \
    inst $2, $3, fail; \
    nop; \
    addiu $5, $5, 1; \
    li $6, 2; \
    bne $5, $6, 1b; \
    nop;

#-----------------------------------------------------------------------
# Test jump instructions
#-----------------------------------------------------------------------

#define TEST_JR_SRC1_BYPASS( testnum, nop_cycles, inst ) \
test_ ## testnum: \
    li $30, testnum; \
    li $5, 0; \
1:  la $7, 2f; \
    TEST_INSERT_NOPS_ ## nop_cycles \
    inst $7; \
    nop; \
    bne $0, $30, fail; \
    nop; \
2:  addiu $5, $5, 1; \
    li $6, 2; \
    bne $5, $6, 1b; \
    nop;

#define TEST_JALR_SRC1_BYPASS( testnum, nop_cycles, inst ) \
test_ ## testnum: \
    li $30, testnum; \
    li $5, 0; \
1:  la $7, 2f; \
    TEST_INSERT_NOPS_ ## nop_cycles \
    inst $16, $7; \
    nop; \
    bne $0, $30, fail; \
2:  addiu $5, $5, 1; \
    li $6, 2; \
    bne $5, $6, 1b; \
    nop;


