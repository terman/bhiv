        .text
_start:	
	j start
exception:
	j exception
fail:
	j fail

start:        
        
# smipsv1_bne.S
	
        # Test 1: Taken?

        addiu $2, $0, 1
        addiu $3, $0, 2
        bne   $2, $3, 1f
        bne   $0, $2, fail
1:

        # Test 2: Not taken?

        addiu $2, $0, 1
        addiu $3, $0, 1
        bne   $2, $3, fail

# smipsv1_addiu.S
		
        # Test 1: 1 + 1 = 2

        addiu $2, $0, 1
        addiu $3, $2, 1
        addiu $4, $0, 2
        bne   $4, $3, fail
	
        # Test 2: 0x0fff + 0x0001 = 0x1000

        addiu $2, $0, 0x0fff
        addiu $3, $2, 0x0001
        addiu $4, $0, 0x1000
        bne   $4, $3, fail

        # Test 3: 0xffff + 0x0001 = 0x0000

        addiu $2, $0, 0xffff
        addiu $3, $2, 0x0001
        bne   $0, $3, fail

# smipsv1_lw.S
	
        # Test 1: Load some data

        addiu $2, $0, %lo(lw_tdat)

        lw    $3, 0($2)
        addiu $4, $0, 0x00ff
        bne   $4, $3, fail
        
        lw    $3, 4($2)
        addiu $4, $0, 0x7f00
        bne   $4, $3, fail
        
        lw    $3, 8($2)
        addiu $4, $0, 0x0ff0
        bne   $4, $3, fail
        
        lw    $3, 12($2)
        addiu $4, $0, 0x700f
        bne   $4, $3, fail

        # Test 2: Load some data with negative offsets

        addiu $2, $0, %lo(lw_tdat4)

        lw    $3, -12($2)
        addiu $4, $0, 0x00ff
        bne   $4, $3, fail
        
        lw    $3, -8($2)
        addiu $4, $0, 0x7f00
        bne   $4, $3, fail
        
        lw    $3, -4($2)
        addiu $4, $0, 0x0ff0
        bne   $4, $3, fail
        
        lw    $3, 0($2)
        addiu $4, $0, 0x700f
        bne   $4, $3, fail
                
        .data
lw_tdat:
lw_tdat1:  .word 0x000000ff
lw_tdat2:  .word 0x00007f00        
lw_tdat3:  .word 0x00000ff0
lw_tdat4:  .word 0x0000700f
	.text
	
# smipsv1_sw.S
		
        # Test 1: Store then load some data

        addiu $2, $0, %lo(sw_tdat)

        addiu $3, $0, 0x00ff
        sw    $3, 0($2)
        lw    $4, 0($2)
        bne   $4, $3, fail

        addiu $3, $0, 0x7f00
        sw    $3, 4($2)
        lw    $4, 4($2)
        bne   $4, $3, fail        
                
        addiu $3, $0, 0x0ff0
        sw    $3, 8($2)
        lw    $4, 8($2)
        bne   $4, $3, fail
        
        addiu $3, $0, 0x700f
        sw    $3, 12($2)
        lw    $4, 12($2)
        bne   $4, $3, fail        
        
        # Test 2: Store then load some data (negative offsets)

        addiu $2, $0, %lo(sw_tdat8)        

        addiu $3, $0, 0x00ff
        sw    $3, -12($2)
        lw    $4, -12($2)
        bne   $4, $3, fail

        addiu $3, $0, 0x7f00
        sw    $3, -8($2)
        lw    $4, -8($2)
        bne   $4, $3, fail        
                
        addiu $3, $0, 0x0ff0
        sw    $3, -4($2)
        lw    $4, -4($2)
        bne   $4, $3, fail
        
        addiu $3, $0, 0x700f
        sw    $3, 0($2)
        lw    $4, 0($2)
        bne   $4, $3, fail        
                                        
        .data
sw_tdat:
sw_tdat1:  .word 0xdeadbeef
sw_tdat2:  .word 0xdeadbeef        
sw_tdat3:  .word 0xdeadbeef
sw_tdat4:  .word 0xdeadbeef
sw_tdat5:  .word 0xdeadbeef
sw_tdat6:  .word 0xdeadbeef        
sw_tdat7:  .word 0xdeadbeef
sw_tdat8:  .word 0xdeadbeef        
	.text

        # If we get here then we passed

1:	b 1b
