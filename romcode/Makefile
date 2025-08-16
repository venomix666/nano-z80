all:	install

install: nano-z80.hex
	cp nano-z80.hex ../src
	cp nano-z80.hex ../verilator

nano-z80.hex: nano-z80.bin
	./mkhexfile.py nano-z80.bin nano-z80.hex

nano-z80.bin: nano-z80.z80
	zasm -o nano-z80.bin nano-z80.z80
	
clean:
	$(RM) -f *.bin *.lst *.hex
