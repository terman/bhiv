// -*- mode: Verilog; -*-

/*
Copyright (C) 2011 by Christopher Terman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// values for control signals

// pc select
localparam pc_x = 3'bxxx;
localparam pc_inc = 3'b000;
localparam pc_br = 3'b001;
localparam pc_jump = 3'b010;
localparam pc_jr = 3'b011;
localparam pc_reset = 3'b100;
localparam pc_exception = 3'b101;

// branch decision
localparam br_x = 3'bxxx;
localparam br_beq = 3'b100;
localparam br_bneq = 3'b000;
localparam br_blez = 3'b110;
localparam br_bgtz = 3'b010;
localparam br_bltz = 3'b001;
localparam br_bgez = 3'b101;

// exception code
localparam exc_x = 5'bxxxxx;
localparam exc_reserved = 5'd1;
localparam exc_ov = 5'd2;
localparam exc_syscall = 5'd3;
localparam exc_break = 5'd4;

// A operand select
localparam a_x = 2'bxx;
localparam a_rs = 2'b00;
localparam a_16 = 2'b01;
localparam a_shamt = 2'b11;

// B operand select
localparam b_x = 2'bxx;
localparam b_rt = 2'b00;
localparam b_imm = 2'b01;
localparam b_sxtimm = 2'b11;

// ALU unit select
localparam unit_x = 2'bxx;
localparam unit_addsub = 2'b00;
localparam unit_slt = 2'b01;
localparam unit_boolean = 2'b10;
localparam unit_shifter = 2'b11;

// adder control
localparam addsub_x = 1'bx;
localparam addsub_add = 1'b0;
localparam addsub_sub = 1'b1;

// slt control
localparam slt_x = 1'bx;
localparam slt_slt = 1'b0;
localparam slt_sltu = 1'b1;

// boolean control
localparam boole_x = 2'bxx;
localparam boole_and = 2'b00;
localparam boole_or = 2'b01;
localparam boole_xor = 2'b10;
localparam boole_nor = 2'b11;

// shifter control
localparam shift_x = 2'bxx;
localparam shift_ll = 2'b00;
localparam shift_lr = 2'b01;
localparam shift_ar = 2'b10;

// trap if arithmetic overflow
localparam checkv_x = 1'bx;
localparam checkv_no = 1'b0;
localparam checkv_yes = 1'b1;

// MUL/DIV control
localparam muldiv_x = 3'bxxx;
localparam muldiv_none = 3'b000;
localparam muldiv_mtlo = 3'b010;
localparam muldiv_mthi = 3'b011;
localparam muldiv_mult = 3'b100;
localparam muldiv_multu = 3'b101;
localparam muldiv_div = 3'b110;
localparam muldiv_divu = 3'b111;

// writeback address select
localparam wa_x = 2'bxx;
localparam wa_rt = 2'b00;
localparam wa_rd = 2'b01;
localparam wa_31 = 2'b10;
localparam wa_0 = 2'b11;

// writeback data select
localparam wb_x = 2'bxx;
localparam wb_pcinc = 2'b00;
localparam wb_alu = 2'b01;
localparam wb_mdin = 2'b10;
localparam wb_cpin = 2'b11;

// coproc data select
localparam cpsel_x = 2'bxx;
localparam cpsel_lo = 2'b00;
localparam cpsel_hi = 2'b01;
localparam cpsel_cpin = 2'b10;

// coproc 0 operation
localparam cp0_none = 2'b00;
localparam cp0_mtc0 = 2'b01;
localparam cp0_rfe = 2'b10;

// coproc 0 register numbers
localparam cp0reg_status = 5'b00000;
localparam cp0reg_epc = 5'b00001;
localparam cp0reg_cyclelo = 5'b00010;
localparam cp0reg_cyclehi = 5'b00011;

// memory operation
localparam mem_x = 2'bxx;
localparam mem_none = 2'b00;
localparam mem_read = 2'b01;
localparam mem_write = 2'b10;
localparam mem_read_miss = 2'b11;

// memory data size
localparam msize_x = 2'bxx;
localparam msize_b = 2'b00;
localparam msize_h = 2'b01;
localparam msize_w = 2'b10;
localparam msize_lwx = 2'b11;

// memory data sign extension
localparam msxt_x = 1'bx;
localparam msxt_unsigned = 1'b0;
localparam msxt_signed = 1'b1;

// memory load word left/right
localparam mleft_x = 1'bx;
localparam mleft_right = 1'b0;
localparam mleft_left = 1'b1;
