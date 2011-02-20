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
//	A single core: CPU, caches, local i/o
//
////////////////////////////////////////////////////////////////////////////////

module core #(parameter
  CORENUM=1,    // number for this core
  NCORES=1,     // total number of cores
  TSIZE=4,      // size of slot type field
  SSIZE=4,      // size of slot source field
  NBLINES=7,    // 2**NBLINES lines in each way of cache
  NBWORDS=3,    // 2**NBWORDS words in each cache line
  SLOT_METERS=0, // include meters for slot type
  MEM_METERS=0  // include meters for memory accesses
) (
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

  `include "ring.h"

  ////////////////////////////////////////////////////
  //
  //  CPU
  // 
  ////////////////////////////////////////////////////

  wire rdy;
  wire [31:2] iaddr,maddr;
  wire [31:0] inst,mdout,mdin;
  wire mrd,mwr,force_miss;

  // interrupt support
  wire irq = 1'b0;
  wire [4:0] ivector = 5'b0000;
  wire iack;

  // the CPU itself
  risc cpu(.clk(clk),.reset(reset),.rdy(rdy),
           .iaddr(iaddr),.inst(inst),
           .maddr(maddr),.mrd(mrd),.force_miss(force_miss),.mwr(mwr),.mdout(mdout),.mdin(mdin),
	   .irq(irq),.ivector(ivector),.iack(ack));

  ////////////////////////////////////////////////////
  //
  //  I Cache
  // 
  ////////////////////////////////////////////////////

  wire irdy;
  wire i_ring_req,i_ring_ack,i_drive_ring,i_mc_ack;
  wire [TSIZE-1:0] i_slot_type;
  wire [31:0] i_slot_data;
  cache #(.TSIZE(TSIZE),.NBLINES(NBLINES),.NBWORDS(NBWORDS),.CTYPE(1'b1))
        icache(.clk(clk),.reset(reset),
               .rd(1'b1),.force_miss(1'b0),.wr(1'b0),.addr(iaddr),.rdata(inst),.wdata(0),.rdy(irdy),
               .ring_req(i_ring_req),.ring_ack(i_ring_ack),.drive_ring(i_drive_ring),
               .slot_type(i_slot_type),.slot_data(i_slot_data),
	       .mc_ack_in(i_mc_ack),.mc_ack_out(),.mc_count(mc_count),.mc_data(mc_data));

  ////////////////////////////////////////////////////
  //
  //  Local i/o (top 32KB of address space, ie, negative offsets from $0)
  // 
  ////////////////////////////////////////////////////

  wire io_addr = (maddr[31:15] == 17'h1FFFF);
  wire io_rd = !reset && mrd && io_addr;
  wire io_wr = !reset && mwr && io_addr;

  // simple local i/o state machine: respond on cycle following i/o request
  reg saved_io_rd,saved_io_wr;
  wire io_rdy = saved_io_rd || saved_io_wr;
  reg [14:2] saved_io_addr;
  always @(posedge clk) begin
    saved_io_addr = maddr[14:2];
    saved_io_rd = io_rd && !io_rdy;
    saved_io_wr = io_wr && !io_rdy;
  end
  wire io_req = io_rdy;

  // local i/o address assignments (2**13 words)
  localparam io_corenum =    13'h1FFF;  // [-4($0)] corenum and ncores
  localparam io_cyclelo =    13'h1FFE;  // [-8($0)] low-order word of cycle counter
  localparam io_cyclehi =    13'h1FFD;  // [-12$(0)] high-order word of cycle counter
  localparam io_slot_meter = 13'h1FE?;  // [-128($0)] slot type counters (need 2**TSIZE locations)
  localparam io_mem_meter =  13'h1E??;  // [-1024($0)] mem access counters (need 4 * 2**SSIZE locations)

  // corenum register
  wire [7:0] corenum = CORENUM;
  wire [7:0] ncores = NCORES;

  // cycle counter
  reg [47:0] cycle_count;
  always @(posedge clk) cycle_count <= reset ? 0 : cycle_count + 1;

  // slot type counters
  wire [31:0] slot_count;
  generate
    if (SLOT_METERS) begin
      localparam NLOCNS = (1 << TSIZE);

      (* ram_style = "distributed" *)
      reg [31:0] slot_counter[NLOCNS-1:0];
      always @(posedge clk) 
        slot_counter[slot_type_in] <= slot_counter[slot_type_in] + 1;

      // initialize counters for simulation
      integer i;
      initial begin
        for (i = 0; i < NLOCNS; i = i + 1) slot_counter[i] = 0;
      end;

      assign slot_count = slot_counter[saved_io_addr];
    end
    else
      assign slot_count = 0;
  endgenerate

  // memory access counters (dreads, dwrites, ireads, ???)
  wire [31:0] mem_count;
  generate
    if (MEM_METERS) begin
      localparam NLOCNS = 4 * (1 << SSIZE);
      localparam NBCACHELINE = 30-NBWORDS;  // number of address bits to address a cache line

      (* ram_style = "distributed" *)
      reg [31:0] mem_counts[NLOCNS-1:0];

      wire write = slot_data_in[NBCACHELINE];
      wire iaccess = slot_data_in[NBCACHELINE+1];
      wire [SSIZE+1:0] addr = {iaccess,write,saved_io_addr[SSIZE-1:0]};

      always @(posedge clk)
        if (slot_type_in == ADDR) mem_counts[addr] <=  mem_counts[addr] + 1;

      // initialize counters for simulation
      integer i;
      initial begin
        for (i = 0; i < NLOCNS; i = i + 1) mem_counts[i] = 0;
      end

      assign mem_count = mem_counts[saved_io_addr];
    end
    else
      assign mem_count = 0;
  endgenerate

  // handle read requests
  reg [31:0] io_rdata;
  always @(*) begin
    casez (saved_io_addr)
      io_corenum: io_rdata = {16'h0000,ncores,corenum};
      io_cyclelo: io_rdata = cycle_count[31:0];
      io_cyclehi: io_rdata = {16'h0000,cycle_count[47:32]};
      io_slot_meter: io_rdata = slot_count;
      io_mem_meter: io_rdata = mem_count;
      default:    io_rdata = 32'hXXXXXXXX;
    endcase
  end
  
  ////////////////////////////////////////////////////
  //
  //  D Cache
  // 
  ////////////////////////////////////////////////////

  wire mem_rd = !reset && mrd && !io_addr;
  wire mem_wr = !reset && mwr && !io_addr;
  wire mem_req = mem_rd || mem_wr;

  wire mem_rdy;
  wire d_ring_req,d_ring_ack,d_drive_ring;
  wire [TSIZE-1:0] d_slot_type;
  wire [31:0] d_slot_data,mem_rdata;

  cache #(.TSIZE(TSIZE),.NBLINES(NBLINES),.NBWORDS(NBWORDS),.CTYPE(1'b0))
        dcache(.clk(clk),.reset(reset),
               .rd(mem_rd && !mem_rdy),.force_miss(force_miss),.wr(mem_wr && !mem_rdy),
               .addr(maddr),.rdata(mem_rdata),.wdata(mdout),.rdy(mem_rdy),
               .ring_req(d_ring_req),.ring_ack(d_ring_ack),.drive_ring(d_drive_ring),
               .slot_type(d_slot_type),.slot_data(d_slot_data),
               .mc_ack_in(mc_dest == CORENUM),.mc_ack_out(i_mc_ack),.mc_count(mc_count),.mc_data(mc_data));

  // allow cpu to proceed when all memory requests are satisfied
  assign mdin = io_req ? io_rdata : mem_rdata;
  assign rdy = reset || (irdy && ((mrd || mwr) ? (io_rdy || mem_rdy) : 1'b1));

  ////////////////////////////////////////////////////
  //
  //  Ring Interface
  // 
  ////////////////////////////////////////////////////

  // to request a slot, devices assert their ring_req.
  // their ring_ack is asserted when it's their turn to output a slot.
  // devices assert their drive_ring when generating or rewriting a slot

  // nullify any incoming slots that we put on ring (this only matters when
  // when don't have the token).
  wire nullify_slot = reset || (slot_source_in == CORENUM);

  // if we have a ring request pending, grab the token when it comes around.
  // we keep the token as long as a local device has asserted their ring request
  // plus one additional slot when we output a TOKEN.
  reg have_token;
  wire ring_req = i_ring_req || d_ring_req;
  wire can_xmit = !reset && ((slot_type_in == TOKEN && ring_req) || have_token);
  always @(posedge clk) have_token <= can_xmit && ring_req;

  // we drive the ring if we're nullifying, generating or rewriting a slot
  wire drive_ring = can_xmit || nullify_slot;
  assign d_ring_ack = can_xmit && d_ring_req;   // D cache gets priority
  assign i_ring_ack = can_xmit && !d_ring_req && i_ring_req;

  // all slots we generate get our corenum as the source.  The source
  // field on rewitten slots is unchanged.
  assign slot_source_out = drive_ring ? (ring_req ? CORENUM : 0) :
                           slot_source_in;

  assign slot_type_out = d_drive_ring ? d_slot_type :
                         i_drive_ring ? i_slot_type :
		         have_token ? TOKEN :   // have token, but no requests
			 nullify_slot ?  NULL : // don't have token, but nullifying
                         slot_type_in;

  assign slot_data_out = d_drive_ring ? d_slot_data :
                         i_drive_ring ? i_slot_data :
                         (have_token || nullify_slot) ? 32'h00000000 :
                         slot_data_in;
endmodule




