    .const SCREEN=$0400
    .const SCREEN2=$3c00
    .const ROWS_TO_RENDER_PER_FRAME=4
    .const FRAMES_TO_RENDER_TILES=6

BasicUpstart2(program_start)
    *=$080e

program_start:
    jsr setup_screen
    sei
    ldx #<irq
    ldy #>irq
    lda #$f6
    jsr lib_setup_irq
    cli
    jmp *

irq:
    sta save_a
    stx save_x
    sty save_y

    lda frame
    clc
    adc #1
    sta frame
    and #7
    //bne !irq_end+

    lda #6
    sta $d020

    ldx scroll
    inx
    stx scroll
    txa
    and #7
    tax
    lda d011,x
    sta $d011
    cpx #0
    bne !+

    jsr flip_screen
    jsr reset_render
!:
    cpx #FRAMES_TO_RENDER_TILES
    bcs !+
    jsr draw_tiles
!:
    lda #14
    sta $d020

!irq_end:
    lda #$ff   // this is the orthodox and safe way of clearing the interrupt condition of the VICII.
    sta $d019

    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti

flip_screen:
    lda screen_number
    eor #1
    and #1
    sta screen_number
    tax
    lda d018,x
    sta $d018
    lda screen_lo,x
    sta screen_ptr
    lda screen_hi,x
    sta screen_ptr+1
    rts

reset_render:
    lda bottom
    clc
    adc #1
    sta bottom  // The world position at the bottom of the sceren

    adc #FRAMES_TO_RENDER_TILES*ROWS_TO_RENDER_PER_FRAME
    sta bottom_render
    rts

draw_tiles:
    lda bottom_render
    tax
    sec
    sbc #ROWS_TO_RENDER_PER_FRAME
    sta bottom_render
    txa


!:
    {
        lda world,x
        ldy #39
    !:
        sta (screen_ptr),y
        dey
        bpl !-

        clc
        lda #40
        adc screen_ptr
        sta screen_ptr
        bcc !+
        inc screen_ptr+1
    !:
    }
    dex
    cpx bottom_render
    bne !-
    rts

setup_screen:
    lda #$10 // Default vertical scroll, screen height = 24, text mode
    sta $d011

    clc
    lda bottom
//    adc #1
//    sta bottom
    adc #FRAMES_TO_RENDER_TILES*ROWS_TO_RENDER_PER_FRAME
    sta bottom_render

    jsr flip_screen
    .for (var i = 0; i < FRAMES_TO_RENDER_TILES; i++) {
        jsr draw_tiles
    }
    jsr flip_screen
    jsr reset_render
    rts

#import "../../lib/src/irq.asm"

scroll: .byte 0
bottom: .byte 0
d011:   .byte $10,$11,$12,$13,$14,$15,$16,$17
world:  .fill 256,i
d018:   .byte $14, $f4
screen_lo: .byte <SCREEN2,<SCREEN
screen_hi: .byte >SCREEN2,>SCREEN
screen_number: .byte 0
bottom_render: .byte 0
frame: .byte 0
*=$02 "Zeropage" virtual
.zp {
    screen_ptr: .word 0
}