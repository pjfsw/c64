#importonce

.namespace level_renderer {
    .segment Default

    hud_irq:
    {
        sta save_a
        stx save_x
        sty save_y

        debug2()

        ldx scroll
        lda d011,x
        sta $d011

        set_top_row_colors(CHAR_COLOR)
        lda #FG_COLOR
        sta $d021

        debugoff(BORDER_COLOR)

        next_irq(sprite_irq, SPRITE_IRQ_ROW)

        lda save_a:#0
        ldy save_y:#0
        ldx save_x:#0
        rti
    }

    sprite_irq:
    {
        sta save_a
        stx save_x
        sty save_y

        debug1()

        switch_to_playfield_sprites()
        debugoff(BORDER_COLOR)

        next_irq(main_irq, IRQ_ROW)

        lda save_a:#0
        ldy save_y:#0
        ldx save_x:#0
        rti
    }

    .macro switch_to_playfield_sprites() {
        ldy #0
        sty $d01c
        .for (var i = 0; i < 8; i++) {
            lda sprite_ptr + i
            sta (level_renderer.screen_sprite_ptr),y
            iny
        }
        lda #0
        .for (var i = 0; i < 8; i++) {
            asl
            ora sprite_enabled+(7-i)
        }
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
        .for (var i = 0; i < 8; i++) {
            asl
            ora sprite_x_hi + (7-i)
        }
        sta $d010
    }

    main_irq:
    {
        sta save_a
        stx save_x
        sty save_y

        debug2()
        jsr update_screen
        debug1()
        jsr update_hud
        jsr update_anim
        jsr read_input
        set_top_row_colors(HUD_CHAR_COLOR)

        lda bottom+1
        cmp #BOTTOM_TILE_AT_END
        bne !+

        next_irq(level_clear_irq, IRQ_ROW)
        jmp !irq_done+
    !:
        inc frame

        next_irq(hud_irq, HUD_IRQ_ROW)

    !irq_done:
        debugoff(BORDER_COLOR)

        lda save_a:#0
        ldy save_y:#0
        ldx save_x:#0
        rti
    }

    update_screen:
    {
        add8(bottom, 8, bottom)
        ldx scroll
        inx
        txa
        and #7
        tax
        stx scroll
        cpx #0
        bne !+

        jsr flip_screen

        add16(bottom, FRAMES_TO_RENDER_TILES * ROWS_TO_RENDER_PER_FRAME * CHAR_SUBPIXEL_SIZE, bottom_render)
    !:
        jmp draw_tiles
    }

    flip_screen:
    {
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
    }

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

    update_hud:
    {
        lda #hud_sprite/64
        ldy #0

        .for (var i = 0; i < 7; i++) {
            sta (level_renderer.screen_sprite_ptr),y
            iny
        }

        lda #HUD_SPRITE_POS
        .for (var i = 0; i < 7; i++) {
            sta $d001 + i * 2
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
        lda #$7f
        sta $d01c // multicolor
        lda #BORDER_COLOR
        sta $d026
        lda #HUD_CHAR_COLOR
        sta $d025

        lda #$1f
        sta $d011

        ldx level_renderer.screen_number
        lda d018,x
        sta $d018

        ldx #20
    !:
        nop
        dex
        bne !-

        lda #HUD_FG_COLOR
        sta $d021

        rts
    }

    read_input:
    {
        ldx #0
        ldy #1
        lda $dc00
        stx joyup
        lsr
        bcs !+
        sty joyup
    !:
        stx joydown
        lsr
        bcs !+
        sty joydown
    !:
        stx joyleft
        lsr
        bcs !+
        sty joyleft
    !:
        stx joyright
        lsr
        bcs !+
        sty joyright
    !:
        stx joyfire
        lsr
        bcs !+
        sty joyfire
    !:
        rts
    }

    update_anim:
    {
        inc player_anim
        lda player_anim
        lsr
        and #1
        clc
        adc #player_sprite/64
        sta sprite_ptr + PLAYER_SPRITE_NO
        adc #SHADOW_SPRITE_OFFSET
        sta sprite_ptr + SHADOW_SPRITE_NO
        lda #gun_sprite/64
        sta sprite_ptr + FIRE_SPRITE_NO
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

    d011:   .byte $17,$10,$11,$12,$13,$14,$15,$16
    d018:   .byte SCREEN_D018, SCREEN2_D018

    sprite_ptr:
        .fill 8,0
    sprite_x:
        .fill 8,0
    sprite_y:
        .fill 8,0
    sprite_x_hi:
        .fill 8,0
    sprite_color:
        .byte 1,0,7,0,0,0,0,0
    sprite_enabled:
        .byte 0,0,0,0,0,0,0,0

    .segment DATA
    frame:
        .byte 0

    bottom: .word 0
    bottom_render: .word 0
    current_render: .word 0
    joyup:
        .byte 0
    joydown:
        .byte 0
    joyleft:
        .byte 0
    joyright:
        .byte 0
    joyfire:
        .byte 0

    .segment ZP
    .zp {
        screen_sprite_ptr: .word 0
        screen_ptr: .word 0
        tile_to_render: .word 0
    }

}

    // World coordinates:
    // TTTTTTTT CCxxxsss
    // T = Tile number
    // C = Char within tile
    // x = pixel within char
    // s = subpixel

.function pixels_to_world(pixels) {
    .return pixels * 8
}

.function chars_to_world(chars) {
    .return pixels_to_world(chars*8)
}
.function tiles_to_world(tiles) {
    .return chars_to_world(tiles * 4)
}


