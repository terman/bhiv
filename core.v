`timescale 1 ns / 100 ps

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//	CPU + caches
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module core #(parameter CORENUM=1,TSIZE=4,SSIZE=4,NBLINES=7,NBWORDS=3) (
  input clk,
  input reset,
  // ring
  input [TSIZE-1:0] slot_type_in,
  input [SSIZE-1:0] slot_source_in,
  input [31:0] slot_data_in,
  output [TSIZE-1:0] slot_type_out,
  output [SSIZE-1:0] slot_source_out,
  output [31:0] slot_data_out,
  // memory controller port
  input [SSIZE-1:0] mc_dest,
  input [NBWORDS-1:0] mc_count,
  input [31:0] mc_data
);

  wire rdy;
  wire [31:2] iaddr,maddr;
  wire [31:0] inst,mdout,mdin;
  wire mrd,mwr;

  // the CPU itself
  risc cpu(.clk(clk),.reset(reset),.irq(1'b0),.rdy(rdy),
           .iaddr(iaddr),.inst(inst),
           .maddr(maddr),.mrd(mrd),.mwr(mwr),.mdout(mdout),.mdin(mdin));

  // icache
  wire irdy;
  wire i_ring_req,i_ring_ack,i_mc_ack;
  wire [TSIZE-1:0] i_slot_type;
  wire [31:0] i_slot_data;
  cache #(.TSIZE(TSIZE),.NBLINES(NBLINES),.NBWORDS(NBWORDS))
        icache(.clk(clk),.reset(reset),
               .rd(1'b1),.wr(1'b0),.addr(iaddr),.rdata(inst),.wdata(),.rdy(irdy),
               .ring_req(i_ring_req),.slot_type(i_slot_type),.slot_data(i_slot_data),.ring_ack(i_ring_ack),
	       .mc_ack_in(i_mc_ack),.mc_ack_out(),.mc_count(mc_count),.mc_data(mc_data));

  // dcache
  wire drdy;
  wire d_ring_req,d_ring_ack;
  wire [TSIZE-1:0] d_slot_type;
  wire [31:0] d_slot_data;
  cache #(.TSIZE(TSIZE),.NBLINES(NBLINES),.NBWORDS(NBWORDS))
        dcache(.clk(clk),.reset(reset),
               .rd(mrd && !drdy),.wr(mwr && !drdy),.addr(maddr),.rdata(mdin),.wdata(mdout),.rdy(drdy),
               .ring_req(d_ring_req),.slot_type(d_slot_type),.slot_data(d_slot_data),.ring_ack(d_ring_ack),
               .mc_ack_in(mc_dest == CORENUM),.mc_ack_out(i_mc_ack),.mc_count(mc_count),.mc_data(mc_data));

  // allow cpu to proceed when all memory requests are satisfied
  wire mreq = !reset && (mrd || mwr);
  assign rdy = reset || (irdy && (!mreq || drdy));

  // ring interface
  `include "ring.v"

  // nullify any incoming slots that we put on ring
  wire nullify_slot = reset || (slot_source_in == CORENUM);

  // if we have a ring request pending, grab the token when it comes around.
  reg have_token;
  wire ring_req = i_ring_req || d_ring_req;
  wire can_xmit = !reset && ((slot_type_in == TOKEN && ring_req) || have_token);
  always @(posedge clk) have_token <= can_xmit && ring_req;

  // we drive the ring if we're nullifying or filling a slot
  wire drive_ring = can_xmit || nullify_slot;
  assign d_ring_ack = can_xmit && d_ring_req;   // D cache gets priority
  assign i_ring_ack = can_xmit && !d_ring_req && i_ring_req;

  assign slot_source_out = drive_ring ? (ring_req ? CORENUM : 0) :
                           slot_source_in;
  assign slot_type_out = drive_ring ? (d_ring_ack ? d_slot_type :
                                       i_ring_ack ? i_slot_type :
				       have_token ? TOKEN :
				       NULL) :          // nullify slot
                         slot_type_in;
  assign slot_data_out = drive_ring ? (d_ring_ack ? d_slot_data :
                                       i_ring_ack ? i_slot_data :
                                       32'h00000000) :
                         slot_data_in;
endmodule


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//	2-way set-associative cache
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// NBLINES is the number of bits in the cache line index
// NBWORDS is the number of bits in the cache line offset
// TSIZE is the number of bits in the slot type field
module cache #(parameter TSIZE=4,NBLINES=7,NBWORDS=3) (
  input clk,
  input reset,
  // cpu port
  input rd,
  input wr,
  input [31:2] addr,
  output [31:0] rdata,
  input [31:0] wdata,
  output rdy,
  // ring port
  output ring_req,
  output [TSIZE-1:0] slot_type,
  output [31:0] slot_data,
  input ring_ack,
  // memory controller port
  input mc_ack_in,
  output mc_ack_out,
  input [NBWORDS-1:0] mc_count,
  input [31:0] mc_data
);

  localparam NBTOTAL = NBLINES + NBWORDS;
  localparam NLINES = (1 << NBLINES);
  localparam NWORDS = (1 << NBWORDS);

  reg [31:2] saved_addr;
  reg saved_rd,saved_wr;
  always @(posedge clk) begin
    saved_addr <= addr;
    saved_rd <= !reset && rd;
    saved_wr <= !reset && wr;
  end
  wire [29-NBTOTAL:0] tag = saved_addr[31:NBTOTAL+2];
  wire [NBTOTAL-1:0] index = saved_addr[NBTOTAL-1+2:2];
  wire [NBLINES-1:0] line = saved_addr[NBTOTAL-1+2:NBWORDS+2];

  // tags: one per cache line
  (* ram_style = "distributed" *)
  reg [29-NBTOTAL:0] tag0[NLINES-1:0], tag1[NLINES-1:0];

  // valid bit: one per cache line
  (* ram_style = "distributed" *)
  reg valid0[NLINES-1:0], valid1[NLINES-1:0];

  // dirty bit: one per cache line
  (* ram_style = "distributed" *)
  reg dirty0[NLINES-1:0], dirty1[NLINES-1:0];

  // lru indicator: one per cache line
  (* ram_style = "distributed" *)
  reg lru[NLINES-1:0];

  // initialize state bits for simulation
  integer i;
  initial begin
    for (i = 0; i < NLINES; i = i+1) begin
      valid0[i] = 0;
      valid1[i] = 0;
      dirty0[i] = 0;
      dirty1[i] = 0;
      lru[i] = 0;
    end
  end

  // determine if we have requested word in the cache
  wire [29-NBTOTAL:0] way0_tag = tag0[line];
  wire [29-NBTOTAL:0] way1_tag = tag1[line];
  wire v0 = valid0[line];
  wire v1 = valid1[line];
  wire hit0 =  v0 && (way0_tag == tag);
  wire hit1 = v1 && (way1_tag == tag);
  wire miss = (saved_rd || saved_wr) && !hit0 && !hit1;

  reg [2:0] state;
  localparam s_idle = 3'd0;   // cache is idle
  localparam s_read_addr = 3'd1;  // waiting to issue read ADDR slot
  localparam s_mc_data = 3'd2;  // waiting for DATA from mc
  localparam s_write_back = 3'd3;  // waiting to issue WDATA slot
  localparam s_write_addr = 3'd4;  // waiting to issue write ADDR slot

  wire write_mc_data = (state == s_mc_data) && mc_ack_in;
  wire lru_way = lru[line];
  wire refill_write_way0 = write_mc_data && (lru_way == 0);
  wire refill_write_way1 = write_mc_data && (lru_way == 1);
  wire dirty = lru_way ? dirty1[line] : dirty0[line];

  reg [NBWORDS-1:0] wb_count;
  wire [NBWORDS-1:0] wb_count_next = (state == s_idle) ? 0 : (ring_ack ? wb_count+1 : wb_count);
  always @(posedge clk) begin
    if (reset) state <= s_idle;
    else case (state)
      s_idle:       // waiting for a miss
        begin
	  wb_count <= 0;
          if (miss) state <= dirty ? s_write_back : s_read_addr;
        end
      s_write_back: // flush cache line words on dirty miss
        if (ring_ack) begin
          wb_count <= wb_count_next;
          if (wb_count == (NWORDS-1)) state <= s_write_addr;
        end
      s_write_addr: // output write address for dirty cache line
        if (ring_ack) state <= s_read_addr;
      s_read_addr:  // output read address for refill
        if (ring_ack) state <= s_mc_data;
      s_mc_data:    // wait for data from memory controller
        if (mc_ack_in && mc_count == (NWORDS-1)) state <= s_idle;
      default:
        state <= s_idle;
    endcase

    // handle data arriving from memory controller
    if (refill_write_way0 && mc_count == (NWORDS-1)) begin
      tag0[line] <= saved_addr[31:NBTOTAL+2];
      valid0[line] <= 1'b1;
      dirty0[line] <= 1'b0;
    end
    if (refill_write_way1 && mc_count == (NWORDS-1)) begin
      tag1[line] <= saved_addr[31:NBTOTAL+2];
      valid1[line] <= 1'b1;
      dirty1[line] <= 1'b0;
    end

    // handle writes to valid cache lines
    if (saved_wr && hit0) dirty0[line] <= 1'b1;
    if (saved_wr && hit1) dirty1[line] <= 1'b1;
  end

  // cache lines
  wire [31:0] way0_cpu_data,way1_cpu_data;
  wire [31:0] way0_ring_data,way1_ring_data;
  wire [NBTOTAL-1:0] refill_addr = (state == s_mc_data) ? {line,mc_count} : {line,wb_count_next};
  bram #(.WIDTH(32),.NADDR(NBTOTAL))
       way0(.clk(clk),
	    // CPU port
            .addrA(saved_wr ? index : addr[NBTOTAL-1+2:2]),   
	    .weA(saved_wr && hit0),
            .wdataA(wdata),
            .rdataA(way0_cpu_data),
	    // refill port
            .addrB(refill_addr),
	    .weB(refill_write_way0),
            .wdataB(mc_data),
            .rdataB(way0_ring_data));
  bram #(.WIDTH(32),.NADDR(NBTOTAL))
       way1(.clk(clk),
	    // CPU port
            .addrA(saved_wr ? index : addr[NBTOTAL-1+2:2]),   
	    .weA(saved_wr & hit1),
            .wdataA(wdata),
            .rdataA(way1_cpu_data),
	    // refill port
            .addrB(refill_addr),
	    .weB(refill_write_way1),
            .wdataB(mc_data),
            .rdataB(way1_ring_data));

  // return results
  assign rdy = (saved_rd || saved_wr) && (hit0 || hit1);
  assign rdata = hit0 ? way0_cpu_data : way1_cpu_data;

  // update LRU indicator on each hit
  always @(posedge clk) if (rdy) lru[line] <= hit0;

  assign mc_ack_out = mc_ack_in && (state != s_mc_data);

  // output slot
  `include "ring.v"
  assign ring_req = (state == s_read_addr) || (state == s_write_addr) || (state == s_write_back);
  assign slot_type = (state == s_write_back) ? WDATA : ADDR;
  assign slot_data = (state == s_read_addr) ? {1'b0,saved_addr[31:NBWORDS+2]} :
                     (state == s_write_addr) ? {1'b1,lru_way ? way1_tag : way0_tag,line} :
		     lru_way ? way1_ring_data : way0_ring_data;   // state == s_write_back
endmodule

// 2-port synchronous block ram as supported by Virtex 5
// Xilinx tools will infer a 2-port BRAM if one port is R/W and the other is R-only.
// Note that they won't infer correctly if both ports are R/W... bummer...
// KLUDGE: combine the two write ports assuming their aren't both active at once.
module bram #(parameter WIDTH=32,NADDR=10)
            (input clk,
             input [NADDR-1:0] addrA,
             input weA,
             input [WIDTH-1:0] wdataA,
             output [WIDTH-1:0] rdataA,
             input [NADDR-1:0] addrB,
             input weB,
             input [WIDTH-1:0] wdataB,
             output [WIDTH-1:0] rdataB
            );
  localparam SIZE = (1 << NADDR);

  (* ram_style = "block" *)
  reg [WIDTH-1:0] mem[SIZE-1:0];

  // kludge
  wire we = weA || weB;
  wire [NADDR-1:0] waddr = weA ? addrA : addrB;
  wire [WIDTH-1:0] wdata = weA ? wdataA : wdataB;

  reg [NADDR-1:0] saved_addrA,saved_addrB;
  always @(posedge clk) begin
    saved_addrA <= addrA;
    saved_addrB <= waddr; //addrB;
    if (we) mem[waddr] <= wdata;
    //if (weA) mem[addrA] <= wdataA;
    // if you comment out the following line, XST will infer the correct BRAM;
    // if you leave it in, the inference fails
    //if (weB) mem[addrB] <= wdataB;
  end

  assign rdataA = mem[saved_addrA];
  assign rdataB = mem[saved_addrB];
endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//	2-stage risc cpu
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module risc(
  input clk,
  input reset,                  // active high
  input irq,			// interrupt request, active high
  input rdy,			// high if we're allowed to finish current inst

  // instruction port
  output [31:2] iaddr,          // address of instruction to be fetched
  input [31:0] inst,            // instruction returning from memory

  // memory port
  output [31:2] maddr,          // address of data word to be accessed
  output mrd,			// read request
  output mwr,                   // write request
  output [31:0] mdout,          // memory write data
  input [31:0] mdin		// read data returning from memory
);
  parameter BIG_ENDIAN = 1'b1;   // set to 0 for little endian
  parameter OVERFLOW_TRAPS = 1'b0;

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
  wire [1:0] msize;	// risc_control
  wire msxt;		// risc_control
  wire mleft;		// risc_control
  wire mdin_ld;		// risc_control
  wire bsign;		// risc_datapath
  wire bneq;		// risc_datapath
  wire alu_v;		// risc_datapath
  wire muldiv_busy;	// risc_datapath
  wire [31:0] cpin;	// risc_datapath
  wire [31:0] cpout;	// risc_datapath

  risc_control ctl(.clk(clk),.reset(reset),.rdy(rdy),.inst(inst),
                   .bsign(bsign),.bneq(bneq),.alu_v(alu_v),.muldiv_busy(muldiv_busy),
		   .inst_x(inst_x),.advance(advance),
		   .pcsel(pcsel),.exccode(exccode),
		   .asel(asel),.bsel(bsel),.alufn(alufn),.muldiv(muldiv),
		   .wasel(wasel),.wbsel(wbsel),.cpsel(cpsel),
		   .mrd(mrd),.mwr(mwr),.msize(msize),.msxt(msxt),.mleft(mleft),.mdin_ld(mdin_ld)
		   );
  defparam ctl.OVERFLOW_TRAPS = OVERFLOW_TRAPS;

  risc_datapath dp(.clk(clk),.reset(reset),.advance(advance),.inst_x(inst_x),
		   .mdin(mdin),.cpin(cpin),
		   .asel(asel),.bsel(bsel),.alufn(alufn),.muldiv(muldiv),
		   .pcsel(pcsel),.wasel(wasel),.wbsel(wbsel),.cpsel(cpsel),
		   .msize(msize),.msxt(msxt),.mleft(mleft),.mdin_ld(mdin_ld),
                   .bsign(bsign),.bneq(bneq),.alu_v(alu_v),.muldiv_busy(muldiv_busy),
		   .iaddr(iaddr),.maddr(maddr),.mdout(mdout),
		   .cpout(cpout)
		   );
  defparam dp.BIG_ENDIAN = BIG_ENDIAN;
endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//	Control logic
//
////////////////////////////////////////////////////////////////////////////////
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
  output mrd,
  output mwr,
  output [1:0] msize,
  output msxt,
  output mleft,
  output mdin_ld
);
  parameter OVERFLOW_TRAPS = 1'b0;

  reg [2:0] d_pcsel;   // pc select
    localparam pc_x = 3'bxxx;
    localparam pc_inc = 3'b000;
    localparam pc_br = 3'b001;
    localparam pc_jump = 3'b010;
    localparam pc_jr = 3'b011;
    localparam pc_reset = 3'b100;
    localparam pc_exception = 3'b101;
  reg [2:0] d_branch;  // branch decision
    localparam br_x = 3'bxxx;
    localparam br_beq = 3'b100;
    localparam br_bneq = 3'b000;
    localparam br_blez = 3'b110;
    localparam br_bgtz = 3'b010;
    localparam br_bltz = 3'b001;
    localparam br_bgez = 3'b101;
  reg [4:0] d_exccode; // exception code
    localparam exc_x = 5'bxxxxx;
    localparam exc_syscall = 5'd8;
    localparam exc_break = 5'd9;
    localparam exc_reserved = 5'd10;
    localparam exc_ov = 5'd12;
  reg [1:0] d_asel;    // A operand select
    localparam a_x = 2'bxx;
    localparam a_rs = 2'b00;
    localparam a_16 = 2'b01;
    localparam a_shamt = 2'b11;
  reg [1:0] d_bsel;    // B operand select
    localparam b_x = 2'bxx;
    localparam b_rt = 2'b00;
    localparam b_imm = 2'b01;
    localparam b_sxtimm = 2'b11;
  reg [1:0] d_unit;    // ALU unit select
    localparam unit_x = 2'bxx;
    localparam unit_addsub = 2'b00;
    localparam unit_slt = 2'b01;
    localparam unit_boolean = 2'b10;
    localparam unit_shifter = 2'b11;
  reg d_addsub;        // adder control
    localparam addsub_x = 1'bx;
    localparam addsub_add = 1'b0;
    localparam addsub_sub = 1'b1;
  reg d_slt;           // slt control
    localparam slt_x = 1'bx;
    localparam slt_slt = 1'b0;
    localparam slt_sltu = 1'b1;
  reg [1:0] d_boole;   // boolean control
    localparam boole_x = 2'bxx;
    localparam boole_and = 2'b00;
    localparam boole_or = 2'b01;
    localparam boole_xor = 2'b10;
    localparam boole_nor = 2'b11;
  reg [1:0] d_shift;   // shifter control
    localparam shift_x = 2'bxx;
    localparam shift_ll = 2'b00;
    localparam shift_lr = 2'b01;
    localparam shift_ar = 2'b10;
  reg d_checkv;        // trap if arithmetic overflow
    localparam checkv_x = 1'bx;
    localparam checkv_no = 1'b0;
    localparam checkv_yes = 1'b1;
  reg [2:0] d_muldiv;  // MUL/DIV control
    localparam muldiv_x = 3'bxxx;
    localparam muldiv_none = 3'b000;
    localparam muldiv_mtlo = 3'b010;
    localparam muldiv_mthi = 3'b011;
    localparam muldiv_mult = 3'b100;
    localparam muldiv_multu = 3'b101;
    localparam muldiv_div = 3'b110;
    localparam muldiv_divu = 3'b111;
  reg [1:0] d_wasel;   // writeback address select
    localparam wa_x = 2'bxx;
    localparam wa_rt = 2'b00;
    localparam wa_rd = 2'b01;
    localparam wa_31 = 2'b10;
    localparam wa_0 = 2'b11;
  reg [1:0] d_wbsel;   // writeback data select
    localparam wb_x = 2'bxx;
    localparam wb_pcinc = 2'b00;
    localparam wb_alu = 2'b01;
    localparam wb_mdin = 2'b10;
    localparam wb_cpin = 2'b11;
  reg [1:0] d_cpsel;   // coproc data select
    localparam cp_x = 2'bxx;
    localparam cp_lo = 2'b00;
    localparam cp_hi = 2'b01;
    localparam cp_cpin = 2'b10;
  reg [1:0] d_mem;	// memory operation
    localparam mem_x = 2'bxx;
    localparam mem_none = 2'b00;
    localparam mem_read = 2'b01;
    localparam mem_write = 2'b10;
  reg [1:0] d_msize;	// memory data size
    localparam msize_x = 2'bxx;
    localparam msize_b = 2'b00;
    localparam msize_h = 2'b01;
    localparam msize_w = 2'b10;
    localparam msize_lwx = 2'b11;
  reg d_msxt;		// memory data sign extension
    localparam msxt_x = 1'bx;
    localparam msxt_unsigned = 1'b0;
    localparam msxt_signed = 1'b1;
  reg d_mleft;		// memory load word left/right
    localparam mleft_x = 1'bx;
    localparam mleft_right = 1'b0;
    localparam mleft_left = 1'b1;
  reg d_mdin_ld;        // load enable for saved_mdin register

  // execution FSM
  reg [1:0] next_state,state;
  localparam s_cycle1 = 2'd0;
  localparam s_cycle2 = 2'd1;
  localparam s_cycle3 = 2'd2;
  always @(posedge clk) state <= reset ? s_cycle1 : next_state;

  // instruction register
  always @(posedge clk) begin
    if (reset) inst_x <= 32'h00000000;  // NOP until first inst arrives
    else if (advance) inst_x <= inst;
  end

  always @(*) begin
    // default values
    d_mem = mem_none;
    d_checkv = checkv_no;
    d_muldiv = muldiv_none;
    d_slt = slt_slt;   // ensure adder behaves
    d_mdin_ld = 0;
    next_state = s_cycle1;
    
    d_pcsel = pc_x;
    d_branch = br_x;
    d_exccode = exc_x;
    d_asel = a_x;
    d_bsel = b_x;
    d_unit = unit_x;
    d_addsub = addsub_x;
    d_boole = boole_x;
    d_shift = shift_x;
    d_wasel = wa_x;
    d_wbsel = wb_x;
    d_cpsel = cp_x;
    d_msize = msize_x;
    d_msxt = msxt_x;
    d_mleft = mleft_x;

    // opcode decode
    case (inst_x[31:26])
      6'b000000:      // special
        case (inst_x[5:0])
          6'b000000:  // SLL
	      begin
		d_pcsel = pc_inc;
		d_asel = a_shamt; d_bsel = b_rt;
		d_unit = unit_shifter; d_shift = shift_ll;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b000010:  // SRL
	      begin
		d_pcsel = pc_inc;
		d_asel = a_shamt; d_bsel = b_rt;
		d_unit = unit_shifter; d_shift = shift_lr;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b000011:  // SRA
	      begin
		d_pcsel = pc_inc;
		d_asel = a_shamt; d_bsel = b_rt;
		d_unit = unit_shifter; d_shift = shift_ar;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b000100:  // SLLV
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_shifter; d_shift = shift_ll;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b000110:  // SRLV
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_shifter; d_shift = shift_lr;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b000111:  // SRAV
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_shifter; d_shift = shift_ar;
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
          6'b001100:  // SYSCALL
	      begin
		d_pcsel = pc_exception; d_exccode = exc_syscall;
		d_wasel = wa_0;
	      end
          6'b001101:  // BREAK
	      begin
		d_pcsel = pc_exception; d_exccode = exc_break;
		d_wasel = wa_0;
	      end
          6'b010000:  // MFHI
	      begin
                d_pcsel = pc_inc;
		d_wasel = wa_rd; d_wbsel = wb_cpin; d_cpsel = cp_hi;
		next_state = muldiv_busy ? s_cycle2 : s_cycle1;
	      end
          6'b010001:  // MTHI
	      begin
                d_pcsel = pc_inc;
		d_wasel = wa_0;
                d_muldiv = muldiv_mthi;
	      end
          6'b010010:  // MFLO
	      begin
                d_pcsel = pc_inc;
		d_wasel = wa_rd; d_wbsel = wb_cpin; d_cpsel = cp_lo;
		next_state = muldiv_busy ? s_cycle2 : s_cycle1;
	      end
          6'b010011:  // MTLO
	      begin
                d_pcsel = pc_inc;
		d_wasel = wa_0;
                d_muldiv = muldiv_mtlo;
	      end
          6'b011000:  // MULT
	      begin
                d_pcsel = pc_inc;
	        d_wasel = wa_0;
                d_muldiv = muldiv_mult;
	      end
          6'b011001:  // MULTU
	      begin
                d_pcsel = pc_inc;
	        d_wasel = wa_0;
                d_muldiv = muldiv_multu;
	      end
          6'b011010:  // DIV
	      begin
                d_pcsel = pc_inc;
	        d_wasel = wa_0;
                d_muldiv = muldiv_div;
	      end
          6'b011011:  // DIVU
	      begin
                d_pcsel = pc_inc;
	        d_wasel = wa_0;
                d_muldiv = muldiv_divu;
	      end
          6'b100000:  // ADD
	      if (OVERFLOW_TRAPS)
 	        begin
		  d_pcsel = pc_inc;
		  d_asel = a_rs; d_bsel = b_rt;
		  d_unit = unit_addsub; d_addsub = addsub_add;
		  d_checkv = checkv_yes; d_exccode = exc_ov;
		  d_wasel = wa_rd; d_wbsel = wb_alu;
	        end
	      else
	        begin
	 	  d_pcsel = pc_exception; d_exccode = exc_reserved;
		  d_wasel = wa_0;
	        end
          6'b100001:  // ADDU
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_addsub; d_addsub = addsub_add;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b100010:  // SUB
	      if (OVERFLOW_TRAPS)
 	        begin
		  d_pcsel = pc_inc;
		  d_asel = a_rs; d_bsel = b_rt;
		  d_unit = unit_addsub; d_addsub = addsub_sub;
		  d_checkv = checkv_yes; d_exccode = exc_ov;
		  d_wasel = wa_rd; d_wbsel = wb_alu;
	        end
	      else
	        begin
	 	  d_pcsel = pc_exception; d_exccode = exc_reserved;
		  d_wasel = wa_0;
	        end
          6'b100011:  // SUBU
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_addsub; d_addsub = addsub_sub;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b100100:  // AND
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_boolean; d_boole = boole_and;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b100101:  // OR
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_boolean; d_boole = boole_or;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b100110:  // XOR
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_boolean; d_boole = boole_xor;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b100111:  // NOR
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_boolean; d_boole = boole_nor;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b101010:  // SLT
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_slt; d_slt = slt_slt; d_addsub = addsub_sub;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          6'b101011:  // SLTU
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_rt;
		d_unit = unit_slt; d_slt = slt_sltu; d_addsub = addsub_sub;
		d_wasel = wa_rd; d_wbsel = wb_alu;
	      end
          default:    // reserved instruction
	      begin
		d_pcsel = pc_exception; d_exccode = exc_reserved;
		d_wasel = wa_0;
	      end
        endcase
      6'b000001:
        case (inst_x[20:16])
          6'b000000:  // BLTZ
	      begin
		d_pcsel = pc_br; d_branch = br_bltz;
		d_wasel = wa_0;
	      end
          6'b000001:  // BGEZ
	      begin
		d_pcsel = pc_br; d_branch = br_bgez;
		d_wasel = wa_0;
	      end
          default:    // reserved instruction
	      begin
		d_pcsel = pc_exception; d_exccode = exc_reserved;
		d_wasel = wa_0;
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
      6'b000100:      // BEQ
	      begin
		d_pcsel = pc_br; d_branch = br_beq;
		d_wasel = wa_0;
	      end
      6'b000101:      // BNE
	      begin
		d_pcsel = pc_br; d_branch = br_bneq;
		d_wasel = wa_0;
	      end
      6'b000110:      // BLEZ
	      begin
		d_pcsel = pc_br; d_branch = br_blez;
		d_wasel = wa_0;
	      end
      6'b000111:      // BGTZ
	      begin
		d_pcsel = pc_br; d_branch = br_bgtz;
		d_wasel = wa_0;
	      end
      6'b001000:      // ADDI
              if (OVERFLOW_TRAPS)
	        begin
		  d_pcsel = pc_inc;
		  d_asel = a_rs; d_bsel = b_sxtimm;
		  d_unit = unit_addsub; d_addsub = addsub_add;
		  d_checkv = checkv_yes; d_exccode = exc_ov;
		  d_wasel = wa_rt; d_wbsel = wb_alu;
	        end
	      else
	        begin
		  d_pcsel = pc_exception; d_exccode = exc_reserved;
		  d_wasel = wa_0;
	        end
      6'b001001:      // ADDIU
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_unit = unit_addsub; d_addsub = addsub_add;
		d_wasel = wa_rt; d_wbsel = wb_alu;
	      end
      6'b001010:      // SLTI
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_unit = unit_slt; d_slt = slt_slt; d_addsub = addsub_sub;
		d_wasel = wa_rt; d_wbsel = wb_alu;
	      end
      6'b001011:      // SLTIU
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_unit = unit_slt; d_slt = slt_sltu; d_addsub = addsub_sub;
		d_wasel = wa_rt; d_wbsel = wb_alu;
	      end
      6'b001100:      // ANDI
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_imm;
		d_unit = unit_boolean; d_boole = boole_and;
		d_wasel = wa_rt; d_wbsel = wb_alu;
	      end
      6'b001101:      // ORI
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_imm;
		d_unit = unit_boolean; d_boole = boole_or;
		d_wasel = wa_rt; d_wbsel = wb_alu;
	      end
      6'b001110:      // XORI
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_imm;
		d_unit = unit_boolean; d_boole = boole_xor;
		d_wasel = wa_rt; d_wbsel = wb_alu;
	      end
      6'b001111:      // LUI
	      begin
		d_pcsel = pc_inc;
		d_asel = a_16; d_bsel = b_imm;
		d_unit = unit_shifter; d_shift = shift_ll;
		d_wasel = wa_rt; d_wbsel = wb_alu;
	      end
      6'b010000:
        case (inst_x[25:21])
          5'b00000:   // MFC0
	      begin
              end
          5'b00100:   // MTC0
	      begin
              end
          default:    // reserved instruction
	      begin
		d_pcsel = pc_exception; d_exccode = exc_reserved;
		d_wasel = wa_0;
	      end
        endcase
      6'b100000:      // LB
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_unit = unit_addsub; d_addsub = addsub_add;
		d_mem = mem_read; d_msize = msize_b; d_msxt = msxt_signed;
		d_wasel = wa_rt; d_wbsel = wb_mdin;
              end
      6'b100001:      // LH
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_mem = mem_read; d_msize = msize_h; d_msxt = msxt_signed;
		d_wasel = wa_rt; d_wbsel = wb_mdin;
              end
      6'b100010:      // LWL
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_mem = mem_read; d_msize = msize_lwx; d_mleft = mleft_left;
		d_wasel = wa_rt; d_wbsel = wb_mdin;
              end
      6'b100011:      // LW
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_mem = mem_read; d_msize = msize_w;
		d_wasel = wa_rt; d_wbsel = wb_mdin;
              end
      6'b100100:      // LBU
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_mem = mem_read; d_msize = msize_b; d_msxt = msxt_unsigned;
		d_wasel = wa_rt; d_wbsel = wb_mdin;
              end
      6'b100101:      // LHU
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_mem = mem_read; d_msize = msize_h; d_msxt = msxt_unsigned;
		d_wasel = wa_rt; d_wbsel = wb_mdin;
              end
      6'b100110:      // LWR
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_mem = mem_read; d_msize = msize_lwx; d_mleft = mleft_right;
		d_wasel = wa_rt; d_wbsel = wb_mdin;
              end
      6'b101000:      // SB
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
                d_msize = msize_b;
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
      6'b101001:      // SH
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_msize = msize_h;
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
      6'b101010:      // SWL
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_msize = msize_lwx;
		d_mleft = mleft_left;
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
      6'b101011:      // SW
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_mem = mem_write; d_msize = msize_w;
		d_wasel = wa_0;
              end
      6'b101110:      // SWR
	      begin
		d_pcsel = pc_inc;
		d_asel = a_rs; d_bsel = b_sxtimm;
		d_addsub = addsub_add;
		d_msize = msize_lwx;
		d_mleft = mleft_right;
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
		 //reset_x ? pc_inc :
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
  assign mrd = d_mem[0];
  assign mwr = d_mem[1];
  assign msize = d_msize;
  assign msxt = d_msxt;
  assign mleft = d_mleft;
  assign mdin_ld = d_mdin_ld;
endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//	Data path
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module risc_datapath(
  input clk,
  input reset,
  input advance,
  input [31:0] inst_x,
  input [31:0] mdin,
  input [31:0] cpin,
  input [1:0] asel,
  input [1:0] bsel,
  input [7:0] alufn,
  input [2:0] muldiv,
  input [2:0] pcsel,
  input [1:0] wasel,
  input [1:0] wbsel,
  input [1:0] cpsel,
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
  output reg [31:0] mdout,
  output [31:0] cpout
);
  parameter BIG_ENDIAN = 1'b1;   // set to 0 for little endian
  parameter MULDIV = 1'b1;

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
  wire signed [31:0] a,b;
  assign a = asel[0] ? {27'b0,(asel[1] ? inst_x[10:6] : 5'b10000)} :
                       rs;
  assign b = bsel[0] ? {{16{bsel[1] & inst_x[15]}},inst_x[15:0]} :
                       rt;

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
  //a 64 X 32 ROM.  Generates the correct mask based on shiftAmount and direction
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
      2'b00:		// adder
        alu = sum[31:0];
      2'b01:		// slt
        alu = {31'd0,sltu ? sum[32] : (sum[31] ^ alu_v)};
      2'b10:		// boolean
        case (boole)
          2'b00: alu = a & b;     // AND
          2'b01: alu = a | b;     // OR
          2'b10: alu = a ^ b;     // XOR
          2'b11: alu = ~(a | b);  // NOR
          default: alu = 32'hxxxxxxxx;
        endcase
      2'b11:		// shifter
        alu = shift_out;
      default:
        alu = 32'hxxxxxxxx;
    endcase

  // MUL/DIV unit
  wire [31:0] hi,lo;
  muldiv_unit md(clk,reset,rs,rt,advance ? muldiv : 3'b000,hi,lo,muldiv_busy);

  // memory address (synchronous ram)
  assign maddr = sum[31:2];

  // memory write data (synchronous ram)
  reg [31:0] saved_mdin;
  always @(posedge clk) if (mdin_ld) saved_mdin <= mdin;
  always @(*)
    case (msize)
    2'b00:
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
    2'b01:
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
    2'b10: mdout = rt;
    2'b11:    // SWL, SWR
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

  assign cpout = rt;

  // pc logic
  reg [31:0] pc_f,pc_next,pc_x;
  wire [31:0] pc_f_4 = pc_f + 4;  // also used by link instructions
  always @(*)
    case (pcsel)
    3'b000: pc_next = pc_f_4;                     // normal execution
    3'b001: pc_next = {{14{inst_x[15]}},inst_x[15:0],2'b0} + pc_f; // branch
    3'b010: pc_next = {pc_f_4[31:28],inst_x[25:0],2'b0};     // jump
    3'b011: pc_next = rs;                         // jr
    3'b100: pc_next = 32'h0000;                   // reset
    3'b101: pc_next = 32'h0008;                   // exception
    default: pc_next = 32'hXXXXXXXX;
    endcase
  always @(posedge clk)
    begin
      if (advance) pc_x <= pc_f;
      if (advance | reset) pc_f <= pc_next;
    end

  assign iaddr = (advance | reset) ? pc_next[31:2] : pc_f[31:2];  // synchronous ram

  // LD result
  reg [31:0] mdata;
  always @(*)
    case (msize)
    2'b00:
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
    2'b01:
      begin
        if (BIG_ENDIAN)
	  mdata[15:0] = sum[1] ? mdin[15:0] : mdin[31:16];
	else
	  mdata[15:0] = sum[1] ? mdin[31:16] : mdin[15:0];
        mdata[31:16] = {16{msxt ? mdata[15] : 1'b0}};
      end
    2'b10: mdata = mdin;
    2'b11:    // LWL, LWR
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

  // regfile writeback
  reg [4:0] wa;
  always @(*)
    case (wasel)
    2'b00: wa = inst_x[20:16];  // RT
    2'b01: wa = inst_x[15:11];  // RD
    2'b10: wa = 5'd31;          // $31
    2'b11: wa = 5'd0;           // $0
    default: wa = 5'bxxxxx;
    endcase
  reg [31:0] wdata;
  always @(*)
    case (wbsel)
    2'b00: wdata = pc_f_4;   // link instructions
    2'b01: wdata = alu;
    2'b10: wdata = mdata;
    2'b11: case (cpsel)
           2'b00: wdata = lo;
           2'b01: wdata = hi;
           2'b10: wdata = cpin;
           default: wdata = 32'hXXXXXXXX;
           endcase
    default: wdata = 32'hXXXXXXXX;
    endcase
  always @(posedge clk)
    if (advance & wa != 0) regfile[wa] <= wdata;
endmodule

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
