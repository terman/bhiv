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
//	2-port synchronous block ram as supported by Virtex 5 
//
////////////////////////////////////////////////////////////////////////////////


// Xilinx tools will infer a 2-port BRAM if one port is R/W and the other is R-only.
// Note that they won't infer correctly if both ports are R/W... bummer...
// KLUDGE: combine the two write ports assuming they aren't both active at once.
module bram #(parameter
  WIDTH=32,	// width of each entry in FIFO
  NADDR=10      // 2**NADDR entries
) (
  input clk,
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

  // kludge: combine write ports in such a way if both WEs are active
  // the write should fail in simulation.  Also should optimize correctly
  // if weB is tied to 0.
  wire we = weA || weB;
  wire [NADDR-1:0] waddr = (weA & !weB) ? addrA : ((weB & !weA) ? addrB : 32'hXXXXXXXX);
  wire [WIDTH-1:0] wdata = (weA & !weB) ? wdataA : ((weB & !weA) ? wdataB : 32'hXXXXXXXX);

  // some debugging support
  always @(*)
    if (weA && weB) $display("***** both WEs active in module bram");

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
