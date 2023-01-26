#importonce

.namespace level_renderer {
    .segment Default

    update:
        ldx scroll
        inx
        txa
        and #7
        tax
        stx scroll
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

        lda screen_lo,x
        sta screen_ptr
        lda screen_hi,x
        sta screen_ptr+1

        lda sprite_data_lo,x
        sta screen_sprite_ptr

        lda sprite_data_hi,x
        sta screen_sprite_ptr+1

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
        lda screen_ptr
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

    .align $100
    #import "level.asm"

    y_to_levelmap_lo: .fill MAP_LENGTH,<(levelmap + i * TILES_PER_ROW)
    .byte 255
    y_to_levelmap_hi: .fill MAP_LENGTH,>(levelmap + i * TILES_PER_ROW)
    .byte 255

    screen_lo: .byte <(SCREEN2+40),<(SCREEN+40)
    screen_hi: .byte >(SCREEN2+40),>(SCREEN+40)
    sprite_data_lo: .byte <SCREEN_SPRITES, <SCREEN2_SPRITES
    sprite_data_hi: .byte >SCREEN_SPRITES, >SCREEN2_SPRITES
    scroll: .byte 7
    screen_number: .byte 0

    .segment DATA

    bottom_render: .word 0
    current_render: .word 0

    .segment ZP
    .zp {
        screen_sprite_ptr: .word 0
        screen_ptr: .word 0
        tile_to_render: .word 0
    }

}