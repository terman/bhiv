#include "test_macros.h"
	
	.set noreorder

        .text
_start:	
	j start
	nop 
exception:
	lw $30,-4($0)
	j exception
	nop
fail:
	lw $30,-4($0)
	j fail
	nop	
start:        
	la $t1,array
	li $t0,4000
loop:	sw $t0,($t1)
	addu $t1,$t1,4
	subu $t0,$t0,1
	bgt  $t0,0,loop
	nop
	
	la $t1,array
	li $t0,4000
loop2:	lw $t2,($t1)
	bne $t2,$t0,fail
	addu $t1,$t1,4
	subu $t0,$t0,1
	bgt  $t0,0,loop2
	nop

force_miss:
	la $t1,array
	lw $t2,($t1)    # ensure word is in cache
	li $t0,0x1234
	sw $t0,($t1)    # make it dirty, should be a hit
	lwu $t2,($t1)   # should force a writeback, refill
	bne $t2,$t0,fail
	nop

done:	lw $30,-4($0)
	j done
	nop

array:
