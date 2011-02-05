	.file	1 "mul.c"
	.section .mdebug.abi32
	.previous
	.text
	.align	2
	.globl	mul
	.ent	mul
mul:
	.frame	$sp,0,$31		# vars= 0, regs= 0/0, args= 0, gp= 0
	.mask	0x00000000,0
	.fmask	0x00000000,0
	.set	noreorder
	.set	nomacro
	
	mult	$4,$5
	mflo	$2
	j	$31
	nop

	.set	macro
	.set	reorder
	.end	mul
