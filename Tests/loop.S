        .text
_start:	
	j start
exception:
	j exception
fail:
	j fail

start:        
	li $2,2
	li $3,3
	addiu $2,$2,1
	bne $2,$3,fail
	b next1

. = 0x1018
next1:		
	li $4,4
	li $5,5
	addiu $4,$4,1
	bne $4,$5,fail
	b start

. = 0x2018
next2:		
	li $6,6
	li $7,7
	addiu $6,$6,1
	bne $6,$7,fail
	b start
