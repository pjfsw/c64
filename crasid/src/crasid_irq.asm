#importonce

.label trackLength = 32;
.label speed = 6;

playIrq:
{
    sta a_temp
    stx x_temp
    sty y_temp

    asl $d019

    lda #BLUE
    sta $d020


// IRQ BEGIN
    dec tick
    bne !+

    jsr prepareNextRow
    jmp tickPost

!:
    bpl tickPost

    lda #speed
    sta tick

    jsr playNextRow
    jsr advanceSong
tickPost:
    jsr pulseWidth

// IRQ END
end:
    lda #LIGHT_BLUE
    sta $d020
    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti

pulseWidth:
    .for (var i = 0; i < 3; i++) {
        inc pwmPtr+i
        ldx pwmPtr+i
        lda pwmLo,x
        sta VOICE1+2 + i * 7
        lda pwmHi,x
        sta VOICE1+3 + i * 7
    }
    rts

prepareNextRow:
    ldy row
    lda rowOffset,y
    tay
    .for (var i = 0; i < 3; i++) {
        lda (trackPtr),y
        beq !+
        // Voice off
        lda #$40
        sta VOICE1 + i * 7 + 4
    !:
        iny
    }
    rts

playNextRow:
    ldy row
    lda rowOffset,y
    tay
    .for (var i = 0; i < 3; i++) {
        lda (trackPtr),y
        beq !+
        tax
        lda frequency_lo,x
        sta VOICE1 + i * 7
        lda frequency_hi,x
        sta VOICE1 + 1 + i * 7
        lda #$41 // Saw + voice on
        sta VOICE1 + 4 + i * 7

        lda #0
        sta pwmPtr + i
    !:
        iny
    }
    rts

advanceSong:
    ldx row
    inx
    cpx #trackLength
    bne !+
    ldx #0
!:
    stx row

    rts
}


tick: .byte 0
row: .byte 0
pwmPtr: .byte 0,0,0

rowOffset:
    .fill 64,i*3
track:
    .byte 36,60,84
    .byte  0,62,0
    .byte 36,63,0
    .byte  0,60,84

    .byte 48,62,0
    .byte 36,63,0
    .byte 0,60,0
    .byte 36,62,0

    .byte 0,70,84
    .byte 36,60,0
    .byte 0,62,0
    .byte 36,63,84

    .byte 48,60,0
    .byte 0,62,79
    .byte 36,63,0
    .byte 0,60,0
//--------------------
    .byte 32,60,77
    .byte  0,62,0
    .byte 32,63,0
    .byte  0,60,77

    .byte 44,62,0
    .byte 32,63,0
    .byte 0,60,0
    .byte 32,62,0

    .byte 0,67,77
    .byte 32,60,0
    .byte 0,62,0
    .byte 32,65,77

    .byte 44,60,0
    .byte 0,62,75
    .byte 32,63,0
    .byte 0,60,0

.function getPw(cycle) {
    .return 2048 + 2000 * sin((cycle+224)*PI/128)
}

pwmLo:
    .fill 256, <getPw(i)
pwmHi:
    .fill 256, >getPw(i)

.function getFrequency(note) {
    .return 440 * pow(2,(note-69+48)/12)
}

frequency_lo:
    .fill 256,<getFrequency(i)

frequency_hi:
    .fill 256,>getFrequency(i)

*=$02 "Zeropage" virtual
.zp {
trackPtr:
    .byte 0,0
}