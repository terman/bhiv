# convert mips elf file into BRAMs (up to 16k x 32 with byte writes)
#!/usr/bin/env python
import sys,os,os.path,traceback

# get name of code/module
if (len(sys.argv) != 3):
    print "Usage: mipsmem bin_input v_output"
    sys.exit(0)

# read in binary file in big-endian format
locations = []
f = open(sys.argv[1],'rb')
binary = f.read()
f.close()
nbytes = 0
word = 0L
for c in binary:
    word = ((word & 0xFFFFFF)<<8) + ord(c)
    nbytes += 1
    if nbytes % 4 == 0:
        locations.append(int(word))
if nbytes % 4 != 0:
    while nbytes % 4 != 0:
        word = (word & 0xFFFFFF)<<8
        nbytes += 1
    locations.append(int(word))
nlocs = len(locations)

#for l in locations: print "%08x" % l

# helper function returns binary string with WIDTH
# digits from BITOFFSET within location LOCN
def bits(width,bitoffset,locn):
    if locn >= nlocs: v = 0
    else: v = locations[locn]
    v >>= bitoffset;
    result = []
    for i in xrange(width):
        if v % 2 == 0: result.append('0')
        else: result.append('1')
        v >>= 1
    result.reverse()
    return ''.join(result)

# see what BRAM organization to use, need to support byte writes
if (nlocs <= 2048):
    nmems = 4            # use four 2048 x 8 BRAMs
    bram = "RAMB16_S9_S9"
    naddr = 11
    width = 8
    pwidth = 1
elif (nlocs <= 4096):
    nmems = 8            # use eight 4096 x 4 BRAMs
    bram = "RAMB16_S4_S4"
    naddr = 12
    width = 4
    pwidth = 0
elif (nlocs <= 8192):
    nmems = 16           # use sixteen 8192 x 2 BRAMs
    bram = "RAMB16_S2_S2"
    naddr = 13
    width = 2
    pwidth = 0
elif (nlocs <= 16384):
    nmems = 32           # use thirty-two 16384 x 1 BRAMs
    bram = "RAMB16_S1_S1"
    naddr = 14
    width = 1
    pwidth = 0
else:
    print "Oops: %d is too big, can only support up to 16k locations" % nlocs
    sys.exit(0)

# ready to create appropriate Verilog module
try:
    v = open(sys.argv[2],'w')

    # output standard module prologue
    v.write("""// dual-port read/write memory initialized with %s code
  module %s(addra,clka,dina,douta,wea,addrb,clkb,dinb,doutb,web);
  input [13:0] addra,addrb;    // up to 16K locations
  input clka,clkb;             // memory has internal address regs
  input [31:0] dina,dinb;      // appears after rising clock edge
  output [31:0] douta,doutb;   // written at rising clock edge
  input wea,web;         // enables write port

  // we're using %d out of %d locations
""" % (sys.argv[1],os.path.splitext(sys.argv[2])[0],nlocs,1 << naddr))

    # output appropriate number of BRAM instances
    for i in xrange(nmems):
        lo = i * width
        hi = lo + width - 1
        if pwidth > 0:
            paritya = ".DIPA(%d'h0)," % pwidth
            parityb = ".DIPB(%d'h0)," % pwidth
        else:
            paritya = ""
            parityb = ""
        v.write("  %s m%d(.CLKA(clka),.ADDRA(addra[%d:0]),.DIA(dina[%d:%d]),%s.DOA(douta[%d:%d]),.WEA(wea),.ENA(1'b1),.SSRA(1'b0),\n" % (bram,i,naddr-1,hi,lo,paritya,hi,lo))
        v.write("             .CLKB(clkb),.ADDRB(addrb[%d:0]),.DIB(dinb[%d:%d]),%s.DOB(doutb[%d:%d]),.WEB(web),.ENB(1'b1),.SSRB(1'b0));\n" % (naddr-1,hi,lo,parityb,hi,lo))
        # output defparams to initialize this BRAM block
        nwords = 256/width
	for init in xrange(64):
	    v.write("  defparam m%d.INIT_%02X = 256'b" % (i,init))
            start = init * nwords
            first = True
            for locn in xrange(start+nwords,start,-1):
                if first: first = False
                else: v.write('_')
                v.write(bits(width,lo,locn-1))
            v.write(';\n')

    v.write("\nendmodule")
    v.close()
except Exception,e:
    print "Oops:",e
    sys.exit(0)

# create a vmh file too
try:
    v = open(os.path.splitext(sys.argv[2])[0]+'.vmh','w')
    v.write("@0\n")
    for w in locations:
        v.write("%08x\n" % w)
    v.close()
except Exception,e:
    print "Oops:",e
    sys.exit(0)

# finished!
