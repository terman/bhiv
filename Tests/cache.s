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

done:	ld $30,-4($0)
	addiu $30,$30,1
	sw $30,-4($0)
	j done
	nop

array:
