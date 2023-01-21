    .const SCREEN=$0400
    .const SCREEN2=$3c00
    .const ROWS_TO_RENDER_PER_FRAME=3
    .const FRAMES_TO_RENDER_TILES=8
    .const BORDER_COLOR = 0
    .const DEBUG_COLOR1 = 11
    .const DEBUG_COLOR2 = 12
    .const TILE_WIDTH = 4
    .const TILES_PER_ROW = 40/TILE_WIDTH
    .const TILE_HEIGHT = 4
    .const FIXED_POINT = 8
    .const CHAR_HEIGHT = 8 // Well this is never gonna change but might as well constant it for readability
    .const CHAR_SUBPIXEL_SIZE = FIXED_POINT * CHAR_HEIGHT

BasicUpstart2(program_start)
    *=$080e

program_start:
    jsr setup_screen
    sei
    ldx #<irq
    ldy #>irq
    lda #$ec
    jsr lib_setup_irq
    cli
    jmp *

irq: {
    sta save_a
    stx save_x
    sty save_y

    lda #DEBUG_COLOR1
    sta $d020
    jsr update_hud
    lda #DEBUG_COLOR2
    sta $d020
    jsr update_screen
    lda #BORDER_COLOR
    sta $d020

    lda #$ff   // this is the orthodox and safe way of clearing the interrupt condition of the VICII.
    sta $d019

    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti

update_screen:
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

    add8(bottom, CHAR_SUBPIXEL_SIZE, bottom)
    add16(bottom, FRAMES_TO_RENDER_TILES * ROWS_TO_RENDER_PER_FRAME * CHAR_SUBPIXEL_SIZE, bottom_render)
!:
    jmp draw_tiles

update_hud:
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

    rts

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
{
    lda bottom_render
    sta current_render
    lda bottom_render+1
    sta current_render+1

    sub16(bottom_render, ROWS_TO_RENDER_PER_FRAME * CHAR_SUBPIXEL_SIZE, bottom_render)

!next_row:
    {
        lda current_render
        lsr // 0XXxxxxx
        lsr // 00XXxxxx
        lsr // 000XXxxx
        lsr // 0000XXxx
        and #$0c  // interested in bits 2-3 i.e. scale by 4
        sta row_in_tile

        ldx current_render+1 // vertical tile number
        lda y_to_levelmap_lo,x
        sta tile_to_render
        lda y_to_levelmap_hi,x
        sta tile_to_render+1

        ldy #0
        .for (var x = 0; x < TILES_PER_ROW; x++) {
            sty save_y
            ldy #x
            lda (tile_to_render),y
            tax
            lda tile_no_to_tile_offset,x
            clc
            adc.z row_in_tile
            tax
            ldy save_y:#0

            // Render tile
            .for (var i = 0; i < TILE_WIDTH; i++) {
                lda tiledata + i,x
                sta (screen_ptr),y
                iny
            }
        }

        add8(screen_ptr, 40, screen_ptr)
        sub8(current_render, CHAR_SUBPIXEL_SIZE, current_render)
    }
    lda current_render
    cmp bottom_render
    beq !+
    jmp !next_row-
!:
    lda current_render+1
    cmp bottom_render+1
    beq !+
    jmp !next_row-
!:
    rts
}
}

setup_screen:
    ldx scroll
    lda d011,x
    sta $d011

    add16(bottom, FRAMES_TO_RENDER_TILES * ROWS_TO_RENDER_PER_FRAME * CHAR_SUBPIXEL_SIZE, bottom_render)

    jsr irq.flip_screen
    .for (var i = 0; i < FRAMES_TO_RENDER_TILES; i++) {
        jsr irq.draw_tiles
    }

    rts

#import "../../lib/src/irq.asm"
#import "arithmetic.asm"

// HUD DATA
    .align 64
hud_sprite:
    .fill 63,255

.align $100
// LEVEL DATA. 4x4 tiles = 10 tiles per row
tiledata: .fill 256,i/16
tile_no_to_tile_offset: .fill 16,i*16

levelmap: .fill 256 * TILES_PER_ROW,i & 15 // 256 tile rows * 10 tile cols, only 16 tiles supported for now
y_to_levelmap_lo: .fill 256,<(levelmap + i * TILES_PER_ROW)
y_to_levelmap_hi: .fill 256,>(levelmap + i * TILES_PER_ROW)

// 16 bit y-coord:
// tttttttt TTyyynnn
// t = tile no
// T = row in tile data
// y = pixel on screen (scroll)
// n = 3-bit fixed point

scroll: .byte 7
bottom: .word 0
d011:   .byte $10,$11,$12,$13,$14,$15,$16,$17
d018:   .byte $14, $f4

screen_lo: .byte <SCREEN2,<SCREEN
screen_hi: .byte >SCREEN2,>SCREEN
screen_number: .byte 0
bottom_render: .word 0
current_render: .word 0
frame: .byte 0
*=$02 "Zeropage" virtual
.zp {
    screen_ptr: .word 0
    tile_to_render: .word 0
    row_in_tile: .byte 0
}