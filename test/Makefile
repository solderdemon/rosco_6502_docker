# Toolchain smoke test - builds one ca65/ld65 target and one vasm/vlink
# target, then converts the result with srec_cat.

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

START_ADDR := 0x0800

all: ca65_features.bin ca65_features.hex vasm_features.bin

ca65_features.o: ca65_features.s
	ca65 -g -D__ROSCO__=1 --cpu 65SC02 --feature string_escapes --list-bytes 0 \
		-l ca65_features.lst $< -o $@

ca65_features.bin: ca65_features.o
	ld65 -v -t none -S $(START_ADDR) -Ln ca65_features.sym -m ca65_features.map $< -o $@
	da65 --comments 4 --cpu 65SC02 --start-addr $(START_ADDR) $@ >ca65_features.dis

ca65_features.hex: ca65_features.bin
	srec_cat $< -Binary -offset $(START_ADDR) -o $@ -Intel -address-length=2

vasm_features.o: vasm_features.asm
	vasm6502_oldstyle -quiet -wdc02 -opt-branch -esc -Fvobj -L vasm_features.lst -o $@ $<

vasm_features.bin: vasm_features.o
	vlink -brawbin1 -Ttext $(START_ADDR) -Mvasm_features.sym -o $@ $<

clean:
	$(RM) *.o *.bin *.hex *.lst *.sym *.map *.dis

.PHONY: all clean
