BasicUpstart2(programstart)

*=$080e
programstart:
    jsr init_memory
!:
    jsr start
    jsr game
    jsr gameover
    jmp !-

init_memory:
    sei

    lda #$7f    // Clear CIA interrupts
    sta $dc0d
    sta $dd0d
    lda $dc0d   // Clear pending interrupts by reading it
    lda $dd0d

    lda #$01
    sta $d01a   // Raster IRQ enable

    lda #$f8    // Raster Y position
    sta $d012

    lda #$1b    // Raster Y < 256 + character mode + 25 lines
    sta $d011

    lda #$35    // RAM $0000-$CFFF, IO $D000-$DFFF, RAM $E000-$FFFF
    sta $01

    lda #<default_irq
    sta $fffe
    lda #>default_irq
    sta $ffff

    cli
    rts

default_irq:
{
    sta a_temp
    stx x_temp
    sty y_temp

    lda #$ff
    sta $d019

    lda a_temp:#0
    ldx x_temp:#0
    ldy y_temp:#0
    rti
}

#import "start.asm"
#import "game.asm"
#import "gameover.asm"