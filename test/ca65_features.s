; Toolchain smoke test: exercises the ca65 features the rosco_6502 sources
; rely on - string escapes, a backslash character constant, and the generic
; macro package (bge/blt).
                .setcpu "65SC02"
                .macpack generic
                .macpack longbranch

                .segment "CODE"

start:          lda     #'\'                    ; backslash character constant
                cpx     #$20
                bge     :+
                blt     :+
:               ldy     #<message
                rts

                .segment "RODATA"
message:        .byte   "escaped\r\n", 0
