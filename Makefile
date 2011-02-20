MIPS=/afs/csail.mit.edu/proj/redsocs/mips-elf/bin
MEM=Tests/cache.s

HFILES = ring.h risc.h
SIM = bhiv_sim.v bram.v cache.v core.v fifo.v risc.v
SYNTH = bram.v cache.v core.v fifo.v risc.v mem.v bhiv.v

mem.v: $(MEM)
	$(MIPS)/mips-elf-cpp $(MEM) | $(MIPS)/mips-elf-as -mips3 -O1 -o mem.o 
	$(MIPS)/mips-elf-ld -n -N -Ttext 0 mem.o -o mem.elf
	$(MIPS)/mips-elf-objcopy -O binary mem.elf mem.bin
	$(MIPS)/mips-elf-objdump -S mem.elf >mem.dump
	python bhivmem.py mem.bin mem.v

sim: mem.v
	vlib work
	for v in $(SIM); do vlog $$v; done;
	vsim -c bhiv_sim -do simulate.do >/dev/null

synth::
	cat /dev/null >bhiv.prj
	for v in $(SYNTH); do echo verilog work $$v >>bhiv.prj; done;
	xst -ifn bhiv.xst -ofn bhiv.syr	

clean::
	@rm -rf work xst
	@rm -f *.ngc *.ngr *.xrpt *.lso
	@rm -f trace mem.* *~ *.o *.wlf transcript
