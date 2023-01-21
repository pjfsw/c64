    .const SCREEN=$0400
    .const SCREEN2=$3c00
    .const ROWS_TO_RENDER_PER_FRAME=3
    .const FRAMES_TO_RENDER_TILES=8
    .const BORDER_COLOR = 0
    .const FG_COLOR = 6
    .const CHAR_COLOR = 5
    .const DEBUG_COLOR1 = 11
    .const DEBUG_COLOR2 = 12
    .const TILE_WIDTH = 4
    .const TILES_PER_ROW = 40/TILE_WIDTH
    .const TILE_HEIGHT = 4
    .const FIXED_POINT = 8
    .const CHAR_HEIGHT = 8 // Well this is never gonna change but might as well constant it for readability
    .const CHAR_SUBPIXEL_SIZE = FIXED_POINT * CHAR_HEIGHT
    .const MAP_LENGTH = 200
    .const BOTTOM_TILE_AT_END = MAP_LENGTH - 24/TILE_HEIGHT

BasicUpstart2(program_start)
    *=$080e

program_start:
    jsr setup_screen
    sei
    ldx #<irq
    ldy #>irq
    lda #$ea
    jsr lib_setup_irq
    cli
    jmp *

level_clear_irq: {
    sta save_a
    stx save_x
    sty save_y
    lda #$ff   // this is the orthodox and safe way of clearing the interrupt condition of the VICII.
    sta $d019

    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti
}


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
    lda #DEBUG_COLOR1
    sta $d020
    jsr update_sprites
    jsr update_anim

    lda bottom+1
    cmp #BOTTOM_TILE_AT_END
    bne !+
    lda #<level_clear_irq
    sta $fffe
    lda #>level_clear_irq
    sta $ffff
!:

    lda #BORDER_COLOR
    sta $d020

    lda #$ff   // this is the orthodox and safe way of clearing the interrupt condition of the VICII.
    sta $d019

    lda save_a:#0
    ldy save_y:#0
    ldx save_x:#0
    rti

update_sprites:
{
    .for (var i = 0; i < 8; i++) {
        // TODO FIX THIS
        lda sprite_ptr + i
        sta SCREEN + $3f8 + i
        sta SCREEN2 + $3f8 + i
    }

    lda #$7f
    sta $d015 // sprite enable
    lda #0
    sta $d01d // normal width

    .for (var i = 0; i < 8; i++) {
        lda sprite_x + i
        sta $d000 + i * 2
        lda sprite_y + i
        sta $d001 + i * 2
        lda sprite_color + i
        sta $d027 + i // color
    }

    lda #0
    sta $d010

    rts
}

update_anim:
    lda player_anim
    eor #1
    sta player_anim
    clc
    adc #player_sprite/64
    sta sprite_ptr
    rts

update_hud:
    lda #hud_sprite/64
    .for (var i = 0; i < 7; i++) {
        // TODO FIX THIS
        sta SCREEN+$3f8 + i
        sta SCREEN2+$3f8 + i
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

    rts

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

flip_screen:
    lda screen_number
    eor #1
    sta screen_number
    tax
    lda d018,x
    sta $d018
    lda screen_lo,x
    sta screen_ptr
    lda screen_hi,x
    sta screen_ptr+1

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
    lda #0
    sta $d01b // sprite priority

    .for (var i = 0; i < 63; i++) {
        lda player_sprite + i
        .if (mod(i,6) >= 3) {
            and #%10101010
        } else {
            and #%01010101
        }
        sta shadow_sprite + i
    }

    lda #172
    sta sprite_x
    lda #208
    sta sprite_y

    lda #176
    sta sprite_x+1
    lda #212
    sta sprite_y+1

    lda #FG_COLOR
    sta $d021
    ldx scroll
    lda d011,x
    sta $d011

    lda #CHAR_COLOR
    ldx #0
!:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    inx
    bne !-

    add16(bottom, FRAMES_TO_RENDER_TILES * ROWS_TO_RENDER_PER_FRAME * CHAR_SUBPIXEL_SIZE, bottom_render)

    jsr irq.flip_screen
    .for (var i = 0; i < FRAMES_TO_RENDER_TILES; i++) {
        jsr irq.draw_tiles
    }

    rts

#import "../../lib/src/irq.asm"
#import "arithmetic.asm"

// SPRITE DATA
    .align 64
hud_sprite:
    .fill 64,255
player_sprite:
    .for (var i = 0; i < 2; i++) {
        .byte %00000000
         .if (i == 0) {
            .byte %11111000
        } else {
            .byte %00011111
        }
        .byte %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00111100, %00000000
        .byte %01111111,%11111111, %11111110
        .byte %11111111,%11111111, %11111111
        .byte %01111111,%11111111, %11111110
        .byte %00011111,%11111111, %11111000
        .byte %00000000,%00111100, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00011000, %00000000
        .byte %00000000,%00111100, %00000000
        .byte %00000000,%11111111, %00000000
        .byte 0
    }

shadow_sprite:
    .fill 64,0
player_anim:
    .byte 0

sprite_ptr:
    .byte player_sprite/64
    .byte shadow_sprite/64
    .fill 6,0
sprite_x:
    .fill 8,0
sprite_y:
    .fill 8,0
sprite_x_hi:
    .fill 8,0
sprite_color:
    .byte 1,0,0,0,0,0,0,0

.align $100
// LEVEL DATA. 4x4 tiles = 10 tiles per row
tiledata:
  .fill 16,$20

  .byte $20,$66,$66,$20
  .byte $66,$dc,$a0,$5c
  .byte $66,$a0,$a0,$5c
  .byte $20,$68,$68,$20

  .fill 16,$20
  .fill 16,$20

  .fill 4,[$a0,$5c,$20,$20]
  .fill 4,[$a0,$66,$20,$20]
  .fill 4,[$20,$20,$66,$a0]
  .fill 4,[$20,$66,$a0,$a0]

  .byte $4a,$40,$40,$4b
  .byte $42,$20,$20,$42
  .byte $42,$20,$20,$42
  .byte $55,$40,$40,$49

  .byte $6d,$40,$40,$7d
  .byte $42,$20,$20,$42
  .byte $42,$20,$20,$42
  .byte $70,$40,$40,$6e

  .byte $20,$20,$20,$5f
  .byte $20,$20,$5f,$a0
  .byte $20,$5f,$a0,$a0
  .byte $5f,$a0,$a0,$a0
tiledata_manual_end:
 .fill 256-(tiledata_manual_end-tiledata),i/16
tile_no_to_tile_offset: .fill 16,i*16

levelmap:
    .for (var n = 0; n < MAP_LENGTH; n++) {
        .byte 4+(n&1) // left Shore
        .for (var n = 1; n < 9; n++) {
            .var r = floor(8 * random())
            .if (r == 0) {
                .byte $1
            } else {
                .byte $0
            }
        }
        .byte 6+(n&1)
    }

y_to_levelmap_lo: .fill MAP_LENGTH,<(levelmap + i * TILES_PER_ROW)
.byte 255
y_to_levelmap_hi: .fill MAP_LENGTH,>(levelmap + i * TILES_PER_ROW)
.byte 255

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
    screen_sprite_ptr: .word 0
    tile_to_render: .word 0
    row_in_tile: .byte 0
}