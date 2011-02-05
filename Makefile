MIPS=/afs/csail.mit.edu/proj/redsocs/mips-elf/bin
MEM=Tests/test_v2.s

mem.v: $(MEM)
	$(MIPS)/mips-elf-cpp $(MEM) | $(MIPS)/mips-elf-as -O1 -o mem.o 
	$(MIPS)/mips-elf-ld -n -N -Ttext 0 mem.o -o mem.elf
	$(MIPS)/mips-elf-objcopy -O binary mem.elf mem.bin
	$(MIPS)/mips-elf-objdump -S mem.elf >mem.dump
	python bhivmem.py mem.bin mem.v

sim: mem.v
	vlib work
	vlog bhiv.v
	vsim -c bhiv -do simulate.do >/dev/null

iverilog: mem.v
	iverilog -o bhiv.o bhiv.v
	vvp bhiv.o >trace

synth::
	xst -ifn bhiv.xst -ofn bhiv.syr	

clean::
	@rm -rf work xst
	@rm -f *.ngc *.ngr *.xrpt *.lso
	@rm -f trace mem.* *~ *.o *.wlf transcript
