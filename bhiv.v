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

`timescale 1 ns / 100 ps

////////////////////////////////////////////////////////////////////////////////
//
//	Multicore system with ring interconnect (simulation top level)
//
////////////////////////////////////////////////////////////////////////////////

module bhiv(
  input clk,
  input reset
);
  localparam TSIZE = 4;   // slot type field is [TSIZE-1:0]
  localparam SSIZE = 4;   // slot source field is [SSIZE-1:0]
  localparam NCORES = 3;  // must be less than (1 << SSIZE)

  localparam NBLINES = 7;  // caches have 2**7 lines
  localparam NBWORDS = 3;   // with 2**3 words each
  localparam NBCACHELINE = 30-NBWORDS;  // number of address bits to address a cache line
  localparam NWORDS = (1 << NBWORDS);  // words per cache line

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

      localparam FIRSTCORE = (i == 1);

      // wire up a core!
      core #(.CORENUM(i),
             .NCORES(NCORES),
             .TSIZE(TSIZE),
             .SSIZE(SSIZE),
             .NBLINES(NBLINES),
             .NBWORDS(NBWORDS),
             .SLOT_METERS(FIRSTCORE),
             .MEM_METERS(FIRSTCORE))
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

  `include "ring.h"

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

  // simple counter-baseed state machine
  //   idle when count == NWORDS
  //   mem access when 0 <= count < NWORDS
  reg [NBWORDS:0] mcnt;
  wire m_idle = reset || (mcnt == NWORDS);

  // decode output of address fifo
  wire [NBCACHELINE-1:0] line = addr_out[NBCACHELINE-1:0];
  wire write = addr_out[NBCACHELINE];
  wire [SSIZE-1:0] dest = addr_out[SSIZE+NBCACHELINE+1 - 1:NBCACHELINE+1];

  // THIS IS WRONG! doesn't account for pipe state on reads
  wire [31:0] mem_out;
  always @(posedge clk) begin
    if (reset) mcnt <= NWORDS;
    else if (!addr_empty && m_idle) mcnt <= 0;
    else if (!m_idle) mcnt <= mcnt + 1;

    // fill in head of memory controller ring
    mc_dest[0] <= (!m_idle && !write) ? dest : 0;
    mc_count[0] <= mcnt[NBWORDS-1:0];
    mc_data[0] <= (!m_idle && !write) ? mem_out : 0;
  end
  assign wdata_rd = !m_idle && write;  // consume a word of data from the wdata fifo
  assign addr_rd = (mcnt == NWORDS-1);  // move to the next address in the addr fifo

  // main memory, currently just a block ram
  mem main(.addra({line,mcnt[NBWORDS-1:0]}),.clka(clk),.dina(wdata_data),.douta(mem_out),.wea(!m_idle && write),
           .addrb(0),.clkb(clk),.dinb(0),.doutb(),.web(0));

endmodule
