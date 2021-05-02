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
    sta VOICE1+4
    sta VOICE2+4
    sta VOICE3+4
    lda #$09 // Decay 750 ms
    sta VOICE1+5
    sta VOICE2+5
    lda #$0a
    sta VOICE3+5
    lda #$36 // Sustain 3, Release 204 ms
    sta VOICE1+6
    sta VOICE2+6
    sta VOICE3+6
    lda #$0f // Volume
    sta $d418

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

#import "crasid_irq.asm"

