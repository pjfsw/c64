#import "vic.asm"

BasicUpstart2(programstart)
    *=$080e

programstart:
    lda #BLACK
    sta $d020
    lda #LIGHT_GRAY
    sta $d021

    jsr init_memory
!:
    jsr game
    jmp !-

init_memory:
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

#import "game.asm"
