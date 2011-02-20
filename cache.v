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
//	2-way set-associative cache with ring interface
//
////////////////////////////////////////////////////////////////////////////////

//   NBLINES is the number of bits in the cache line index
//   NBWORDS is the number of bits in the cache line offset
//    TSIZE is the number of bits in the slot type field
module cache #(parameter TSIZE=4,NBLINES=7,NBWORDS=3,CTYPE=1'b0) (
  input clk,
  input reset,
  // cpu port
  input rd,
  input force_miss,
  input wr,
  input [31:2] addr,
  output [31:0] rdata,
  input [31:0] wdata,
  output rdy,
  // ring port
  output ring_req,
  input ring_ack,
  output drive_ring,
  output [TSIZE-1:0] slot_type,
  output [31:0] slot_data,
  // memory controller port
  input mc_ack_in,
  output mc_ack_out,
  input [NBWORDS-1:0] mc_count,
  input [31:0] mc_data
);

  localparam NBTOTAL = NBLINES + NBWORDS;
  localparam NLINES = (1 << NBLINES);
  localparam NWORDS = (1 << NBWORDS);

  reg [2:0] state,next_state;
  localparam s_idle = 3'd0;   // cache is idle
  localparam s_read_addr = 3'd1;  // waiting to issue read ADDR slot
  localparam s_mc_data = 3'd2;  // waiting for DATA from mc
  localparam s_write_back = 3'd3;  // waiting to issue WDATA slot
  localparam s_write_addr = 3'd4;  // waiting to issue write ADDR slot

  reg [31:2] saved_addr;
  reg saved_rd,saved_wr,saved_force_miss;
  always @(posedge clk) begin
    saved_addr <= addr;
    saved_rd <= !reset && rd;
    saved_wr <= !reset && wr;
    // force miss only happens on first cache probe, causing a refill
    // potentially preceeded by a writeback if cache line is dirty.
    // signal is only asserted until refill is complete so that
    // post-refill cache probe is not forced to miss
    if (reset || (saved_force_miss && state == s_mc_data && next_state == s_idle))
      saved_force_miss <= 0;
    else if (!reset && rd && force_miss)
      saved_force_miss <= 1;
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
  wire hit0 = v0 && (way0_tag == tag);
  wire hit1 = v1 && (way1_tag == tag);
  wire miss = saved_force_miss || ((saved_rd || saved_wr) && !hit0 && !hit1);

  // state machine -- handles writeback, refills on a miss
  wire write_mc_data = (state == s_mc_data) && mc_ack_in;
  // on a forced miss, use way that hit if any, otherwise use LRU way
  wire refill_way = saved_force_miss ? (hit0 ? 0 : (hit1 ? 1 : lru[line])) : lru[line];
  wire refill_write_way0 = write_mc_data && (refill_way == 0);
  wire refill_write_way1 = write_mc_data && (refill_way == 1);
  wire dirty = refill_way ? dirty1[line] : dirty0[line];

  // index for accessing words in cache line during writeback
  reg [NBWORDS-1:0] wb_count;
  wire [NBWORDS-1:0] wb_count_next = (state == s_idle) ? 0 : (ring_ack ? wb_count+1 : wb_count);

  always @(*) begin
    next_state = state;   // default -- no change in state
    if (reset) next_state = s_idle;
    else case (state)
      s_idle:       // waiting for a miss
        if (miss) next_state = dirty ? s_write_back : s_read_addr;
      s_write_back: // flush cache line words on dirty miss
        if (ring_ack && wb_count == (NWORDS-1)) next_state = s_write_addr;
      s_write_addr: // output write address for dirty cache line
        if (ring_ack) next_state = s_read_addr;
      s_read_addr:  // output read address for refill
        if (ring_ack) next_state = s_mc_data;
      s_mc_data:    // wait for data from memory controller
        if (mc_ack_in && mc_count == (NWORDS-1)) next_state = s_idle;
      default:
        next_state = s_idle;
    endcase
  end

  // update cache state
  always @(posedge clk) begin
    wb_count <= wb_count_next;
    state <= next_state;

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
  assign rdy = !saved_force_miss && ((saved_rd || saved_wr) && (hit0 || hit1));
  assign rdata = hit0 ? way0_cpu_data : way1_cpu_data;

  // update LRU indicator on each hit
  always @(posedge clk) if (rdy) lru[line] <= hit0;

  // daisy chain to determine which cache is consumimg words
  // arriving from memory controller
  assign mc_ack_out = mc_ack_in && (state != s_mc_data);

  // output slot
  `include "ring.h"
  assign drive_ring = ring_ack;   // drive ring when it's our turn for a slot
  assign ring_req = (state == s_read_addr) || (state == s_write_addr) || (state == s_write_back);
  assign slot_type = (state == s_write_back) ? WDATA : ADDR;
  assign slot_data = (state == s_read_addr) ? {CTYPE,1'b0,saved_addr[31:NBWORDS+2]} :
                     (state == s_write_addr) ? {CTYPE,1'b1,refill_way ? way1_tag : way0_tag,line} :
		     refill_way ? way1_ring_data : way0_ring_data;   // state == s_write_back
endmodule
