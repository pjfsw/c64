    .const SCREEN=$0400
    .const SCREEN2=$3c00
    .const ROWS_TO_RENDER_PER_FRAME=4
    .const FRAMES_TO_RENDER_TILES=6
    .const BORDER_COLOR = 0
    .const DEBUG_COLOR = 6

BasicUpstart2(program_start)
    *=$080e

program_start:
    jsr setup_screen
    sei
    ldx #<irq
    ldy #>irq
    lda #$fa
    jsr lib_setup_irq
    cli
    jmp *

irq:
    sta 1 + !save_a+
    stx 1 + !save_x+
    sty 1 + !save_y+

    //lda frame
    //clc
    //adc #1
    //sta frame
    //and #15
    //bne !irq_end+

    lda #DEBUG_COLOR
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

    lda bottom
    clc
    adc #1
    sta bottom  // The world position at the bottom of the sceren

    adc #FRAMES_TO_RENDER_TILES*ROWS_TO_RENDER_PER_FRAME
    sta bottom_render
    jmp !irq_end+

!:
    cpx #FRAMES_TO_RENDER_TILES+1
    bcs !+
    jsr draw_tiles
!:

!irq_end:
    lda #BORDER_COLOR
    sta $d020

    set_next_irq()

    lda #$ff   // this is the orthodox and safe way of clearing the interrupt condition of the VICII.
    sta $d019

!save_a:
    lda #0
!save_y:
    ldy #0
!save_x:
    ldx #0

    rti

irq_hud:
    sta 1 + !save_a+
    stx 1 + !save_x+
    sty 1 + !save_y+

    lda #DEBUG_COLOR
    sta $d020

    lda #hud_sprite/64
hud_sprite_ptr_sta:
    .for (var i = 0; i < 7; i++) {
        sta SCREEN+$3f8+i
    }
    lda #238
    ldx #BORDER_COLOR
    .for (var i = 0; i < 7; i++) {
        sta $d001 + i * 2
        stx $d027 + i // color
    }
    .for (var i = 0; i < 7; i++) {
        lda #i*48+24
        sta $d000 + i * 2
    }
    lda #$60
    sta $d010
    lda #$7f
    sta $d015 // sprite enable
    sta $d01d // double width
    lda #0
    sta $d01b // sprite priority

    set_next_irq()

    lda #BORDER_COLOR
    sta $d020
    lda #$ff   // this is the orthodox and safe way of clearing the interrupt condition of the VICII.
    sta $d019

!save_a:
    lda #0
!save_y:
    ldy #0
!save_x:
    ldx #0
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

    // Fix hud sprite ptr
    clc
    adc #3
    .for (var i = 0; i < 7; i++) {
        sta 2 + hud_sprite_ptr_sta + i * 3
    }

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
    ldx scroll
    lda d011,x
    sta $d011

    clc
    lda bottom
    adc #FRAMES_TO_RENDER_TILES*ROWS_TO_RENDER_PER_FRAME
    sta bottom_render

    jsr flip_screen
    .for (var i = 0; i < FRAMES_TO_RENDER_TILES; i++) {
        jsr draw_tiles
    }

    rts

.macro set_next_irq() {
    ldx next_irq
    lda irq_lo,x
    sta $fffe
    lda irq_hi,x
    sta $ffff
    lda irq_at,x
    sta $d012
    inx
    cpx #irq_lo_end-irq_lo
    bne !+
    ldx #0
!:
    stx next_irq
}

#import "../../lib/src/irq.asm"

// HUD DATA
    .align 64
hud_sprite:
    .fill 63,255

// LEVEL DATA
tilemap: .fill 256,i/16
world:  .fill 256,i


scroll: .byte 7
bottom: .byte 0
d011:   .byte $10,$11,$12,$13,$14,$15,$16,$17
d018:   .byte $14, $f4
next_irq: .byte 0
irq_lo: .byte  <irq_hud, <irq
irq_lo_end:
irq_hi: .byte  >irq_hud, >irq
irq_at: .byte $ea, $f0

screen_lo: .byte <SCREEN2,<SCREEN
screen_hi: .byte >SCREEN2,>SCREEN
screen_number: .byte 0
bottom_render: .byte 0
frame: .byte 0
*=$02 "Zeropage" virtual
.zp {
    screen_ptr: .word 0
}