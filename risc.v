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

////////////////////////////////////////////////////////////////////////////////
//
//	RISC CPU with 2-stage pipeline
//
////////////////////////////////////////////////////////////////////////////////

module risc(
  input clk,
  input reset,                  // active high
  input rdy,			// high if we're allowed to finish current inst

  // instruction port
  output [31:2] iaddr,          // address of instruction to be fetched
  input [31:0] inst,            // instruction returning from memory

  // memory port
  output [31:2] maddr,          // address of data word to be accessed
  output mrd,			// read request
  output force_miss,            // force miss on read request
  output mwr,                   // write request
  output [31:0] mdout,          // memory write data
  input [31:0] mdin,		// read data returning from memory

  // interrupt port
  input irq,			// interrupt request, active high
  input [4:0] ivector,		// requested interrupt vector
  output iack			// interrupt acknowledged
);
  parameter BIG_ENDIAN = 1'b1;   // set to 0 for little endian
  parameter OVERFLOW_TRAPS = 1'b0;
  parameter MULDIV = 1'b1;

  wire [31:0] inst_x;	// risc_control
  wire [2:0] pcsel;	// risc_control
  wire [4:0] exccode;	// risc_control
  wire [1:0] asel;	// risc_control
  wire [1:0] bsel;	// risc_control
  wire [7:0] alufn;	// risc_control
  wire [2:0] muldiv;	// risc_control
  wire [1:0] wasel;	// risc_control
  wire [1:0] wbsel;	// risc_control
  wire [1:0] cpsel;	// risc_control
  wire [1:0] cp0;       // risc_control
  wire [1:0] msize;	// risc_control
  wire msxt;		// risc_control
  wire mleft;		// risc_control
  wire mdin_ld;		// risc_control
  wire bsign;		// risc_datapath
  wire bneq;		// risc_datapath
  wire alu_v;		// risc_datapath
  wire muldiv_busy;	// risc_datapath

  risc_control ctl(.clk(clk),.reset(reset),.rdy(rdy),.inst(inst),
                   .bsign(bsign),.bneq(bneq),.alu_v(alu_v),.muldiv_busy(muldiv_busy),
		   .inst_x(inst_x),.advance(advance),
		   .pcsel(pcsel),.exccode(exccode),
		   .asel(asel),.bsel(bsel),.alufn(alufn),.muldiv(muldiv),
		   .wasel(wasel),.wbsel(wbsel),.cpsel(cpsel),.cp0(cp0),
		   .mrd(mrd),.force_miss(force_miss),.mwr(mwr),
                   .msize(msize),.msxt(msxt),.mleft(mleft),.mdin_ld(mdin_ld),
                   .irq(irq),.ivector(ivector),.iack(iack));
  defparam ctl.OVERFLOW_TRAPS = OVERFLOW_TRAPS;
  defparam ctl.MULDIV = MULDIV;

  risc_datapath dp(.clk(clk),.reset(reset),.advance(advance),.inst_x(inst_x),.mdin(mdin),
		   .asel(asel),.bsel(bsel),.alufn(alufn),.muldiv(muldiv),
		   .pcsel(pcsel),.exccode(exccode),.wasel(wasel),.wbsel(wbsel),
                   .cpsel(cpsel),.cp0(cp0),
		   .msize(msize),.msxt(msxt),.mleft(mleft),.mdin_ld(mdin_ld),
                   .bsign(bsign),.bneq(bneq),.alu_v(alu_v),.muldiv_busy(muldiv_busy),
		   .iaddr(iaddr),.maddr(maddr),.mdout(mdout));
  defparam dp.BIG_ENDIAN = BIG_ENDIAN;
  defparam dp.MULDIV = MULDIV;
endmodule

////////////////////////////////////////////////////////////////////////////////
//
//	Control logic
//
////////////////////////////////////////////////////////////////////////////////

module risc_control(
  input clk,
  input reset,
  input rdy,
  input [31:0] inst,
  input bsign,
  input bneq,
  input alu_v,
  input muldiv_busy,
  output reg [31:0] inst_x,
  output advance,
  output [2:0] pcsel,
  output [4:0] exccode,
  output [1:0] asel,
  output [1:0] bsel,
  output [7:0] alufn,
  output [2:0] muldiv,
  output [1:0] wasel,
  output [1:0] wbsel,
  output [1:0] cpsel,
  output [1:0] cp0,
  output mrd,
  output force_miss,
  output mwr,
  output [1:0] msize,
  output msxt,
  output mleft,
  output mdin_ld,
  input irq,
  input [4:0] ivector,
  output iack
);
  parameter OVERFLOW_TRAPS = 1'b0;
  parameter MULDIV = 1'b1;

  `include "risc.h"

  reg [2:0] d_pcsel;   // pc select
  reg [2:0] d_branch;  // branch decision
  reg [4:0] d_exccode; // exception code
  reg d_annul_next;    // annul next instruction
  reg [1:0] d_asel;    // A operand select
  reg [1:0] d_bsel;    // B operand select
  reg [1:0] d_unit;    // ALU unit select
  reg d_addsub;        // adder control
  reg d_slt;           // slt control
  reg [1:0] d_boole;   // boolean control
  reg [1:0] d_shift;   // shifter control
  reg d_checkv;        // trap if arithmetic overflow
  reg [2:0] d_muldiv;  // MUL/DIV control
  reg [1:0] d_wasel;   // writeback address select
  reg [1:0] d_wbsel;   // writeback data select
  reg [1:0] d_cpsel;   // coproc data select
  reg [1:0] d_mem;     // memory operation
  reg [1:0] d_msize;   // memory data size
  reg d_msxt;	       // memory data sign extension
  reg d_mleft;	       // memory load word left/right
  reg d_mdin_ld;       // load enable for saved_mdin register
  reg [1:0] d_cp0;     // action for cp0

  // execution FSM
  reg [1:0] next_state,state;
  localparam s_cycle1 = 2'd0;
  localparam s_cycle2 = 2'd1;
  localparam s_cycle3 = 2'd2;
  always @(posedge clk) state <= reset ? s_cycle1 : next_state;

  // instruction register
  always @(posedge clk) begin
    if (reset) inst_x <= 32'h00000000;
    else if (advance) inst_x <= d_annul_next ? 32'h00000000 : inst;
  end

  always @(*) begin
    // default values
    d_mem = mem_none;
    d_checkv = checkv_no;
    d_muldiv = muldiv_none;
    d_slt = slt_slt;   // ensure adder behaves
    d_mdin_ld = 1'b0;
    next_state = s_cycle1;
    
    d_pcsel = pc_x;
    d_branch = br_x;
    d_exccode = exc_x;
    d_annul_next = 1'b0;
    d_asel = a_x;
    d_bsel = b_x;
    d_unit = unit_x;
    d_addsub = addsub_x;
    d_boole = boole_x;
    d_shift = shift_x;
    d_wasel = wa_x;
    d_wbsel = wb_x;
    d_cpsel = cpsel_x;
    d_cp0 = cp0_none;
    d_msize = msize_x;
    d_msxt = msxt_x;
    d_mleft = mleft_x;

    // opcode decode
    casez (inst_x[31:26])
      6'b000000:      // special
        casez (inst_x[5:0])
          6'b000?01:  // reserved (shadows next pattern)
	    begin
	      d_pcsel = pc_exception; d_exccode = exc_reserved;
	      d_wasel = wa_0;
	    end
          6'b000???:  // SLL, ???, SRL, SRA, SLLV, ???, SRLV, SRAV
	    begin
	      d_pcsel = pc_inc;
	      d_asel = inst_x[2] ? a_rs : a_shamt;
              d_bsel = b_rt;
	      d_unit = unit_shifter;
              case (inst_x[1:0])
                2'b00: d_shift = shift_ll;    // SLL, SLLV
                2'b10: d_shift = shift_lr;    // SRL, SRLV
                2'b11: d_shift = shift_ar;    // SRA, SRAV
                default: d_shift = shift_x;
              endcase
	      d_wasel = wa_rd; d_wbsel = wb_alu;
	    end
          6'b001000:  // JR
	    begin
	      d_pcsel = pc_jr;
	      d_wasel = wa_0;
	    end
          6'b001001:  // JALR
	    begin
	      d_pcsel = pc_jr;
	      d_wasel = wa_rd; d_wbsel = wb_pcinc;
	    end
          6'b00110?:  // SYSCALL, BREAK
	    begin
	      d_pcsel = pc_exception;
              d_exccode = inst_x[0] ? exc_break : exc_syscall;
	      d_wasel = wa_0;
	      d_annul_next = 1'b1;
	    end
          6'b0100?0:  // MFHI, MFLO
	    begin
              d_pcsel = pc_inc;
	      d_wasel = wa_rd;
              d_wbsel = wb_cpin;
              d_cpsel = inst_x[1] ? cpsel_lo : cpsel_hi;
	      next_state = muldiv_busy ? s_cycle2 : s_cycle1;
	    end
          6'b0100?1:  // MTHI, MTLO
	    begin
              d_pcsel = pc_inc;
	      d_wasel = wa_0;
              d_muldiv = inst_x[1] ? muldiv_mtlo : muldiv_mthi;
	    end
          6'b0110??:  // MULT,MULTU,DIV,DIVU
	    if (MULDIV) begin
              d_pcsel = pc_inc;
	      d_wasel = wa_0;
	      case (inst_x[1:0])
                2'b00: d_muldiv = muldiv_mult;
                2'b01: d_muldiv = muldiv_multu;
                2'b10: d_muldiv = muldiv_div;
                2'b11: d_muldiv = muldiv_divu;
                default: d_muldiv = 2'bxx;
              endcase
	    end
            else begin  // reserved instruction
	      d_pcsel = pc_exception; d_exccode = exc_reserved;
	      d_wasel = wa_0;
	      d_annul_next = 1'b1;
	    end
          6'b1000??:  // ADD, ADDU, SUB, SUBU
	    begin
              d_pcsel = pc_inc;
	      d_asel = a_rs; d_bsel = b_rt;
	      d_unit = unit_addsub;
              d_addsub = inst_x[1] ? addsub_sub : addsub_add;
	      if (OVERFLOW_TRAPS && inst_x[0]==1'b0) begin
	        d_checkv = checkv_yes;
                d_exccode = exc_ov;
              end
	      d_wasel = wa_rd; d_wbsel = wb_alu;
	    end
          6'b1001??:  // AND, OR, XOR, NOR
	    begin
	      d_pcsel = pc_inc;
	      d_asel = a_rs; d_bsel = b_rt;
	      d_unit = unit_boolean;
              case (inst_x[1:0])
                2'b00: d_boole = boole_and;
                2'b01: d_boole = boole_or;
                2'b10: d_boole = boole_xor;
                2'b11: d_boole = boole_nor;
                default: d_boole = boole_x;
              endcase
	      d_wasel = wa_rd; d_wbsel = wb_alu;
	    end
          6'b10101?:  // SLT, SLTU
	    begin
	      d_pcsel = pc_inc;
	      d_asel = a_rs; d_bsel = b_rt;
	      d_unit = unit_slt;
	      d_slt = inst_x[0] ? slt_sltu : slt_slt;
              d_addsub = addsub_sub;
	      d_wasel = wa_rd; d_wbsel = wb_alu;
	    end
          default:    // reserved instruction
	    begin
	      d_pcsel = pc_exception; d_exccode = exc_reserved;
	      d_wasel = wa_0;
	      d_annul_next = 1'b1;
	    end
        endcase
      6'b000001:
        casez (inst_x[20:16])
          5'b?000?:  // BLTZ, BGEZ, BLTZAL, BGEZAL
	    begin
	      d_pcsel = pc_br;
              d_branch = inst_x[16] ? br_bgez : br_bltz;
	      d_wasel = inst_x[20] ? wa_31 : wa_0;
	    end
          default:    // reserved instruction
	    begin
	      d_pcsel = pc_exception; d_exccode = exc_reserved;
	      d_wasel = wa_0;
	      d_annul_next = 1'b1;
	    end
        endcase
      6'b000010:      // J
	begin
	  d_pcsel = pc_jump;
	  d_wasel = wa_0;
        end
      6'b000011:      // JAL
	begin
	  d_pcsel = pc_jump;
	  d_wasel = wa_31; d_wbsel = wb_pcinc;
	end
      6'b0001??:      // BEQ, BNE, BLEZ, BGTZ
	begin
	  d_pcsel = pc_br;
          case (inst_x[27:26])
            2'b00: d_branch = br_beq;
            2'b01: d_branch = br_bneq;
            2'b10: d_branch = br_blez;
            2'b11: d_branch = br_bgtz;
            default: d_branch = br_x;
          endcase
	  d_wasel = wa_0;
	end
      6'b00100?:      // ADDI, ADDIU
        begin
	  d_pcsel = pc_inc;
	  d_asel = a_rs; d_bsel = b_sxtimm;
	  d_unit = unit_addsub; d_addsub = addsub_add;
          if (OVERFLOW_TRAPS && inst_x[0] == 0) begin
	    d_checkv = checkv_yes;
            d_exccode = exc_ov;
          end
	  d_wasel = wa_rt; d_wbsel = wb_alu;
	end
      6'b00101?:      // SLTI, SLTIU
	begin
	  d_pcsel = pc_inc;
	  d_asel = a_rs; d_bsel = b_sxtimm;
	  d_unit = unit_slt;
          d_slt = inst_x[26] ? slt_sltu : slt_slt;
          d_addsub = addsub_sub;
          d_wasel = wa_rt; d_wbsel = wb_alu;
	end
      6'b001111:      // LUI
	begin
	  d_pcsel = pc_inc;
	  d_asel = a_16; d_bsel = b_imm;
	  d_unit = unit_shifter; d_shift = shift_ll;
	  d_wasel = wa_rt; d_wbsel = wb_alu;
	end
      6'b0011??:      // ANDI, ORI, XORI
	begin
	  d_pcsel = pc_inc;
	  d_asel = a_rs; d_bsel = b_imm;
	  d_unit = unit_boolean;
          case (inst_x[27:26])
            2'b00: d_boole = boole_and;
            2'b01: d_boole = boole_or;
            2'b10: d_boole = boole_xor;
            default: d_boole = boole_x;
          endcase
	  d_wasel = wa_rt; d_wbsel = wb_alu;
	end
      6'b010000:      // COP0
        casez (inst_x[25:21])
          5'b00000:   // MFC0
	    begin
	      d_pcsel = pc_inc;
	      d_wasel = wa_rt; d_wbsel = wb_cpin; d_cpsel = cpsel_cpin;
            end
          5'b00100:   // MTC0
	    begin
	      d_pcsel = pc_inc;
	      d_wasel = wa_0;
	      d_cp0 = cp0_mtc0;
            end
          5'b10000:   // RFE
	    begin
	      d_pcsel = pc_inc;
	      d_wasel = wa_0;
	      d_cp0 = cp0_rfe;
            end
          default:    // reserved instruction
	    begin
	      d_pcsel = pc_exception; d_exccode = exc_reserved;
	      d_wasel = wa_0;
	      d_annul_next = 1'b1;
	    end
        endcase
      6'b100???:      // LB, LH, LWL, LW, LBU, LHU, LWR, LWMISS/LWU
	begin
	  d_pcsel = pc_inc;
	  d_asel = a_rs; d_bsel = b_sxtimm;
	  d_unit = unit_addsub; d_addsub = addsub_add;
	  d_mem = (inst_x[28:26] == 3'b111) ? mem_read_miss : mem_read;
          d_msxt = inst_x[28] ? msxt_unsigned : msxt_signed;
          case (inst_x[27:26])
            2'b00: d_msize = msize_b;
            2'b01: d_msize = msize_h; 
            2'b10: begin
                     d_msize = msize_lwx;
                     d_mleft = inst_x[28] ? mleft_right : mleft_left;
                   end
            2'b11: d_msize = msize_w;
            default: d_msize = msize_x;
          endcase
	  d_wasel = wa_rt; d_wbsel = wb_mdin;
        end
      6'b101011:      // SW
	begin
	  d_pcsel = pc_inc;
	  d_asel = a_rs; d_bsel = b_sxtimm;
	  d_addsub = addsub_add;
	  d_mem = mem_write; d_msize = msize_w;
	  d_wasel = wa_0;
        end
      6'b10100?:      // SB, SH
	begin
	  d_pcsel = pc_inc;
	  d_asel = a_rs; d_bsel = b_sxtimm;
	  d_addsub = addsub_add;
          d_msize = inst_x[26] ? msize_h : msize_b;
	  d_wasel = wa_0;
          case (state)
            s_cycle1:      // start read/modify/write of memory location
              begin
                next_state = s_cycle2;
                d_mem = mem_read;
                d_mdin_ld = 1'b1;
              end
            s_cycle2:  // wait for read to finish
              begin
                next_state = rdy ? s_cycle3 : s_cycle2;
                d_mem = mem_read;
                d_mdin_ld = 1'b1;
              end
            s_cycle3:  // write out modified result
              begin
	        next_state = rdy ? s_cycle1 : s_cycle3;
                d_mem = mem_write;
              end
	    default:       // oops! shouldn't get here
	      begin
	        next_state = s_cycle1;
                d_mem = mem_none;
               end
	  endcase
        end
      6'b101?10:      // SWL, SWR
	begin
	  d_pcsel = pc_inc;
	  d_asel = a_rs; d_bsel = b_sxtimm;
	  d_addsub = addsub_add;
	  d_msize = msize_lwx;
	  d_mleft = inst_x[28] ? mleft_right : mleft_left;
	  d_wasel = wa_0;
          case (state)
            s_cycle1:      // start read/modify/write of memory location
              begin
                next_state = s_cycle2;
                d_mem = mem_read;
                d_mdin_ld = 1'b1;
              end
            s_cycle2:  // wait for read to finish
              begin
                next_state = rdy ? s_cycle3 : s_cycle2;
                d_mem = mem_read;
                d_mdin_ld = 1'b1;
              end
            s_cycle3:  // write out modified result
              begin
	        next_state = rdy ? s_cycle1 : s_cycle3;
                d_mem = mem_write;
              end
	    default:       // oops! shouldn't get here
	      begin
	        next_state = s_cycle1;
                d_mem = mem_none;
              end
	  endcase
        end
      default:        // reserved instruction
	begin
	  d_pcsel = pc_exception; d_exccode = exc_reserved;
	  d_wasel = wa_0;
	  d_annul_next = 1'b1;
	end
    endcase
  end

  // Branch decision encoded in d_branch[2:0]:
  //  BEQ:  4'b100 (~bneq)
  //  BNE:  4'b000 (bneq)
  //  BLEZ: 4'b110 (~bneq | bsign)
  //  BGTZ: 4'b010 (bneq & ~bsign)
  //  BLTZ: 4'b001 (bsign)
  //  BGEZ: 4'b101 (~bsign)
  reg branch;
  always @(*)
    case (d_branch[1:0])
    2'b00: branch = d_branch[2] ^ bneq;
    2'b01: branch = d_branch[2] ^ bsign;
    2'b10: branch = d_branch[2] ^ (bneq & ~bsign);
    default: branch = 1'bx;
    endcase

  assign advance = rdy && (next_state == s_cycle1);

  assign pcsel = reset ? pc_reset :
		 (d_checkv && alu_v) ? pc_exception :
		 ((d_pcsel == pc_br) && ~branch) ? pc_inc :
		 d_pcsel;

  assign exccode = d_exccode;
  assign asel = d_asel;
  assign bsel = d_bsel;
  assign alufn = {d_unit,d_addsub,d_slt,d_boole,d_shift};
  assign muldiv = d_muldiv;
  assign wasel = reset ? wa_0 : d_wasel;
  assign wbsel = d_wbsel;
  assign cpsel = d_cpsel;
  assign cp0 = d_cp0;
  assign mrd = (d_mem == mem_read) || (d_mem == mem_read_miss);
  assign mwr = (d_mem == mem_write);
  assign force_miss = (d_mem == mem_read_miss);
  assign msize = d_msize;
  assign msxt = d_msxt;
  assign mleft = d_mleft;
  assign mdin_ld = d_mdin_ld;

  assign iack = 1'b0;
endmodule

////////////////////////////////////////////////////////////////////////////////
//
//	Data path
//
////////////////////////////////////////////////////////////////////////////////

module risc_datapath(
  input clk,
  input reset,
  input advance,
  input [31:0] inst_x,
  input [31:0] mdin,
  input [1:0] asel,
  input [1:0] bsel,
  input [7:0] alufn,
  input [2:0] muldiv,
  input [2:0] pcsel,
  input [4:0] exccode,
  input [1:0] wasel,
  input [1:0] wbsel,
  input [1:0] cpsel,
  input [1:0] cp0,
  input [1:0] msize,
  input msxt,
  input mleft,
  input mdin_ld,
  output bsign,
  output bneq,
  output alu_v,
  output muldiv_busy,
  output [31:2] iaddr,
  output [31:2] maddr,
  output reg [31:0] mdout
);
  parameter BIG_ENDIAN = 1'b1;   // set to 0 for little endian
  parameter MULDIV = 1'b1;

  `include "risc.h"

  // register file
  (* ram_style = "distributed" *)
  reg [31:0] regfile[31:0];
  wire [31:0] rs = regfile[inst_x[25:21]];
  wire [31:0] rt = regfile[inst_x[20:16]];

  //for simulation: initialize regfile[0] to 0
  //this happens by default in FPGAs...
  initial begin
    regfile[0] = 0;
  end

  assign bsign = rs[31];
  assign bneq = (rs != rt);

  // operand selection
  reg signed [31:0] a,b;
  always @(*) begin
    case (asel)
      a_rs:    a = rs;
      a_16:    a = {27'b0,5'b10000};
      a_shamt: a = {27'b0,inst_x[10:6]};
      default: a = 32'hXXXXXXXX;
    endcase
    case (bsel)
      b_rt:     b = rt;
      b_imm:    b = {16'b0,inst_x[15:0]};
      b_sxtimm: b = {{16{inst_x[15]}},inst_x[15:0]};
      default:  b = 32'hXXXXXXXX;
    endcase
  end

  // ALU control
  wire [1:0] unit = alufn[7:6];
  wire addsub = alufn[5];
  wire sltu = alufn[4];
  wire [1:0] boole = alufn[3:2];
  wire [1:0] shift = alufn[1:0];

  // adder
  wire [32:0] aext = {~sltu & a[31], a[31:0]};
  wire [32:0] bext = {~sltu & b[31], b[31:0]};
  wire [32:0] sum = addsub ? aext - bext : aext + bext;   // sum[32] is carry
  wire xb31 = addsub ^ b[31];
  assign alu_v = (a[31] & xb31 & ~sum[31]) | (~a[31] & ~xb31 & sum[31]);

  // barrel shifter for left/right/arithmetic-right shifts
  wire left = (shift == 2'b00);
  wire [4:0] shift_amount = a[4:0];
  // a 64 X 32 ROM.  Generates the correct mask based on shiftAmount and direction
  wire [5:0] mindex = {left, shift_amount};
  reg [31:0] mask;
  always @(mindex) begin
    case (mindex)
      6'h00: mask = 32'b11111111111111111111111111111111;
      6'h01: mask = 32'b01111111111111111111111111111111;
      6'h02: mask = 32'b00111111111111111111111111111111;
      6'h03: mask = 32'b00011111111111111111111111111111;
      6'h04: mask = 32'b00001111111111111111111111111111;
      6'h05: mask = 32'b00000111111111111111111111111111;
      6'h06: mask = 32'b00000011111111111111111111111111;
      6'h07: mask = 32'b00000001111111111111111111111111;
      6'h08: mask = 32'b00000000111111111111111111111111;
      6'h09: mask = 32'b00000000011111111111111111111111;
      6'h0A: mask = 32'b00000000001111111111111111111111;
      6'h0B: mask = 32'b00000000000111111111111111111111;
      6'h0C: mask = 32'b00000000000011111111111111111111;
      6'h0D: mask = 32'b00000000000001111111111111111111;
      6'h0E: mask = 32'b00000000000000111111111111111111;
      6'h0F: mask = 32'b00000000000000011111111111111111;
      6'h10: mask = 32'b00000000000000001111111111111111;
      6'h11: mask = 32'b00000000000000000111111111111111;
      6'h12: mask = 32'b00000000000000000011111111111111;
      6'h13: mask = 32'b00000000000000000001111111111111;
      6'h14: mask = 32'b00000000000000000000111111111111;
      6'h15: mask = 32'b00000000000000000000011111111111;
      6'h16: mask = 32'b00000000000000000000001111111111;
      6'h17: mask = 32'b00000000000000000000000111111111;
      6'h18: mask = 32'b00000000000000000000000011111111;
      6'h19: mask = 32'b00000000000000000000000001111111;
      6'h1A: mask = 32'b00000000000000000000000000111111;
      6'h1B: mask = 32'b00000000000000000000000000011111;
      6'h1C: mask = 32'b00000000000000000000000000001111;
      6'h1D: mask = 32'b00000000000000000000000000000111;
      6'h1E: mask = 32'b00000000000000000000000000000011;
      6'h1F: mask = 32'b00000000000000000000000000000001;
      6'h20: mask = 32'b11111111111111111111111111111111;
      6'h21: mask = 32'b11111111111111111111111111111110;
      6'h22: mask = 32'b11111111111111111111111111111100;
      6'h23: mask = 32'b11111111111111111111111111111000;
      6'h24: mask = 32'b11111111111111111111111111110000;
      6'h25: mask = 32'b11111111111111111111111111100000;
      6'h26: mask = 32'b11111111111111111111111111000000;
      6'h27: mask = 32'b11111111111111111111111110000000;
      6'h28: mask = 32'b11111111111111111111111100000000;
      6'h29: mask = 32'b11111111111111111111111000000000;
      6'h2A: mask = 32'b11111111111111111111110000000000;
      6'h2B: mask = 32'b11111111111111111111100000000000;
      6'h2C: mask = 32'b11111111111111111111000000000000;
      6'h2D: mask = 32'b11111111111111111110000000000000;
      6'h2E: mask = 32'b11111111111111111100000000000000;
      6'h2F: mask = 32'b11111111111111111000000000000000;
      6'h30: mask = 32'b11111111111111110000000000000000;
      6'h31: mask = 32'b11111111111111100000000000000000;
      6'h32: mask = 32'b11111111111111000000000000000000;
      6'h33: mask = 32'b11111111111110000000000000000000;
      6'h34: mask = 32'b11111111111100000000000000000000;
      6'h35: mask = 32'b11111111111000000000000000000000;
      6'h36: mask = 32'b11111111110000000000000000000000;
      6'h37: mask = 32'b11111111100000000000000000000000;
      6'h38: mask = 32'b11111111000000000000000000000000;
      6'h39: mask = 32'b11111110000000000000000000000000;
      6'h3A: mask = 32'b11111100000000000000000000000000;
      6'h3B: mask = 32'b11111000000000000000000000000000;
      6'h3C: mask = 32'b11110000000000000000000000000000;
      6'h3D: mask = 32'b11100000000000000000000000000000;
      6'h3E: mask = 32'b11000000000000000000000000000000;
      6'h3F: mask = 32'b10000000000000000000000000000000;
      default: mask = 32'hXXXXXXXX;
    endcase
  end
  wire [31:0] t1,t2,shift_out;
  wire [4:0] n = left ? ((32 - shift_amount) & 5'h1F) : shift_amount;
  wire fill = shift[1] & b[31];   // arithmetic shift & sign bit
  genvar i;
  generate
    for (i = 0; i < 32; i = i+1) begin: rotblock
      assign t1[i] = (n[1] & n[0]) ? b[(i+3)%32] :
                     (n[1] & ~n[0]) ? b[(i+2)%32] :
                     (~n[1] & n[0]) ? b[(i+1)%32] :
                     b[i];
      assign t2[i] = (n[3] & n[2]) ? t1[(i+12)%32] :
                     (n[3] & ~n[2]) ? t1[(i+8)%32] :
                     (~n[3] & n[2]) ? t1[(i+4)%32] :
                     t1[i];
      assign shift_out[i] = (mask[i] & n[4] & t2[(i+16)%32]) |  //shift, no fill
                            (mask[i] & ~n[4] &  t2[i]) |
                            (~mask[i] & fill);                  //shift, do fill
    end
  endgenerate

  // select between ALU subunits
  reg [31:0] alu;
  always @(*)
    case (unit)
      unit_addsub:
        alu = sum[31:0];
      unit_slt:
        alu = {31'd0,sltu ? sum[32] : (sum[31] ^ alu_v)};
      unit_boolean:
        case (boole)
          boole_and: alu = a & b;     // AND
          boole_or:  alu = a | b;     // OR
          boole_xor: alu = a ^ b;     // XOR
          boole_nor: alu = ~(a | b);  // NOR
          default:   alu = 32'hxxxxxxxx;
        endcase
      unit_shifter:
        alu = shift_out;
      default:
        alu = 32'hxxxxxxxx;
    endcase

  // MUL/DIV unit
  wire [31:0] hi,lo;
  generate
    if (MULDIV)
      muldiv_unit md(clk,reset,rs,rt,advance ? muldiv : 3'b000,hi,lo,muldiv_busy);
    else begin
      assign hi = 32'hXXXXXXXX;
      assign lo = 32'hXXXXXXXX;
      assign muldiv_busy = 1'b0;
    end
  endgenerate

  // memory address (synchronous ram)
  assign maddr = sum[31:2];

  // memory write data (synchronous ram)
  reg [31:0] saved_mdin;
  always @(posedge clk) if (mdin_ld) saved_mdin <= mdin;
  always @(*)
    case (msize)
    msize_b:
      if (BIG_ENDIAN)
        begin
          mdout[7:0]   = (sum[1:0] == 2'b11) ? rt[7:0] : saved_mdin[7:0];
          mdout[15:8]  = (sum[1:0] == 2'b10) ? rt[7:0] : saved_mdin[15:8];
          mdout[23:16] = (sum[1:0] == 2'b01) ? rt[7:0] : saved_mdin[23:16];
          mdout[31:24] = (sum[1:0] == 2'b00) ? rt[7:0] : saved_mdin[31:24];
        end
      else
        begin
          mdout[7:0]   = (sum[1:0] == 2'b00) ? rt[7:0] : saved_mdin[7:0];
          mdout[15:8]  = (sum[1:0] == 2'b01) ? rt[7:0] : saved_mdin[15:8];
          mdout[23:16] = (sum[1:0] == 2'b10) ? rt[7:0] : saved_mdin[23:16];
          mdout[31:24] = (sum[1:0] == 2'b11) ? rt[7:0] : saved_mdin[31:24];
        end
    msize_h:
      if (BIG_ENDIAN)
        begin
          mdout[15:0]  = (sum[1] == 1'b1) ? rt[15:0] : saved_mdin[15:0];
          mdout[31:16] = (sum[1] == 1'b0) ? rt[15:0] : saved_mdin[31:16];
        end
      else
        begin
          mdout[15:0]  = (sum[1] == 1'b0) ? rt[15:0] : saved_mdin[15:0];
          mdout[31:16] = (sum[1] == 1'b1) ? rt[15:0] : saved_mdin[31:16];
        end
    msize_w: mdout = rt;
    msize_lwx:    // SWL, SWR
      begin
        if (BIG_ENDIAN)
          case (sum[1:0])
            2'b00: mdout = mleft ? rt : {rt[7:0],saved_mdin[23:0]};
            2'b01: mdout = mleft ? {saved_mdin[31:24],rt[31:8]} : {rt[15:0],saved_mdin[15:0]};
            2'b10: mdout = mleft ? {saved_mdin[31:16],rt[31:16]} : {rt[23:0],saved_mdin[7:0]};
            2'b11: mdout = mleft ? {saved_mdin[31:8],rt[31:24]} : rt;
            default: mdout = 32'hXXXXXXXX;
          endcase
        else
          case (sum[1:0])
            2'b00: mdout = mleft ? {saved_mdin[31:8],rt[31:24]} : rt;
            2'b01: mdout = mleft ? {saved_mdin[31:16],rt[31:16]} : {rt[23:0],saved_mdin[7:0]};
            2'b10: mdout = mleft ? {saved_mdin[31:24],rt[31:8]} : {rt[15:0],saved_mdin[15:0]};
            2'b11: mdout = mleft ? rt : {rt[7:0],saved_mdin[23:0]};
            default: mdout = 32'hXXXXXXXX;
          endcase
      end
    default: mdout = 32'hXXXXXXXX;
    endcase

  // pc logic
  reg [31:0] pc_f,pc_next,pc_exe,epc;
  wire [31:0] pc_f_4 = pc_f + 4;  // also used by link instructions
  always @(*)
    case (pcsel)
      pc_inc:       pc_next = pc_f_4;                     // normal execution
      pc_br:        pc_next = {{14{inst_x[15]}},inst_x[15:0],2'b0} + pc_f; // branch
      pc_jump:      pc_next = {pc_f_4[31:28],inst_x[25:0],2'b0};     // jump
      pc_jr:        pc_next = rs;                         // jr
      pc_reset:     pc_next = 32'h00000000;               // reset
      pc_exception: pc_next = {24'h000000,exccode,3'b000};     // exception
      default:      pc_next = 32'hXXXXXXXX;
    endcase
  always @(posedge clk)
    begin
      if (advance) pc_exe <= pc_f;
      if (advance || reset) pc_f <= pc_next;
      if (advance) epc <= (pcsel == pc_exception || reset) ? pc_exe :
                          (cp0 == cp0_mtc0 && inst_x[15:11] == cp0reg_epc) ? rt :
			  epc;
    end

  assign iaddr = (advance || reset) ? pc_next[31:2] : pc_f[31:2];  // synchronous ram

  // LD result
  reg [31:0] mdata;
  always @(*)
    case (msize)
    msize_b:
      begin
        if (BIG_ENDIAN)
	  case (sum[1:0])  // big endian
            2'b00: mdata[7:0] = mdin[31:24];
	    2'b01: mdata[7:0] = mdin[23:16];
	    2'b10: mdata[7:0] = mdin[15:8];
	    2'b11: mdata[7:0] = mdin[7:0];
            default: mdata[7:0] = 8'hXX;
          endcase
	else
	  case (sum[1:0])  // little endian
            2'b00: mdata[7:0] = mdin[7:0];
	    2'b01: mdata[7:0] = mdin[15:8];
	    2'b10: mdata[7:0] = mdin[23:16];
	    2'b11: mdata[7:0] = mdin[31:24];
            default: mdata[7:0] = 8'hXX;
          endcase
        mdata[31:8] = {24{msxt ? mdata[7] : 1'b0}};
      end
    msize_h:
      begin
        if (BIG_ENDIAN)
	  mdata[15:0] = sum[1] ? mdin[15:0] : mdin[31:16];
	else
	  mdata[15:0] = sum[1] ? mdin[31:16] : mdin[15:0];
        mdata[31:16] = {16{msxt ? mdata[15] : 1'b0}};
      end
    msize_w: mdata = mdin;
    msize_lwx:    // LWL, LWR
      begin
        if (BIG_ENDIAN)
          case (sum[1:0])
            2'b00: mdata = mleft ? mdin : {rt[31:8],mdin[31:24]};
            2'b01: mdata = mleft ? {mdin[23:0],rt[7:0]} : {rt[31:16],mdin[31:16]};
            2'b10: mdata = mleft ? {mdin[15:0],rt[15:0]} : {rt[31:24],mdin[31:8]};
            2'b11: mdata = mleft ? {mdin[7:0],rt[23:0]} : mdin;
            default: mdata = 32'hXXXXXXXX;
          endcase
        else
          case (sum[1:0])
            2'b00: mdata = mleft ? {mdin[7:0],rt[23:0]} : mdin;
            2'b01: mdata = mleft ? {mdin[15:0],rt[15:0]} : {rt[31:24],mdin[31:8]};
            2'b10: mdata = mleft ? {mdin[23:0],rt[7:0]} : {rt[31:16],mdin[31:16]};
            2'b11: mdata = mleft ? mdin : {rt[31:8],mdin[31:24]};
            default: mdata = 32'hXXXXXXXX;
          endcase
      end
    default: mdata = 32'hXXXXXXXX;
    endcase

  // coproc 0 registers
  reg [31:0] cpin;
  always @(*) case (inst_x[15:11])
    cp0reg_status:  cpin = 32'hXXXXXXXX;          // status
    cp0reg_epc:     cpin = epc;                   // exception pc
    default:        cpin = 32'hXXXXXXXX;
  endcase

  // regfile writeback
  reg [4:0] wa;
  always @(*)
    case (wasel)
      wa_rt: wa = inst_x[20:16];  // RT
      wa_rd: wa = inst_x[15:11];  // RD
      wa_31: wa = 5'd31;          // $31
      wa_0:  wa = 5'd0;           // $0
      default: wa = 5'bxxxxx;
    endcase
  reg [31:0] wdata;
  always @(*)
    case (wbsel)
      wb_pcinc: wdata = pc_f_4;   // link instructions
      wb_alu:   wdata = alu;
      wb_mdin:  wdata = mdata;
      wb_cpin:
        case (cpsel)
          cpsel_lo:   wdata = lo;
          cpsel_hi:   wdata = hi;
          cpsel_cpin: wdata = cpin;
          default:    wdata = 32'hXXXXXXXX;
        endcase
      default: wdata = 32'hXXXXXXXX;
    endcase
  always @(posedge clk)
    if (advance & wa != 0) regfile[wa] <= wdata;
endmodule

////////////////////////////////////////////////////////////////////////////////
//
//	Multiply/divide unit
//
////////////////////////////////////////////////////////////////////////////////

// home of the HI and LO registers
// op:
//  3'b000 -- no operation
//  3'b010 -- MTLO
//  3'b011 -- MTHI
//  3'b100 -- MULT
//  3'b101 -- MULTU
//  3'b110 -- DIV
//  3'b111 -- DIVU
module  muldiv_unit(
  input clk,
  input reset,
  input [31:0] rs,
  input [31:0] rt,
  input [2:0] op,
  output reg [31:0] hi,
  output reg [31:0] lo,
  output busy
);

  reg [2:0] state;
  localparam s_idle = 3'b000;
  localparam s_mult = 3'b001;
  localparam s_divu = 3'b010;
  localparam s_div1 = 3'b011;
  localparam s_div2 = 3'b100;
  localparam s_div3 = 3'b101;
  localparam s_div4 = 3'b110;
  localparam s_div5 = 3'b111;

  reg [31:0] a,b,next_hi,next_lo,neg_in,neg_out;
  reg [63:0] p,next_p;
  reg unsigned_flag;
  reg [4:0] counter;
  reg dividend_sign,divisor_sign;

  // state machine, initialization
  always @(posedge clk) begin
    if (reset)
      state <= s_idle;
    else if (op != 3'b000) begin    // new instruction arriving...
      if (op[2]) begin
        if (op[1]) begin  // div
          state <= op[0] ? s_divu : s_div1;
	  counter <= 5'd31;
        end
        else begin        // mul
	  state <= s_mult;
          counter <= 5'd4;
        end
	dividend_sign <= rs[31];
	divisor_sign <= rt[31];
        a <= rs;
        b <= rt;
        unsigned_flag <= op[0];
	p <= {32'h0, rs[31:0]};
      end
      else if (op[1]) begin
        state <= s_idle;   // MTLO, MTHI abort running operation
        if (op[0] == 1'b0) lo <= rs;
        else hi <= rs;
      end
    end
    else if (state != s_idle) begin
       case (state)
       s_div1:    // check divisor sign
         begin
           state <= s_div2;
	   if (divisor_sign) b <= neg_out;
         end
       s_div2:    // check dividend sign
         begin
           state <= s_div3;
	   if (dividend_sign) p[31:0] <= neg_out;
	 end
       s_div4:    // correct quotient sign
         begin
           state <= s_div5;
	   if (dividend_sign ^ divisor_sign) p[31:0] <= neg_out;
         end
       s_div5:    // correct remainder sign (make it same as dividend)
         begin
           state <= s_idle;
	   lo <= p[31:0];
	   hi <= (dividend_sign & ~divisor_sign) ? neg_out : p[63:32];
         end
       default:   // noodle away until counter expires
         begin
           hi <= next_hi;
           lo <= next_lo;
           p <= next_p;
           if (counter == 0) state <= (state == s_div3) ? s_div4 : s_idle;
	   else counter <= counter - 1;
         end
       endcase
    end
  end

  // multiplier is a little 2-stage pipeline:
  //   first stage is an 18x18 signed multiply
  //   second stage is a 48-bit addition
  // here's what happens on successive cycles:
  //   product = alo * blo, sum = ???
  //   product = ahi * blo, sum = ??? (LO is loaded with alo*blo)
  //   product = alo * bhi, sum = sxt(product) + {HI,LO[31:15]}
  //   product = ahi * bhi, sum = sxt(product) + {HI,LO[31:15]}
  //   product = ???, sum =  (product<<16) + {HI,LO[31:15]}
  wire aextend = unsigned_flag ? 0 : a[31];
  wire bextend = unsigned_flag ? 0 : b[31];
  reg signed [17:0] mop1,mop2;   // the two signed 18-bit multiplier operands
  always @(*)
    case (counter)
    5'd4:   // first cycle
      begin
        mop1 = {2'b00, a[15:0]};   // low half of A
        mop2 = {2'b00, b[15:0]};   // low half of B
      end
    5'd3:   // second cycle
      begin
        mop1 = {aextend, aextend, a[31:16]};   // high half of A
        mop2 = {2'b00, b[15:0]};   // low half of B
      end
    5'd2:   // third cycle
      begin
        mop1 = {2'b00, a[15:0]};   // low half of A
        mop2 = {bextend, bextend, b[31:16]};   // high half of B
      end
    5'd1:   // fourth cycle
      begin
        mop1 = {aextend, aextend, a[31:16]};   // high half of A
        mop2 = {bextend, bextend, b[31:16]};   // low half of B
      end
    default:
      begin
        mop1 = 32'hXXXXXXXX;
        mop2 = 32'hXXXXXXXX;
      end
    endcase
  reg signed [35:0] product;
  always @(posedge clk) product <= mop1 * mop2;    // 18x18 signed multiply
  wire [47:0] pp = (counter == 0) ? {product[31:0],16'b0} :
                                    {{12{product[35]}},product[35:0]};
  wire [47:0] sum = pp + {hi[31:0],lo[31:16]};

  // negater used to fix up operands/results during signed division
  always @(*) begin
    neg_in = 32'hXXXXXXXX;
    case (state)
    s_div1: neg_in = b;
    s_div2: neg_in = p[31:0];
    s_div4: neg_in = p[31:0];
    s_div5: neg_in = p[63:32];
    endcase
    neg_out = 32'h0 - neg_in;
  end
  
  // unsigned restoring divider
  wire [32:0] difference = p[63:31] - {1'b0, b[31:0]};
  always @(*) begin
    // we perform the "restore" by simply not updating p if the difference
    // was negative.  The left shift always happens...
    next_p = difference[32] ? {p[62:0],1'b0} : {difference[31:0],p[30:0],1'b1};
  end

  // update HI/LO regs
  always @(*) begin
    next_lo = 32'hXXXXXXXX; 
    next_hi = 32'hXXXXXXXX; 
    if (state == s_mult)
      case (counter)
      5'd3:   // second cycle
        begin
          next_lo = product[31:0];
          next_hi = 0;
        end
      5'd2:   // third cycle
        begin
          next_lo = {sum[15:0], lo[15:0]};
          next_hi = sum[47:16];
        end
      5'd1:   // fourth cycle
        begin
          next_lo = {sum[15:0], lo[15:0]};
          next_hi = sum[47:16];
        end
      5'd0:   // fifth cycle
        begin
          next_lo = {sum[15:0], lo[15:0]};
          next_hi = sum[47:16];
        end
      endcase
    else if (state == s_divu && counter == 0) begin
      next_lo = next_p[31:0];
      next_hi = next_p[63:32];
    end
      
  end

  assign busy = (state != s_idle);
endmodule
