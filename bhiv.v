`timescale 1 ns / 100 ps

// a simple multicore system
module bhiv();
  localparam TSIZE = 4;   // slot type field is [TSIZE-1:0]
  localparam SSIZE = 4;   // slot source field is [SSIZE-1:0]
  localparam NCORES = 3;  // must be less than (1 << SSIZE)

  localparam NBLINES = 7;  // caches have 2**7 lines
  localparam NBWORDS = 3;   // with 2**3 words each
  localparam NBCACHELINE = 30-NBWORDS;  // number of address bits to address a cache line
  localparam NWORDS = (1 << NBWORDS);  // words per cache line

  reg clk,reset;

  //**************************************************
  //**
  //**  multicore
  //**
  //**************************************************

  // the registers of the ring
  reg [31:0] slot_data[0:NCORES];
  reg [TSIZE-1:0] slot_type[0:NCORES];
  reg [SSIZE-1:0] slot_source[0:NCORES];
 
  // separate pipelined bus for read data
  reg [SSIZE-1:0] mc_dest[0:NCORES];
  reg [NBWORDS-1:0] mc_count[0:NCORES];
  reg [31:0] mc_data[0:NCORES];

  // instantiate the cores
  genvar i;
  generate
    for (i = 1; i <= NCORES; i = i+1) begin : coreBlk
      wire [TSIZE-1:0] type;
      wire [SSIZE-1:0] source;
      wire [31:0] data;

      // wire up a core!
      core #(.CORENUM(i),.TSIZE(TSIZE),.SSIZE(SSIZE),.NBLINES(NBLINES),.NBWORDS(NBWORDS))
           coreN(.clk(clk),
                 .reset(reset),
                .slot_type_in(slot_type[i-1]),
                .slot_source_in(slot_source[i-1]),
                .slot_data_in(slot_data[i-1]),
                .slot_type_out(type),
                .slot_source_out(source),
                .slot_data_out(data),
                .mc_dest(mc_dest[i-1]),
		.mc_count(mc_count[i-1]),
                .mc_data(mc_data[i-1]));

      // ring and data registers
      always @(posedge clk) begin
        mc_dest[i] <= mc_dest[i-1];
        mc_count[i] <= mc_count[i-1];
        mc_data[i] <= mc_data[i-1];
        slot_type[i] <= type;
        slot_source[i] <= source;
        slot_data[i] <= data;
      end
    end
  endgenerate

  `include "ring.v"

  // connect up the ends of the ring
  always @(posedge clk) begin
    slot_type[0] <= reset ? TOKEN : slot_type[NCORES];
    slot_source[0] <= reset ? 0 : slot_source[NCORES];
    slot_data[0] <= reset ? 0 : slot_data[NCORES];
  end

  // capture incoming ADDR and WDATA slots

  wire wdata_rd;
  wire [31:0] wdata_data;
  fifo #(.WIDTH(32),.LOGSIZE(10))
       wdata(.clk(clk),
             .reset(reset),  
             .din(slot_data[NCORES]),
             .rd_en(wdata_rd),
             .wr_en(slot_type[NCORES] == WDATA),
             .dout(wdata_data),
             .empty(),
             .full());
  // address fifo contains {dest[SSIZE-1:0],rw,cacheline[NBCACHELINE-1:0]}
  wire addr_rd,addr_empty;
  wire [SSIZE + 1 + NBCACHELINE - 1:0] addr_out;
  fifo #(.WIDTH(SSIZE + 1 + NBCACHELINE),.LOGSIZE(10))
       addr(.clk(clk),
            .reset(reset),  
            .din({slot_source[NCORES],slot_data[NCORES][NBCACHELINE],slot_data[NCORES][NBCACHELINE-1:0]}),
            .rd_en(addr_rd),
            .wr_en(slot_type[NCORES] == ADDR),
            .dout(addr_out),
            .empty(addr_empty),
            .full());

  // simple memory for now
  parameter MBITS = 14;   // 8k words
  (* ram_style = "block" *)
  reg [31:0] mem[0:(1 << MBITS)-1];
  
  // states 0-(NWORDS-1) count the cycles during which a cache line is read/written
  // state NWORDS is the idle state
  reg [NBWORDS:0] mcnt;

  wire m_idle = reset || (mcnt == NWORDS);
  wire [NBCACHELINE-1:0] line = addr_out[NBCACHELINE-1:0];
  wire out_of_range = (line[NBCACHELINE-1:(MBITS-1)-NBWORDS+1] != 0);
  wire write = addr_out[NBCACHELINE];
  wire [SSIZE-1:0] dest = addr_out[SSIZE+NBCACHELINE+1 - 1:NBCACHELINE+1];
  wire [MBITS-1:0] m_addr = {line[(MBITS-1)-NBWORDS:0],mcnt[NBWORDS-1:0]};
  always @(posedge clk) begin
    if (reset) mcnt <= NWORDS;
    else if (!addr_empty && m_idle && !out_of_range) mcnt <= 0;
    else if (!m_idle) mcnt <= mcnt + 1;

    if (!m_idle && write) mem[m_addr] <= wdata_data;

    mc_dest[0] <= (!m_idle && !write) ? dest : 0;
    mc_count[0] <= mcnt[NBWORDS-1:0];
    mc_data[0] <= (!m_idle && !write) ? mem[m_addr] : 0;

    // some debuging: look for access to a cache line beyond the top of memory
    if (!addr_empty && out_of_range)
      $display("***** address out of range: src=%x, write=%x, line=%x",dest,write,line);
  end
  assign wdata_rd = !m_idle && write;  // consume a word of data from the wdata fifo
  assign addr_rd = (mcnt == NWORDS-1);  // move to the next address in the addr fifo

  //**************************************************
  //**  simulation lash up
  //**************************************************

  initial begin
    clk = 1;
    reset = 1;
    $readmemh("mem.vmh",mem);

    #35   // 3 cycles of reset
    reset = 0;

    //#100000   // 10000 cycles
    //$finish;
  end
  always #5 clk = ~clk;

  reg [31:0] cycle;
  always @(posedge clk) cycle <= reset ? 0 : cycle+1;

  // stop when there's a read from last line
  always @ (negedge clk)
    if (!addr_empty && line == ((1<<NBCACHELINE) - 1)) begin
      $display("terminated at cycle %d!",cycle);
      $finish;
    end

  // follow execution in core N
  localparam N = 1;
  always @(negedge clk) if (!reset) begin
    $write("slot=");
    case (bhiv.coreBlk[N].type)
      NULL: $write("----");
      TOKEN: $write("TOKN");
      ADDR: $write("ADDR");
      WDATA: $write("WDAT");
      default: $write("%x",bhiv.coreBlk[N].type);
    endcase
    $write(":%x:%x ",bhiv.coreBlk[N].source,bhiv.coreBlk[N].data);
    $write("mc=%x:%x:%x ",mc_dest[N-1],mc_count[N-1],mc_data[N-1]);
    $write("pcx1=%x ",bhiv.coreBlk[1].coreN.cpu.dp.pc_x);
    $write("pcx2=%x ",bhiv.coreBlk[2].coreN.cpu.dp.pc_x);
    $write("pcx3=%x ",bhiv.coreBlk[3].coreN.cpu.dp.pc_x);
    //$write("rdy=%x ",bhiv.coreBlk[N].coreN.rdy);
    //$write("mreq=%x%x ",bhiv.coreBlk[N].coreN.dcache.saved_rd,bhiv.coreBlk[N].coreN.dcache.saved_wr);
    //$write("maddr=%x ",bhiv.coreBlk[N].coreN.maddr);
    //$write("iaddr=%x ",bhiv.coreBlk[N].coreN.iaddr);
    //$write("advance=%x ",bhiv.coreBlk[N].coreN.cpu.ctl.advance);
    //$write("next_cstate=%x ",bhiv.coreBlk[N].coreN.cpu.ctl.next_state);
    //$write("cstate=%x ",bhiv.coreBlk[N].coreN.cpu.ctl.state);
    //$write("dvalid=%x%x ",bhiv.coreBlk[N].coreN.dcache.v0,bhiv.coreBlk[N].coreN.dcache.v1);
    //$write("dhit=%x%x ",bhiv.coreBlk[N].coreN.dcache.hit0,bhiv.coreBlk[N].coreN.dcache.hit1);
    //$write("state=%x ",bhiv.coreBlk[N].coreN.dcache.state);
    //$write("cnt=%x ",bhiv.coreBlk[N].coreN.dcache.wb_count);
    //$write("rfaddr=%x ",bhiv.coreBlk[N].coreN.dcache.refill_addr);
    //$write("rfwr=%x%x",bhiv.coreBlk[N].coreN.dcache.refill_write_way0,bhiv.coreBlk[N].coreN.dcache.refill_write_way1);
    //$write("dmiss=%x ",bhiv.coreBlk[N].coreN.dcache.miss);
    //$write("dreq=%x ",bhiv.coreBlk[N].coreN.d_ring_req);
    //$write("dack=%x ",bhiv.coreBlk[N].coreN.d_ring_ack);
    //$write("rdata=%x ",bhiv.coreBlk[N].coreN.mdin);
    //$write("pcx=%x ",bhiv.coreBlk[N].coreN.cpu.dp.pc_x);
    //$write("instx=%x ",bhiv.coreBlk[N].coreN.cpu.ctl.inst_x);
    //$write("opcode=%x ",bhiv.coreBlk[N].coreN.cpu.ctl.inst_x[31:26]);
    //$write("rs=%x ",bhiv.coreBlk[N].coreN.cpu.dp.rs);
    //$write("a=%x ",bhiv.coreBlk[N].coreN.cpu.dp.a);
    //$write("b=%x ",bhiv.coreBlk[N].coreN.cpu.dp.b);
    //$write("wdata=%x ",bhiv.coreBlk[N].coreN.cpu.dp.wdata);
    //$write("op=%x ",bhiv.coreBlk[N].coreN.cpu.dp.md.op);
    //$write("state=%x ",bhiv.coreBlk[N].coreN.cpu.dp.md.state);
    //$write("counter=%x ",bhiv.coreBlk[N].coreN.cpu.dp.md.counter);
    //$write("b=%x ",bhiv.coreBlk[N].coreN.cpu.dp.md.b);
    //$write("p=%x ",bhiv.coreBlk[N].coreN.cpu.dp.md.p);
    //$write("lo=%x ",bhiv.coreBlk[N].coreN.cpu.dp.md.lo);
    //$write("hi=%x ",bhiv.coreBlk[N].coreN.cpu.dp.md.hi);
    //$write("=%x ",{cbhiv.coreBlk[N].coreN.cpu.dp.md.dividend_sign,bhiv.coreBlk[N].coreN.cpu.dp.md.divisor_sign});
    $display("");
  end
endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//	FIFO
//
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module fifo #(parameter WIDTH = 32, LOGSIZE = 10) (
  input clk,
  input reset,
  input [WIDTH-1:0] din,
  input rd_en,
  input wr_en,
  output [WIDTH-1:0] dout,
  output empty,
  output full
  );

  localparam SIZE = 1 << LOGSIZE;

  reg [LOGSIZE-1:0] ra, wa, count;

  assign full = (count > (SIZE-4));
  assign empty = (count == 0);

  always @(posedge clk) begin
    if (reset) count <= 0;
    else if (rd_en && ~wr_en) count <= count - 1;
    else if (wr_en && ~rd_en) count <= count + 1;
  end

  wire [LOGSIZE-1:0] next_ra = reset ? 0 : rd_en ? ra+1 : ra;
  always @(posedge clk) begin
    ra <= next_ra;
  end

  always @(posedge clk) begin
    if (reset) wa <= 0;
    else if (wr_en) wa <= wa + 1;
  end

  generate
    if (LOGSIZE <= 6) begin
      (* ram_style = "distributed" *)
      reg [WIDTH-1:0] qram[SIZE-1:0];
      reg [LOGSIZE-1:0] qramAddr;
      always @(posedge clk) begin
        qramAddr <= next_ra;
        if (wr_en) qram[wa] <= din;
      end
      assign dout = qram[qramAddr];
    end
    else begin
      (* ram_style = "block" *)
      reg [WIDTH-1:0] qram[SIZE-1:0];
      reg [LOGSIZE-1:0] qramAddr;
      always @(posedge clk) begin
        qramAddr <= next_ra;
        if (wr_en) qram[wa] <= din;
      end
      assign dout = qram[qramAddr];
    end
  endgenerate
endmodule

`include "core.v"
