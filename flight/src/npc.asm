npc: {
.segment Default

update_npc_hit:
{
    lda npc_player_fire_x+1
    cmp #$ff
    beq !+

    ldx npc_index
    lda npc_is_alive,x
    beq !+

    // Compare heights first
    ldy npc_h_index
    lda npc_h,y
    adc #7 // Add some slack in height comparison
    cmp player_h
    bcc !+
    sec
    sbc #9
    cmp player_h
    bcs !+


    // 16-bit indexed from here
    txa
    asl
    tax
    clc
    lda npc_player_fire_x
    adc #24
    sta npc_temp
    lda npc_player_fire_x+1
    adc #0
    sta npc_temp+1
    cmp16x_mem(sprite_x_coord.npc, sprite_x_coord.npc+1, npc_temp)
    bcs !+

    clc
    lda sprite_x_coord.npc,x
    adc #24
    sta npc_temp
    lda sprite_x_coord.npc + 1,x
    adc #0
    sta npc_temp+1

    cmp16mem(npc_temp, npc_player_fire_x)
    bcc !+
    {
        ldx npc_index
        dec npc_hitpoints,x
        bne !+
        lda #0
        sta npc_is_alive,x
        rts
    !:
        lda #4
        sta npc_hit_display_timer,x
    }
!:
    rts
}

update_npc:
{
    ldx npc_index
    lda npc_is_alive,x
    sta npc_enabled,x

    // Animation stuff
    lda level_renderer.frame
    and #2
    lsr
    tay
    clc
    adc #npc_sprite/64
    sta level_renderer.sprite_ptr + NPC_SPRITE_NO
    sta level_renderer.sprite_ptr + NPC_SPRITE_NO+1
    lda #0
    sta level_renderer.sprite_color + NPC_SPRITE_NO,x
    lda npc_hit_display_timer,x
    beq !+
    lda #2
    sta level_renderer.sprite_color + NPC_SPRITE_NO,x
    dec npc_hit_display_timer,x
!:
    // Setup proper sprite  pointers and colors
    lda #0
    sta level_renderer.sprite_color + NPC_SHADOW_SPRITE_NO,x

    tya
    clc
    adc #npc_shadow_sprite/64
    sta level_renderer.sprite_ptr + NPC_SHADOW_SPRITE_NO
    sta level_renderer.sprite_ptr + NPC_SHADOW_SPRITE_NO+1

    lda npc_sequence_pos_scale,x
    clc
    adc #1
    and #7  // Takes too much memory to change position every frame
    bne !+
    inc npc_sequence_pos,x
    lda #0
!:
    sta npc_sequence_pos_scale,x
    lda npc_sequence_pos,x
    tay
    // Do 8-bit indexed operations here
    // ..
    // 16-bit indexed from here
    txa
    asl
    tax

    // Update and store x-position of NPC which is unaffected by height
    clc
    lda npc_movement_x_lo,y
    adc sprite_x_coord.npc,x
    sta sprite_x_coord.npc,x
    lda npc_movement_x_hi,y
    adc sprite_x_coord.npc+1,x
    sta sprite_x_coord.npc+1,x

    // Update and store NPC shadow y-position as it's not affected by height
    clc
    lda npc_movement_y_lo,y
    adc sprite_y_coord.npc_shadow,x
    sta sprite_y_coord.npc_shadow,x
    lda npc_movement_y_hi,y
    adc sprite_y_coord.npc_shadow+1,x
    sta sprite_y_coord.npc_shadow+1,x

    // Update y position of NPC based on shadow y position and height
    ldy npc_h_index
    lda npc_h,y
    tay

    clc
    lda height_to_world,y
    adc sprite_y_coord.npc_shadow,x
    sta sprite_y_coord.npc,x
    lda #0
    adc sprite_y_coord.npc_shadow+1,x
    sta sprite_y_coord.npc+1,x

    // Finally fix shadow X-position
    clc
    lda sprite_x_coord.npc,x
    ldy npc_h_index
    adc npc_h,y
    sta sprite_x_coord.npc_shadow,x
    lda sprite_x_coord.npc+1,x
    adc #0
    sta sprite_x_coord.npc_shadow+1,x

    rts
}

next_npc:
    .byte 0
next_npc_sprite:
    .byte 0
npc_trigger_x_coord:
    .word 0,0
npc_hitpoints:
    .fill 2,0
npc_is_alive:
    .fill 2,0
npc_hit_display_timer:
    .fill 2,0

npc_trigger:
    .fill NUMBER_OF_NPCS, [i*10+4, i*10+9] // 41*6+9 = 255
npc_move_func_lo:
    .fill NUMBER_OF_NPCS, <update_npc
npc_move_func_hi:
    .fill NUMBER_OF_NPCS, >update_npc

npc_movement_x_lo:
    .fill 64,<getMoveX(i)
npc_movement_x_hi:
    .fill 64,>getMoveX(i)
npc_movement_y_lo:
    .fill 64,<getMoveY(i)
npc_movement_y_hi:
    .fill 64,>getMoveY(i)
npc_h:
    .fill 256,round(8+7*sin(toRadians(i*360/256)))

.segment DATA
npc_index:
    .byte 0
npc_sequence_pos_scale:
    .byte 0
    .byte 0
npc_sequence_pos:
    .byte 0
    .byte 0
npc_player_fire_x:
    .word 0
npc_temp:
    .word 0
npc_h_index:
    .byte 0
npc_enabled:
    .byte 0,0
}

.function getMoveX(i) {
    .return abs(i-32)/28+1
}

.function getMoveY(i) {
    .return 16-i/2
}