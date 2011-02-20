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
//	Parameterizable FIFO
//
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
