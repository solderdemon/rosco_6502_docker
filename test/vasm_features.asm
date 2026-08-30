; Toolchain smoke test for vasm6502_oldstyle and vlink.
                org     $0800
_start:         lda     #'A'
                sta     $C000
                bra     _done
_done:          rts
