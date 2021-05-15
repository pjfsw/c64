#import "sid.asm"

BasicUpstart2(programstart)
    *=$080e

programstart:
    jsr memorySetup
    jsr sidSetup
    jsr irqSetup

    jmp *

sidSetup:
    lda #<track
    sta trackPtr
    lda #>track
    sta trackPtr+1

    lda #$00
    sta voice1+4
    sta voice2+4
    sta voice3+4
    lda #$23 // Decay 750 ms
    sta voice1+5
    sta voice2+5
    lda #$25
    sta voice3+5
    lda #$58 // Sustain 3, Release 204 ms
    sta voice1+6
    sta voice3+6
    lda #$16
    sta voice2+6
    lda #$0f // Volume
    sta $d418

    lda #0
    sta tick

    rts

irqSetup:
    sei
    lda #<playIrq
    sta $fffe
    lda #>playIrq
    sta $ffff
    cli
    rts

memorySetup:
    sei

    lda #$35    // RAM $0000-$CFFF, IO $D000-$DFFF, RAM $E000-$FFFF
    sta $01

    lda #$7f    // Clear CIA interrupts
    sta $dc0d
    sta $dd0d
    lda $dc0d   // Clear pending interrupts by reading it
    lda $dd0d

    lda #$01
    sta $d01a   // Raster IRQ enable

    lda #$f8    // Raster Y position
    sta $d012

    lda #$1b    // 25 rows
    sta $d011

    lda #$c8    // 40 cols, two color
    sta $d016

    rts

.label trackLength = 32;
.label speed = 7;

playIrq:
{
    sta a_temp
    stx x_temp
    sty y_temp

    asl $d019

    lda #BLUE
    sta $d020

    .for (var i = 0; i < 21; i++) {
        lda voice1+i
        sta VOICE1+i
    }

// IRQ BEGIN
    lda tick
    cmp #0
    bne !+
    jsr playNextRow
    jsr advanceSong
    jmp tickPost
!:
    cmp #speed-3
    bne tickPost

    // Turn off voice
    jsr prepareNextRow

tickPost:
    jsr pulseWidth
    ldx tick
    inx
    cpx #speed
    bne !+
    ldx #0
!:
    stx tick

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
        sta voice1+2 + i * 7
        lda pwmHi,x
        sta voice1+3 + i * 7
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
        sta voice1 + i * 7 + 4
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
        sta voice1 + i * 7
        lda frequency_hi,x
        sta voice1 + 1 + i * 7
        lda #$41 // Saw + voice on
        sta voice1 + 4 + i * 7

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
    .byte 36,60,72
    .byte  0,62,0
    .byte 36,63,0
    .byte  0,60,72

    .byte 48,62,0
    .byte 36,63,67
    .byte 0,60,70
    .byte 36,62,0

    .byte 0,70,72
    .byte 36,60,0
    .byte 0,62,0
    .byte 36,63,72

    .byte 48,60,0
    .byte 0,62,67
    .byte 36,63,0
    .byte 0,60,0
//--------------------
    .byte 32,60,65
    .byte  0,62,0
    .byte 32,63,0
    .byte  0,60,65

    .byte 44,62,0
    .byte 32,63,0
    .byte 0,60,0
    .byte 32,62,0

    .byte 0,67,65
    .byte 32,60,0
    .byte 0,62,0
    .byte 32,65,65

    .byte 44,60,0
    .byte 0,62,67
    .byte 32,63,0
    .byte 0,60,0

.function getPw(cycle) {
    .return 2048 + 2000 * sin((cycle+240)*PI/128)
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

voice1:
    .fill 7,0
voice2:
    .fill 7,0
voice3:
    .fill 7,0

*=$02 "Zeropage" virtual
.zp {
trackPtr:
    .byte 0,0
}
